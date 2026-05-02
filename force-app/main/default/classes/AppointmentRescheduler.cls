public class AppointmentRescheduler {
    
    @InvocableMethod(label='Reschedule Appointment'
                     description='Atomic move: Handles IDs, APT-XXXX, and Doctor Names')
    public static List<RescheduleResult> reschedule(List<RescheduleRequest> requests) {
        List<RescheduleResult> results = new List<RescheduleResult>();
        
        for (RescheduleRequest req : requests) {
            RescheduleResult result = new RescheduleResult();
            Savepoint sp = Database.setSavepoint();
            
            try {
                // 1. RESOLVE OLD APPOINTMENT ID
                Id oldAptId;
                String inputId = req.oldAppointmentId;
                if (inputId.startsWith('a0')) {
                    oldAptId = (Id)inputId;
                } else {
                    List<Appointment__c> apts = [SELECT Id FROM Appointment__c WHERE Name = :inputId LIMIT 1];
                    if (!apts.isEmpty()) oldAptId = apts[0].Id;
                    else throw new IllegalArgumentException('Appointment Number not found: ' + inputId);
                }

                Appointment__c oldApt = [
                    SELECT Id, Patient__c, Provider__c, Department__c, Hospital__c, 
                           Reason_for_Visit__c, Times_Modified__c, Name
                    FROM Appointment__c WHERE Id = :oldAptId
                ];
                
                // 2. RESOLVE NEW DOCTOR ID (If provided, otherwise use old doctor)
                Id newDoctorId;
                if (req.newProviderId == null || req.newProviderId == '') {
                    newDoctorId = oldApt.Provider__c;
                } else if (req.newProviderId.startsWith('a0')) {
                    newDoctorId = (Id)req.newProviderId;
                } else {
                    List<Provider__c> docs = [SELECT Id FROM Provider__c WHERE Name = :req.newProviderId OR Name LIKE :('%'+req.newProviderId+'%') LIMIT 1];
                    if (!docs.isEmpty()) newDoctorId = docs[0].Id;
                    else newDoctorId = oldApt.Provider__c; // Backup to old doctor
                }

                Provider__c docDetails = [SELECT Hospital__c, Department__c, Name FROM Provider__c WHERE Id = :newDoctorId];

                // 3. Mark old as Rescheduled and free the slot
                oldApt.Status__c = 'Rescheduled';
                update oldApt;
                
                List<Time_Slot__c> oldSlots = [SELECT Id FROM Time_Slot__c WHERE Linked_Appointment__c = :oldApt.Id LIMIT 1];
                if(!oldSlots.isEmpty()){
                    oldSlots[0].Is_Available__c = true;
                    oldSlots[0].Is_Booked__c = false;
                    oldSlots[0].Linked_Appointment__c = null;
                    update oldSlots[0];
                }

                // 4. Create NEW Appointment
                Appointment__c newApt = new Appointment__c();
                newApt.Patient__c = oldApt.Patient__c;
                newApt.Provider__c = newDoctorId;
                newApt.Department__c = docDetails.Department__c;
                newApt.Hospital__c = docDetails.Hospital__c;
                newApt.Appointment_Date__c = Date.valueOf(req.newDate);
                newApt.Appointment_Time__c = req.newTime;
                newApt.Status__c = 'Scheduled';
                newApt.Reason_for_Visit__c = oldApt.Reason_for_Visit__c;
                newApt.Rescheduled_From__c = oldApt.Id;
                newApt.Times_Modified__c = (oldApt.Times_Modified__c != null ? oldApt.Times_Modified__c : 0) + 1;
                insert newApt;
                
                // 5. Lock the NEW Slot
                List<Time_Slot__c> newSlots = [SELECT Id FROM Time_Slot__c WHERE Provider__c = :newDoctorId AND Slot_Date__c = :newApt.Appointment_Date__c AND Start_Time__c = :req.newTime LIMIT 1];
                if (!newSlots.isEmpty()) {
                    newSlots[0].Is_Available__c = false;
                    newSlots[0].Is_Booked__c = true;
                    newSlots[0].Linked_Appointment__c = newApt.Id;
                    update newSlots[0];
                }
                
                newApt = [SELECT Name FROM Appointment__c WHERE Id = :newApt.Id];
                result.isSuccess = true;
                result.rescheduleConfirmation = '✅ Appointment Rescheduled Successfully!\n\n'
                    + '🔄 Old: ' + oldApt.Name + ' (Cancelled)\n'
                    + '✨ New: ' + newApt.Name + ' confirmed with **' + docDetails.Name + '** for ' + req.newDate + ' at ' + req.newTime;
                
            } catch (Exception e) {
                Database.rollback(sp);
                result.isSuccess = false;
                result.rescheduleConfirmation = '❌ Reschedule Failed: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class RescheduleRequest {
        @InvocableVariable(required=true) public String oldAppointmentId;
        @InvocableVariable(required=true) public String newDate;
        @InvocableVariable(required=true) public String newTime;
        @InvocableVariable public String newProviderId; // ADDED BACK!
    }
    
    public class RescheduleResult {
        @InvocableVariable public String rescheduleConfirmation;
        @InvocableVariable public Boolean isSuccess;
    }
}