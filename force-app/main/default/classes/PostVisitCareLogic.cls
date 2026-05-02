public class PostVisitCareLogic {
    
    @InvocableMethod(label='Handle Post-Visit Symptom' 
                     description='Analyzes reported symptoms after a visit and provides dynamic advice')
    public static List<CareResult> analyzeSymptom(List<CareRequest> requests) {
        List<CareResult> results = new List<CareResult>();
        
        for (CareRequest req : requests) {
            CareResult result = new CareResult();
            String symptom = req.reportedSymptom.toLowerCase();
            
            // Logic: Distinguish between common side effects and Red Flags
            if (symptom.contains('pain') && symptom.contains('chest') || symptom.contains('breathing')) {
                result.requiresEscalation = true;
                result.advice = 'This sounds serious. Please do not wait—contact our emergency line or proceed to the ER immediately.';
            } else {
                result.requiresEscalation = false;
                result.advice = 'Based on your recent visit, ' + req.reportedSymptom + ' can sometimes occur. I recommend resting, staying hydrated, and searching our care library for specific management tips. Would you like me to book a check-in with your doctor?';
            }
            results.add(result);
        }
        return results;
    }
    
    public class CareRequest {
        @InvocableVariable(label='Reported Symptom' required=true)
        public String reportedSymptom;
    }
    
    public class CareResult {
        @InvocableVariable(label='Care Advice')
        public String advice;
        @InvocableVariable(label='Requires Escalation')
        public Boolean requiresEscalation;
    }
}