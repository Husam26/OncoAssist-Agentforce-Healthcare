public class SlotAvailabilityChecker {
    
    @InvocableMethod(label='Check Available Slots' 
                     description='Smart search that handles both Names and IDs')
    public static List<SlotCheckResult> checkSlots(List<SlotCheckRequest> requests) {
        List<SlotCheckResult> results = new List<SlotCheckResult>();
        
        for (SlotCheckRequest req : requests) {
            SlotCheckResult result = new SlotCheckResult();
            try {
                // 1. SMART ID RESOLUTION: If the Agent sent a name, find the ID
                Id realProviderId;
                String inputId = req.providerId;
                
                if (inputId.startsWith('a0')) { // It's already a Salesforce ID
                    realProviderId = (Id)inputId;
                } else { // It's a Name, let's go find the ID
                    List<Provider__c> docs = [SELECT Id FROM Provider__c WHERE Name = :inputId OR Name LIKE :('%'+inputId+'%') LIMIT 1];
                    if (!docs.isEmpty()) realProviderId = docs[0].Id;
                    else throw new IllegalArgumentException('Doctor not found');
                }

                // 2. PARSE DATE (Handles both - and / formats)
                Date targetDate;
                String d = req.preferredDate;
                if (d.contains('-')) {
                    List<String> parts = d.split('-');
                    if (parts[0].length() == 4) targetDate = Date.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), Integer.valueOf(parts[2]));
                    else targetDate = Date.newInstance(Integer.valueOf(parts[2]), Integer.valueOf(parts[1]), Integer.valueOf(parts[0]));
                } else if (d.contains('/')) {
                    List<String> parts = d.split('/');
                    targetDate = Date.newInstance(Integer.valueOf(parts[2]), Integer.valueOf(parts[0]), Integer.valueOf(parts[1]));
                } else { targetDate = Date.valueOf(d); }

                // 3. QUERY SLOTS
                List<Time_Slot__c> availableSlots = [
                    SELECT Id, Start_Time__c, End_Time__c
                    FROM Time_Slot__c
                    WHERE Provider__c = :realProviderId
                    AND Slot_Date__c = :targetDate
                    AND Is_Available__c = TRUE
                    AND Is_Booked__c = FALSE
                    ORDER BY Start_Time__c ASC
                ];
                
                if (!availableSlots.isEmpty()) {
                    result.slotCount = availableSlots.size();
                    String slotList = '📅 Available slots for Dr. Joshi on ' + targetDate.format() + ':\n\n';
                    Integer counter = 1;
                    for (Time_Slot__c slot : availableSlots) {
                        slotList += counter + '. 🕐 ' + slot.Start_Time__c + ' - ' + slot.End_Time__c + '\n';
                        counter++;
                    }
                    slotList += '\nWhich slot number (1-' + availableSlots.size() + ') should I book for you?';
                    result.availableSlots = slotList;
                } else {
                    result.slotCount = 0;
                    result.availableSlots = '❌ No open slots found for ' + inputId + ' on ' + targetDate.format() + '. Would you like to try another date?';
                }
            } catch (Exception e) {
                result.slotCount = 0;
                result.availableSlots = '❌ Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class SlotCheckRequest {
        @InvocableVariable(required=true) public String providerId;
        @InvocableVariable(required=true) public String preferredDate;
    }
    
    public class SlotCheckResult {
        @InvocableVariable public String availableSlots;
        @InvocableVariable public Integer slotCount;
    }
}