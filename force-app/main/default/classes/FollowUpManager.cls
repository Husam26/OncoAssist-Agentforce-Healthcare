public class FollowUpManager {
    
    @InvocableMethod(label='Get Pending Follow-Ups' 
                     description='Checks for patients who recently completed an appointment')
    public static List<FollowUpResult> check(List<FollowUpRequest> requests) {
        List<FollowUpResult> results = new List<FollowUpResult>();
        
        for (FollowUpRequest req : requests) {
            FollowUpResult result = new FollowUpResult();
            try {
                // Fetching Department__r.Name to get the human-readable name!
                List<Appointment__c> appts = [SELECT Id, Patient__r.Name, Department__r.Name, Appointment_Date__c 
                                               FROM Appointment__c 
                                               WHERE (Patient__c = :req.patientId OR Patient__r.Name = :req.patientId)
                                               AND Status__c = 'Completed' 
                                               ORDER BY Appointment_Date__c DESC LIMIT 1];
                
                if (appts.isEmpty()) {
                    result.hasPendingFollowUp = false;
                    result.message = 'No recent visits.';
                } else {
                    result.hasPendingFollowUp = true;
                    // Fix: Use .Name to avoid showing the ID
                    String deptName = appts[0].Department__r.Name != null ? appts[0].Department__r.Name : 'clinic';
                    String visitDate = appts[0].Appointment_Date__c != null ? appts[0].Appointment_Date__c.format() : 'recently';
                    
                    result.message = 'Hi ' + appts[0].Patient__r.Name + '! I see you completed your visit with the ' + deptName + ' department on ' + visitDate + '. How are you feeling today?';
                }
            } catch (Exception e) {
                result.hasPendingFollowUp = false;
                result.message = 'Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class FollowUpRequest {
        @InvocableVariable(label='Patient ID or Name' required=true)
        public String patientId;
    }
    
    public class FollowUpResult {
        @InvocableVariable(label='Has Pending Follow-Up')
        public Boolean hasPendingFollowUp;
        @InvocableVariable(label='Follow-Up Message')
        public String message;
    }
}