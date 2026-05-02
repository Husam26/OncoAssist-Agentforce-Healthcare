public class PatientSentimentAnalyzer {
    
    @InvocableMethod(label='Analyze Patient Sentiment' 
                     description='Detects emotion in patient messages for empathy routing')
    public static List<SentimentResult> analyze(List<SentimentRequest> requests) {
        List<SentimentResult> results = new List<SentimentResult>();
        
        for (SentimentRequest req : requests) {
            SentimentResult result = new SentimentResult();
            String msg = req.lastMessage.toLowerCase();
            
            // Basic Keyword Sentiment Engine
            if (msg.contains('angry') || msg.contains('frustrated') || msg.contains('worst') || msg.contains('wait')) {
                result.sentiment = 'Frustrated';
                result.empathyProtocol = 'Escalate to Patient Relations Manager immediately. Use de-escalation tone.';
            } else if (msg.contains('worried') || msg.contains('scared') || msg.contains('pain') || msg.contains('help')) {
                result.sentiment = 'Anxious';
                result.empathyProtocol = 'Use supportive, calming tone. Offer a callback from a Nurse Coordinator.';
            } else {
                result.sentiment = 'Neutral';
                result.empathyProtocol = 'Maintain professional and helpful tone.';
            }
            results.add(result);
        }
        return results;
    }
    
    public class SentimentRequest {
        @InvocableVariable(label='Last Message' required=true)
        public String lastMessage;
    }
    
    public class SentimentResult {
        @InvocableVariable(label='Detected Sentiment')
        public String sentiment;
        @InvocableVariable(label='Empathy Protocol')
        public String empathyProtocol;
    }
}