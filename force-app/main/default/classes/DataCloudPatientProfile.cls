public class DataCloudPatientProfile {
    
    @InvocableMethod(label='Get Patient 360 Profile' 
                     description='Fetch unified patient profile insights and Predictive No-Show risk')
    public static List<ProfileResult> getProfile(List<ProfileRequest> requests) {
        List<ProfileResult> results = new List<ProfileResult>();
        
        for (ProfileRequest req : requests) {
            ProfileResult result = new ProfileResult();
            try {
                // Step 1: Fetch core patient data
                List<Account> patients = [
                    SELECT Id, Name, Patient_ID__c, Primary_Diagnosis__c, Is_High_Risk__c
                    FROM Account
                    WHERE Id = :req.patientId OR Patient_ID__c = :req.patientId LIMIT 1
                ];
                
                if (patients.isEmpty()) {
                    result.profileSummary = 'Patient profile not found.';
                    results.add(result);
                    continue;
                }
                
                Account p = patients[0];
                
                // Step 2: Calculate Predictive Insights
                Integer total = [SELECT COUNT() FROM Appointment__c WHERE Patient__c = :p.Id];
                Integer noShows = [SELECT COUNT() FROM Appointment__c WHERE Patient__c = :p.Id AND Status__c = 'No Show'];
                
                // Step 3: Predictive No-Show Logic (The AI part)
                Decimal probability = 10; // Default 10%
                if (noShows >= 3) probability = 90;
                else if (noShows == 2) probability = 60;
                else if (noShows == 1) probability = 30;

                // Step 4: Build the Predictive Intelligence Brief
                String summary = '📊 **Patient 360° Predictive Intelligence**\n\n';
                summary += '👤 **Patient:** ' + p.Name + '\n';
                summary += '🩺 **Diagnosis:** ' + (p.Primary_Diagnosis__c != null ? p.Primary_Diagnosis__c : 'Not specified') + '\n';
                summary += '📈 **Predictive No-Show Probability:** ' + probability + '%\n';
                
                if (probability >= 60) {
                    summary += '⚠️ **PREDICTIVE ALERT:** High probability of missing next appointment. Action: Confirm transport and send extra reminders.\n';
                }
                
                summary += '📅 **Visit History:** ' + total + ' visits (' + noShows + ' no-shows)\n';
                summary += '⚡ **Clinical Risk:** ' + (p.Is_High_Risk__c ? 'High' : 'Low') + '\n';

                result.profileSummary = summary;
                result.riskLevel = p.Is_High_Risk__c ? 'High' : 'Low';
                
            } catch (Exception e) {
                result.profileSummary = 'Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class ProfileRequest {
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
    }
    
    public class ProfileResult {
        @InvocableVariable(label='Profile Summary')
        public String profileSummary;
        @InvocableVariable(label='Risk Level')
        public String riskLevel;
    }
}