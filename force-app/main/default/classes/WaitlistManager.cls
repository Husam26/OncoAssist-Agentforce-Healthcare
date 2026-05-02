public class WaitlistManager {
    
    @InvocableMethod(label='Add to Smart Waitlist' 
                     description='Creates a real Waitlist record in Salesforce')
    public static List<WaitlistResult> addToWaitlist(List<WaitlistRequest> requests) {
        List<WaitlistResult> results = new List<WaitlistResult>();
        List<Waitlist__c> entriesToInsert = new List<Waitlist__c>();
        
        for (WaitlistRequest req : requests) {
            Waitlist__c entry = new Waitlist__c();
            
            // Try to find the Patient (Account) by ID or Name
            List<Account> patients = [SELECT Id FROM Account WHERE Id = :req.patientId OR Name = :req.patientId LIMIT 1];
            if(!patients.isEmpty()) entry.Patient__c = patients[0].Id;
            
            entry.Department__c = req.department;
            entry.Status__c = 'Active';
            
            // In a real hackathon demo, we just assign a random position for speed
            entry.Waitlist_Position__c = Math.floor(Math.random() * 10) + 1; 
            
            entriesToInsert.add(entry);
        }
        
        if (!entriesToInsert.isEmpty()) {
            insert entriesToInsert;
        }
        
        // Return results to Agent
        for (Waitlist__c inserted : entriesToInsert) {
            WaitlistResult res = new WaitlistResult();
            res.confirmationMessage = 'Record created! You are now officially on the waitlist.';
            res.waitlistPosition = Integer.valueOf(inserted.Waitlist_Position__c);
            res.estimatedDays = res.waitlistPosition * 2;
            results.add(res);
        }
        
        return results;
    }
    
    public class WaitlistRequest {
        @InvocableVariable(label='Patient ID or Name' required=true)
        public String patientId;
        
        @InvocableVariable(label='Department')
        public String department;
        
        @InvocableVariable(label='Preferred Doctor')
        public String preferredDoctor; // Added this field to fix the error!
    }
    
    public class WaitlistResult {
        @InvocableVariable(label='Confirmation Message')
        public String confirmationMessage;
        
        @InvocableVariable(label='Waitlist Position')
        public Integer waitlistPosition;
        
        @InvocableVariable(label='Estimated Wait (Days)')
        public Integer estimatedDays;
    }
}