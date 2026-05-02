public class AppointmentCreator {
    
    @InvocableMethod(label='Book Appointment' 
                     description='Smart booking that resolves names and IDs automatically')
    public static List<BookingResult> createAppointment(List<BookingRequest> requests) {
        List<BookingResult> results = new List<BookingResult>();
        
        for (BookingRequest req : requests) {
            BookingResult result = new BookingResult();
            try {
                // 1. RESOLVE DOCTOR ID (Handle Name or ID)
                Id doctorId;
                if (req.providerId.startsWith('a0')) {
                    doctorId = (Id)req.providerId;
                } else {
                    List<Provider__c> docs = [SELECT Id, Department__c, Hospital__c FROM Provider__c WHERE Name = :req.providerId OR Name LIKE :('%'+req.providerId+'%') LIMIT 1];
                    if (!docs.isEmpty()) doctorId = docs[0].Id;
                    else throw new IllegalArgumentException('Doctor Name not found: ' + req.providerId);
                }

                // 2. AUTO-GET HOSPITAL & DEPT (Since the doctor belongs to them anyway)
                Provider__c docDetails = [SELECT Hospital__c, Department__c FROM Provider__c WHERE Id = :doctorId];
                
                // 3. CLEAN THE TIME (Convert "05:00 PM - 05:30 PM" -> "05:00 PM")
                String cleanTime = req.appointmentTime;
                if (cleanTime.contains('-')) {
                    cleanTime = cleanTime.split('-')[0].trim();
                }

                // 4. CREATE THE APPOINTMENT
                Appointment__c apt = new Appointment__c();
                apt.Patient__c = (Id)req.patientId;
                apt.Provider__c = doctorId;
                apt.Hospital__c = docDetails.Hospital__c;
                apt.Department__c = docDetails.Department__c;
                apt.Appointment_Date__c = Date.valueOf(req.appointmentDate);
                apt.Appointment_Time__c = cleanTime;
                apt.Status__c = 'Scheduled';
                apt.Reason_for_Visit__c = req.visitReason;
                apt.Source_Channel__c = 'Web Chat';
                insert apt;
                
                // 5. LOCK THE SLOT
                List<Time_Slot__c> slots = [SELECT Id FROM Time_Slot__c WHERE Provider__c = :doctorId AND Slot_Date__c = :apt.Appointment_Date__c AND Start_Time__c = :cleanTime LIMIT 1];
                if (!slots.isEmpty()) {
                    slots[0].Is_Available__c = false;
                    slots[0].Is_Booked__c = true;
                    slots[0].Linked_Appointment__c = apt.Id;
                    update slots[0];
                }
                
                apt = [SELECT Name FROM Appointment__c WHERE Id = :apt.Id];
                result.isSuccess = true;
                result.bookingConfirmation = '✅ Appointment Booked! 📋 Number: ' + apt.Name + ' for ' + cleanTime + '. See you then!';
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.bookingConfirmation = '❌ Error: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }
    
    public class BookingRequest {
        @InvocableVariable(required=true) public String patientId;
        @InvocableVariable(required=true) public String providerId;
        @InvocableVariable public String hospitalId; // Optional now!
        @InvocableVariable public String departmentId; // Optional now!
        @InvocableVariable(required=true) public String appointmentDate;
        @InvocableVariable(required=true) public String appointmentTime;
        @InvocableVariable public String visitReason;
    }
    
    public class BookingResult {
        @InvocableVariable public String bookingConfirmation;
        @InvocableVariable public Boolean isSuccess;
    }
}