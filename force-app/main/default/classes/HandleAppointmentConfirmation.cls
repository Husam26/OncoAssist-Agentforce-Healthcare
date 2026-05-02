public class HandleAppointmentConfirmation {

    @InvocableMethod(label='Handle Appointment Confirmation' 
                     description='Processes patient responses to reminders (Confirm/Cancel)')
    public static List<ConfirmationResult> handle(List<ConfirmationRequest> requests) {
        List<ConfirmationResult> results = new List<ConfirmationResult>();

        for (ConfirmationRequest req : requests) {
            ConfirmationResult result = new ConfirmationResult();
            
            // Smart Identification (Handles APT-XXXX or ID)
            String aptRef = req.appointmentId;
            List<Appointment__c> apts;
            if (aptRef.startsWith('APT-')) {
                apts = [SELECT Id, Status__c, Confirmation_Status__c FROM Appointment__c WHERE Name = :aptRef LIMIT 1];
            } else {
                apts = [SELECT Id, Status__c, Confirmation_Status__c FROM Appointment__c WHERE Id = :aptRef LIMIT 1];
            }

            if (apts.isEmpty()) {
                result.confirmationMessage = 'I couldn\'t find that appointment record.';
                results.add(result); continue;
            }

            Appointment__c apt = apts[0];
            String response = req.patientResponse.toLowerCase();

            if (response.contains('yes') || response.contains('confirm')) {
                apt.Confirmation_Status__c = 'Confirmed';
                apt.Status__c = 'Scheduled'; // Ensure it is still scheduled
                result.confirmationMessage = '✅ Thank you! I have confirmed your appointment. We look forward to seeing you.';
                result.requiresAction = false;
            } 
            else if (response.contains('no') || response.contains('cancel')) {
                apt.Confirmation_Status__c = 'Cancelled';
                apt.Status__c = 'Cancelled';
                result.confirmationMessage = '❌ I have cancelled your appointment as requested. Since regular check-ups are important, would you like to see available slots for next week instead?';
                result.requiresAction = true;
            }
            else {
                result.confirmationMessage = 'I didn\'t quite catch that. Please say "Confirm" or "Cancel".';
                result.requiresAction = false;
            }

            update apt;
            results.add(result);
        }
        return results;
    }

    public class ConfirmationRequest {
        @InvocableVariable(required=true) public String appointmentId;
        @InvocableVariable(required=true) public String patientResponse;
    }

    public class ConfirmationResult {
        @InvocableVariable public String confirmationMessage;
        @InvocableVariable public Boolean requiresAction;
    }
}