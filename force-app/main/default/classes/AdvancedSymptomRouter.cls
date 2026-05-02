public class AdvancedSymptomRouter {
    
    @InvocableMethod(label='Advanced Symptom Router'
                     description='Final Version: Fixes Hematology/Diagnostics and preserves Emergency/Urgent behavior')
    public static List<TriageResult> analyze(List<TriageRequest> requests) {
        List<TriageResult> results = new List<TriageResult>();
        
        for (TriageRequest req : requests) {
            TriageResult result = new TriageResult();
            String input = req.patientSymptoms.toLowerCase();
            
            Map<Id, Double> scores = new Map<Id, Double>();
            Map<Id, String> deptNames = new Map<Id, String>();
            Map<Id, String> followUps = new Map<Id, String>();
            
            // To track the highest urgency found for the WINNING department
            Map<Id, Integer> deptMaxUrgency = new Map<Id, Integer>();
            Map<Id, Boolean> deptHasRedFlag = new Map<Id, Boolean>();

            // 1. MATCH AGAINST SPECIALTY TAGS (Word-level Fuzzy Match)
            List<Department__c> allDepts = [SELECT Id, Name, Specialty_Tags__c FROM Department__c WHERE Is_Active__c = true];
            List<String> inputWords = input.replaceAll('[^a-zA-Z0-9\\s]', ' ').split('\\s+');

            for (Department__c d : allDepts) {
                String tags = d.Specialty_Tags__c != null ? d.Specialty_Tags__c.toLowerCase() : '';
                Double deptBoost = 0;

                for (String word : inputWords) {
                    if (word.length() >= 3 && tags.contains(word)) {
                        deptBoost += 40.0; // Cumulative boost for multiple tag matches
                    }
                }
                
                if (deptBoost > 0) {
                    scores.put(d.Id, deptBoost);
                    deptNames.put(d.Id, d.Name);
                }
            }

            // 2. MATCH AGAINST SYMPTOM MAPS (Weighted Clinical Logic)
            List<Symptom_Department_Map__c> mappings = [
                SELECT Symptom__c, Department__c, Department__r.Name, 
                       Weight_Score__c, Urgency_Score__c, Red_Flag__c, Follow_Up_Question__c
                FROM Symptom_Department_Map__c
            ];
            
            for (Symptom_Department_Map__c m : mappings) {
                String sym = m.Symptom__c.toLowerCase();
                if (input.contains(sym)) {
                    Double weight = m.Weight_Score__c != null ? (Double)m.Weight_Score__c : 50.0;
                    Double currentScore = scores.containsKey(m.Department__c) ? scores.get(m.Department__c) : 0.0;
                    
                    scores.put(m.Department__c, currentScore + weight);
                    deptNames.put(m.Department__c, m.Department__r.Name);
                    
                    // Track urgency per department
                    Integer urgency = m.Urgency_Score__c != null ? m.Urgency_Score__c.intValue() : 0;
                    if (!deptMaxUrgency.containsKey(m.Department__c) || urgency > deptMaxUrgency.get(m.Department__c)) {
                        deptMaxUrgency.put(m.Department__c, urgency);
                    }
                    if (m.Red_Flag__c == true) {
                        deptHasRedFlag.put(m.Department__c, true);
                    }
                    if (m.Follow_Up_Question__c != null) followUps.put(m.Department__c, m.Follow_Up_Question__c);
                }
            }

            // 3. FIND THE WINNER
            Id bestId = null; Double highestScore = -1.0;
            for(Id i : scores.keySet()) { 
                if(scores.get(i) > highestScore) { 
                    highestScore = scores.get(i); 
                    bestId = i; 
                } 
            }

            if (bestId != null) {
                String finalDeptName = deptNames.get(bestId);
                Integer finalUrgency = deptMaxUrgency.containsKey(bestId) ? deptMaxUrgency.get(bestId) : 0;
                Boolean finalRedFlag = deptHasRedFlag.containsKey(bestId) ? deptHasRedFlag.get(bestId) : false;
                
                result.confidenceScore = 95;
                
                // --- BEHAVIOR SYNC (Matching your exact Test Cases) ---
                
                // EMERGENCY: High Urgency (9+) OR Red Flag
                if (finalUrgency >= 9 || finalRedFlag) {
                    result.severityLevel = 'Emergency';
                    result.isEmergency = true;
                    result.routingResult = '🚨 **CRITICAL ALERT** 🚨\n\n'
                        + 'Your symptoms indicate a need for immediate evaluation in **' + finalDeptName + '**.\n'
                        + '⚠️ **Action Required**: This is potentially life-threatening. Please call **1800-ONCO-911** or visit an ER immediately.';
                } 
                // URGENT: Urgency 7-8
                else if (finalUrgency >= 7) {
                    result.severityLevel = 'Urgent';
                    result.isEmergency = false;
                    result.routingResult = '🔍 Analysis: These symptoms align with our **' + finalDeptName + '** department.\n'
                        + '⚠️ **Priority: Urgent**. Please book an appointment within the next 24-48 hours.';
                } 
                // MODERATE / ROUTINE: Everything else
                else {
                    result.severityLevel = 'Moderate';
                    result.isEmergency = false;
                    result.routingResult = '🔍 Analysis: We recommend a consultation with the **' + finalDeptName + '** department.';
                }
                
                result.followUpQuestions = followUps.get(bestId);
                
                try {
                    Triage_Log__c log = new Triage_Log__c();
                    log.Symptoms_Reported__c = req.patientSymptoms;
                    log.Matched_Department__c = bestId;
                    log.Severity_Level__c = result.severityLevel;
                    log.Triage_Timestamp__c = DateTime.now();
                    insert log;
                } catch(Exception e) {}
            } else {
                result.routingResult = '🤔 I couldn\'t find a specific clinical match. Could you share more details?';
                result.severityLevel = 'Routine';
            }
            results.add(result);
        }
        return results;
    }

    public class TriageRequest { @InvocableVariable(required=true) public String patientSymptoms; }
    public class TriageResult {
        @InvocableVariable public String routingResult;
        @InvocableVariable public String severityLevel;
        @InvocableVariable public String followUpQuestions;
        @InvocableVariable public Boolean isEmergency;
        @InvocableVariable public Integer confidenceScore;
    }
}