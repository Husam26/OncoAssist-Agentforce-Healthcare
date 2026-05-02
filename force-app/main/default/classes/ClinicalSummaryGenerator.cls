public class ClinicalSummaryGenerator {
    
    @InvocableMethod(label='Generate Clinical Summary' 
                     description='Creates a readable summary of the patient care journey')
    public static List<SummaryResult> generate(List<SummaryRequest> requests) {
        List<SummaryResult> results = new List<SummaryResult>();
        
        for (SummaryRequest req : requests) {
            SummaryResult result = new SummaryResult();
            
            try {
                // SMARTER QUERY: Looks for ID or Name to prevent crashes
                List<Account> patients = [SELECT Name, Primary_Diagnosis__c, 
                                          (SELECT Appointment_Date__c, Status__c, Department__c FROM Appointments__r ORDER BY Appointment_Date__c DESC LIMIT 5) 
                                          FROM Account 
                                          WHERE Id = :req.patientId OR Name = :req.patientId 
                                          LIMIT 1];
                
                if (patients.isEmpty()) {
                    result.rawClinicalData = 'No clinical records found for this patient name or ID.';
                } else {
                    Account p = patients[0];
                    String rawData = 'Patient: ' + p.Name + '\nDiagnosis: ' + (p.Primary_Diagnosis__c != null ? p.Primary_Diagnosis__c : 'General Oncology') + '\nRecent History:\n';
                    
                    if (p.Appointments__r.isEmpty()) {
                        rawData += 'No recent appointment history found.';
                    } else {
                        for (Appointment__c appt : p.Appointments__r) {
                            rawData += '- ' + appt.Appointment_Date__c + ': ' + appt.Department__c + ' (' + appt.Status__c + ')\n';
                        }
                    }
                    result.rawClinicalData = rawData;
                }
            } catch (Exception e) {
                result.rawClinicalData = 'Technical issue retrieving summary: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class SummaryRequest {
        @InvocableVariable(label='Patient ID or Name' required=true)
        public String patientId;
    }
    
    public class SummaryResult {
        @InvocableVariable(label='Raw Clinical Data')
        public String rawClinicalData;
    }
}