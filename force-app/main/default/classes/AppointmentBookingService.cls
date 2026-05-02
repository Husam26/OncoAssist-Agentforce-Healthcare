public class AppointmentBookingService {
    
    @InvocableMethod(label='Identify Patient' 
                     description='Search for a patient by name, ID, phone, or email')
    public static List<PatientSearchResult> identifyPatient(List<PatientSearchRequest> requests) {
        List<PatientSearchResult> results = new List<PatientSearchResult>();
        
        for (PatientSearchRequest req : requests) {
            PatientSearchResult result = new PatientSearchResult();
            String term = req.searchTerm.trim();
            
            List<Account> patients;
            
            // Try Patient ID first (Format: PAT-XXXXX)
            if (term.startsWithIgnoreCase('PAT-')) {
                patients = [
                    SELECT Id, Name, Patient_ID__c, Phone, PersonEmail,
                           Preferred_Hospital__r.Name
                    FROM Account
                    WHERE Patient_ID__c = :term
                    LIMIT 1
                ];
            } else {
                // Search by name, phone, or email
                patients = [
                    SELECT Id, Name, Patient_ID__c, Phone, PersonEmail,
                           Preferred_Hospital__r.Name
                    FROM Account
                    WHERE Name LIKE :('%' + term + '%')
                    OR Phone = :term
                    OR PersonEmail = :term
                    LIMIT 5
                ];
            }
            
            if (!patients.isEmpty()) {
                Account p = patients[0];
                result.patientFound = true;
                result.patientId = p.Id;
                result.patientName = p.Name;
                result.patientDetails = '👤 ' + p.Name + '\n'
                    + '🆔 ' + (p.Patient_ID__c != null ? p.Patient_ID__c : 'N/A') + '\n'
                    + '📞 ' + (p.Phone != null ? p.Phone : 'N/A') + '\n'
                    + '🏥 Preferred: ' + (p.Preferred_Hospital__r != null ? p.Preferred_Hospital__r.Name : 'None set');
                
                if (patients.size() > 1) {
                    result.patientDetails += '\n\n⚠️ Multiple patients found. Using the first match.';
                }
            } else {
                result.patientFound = false;
                result.patientDetails = 'No patient found with "' + term + '". Please check the spelling or provide your Patient ID.';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class PatientSearchRequest {
        @InvocableVariable(label='Search Term' required=true)
        public String searchTerm;
    }
    
    public class PatientSearchResult {
        @InvocableVariable(label='Patient Found')
        public Boolean patientFound;
        @InvocableVariable(label='Patient Salesforce ID')
        public String patientId;
        @InvocableVariable(label='Patient Name')
        public String patientName;
        @InvocableVariable(label='Patient Details')
        public String patientDetails;
    }
}