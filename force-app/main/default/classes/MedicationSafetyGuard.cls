public class MedicationSafetyGuard {
    
    // API Key stored in Salesforce Custom Metadata for security. Replace with your own Groq API key.
    private static final String GROQ_API_KEY = 'YOUR_GROQ_API_KEY_HERE';
    private static final String GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';
    private static final String VISION_MODEL = 'meta-llama/llama-4-scout-17b-16e-instruct';
    private static final String TEXT_MODEL = 'llama-3.1-8b-instant';

    @InvocableMethod(label='Groq: Extract and Sync Meds' 
                     description='Syncs medications via raw text or by reading the actual uploaded prescription using Vision AI')
    public static List<SafetyResult> process(List<SafetyRequest> requests) {
        List<SafetyResult> results = new List<SafetyResult>();
        
        for (SafetyRequest req : requests) {
            SafetyResult result = new SafetyResult();
            try {
                Account p = [SELECT Id, External_Medications__c FROM Account WHERE Name = :req.patientName LIMIT 1];
                String extractedMeds = '';

                if (req.processLatestFile == true) {
                    List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId = :p.Id 
                                                      ORDER BY SystemModstamp DESC LIMIT 1];
                    if (links.isEmpty()) {
                        result.safetyMessage = 'No files found. Please upload your prescription to the Files section first.';
                        results.add(result);
                        continue;
                    }
                    
                    ContentVersion latestFile = [SELECT VersionData FROM ContentVersion 
                                                WHERE ContentDocumentId = :links[0].ContentDocumentId 
                                                AND IsLatest = true LIMIT 1];
                    
                    String base64Image = EncodingUtil.base64Encode(latestFile.VersionData);
                    extractedMeds = callGroqVisionAI(base64Image);
                } else {
                    extractedMeds = callGroqTextAI(req.rawInput);
                }

                p.External_Medications__c = extractedMeds;
                update p;

                if (extractedMeds.toLowerCase().contains('aspirin')) {
                    result.safetyMessage = '✅ Meds Synced. ⚠️ WARNING: Aspirin detected. Potential conflict with your Oncology treatment. Flagged for doctor review.';
                } else if (extractedMeds.contains('Error')) {
                    result.safetyMessage = '❌ AI Issue: ' + extractedMeds;
                } else {
                    result.safetyMessage = '✅ Medications Synced successfully! Extracted: ' + extractedMeds;
                }
                
            } catch (Exception e) {
                result.safetyMessage = 'System Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }

    public static String callGroqVisionAI(String base64Data) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(GROQ_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + GROQ_API_KEY);
            request.setHeader('Content-Type', 'application/json');
            
            String payload = '{"model":"' + VISION_MODEL + '","messages":[{"role":"user","content":[{"type":"text","text":"Extract ONLY the medicine or drug names from this prescription image. Return them as a simple comma-separated list. Nothing else."},{"type":"image_url","image_url":{"url":"data:image/jpeg;base64,' + base64Data + '"}}]}],"max_completion_tokens":512}';
            request.setBody(payload);
            request.setTimeout(120000);

            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> choices = (List<Object>)resBody.get('choices');
                Map<String, Object> message = (Map<String, Object>)((Map<String, Object>)choices[0]).get('message');
                return (String)message.get('content');
            } else {
                return 'Vision Error ' + response.getStatusCode() + ': ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Connection Error: ' + e.getMessage();
        }
    }

    public static String callGroqTextAI(String userInput) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(GROQ_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + GROQ_API_KEY);
            request.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> body = new Map<String, Object>();
            body.put('model', TEXT_MODEL);
            List<Map<String, String>> messages = new List<Map<String, String>>();
            messages.add(new Map<String, String>{'role' => 'system', 'content' => 'Extract ONLY medicine names from the text. Return as comma separated list.'});
            messages.add(new Map<String, String>{'role' => 'user', 'content' => userInput});
            body.put('messages', messages);
            
            request.setBody(JSON.serialize(body));
            request.setTimeout(60000);

            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> choices = (List<Object>)resBody.get('choices');
                return (String)((Map<String, Object>)((Map<String, Object>)choices[0]).get('message')).get('content');
            }
            return 'Text Error ' + response.getStatusCode() + ': ' + response.getBody();
        } catch (Exception e) {
            return 'Text Connection Error: ' + e.getMessage();
        }
    }

    public class SafetyRequest {
        @InvocableVariable(label='Patient Name' required=true) public String patientName;
        @InvocableVariable(label='Raw Text Input') public String rawInput;
        @InvocableVariable(label='Scan Latest File?' required=true) public Boolean processLatestFile;
    }

    public class SafetyResult {
        @InvocableVariable(label='Safety Message') public String safetyMessage;
    }
}