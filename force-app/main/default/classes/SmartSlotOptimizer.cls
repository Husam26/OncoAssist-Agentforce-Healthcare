public class SmartSlotOptimizer {
    
    @InvocableMethod(label='Smart Slot Recommendation'
                     description='AI-optimized recommendations (Handles Names, IDs, and Time Preferences)')
    public static List<OptimizationResult> getOptimizedSlots(List<OptimizationRequest> requests) {
        List<OptimizationResult> results = new List<OptimizationResult>();
        
        for (OptimizationRequest req : requests) {
            OptimizationResult result = new OptimizationResult();
            
            // 1. SMART ID RESOLUTION: Convert Department Name to ID
            Id realDeptId;
            String inputDept = req.departmentId;
            if (inputDept == null) {
                result.optimizedSlots = 'Please specify a department.';
                results.add(result); continue;
            }

            if (inputDept.startsWith('a0')) { // It's already an ID
                realDeptId = (Id)inputDept;
            } else { // It's a Name
                List<Department__c> depts = [SELECT Id FROM Department__c WHERE Name = :inputDept OR Name LIKE :('%'+inputDept+'%') LIMIT 1];
                if (!depts.isEmpty()) realDeptId = depts[0].Id;
                else {
                    result.optimizedSlots = 'Department not found: ' + inputDept;
                    results.add(result); continue;
                }
            }

            // 2. GATHER PATIENT PREFERENCES
            Account patient = null;
            if (req.patientId != null && req.patientId != '') {
                List<Account> patients = [SELECT Id, Preferred_Time__c FROM Account WHERE Id = :req.patientId LIMIT 1];
                if (!patients.isEmpty()) patient = patients[0];
            }
            
            // 3. FETCH CANDIDATE SLOTS (Next 14 Days)
            Date startDate = (req.urgencyLevel == 'Urgent' || req.urgencyLevel == 'High') ? Date.today() : Date.today().addDays(1);
            Date endDate = startDate.addDays(14);
            
            List<Time_Slot__c> slots = [
                SELECT Id, Provider__c, Provider__r.Name, Provider__r.Hospital__r.Name,
                       Slot_Date__c, Start_Time__c, Provider__r.Experience_Years__c
                FROM Time_Slot__c
                WHERE Provider__r.Department__c = :realDeptId
                AND Slot_Date__c >= :startDate AND Slot_Date__c <= :endDate
                AND Is_Available__c = TRUE AND Is_Booked__c = FALSE
                ORDER BY Slot_Date__c ASC, Start_Time__c ASC
                LIMIT 50
            ];

            // 4. GET WORKLOAD DATA
            Map<String, Integer> workloadMap = new Map<String, Integer>();
            for (AggregateResult ar : [SELECT Provider__c pId, Appointment_Date__c aDate, COUNT(Id) cnt 
                                       FROM Appointment__c WHERE Appointment_Date__c >= :startDate 
                                       GROUP BY Provider__c, Appointment_Date__c]) {
                workloadMap.put((Id)ar.get('pId') + '_' + (Date)ar.get('aDate'), (Integer)ar.get('cnt'));
            }
            
            // 5. SCORE AND RANK
            List<ScoredSlot> scoredSlots = new List<ScoredSlot>();
            for (Time_Slot__c s : slots) {
                ScoredSlot ss = new ScoredSlot();
                ss.slot = s;
                ss.totalScore = 100; // Base Score
                ss.reasons = new List<String>();
                
                // Rule A: Earliest Availability (Lower days = Higher score)
                Integer daysOut = Date.today().daysBetween(s.Slot_Date__c);
                ss.totalScore += (14 - daysOut) * 10;
                
                // Rule B: Preference (Morning, Afternoon, or Evening)
                if (patient != null && patient.Preferred_Time__c != null) {
                    String timeStr = s.Start_Time__c;
                    Integer hour = Integer.valueOf(timeStr.split(':')[0]);
                    
                    // Convert to 24-hour logic
                    if (timeStr.contains('PM') && hour != 12) hour += 12;
                    if (timeStr.contains('AM') && hour == 12) hour = 0;

                    Boolean matches = false;
                    String pref = patient.Preferred_Time__c;
                    
                    if (pref == 'Morning' && hour < 12) matches = true;
                    else if (pref == 'Afternoon' && hour >= 12 && hour < 16) matches = true;
                    else if (pref == 'Evening' && hour >= 16) matches = true;

                    if (matches) {
                        ss.totalScore += 80; // Significant boost for preference
                        ss.reasons.add('✅ Matches ' + pref + ' preference');
                    }
                }

                // Rule C: Workload Balancing
                String key = s.Provider__c + '_' + s.Slot_Date__c;
                Integer load = workloadMap.containsKey(key) ? workloadMap.get(key) : 0;
                if (load > 8) ss.totalScore -= 40; 
                else ss.reasons.add('👨‍⚕️ Light schedule');
                
                scoredSlots.add(ss);
            }
            
            scoredSlots.sort();
            
            // 6. FORMAT RESULTS
            if (scoredSlots.isEmpty()) {
                result.optimizedSlots = 'No available slots found for ' + inputDept + ' in the next 14 days.';
            } else {
                String recs = '🧠 **Smart Recommendations for ' + inputDept + ':**\n\n';
                Integer count = 1;
                for (ScoredSlot ss : scoredSlots) {
                    if (count > 3) break;
                    recs += count + '. ' + ((count == 1) ? '⭐ BEST MATCH' : '🔹 Option ' + count) + '\n';
                    recs += '   📅 ' + ss.slot.Slot_Date__c.format() + ' at ' + ss.slot.Start_Time__c + '\n';
                    recs += '   👨‍⚕️ ' + ss.slot.Provider__r.Name + ' (' + ss.slot.Provider__r.Hospital__r.Name + ')\n';
                    if (!ss.reasons.isEmpty()) recs += '   💡 ' + String.join(ss.reasons, ' | ') + '\n';
                    recs += '\n';
                    count++;
                }
                result.optimizedSlots = recs;
            }
            results.add(result);
        }
        return results;
    }
    
    public class ScoredSlot implements Comparable {
        public Time_Slot__c slot; public Decimal totalScore; public List<String> reasons;
        public Integer compareTo(Object other) {
            ScoredSlot o = (ScoredSlot)other;
            if (this.totalScore > o.totalScore) return -1;
            if (this.totalScore < o.totalScore) return 1;
            return 0;
        }
    }
    
    public class OptimizationRequest {
        @InvocableVariable public String departmentId;
        @InvocableVariable public String patientId;
        @InvocableVariable public String urgencyLevel;
        @InvocableVariable public String appointmentType;
    }
    
    public class OptimizationResult {
        @InvocableVariable public String optimizedSlots;
    }
}