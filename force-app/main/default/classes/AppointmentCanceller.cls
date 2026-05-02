public class AppointmentCanceller {
    
    @InvocableMethod(label='Cancel Appointment'
                     description='Smart cancellation: Handles IDs and APT-XXXX numbers')
    public static List<CancelResult> cancelAppointment(List<CancelRequest> requests) {
        List<CancelResult> results = new List<CancelResult>();
        
        for (CancelRequest req : requests) {
            CancelResult result = new CancelResult();
            
            try {
                // 1. SMART ID RESOLUTION: Handle APT-XXXX or Salesforce ID
                Id realAptId;
                String inputId = req.appointmentId;
                
                if (inputId.startsWith('a0')) { // It's already a Salesforce ID
                    realAptId = (Id)inputId;
                } else { // It's an APT-XXXX number
                    List<Appointment__c> apts = [SELECT Id, Name, Status__c, Appointment_Date__c, 
                           Appointment_Time__c, Provider__r.Name FROM Appointment__c WHERE Name = :inputId LIMIT 1];
                    if (!apts.isEmpty()) realAptId = apts[0].Id;
                    else throw new IllegalArgumentException('Appointment Number not found: ' + inputId);
                }

                // 2. Fetch the appointment using the resolved ID
                Appointment__c apt = [
                    SELECT Id, Name, Status__c, Appointment_Date__c, 
                           Appointment_Time__c, Provider__r.Name
                    FROM Appointment__c
                    WHERE Id = :realAptId
                    LIMIT 1
                ];
                
                // 3. Update status and reason
                apt.Status__c = 'Cancelled';
                apt.Cancellation_Reason__c = req.cancellationReason;
                update apt;
                
                // 4. Free up the slot
                List<Time_Slot__c> slots = [SELECT Id FROM Time_Slot__c WHERE Linked_Appointment__c = :apt.Id LIMIT 1];
                if (!slots.isEmpty()) {
                    slots[0].Is_Available__c = true;
                    slots[0].Is_Booked__c = false;
                    slots[0].Linked_Appointment__c = null;
                    update slots[0];
                }
                
                result.isSuccess = true;
                result.cancellationConfirmation = '✅ Appointment Cancelled Successfully\n'
                    + '📋 Number: ' + apt.Name + '\n'
                    + '👨‍⚕️ Doctor: ' + apt.Provider__r.Name + '\n'
                    + '📅 Date: ' + apt.Appointment_Date__c.format() + '\n\n'
                    + 'The time slot has been freed. Would you like to rebook?';
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.cancellationConfirmation = '❌ Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class CancelRequest {
        @InvocableVariable(required=true) public String appointmentId;
        @InvocableVariable(required=true) public String cancellationReason;
    }
    
    public class CancelResult {
        @InvocableVariable public String cancellationConfirmation;
        @InvocableVariable public Boolean isSuccess;
    }
}