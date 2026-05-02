public class CaregiverAuthorizer {
    
    @InvocableMethod(label='Verify Caregiver Authorization' 
                     description='Checks if a user is authorized to manage another patients records')
    public static List<AuthResult> verify(List<AuthRequest> requests) {
        List<AuthResult> results = new List<AuthResult>();
        
        for (AuthRequest req : requests) {
            AuthResult result = new AuthResult();
            try {
                // Search for the Patient and check their authorized caregiver
                // Using names for the hackathon demo to make it easy to type
                List<Account> patients = [SELECT Name, Authorized_Caregiver__r.Name, Caregiver_Role__c 
                                          FROM Account 
                                          WHERE Name = :req.patientName LIMIT 1];
                
                if (patients.isEmpty()) {
                    result.isAuthorized = false;
                    result.message = 'I could not find a patient named ' + req.patientName + ' in our system.';
                } else {
                    Account p = patients[0];
                    // Case-insensitive name comparison
                    if (p.Authorized_Caregiver__r.Name != null && p.Authorized_Caregiver__r.Name.toLowerCase() == req.caregiverName.toLowerCase()) {
                        result.isAuthorized = true;
                        result.message = 'Access Granted. You are recognized as the ' + p.Caregiver_Role__c + ' and authorized caregiver for ' + p.Name + '.';
                    } else {
                        result.isAuthorized = false;
                        result.message = 'Access Denied. I see ' + p.Name + ' in my records, but you are not listed as an authorized caregiver for them.';
                    }
                }
            } catch (Exception e) {
                result.isAuthorized = false;
                result.message = 'System Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class AuthRequest {
        @InvocableVariable(label='Patient Name' required=true)
        public String patientName;
        @InvocableVariable(label='Caregiver Name' required=true)
        public String caregiverName;
    }
    
    public class AuthResult {
        @InvocableVariable(label='Is Authorized')
        public Boolean isAuthorized;
        @InvocableVariable(label='Authorization Message')
        public String message;
    }
}