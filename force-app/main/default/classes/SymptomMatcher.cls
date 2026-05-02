public class SymptomMatcher {
    @InvocableMethod(label='Match Symptoms to Doctor' description='Fuzzy matches symptoms with Pediatric priority')
    public static List<MatchResult> matchSymptoms(List<MatchRequest> requests) {
        List<MatchResult> results = new List<MatchResult>();
        
        // Keywords that trigger Pediatric prioritization
        Set<String> pediatricKeywords = new Set<String>{'son', 'daughter', 'child', 'kid', 'pediatric', 'year-old', 'boy', 'girl'};
        
        for (MatchRequest req : requests) {
            MatchResult result = new MatchResult();
            if (String.isBlank(req.symptoms)) continue;
            
            String input = req.symptoms.toLowerCase();
            List<String> inputWords = input.split('[,\\s]+');
            
            // Check if input contains any pediatric-related words
            Boolean isPediatric = false;
            for(String word : inputWords) {
                if(pediatricKeywords.contains(word)) { isPediatric = true; break; }
            }
            
            // Strategy 1: Check Mapping Object
            List<Symptom_Department_Map__c> allMappings = [
                SELECT Symptom__c, Department__r.Name, Priority_Provider__r.Name, 
                       Priority_Provider__r.Specialization__c, Priority_Provider__r.Hospital__r.Name 
                FROM Symptom_Department_Map__c
            ];
            
            for(Symptom_Department_Map__c m : allMappings) {
                // If it's a child/pediatric case, skip any map that isn't Pediatric Oncology
                if(isPediatric && !m.Department__r.Name.contains('Pediatric')) continue;
                
                for(String word : inputWords) {
                    if(m.Symptom__c.toLowerCase().contains(word) || word.contains(m.Symptom__c.toLowerCase())) {
                        result.recommendation = '🔍 Based on the description for a young patient, I recommend:\n\n'
                            + '🏥 Department: ' + m.Department__r.Name + '\n'
                            + '👨‍⚕️ Doctor: ' + m.Priority_Provider__r.Name + '\n'
                            + '🏥 Hospital: ' + m.Priority_Provider__r.Hospital__r.Name + '\n'
                            + '\nWould you like to book an appointment with this specialist?';
                        result.isFound = true;
                        break;
                    }
                }
                if(result.isFound) break;
            }

            if (!result.isFound) {
                // Strategy 2: Search Provider keywords
                List<Provider__c> providers = [SELECT Name, Specialization__c, Hospital__r.Name, Symptom_Keywords__c 
                                              FROM Provider__c WHERE Is_Active__c = TRUE];
                for (Provider__c p : providers) {
                    // Skip general doctors if we detected a pediatric case
                    if(isPediatric && !p.Specialization__c.contains('Pediatric')) continue;
                    
                    if (String.isNotBlank(p.Symptom_Keywords__c)) {
                        for (String word : inputWords) {
                            if (p.Symptom_Keywords__c.toLowerCase().contains(word) || word.contains(p.Symptom_Keywords__c.toLowerCase())) {
                                result.recommendation = '🔍 I found a pediatric specialist: ' + p.Name + ' (' + p.Specialization__c + ') at ' + p.Hospital__r.Name + '.\nWould you like to book?';
                                result.isFound = true;
                                break;
                            }
                        }
                    }
                    if (result.isFound) break;
                }
            }
            
            if (!result.isFound) {
                result.recommendation = 'I couldn\'t match your symptoms exactly. For safety, I recommend a General Oncology consultation for your child. Would you like to proceed?';
            }
            results.add(result);
        }
        return results;
    }

    public class MatchRequest { @InvocableVariable(required=true) public String symptoms; }
    public class MatchResult { @InvocableVariable public String recommendation; @InvocableVariable public Boolean isFound = false; }
}