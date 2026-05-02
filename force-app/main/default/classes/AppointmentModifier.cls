public class AppointmentModifier {
    
    @InvocableMethod(label='Lookup Patient Appointments'
                     description='Get upcoming appointments for a patient')
    public static List<AppointmentListResult> lookupAppointments(List<AppointmentLookupRequest> requests) {
        List<AppointmentListResult> results = new List<AppointmentListResult>();
        
        for (AppointmentLookupRequest req : requests) {
            AppointmentListResult result = new AppointmentListResult();
            
            // Query upcoming appointments that are not already cancelled or completed
            List<Appointment__c> appointments = [
                SELECT Id, Name, Appointment_Date__c, Appointment_Time__c, 
                       Provider__r.Name, Department__r.Name, Hospital__r.Name, 
                       Status__c
                FROM Appointment__c 
                WHERE Patient__c = :req.patientId 
                AND Status__c IN ('Scheduled', 'Confirmed')
                AND Appointment_Date__c >= TODAY
                ORDER BY Appointment_Date__c ASC, Appointment_Time__c ASC
                LIMIT 5
            ];
            
            if (!appointments.isEmpty()) {
                result.appointmentCount = appointments.size();
                String aptList = '📋 Your upcoming appointments:\n\n';
                
                Integer counter = 1;
                for (Appointment__c apt : appointments) {
                    aptList += counter + '. 📅 ' + apt.Appointment_Date__c.format() 
                        + ' at ' + apt.Appointment_Time__c + '\n';
                    aptList += '   👨‍⚕️ Doctor: ' + apt.Provider__r.Name + '\n';
                    aptList += '   🏥 Location: ' + apt.Hospital__r.Name + '\n';
                    aptList += '   📋 Appt #: ' + apt.Name + '\n\n';
                    counter++;
                }
                
                aptList += 'Which appointment (1-' + appointments.size() + ') would you like to manage?';
                result.appointmentList = aptList;
            } else {
                result.appointmentCount = 0;
                result.appointmentList = 'You don\'t have any upcoming appointments. Would you like to book a new one?';
            }
            results.add(result);
        }
        return results;
    }
    
    public class AppointmentLookupRequest {
        @InvocableVariable(label='Patient ID' required=true) public String patientId;
    }
    
    public class AppointmentListResult {
        @InvocableVariable(label='Appointment List') public String appointmentList;
        @InvocableVariable(label='Appointment Count') public Integer appointmentCount;
    }
}