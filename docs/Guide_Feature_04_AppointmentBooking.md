# Feature 4: Appointment Booking System

## 📚 1. Concept Explanation

**What we are building:**
The core booking engine — patients can book appointments with a specific doctor from within the chat conversation. The agent collects all needed info, checks slot availability, and creates the appointment record in Salesforce.

**Why it matters:**
- This is THE primary use case — scheduling is what drives 70%+ of call center volume
- Automated booking frees up agents for complex cases
- Real-time slot checking prevents double-bookings
- Patients get instant confirmation — no more "we'll call you back"

**Complete Booking Flow:**
```
Patient starts chat
    ↓
Identifies self (name or Patient ID)
    ↓
Selects doctor (from discovery or directly)
    ↓
Agent checks available slots
    ↓
Patient picks a slot
    ↓
Agent creates Appointment__c record
    ↓
Confirmation message displayed
    ↓
(Later) Reminder sent via SMS/WhatsApp
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Verify Appointment Object Is Ready

Ensure your `Appointment__c` object from Feature 1 has all required fields. Key fields for booking:

| Field | Why It's Needed |
|-------|----------------|
| Patient__c | Who is booking |
| Provider__c | Which doctor |
| Department__c | Which department |
| Hospital__c | Which hospital |
| Appointment_Date__c | Selected date |
| Appointment_Time__c | Selected time |
| Start_DateTime__c | Precise start datetime |
| End_DateTime__c | Precise end datetime |
| Status__c | Set to "Scheduled" on creation |
| Type__c | New Consultation, Follow-up, etc. |
| Reason_for_Visit__c | Patient's stated reason |
| Source_Channel__c | "Web Chat" for this flow |
| Is_First_Visit__c | Auto-detect from patient history |

### Step 2.2: Populate Time Slots

For the demo, create time slots for each doctor. Go to the `Time_Slot__c` object and create records.

**Bulk Time Slot Generator Script (Anonymous Apex):**

Run this in **Developer Console** → **Debug** → **Open Execute Anonymous Window**:

```apex
// Generate time slots for the next 7 days for all active providers
List<Time_Slot__c> slotsToCreate = new List<Time_Slot__c>();
List<Provider__c> providers = [SELECT Id FROM Provider__c WHERE Is_Active__c = TRUE];

List<String> timeSlots = new List<String>{
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
    '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
    '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM'
};

List<String> endTimes = new List<String>{
    '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM',
    '11:30 AM', '12:00 PM', '12:30 PM', '01:00 PM',
    '02:30 PM', '03:00 PM', '03:30 PM', '04:00 PM',
    '04:30 PM', '05:00 PM', '05:30 PM', '06:00 PM'
};

for (Provider__c provider : providers) {
    for (Integer dayOffset = 1; dayOffset <= 7; dayOffset++) {
        Date slotDate = Date.today().addDays(dayOffset);
        // Skip Sundays (day 1 = Sunday in Salesforce)
        DateTime dt = DateTime.newInstance(slotDate, Time.newInstance(0,0,0,0));
        String dayOfWeek = dt.format('EEEE');
        if (dayOfWeek == 'Sunday') continue;
        
        for (Integer i = 0; i < timeSlots.size(); i++) {
            Time_Slot__c slot = new Time_Slot__c();
            slot.Provider__c = provider.Id;
            slot.Slot_Date__c = slotDate;
            slot.Start_Time__c = timeSlots[i];
            slot.End_Time__c = endTimes[i];
            slot.Is_Available__c = true;
            slot.Is_Booked__c = false;
            slot.Slot_Type__c = 'Regular';
            slotsToCreate.add(slot);
        }
    }
}

// Mark some random slots as booked (simulate existing appointments)
Integer bookedCount = 0;
for (Time_Slot__c slot : slotsToCreate) {
    if (Math.random() < 0.2) { // 20% of slots are already booked
        slot.Is_Available__c = false;
        slot.Is_Booked__c = true;
        bookedCount++;
    }
}

insert slotsToCreate;
System.debug('Created ' + slotsToCreate.size() + ' time slots (' + bookedCount + ' pre-booked)');
```

> [!TIP]
> This creates ~900+ time slots across all doctors for the next 7 days. About 20% are randomly marked as booked to simulate a realistic schedule.

### Step 2.3: Create a Validation Rule on Appointment

Prevent double-bookings:

1. Go to **Object Manager** → **Appointment__c** → **Validation Rules** → **New**
2. **Rule Name:** `Prevent_Past_Date_Booking`
3. **Error Condition Formula:**
```
Appointment_Date__c < TODAY()
```
4. **Error Message:** `Cannot book appointments in the past. Please select a future date.`

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Create Booking-Related Agent Actions

#### Action 1: Identify Patient

1. **Action Name:** `Identify_Patient`
2. **Action Type:** Flow
3. **Description:** `Look up a patient by their name, Patient ID, phone number, or email.`
4. **Inputs:**
   - `search_term` (String) — Name, ID, phone, or email
5. **Outputs:**
   - `patient_found` (Boolean)
   - `patient_id` (String) — Salesforce Record ID
   - `patient_name` (String)
   - `patient_details` (String) — Summary of patient info
6. **Agent Instructions:**
```
Use this action at the start of any appointment-related request.
Ask the patient for their name or Patient ID (PAT-XXXXX).
If multiple patients match, present options and ask to confirm.
If no patient is found, offer to proceed with basic info or escalate.
```

#### Action 2: Check Available Slots

1. **Action Name:** `Check_Available_Slots`
2. **Action Type:** Flow (or Apex Invocable)
3. **Description:** `Check available appointment slots for a specific doctor on a given date`
4. **Inputs:**
   - `provider_id` (String) — Doctor's Record ID
   - `preferred_date` (String) — Date in YYYY-MM-DD format
5. **Outputs:**
   - `available_slots` (String) — Formatted list of available times
   - `slot_count` (Number) — How many slots are available
6. **Agent Instructions:**
```
Use this action when the patient has selected a doctor and wants to see
available times. If the patient didn't specify a date, suggest tomorrow
or the next available weekday.

Present the available slots in a clear, numbered format.
If no slots are available on that date, suggest the next 2-3 dates 
with availability.
```

#### Action 3: Book Appointment

1. **Action Name:** `Book_Appointment`
2. **Action Type:** Flow (or Apex Invocable)
3. **Description:** `Create a new appointment record in Salesforce`
4. **Inputs:**
   - `patient_id` (String)
   - `provider_id` (String)
   - `department_id` (String)
   - `hospital_id` (String)
   - `appointment_date` (String)
   - `appointment_time` (String)
   - `visit_reason` (String)
   - `visit_type` (String)
5. **Outputs:**
   - `booking_confirmation` (String) — Confirmation message with appointment number
   - `appointment_id` (String) — Created appointment record ID
6. **Agent Instructions:**
```
Use this action ONLY after confirming ALL details with the patient:
- Doctor name
- Date and time
- Reason for visit

Before calling this action, summarize all details and ask the patient
to confirm: "Just to confirm, I'll be booking: [details]. Is this correct?"

Only proceed when the patient says yes/confirms.
```

### Step 3.2: Update Appointment Management Topic

Update the topic instructions:

```
## Appointment Booking Flow

Follow this EXACT sequence when a patient wants to book:

### Step 1: Identify the Patient
- Ask for their name or Patient ID
- Use Identify_Patient action to look them up
- If found, greet them: "Welcome back, [Name]!"
- If not found, collect: Full Name, Phone Number, Date of Birth

### Step 2: Determine the Doctor
- If coming from symptom routing, doctor is already selected
- If not, ask: "Do you have a specific doctor in mind, or should I help you find one?"
- If they need help → Use Doctor Discovery actions
- If they name a doctor → Look up and confirm

### Step 3: Select Date & Time
- Ask: "When would you like to visit? I can check availability for any date."
- If they give a date → Check_Available_Slots for that date
- If they say "earliest" or "ASAP" → Check today, tomorrow, next 3 days
- Present available slots in a clear format
- Let the patient choose

### Step 4: Collect Visit Details
- Ask: "What is the reason for your visit?"
- Determine visit type (New Consultation, Follow-up, etc.)

### Step 5: Confirm & Book
- Summarize ALL booking details:
  "Here's your appointment summary:
   👨‍⚕️ Doctor: [Name]
   🏥 Hospital: [Name], [City]
   🏬 Department: [Name]
   📅 Date: [Date]
   🕐 Time: [Time]
   📋 Reason: [Reason]
   
   Shall I confirm this booking?"
- On confirmation → Book_Appointment action
- Show confirmation with appointment number

### Step 6: Post-Booking
- Provide the appointment number (APT-XXXX)
- Remind about what to bring (insurance card, ID, previous reports)
- Mention they'll receive a reminder before the appointment
- Ask if they need anything else
```

---

## 🔄 4. Automation / Logic

### Apex Class: Appointment Booking Service

```apex
public class AppointmentBookingService {
    
    // ==========================================
    // ACTION 1: IDENTIFY PATIENT
    // ==========================================
    @InvocableMethod(label='Identify Patient' 
                     description='Search for a patient by name, ID, phone, or email')
    public static List<PatientSearchResult> identifyPatient(List<PatientSearchRequest> requests) {
        List<PatientSearchResult> results = new List<PatientSearchResult>();
        
        for (PatientSearchRequest req : requests) {
            PatientSearchResult result = new PatientSearchResult();
            String term = req.searchTerm.trim();
            
            List<Account> patients;
            
            // Try Patient ID first
            if (term.startsWithIgnoreCase('PAT-')) {
                patients = [
                    SELECT Id, Name, Patient_ID__c, Phone, PersonEmail,
                           Date_of_Birth__c, Gender__c, Primary_Diagnosis__c,
                           Preferred_Hospital__r.Name, Preferred_Language__c,
                           Total_No_Shows__c, Is_High_Risk__c
                    FROM Account
                    WHERE Patient_ID__c = :term
                    LIMIT 1
                ];
            } else {
                // Search by name, phone, or email
                patients = [
                    SELECT Id, Name, Patient_ID__c, Phone, PersonEmail,
                           Date_of_Birth__c, Gender__c, Primary_Diagnosis__c,
                           Preferred_Hospital__r.Name, Preferred_Language__c,
                           Total_No_Shows__c, Is_High_Risk__c
                    FROM Account
                    WHERE Name LIKE :('%' + term + '%')
                    OR Phone = :term
                    OR PersonEmail = :term
                    LIMIT 5
                ];
            }
            
            if (!patients.isEmpty()) {
                Account p = patients[0];
                result.patientFound = true;
                result.patientId = p.Id;
                result.patientName = p.Name;
                result.patientDetails = '👤 ' + p.Name + '\n'
                    + '🆔 ' + (p.Patient_ID__c != null ? p.Patient_ID__c : 'N/A') + '\n'
                    + '📞 ' + (p.Phone != null ? p.Phone : 'N/A') + '\n'
                    + '🏥 Preferred: ' + (p.Preferred_Hospital__r != null ? p.Preferred_Hospital__r.Name : 'None set');
                
                if (patients.size() > 1) {
                    result.patientDetails += '\n\n⚠️ Multiple patients found. Showing the first match. Please confirm this is correct.';
                }
            } else {
                result.patientFound = false;
                result.patientDetails = 'No patient found with "' + term + '". Please check the spelling or provide your Patient ID (PAT-XXXXX).';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class PatientSearchRequest {
        @InvocableVariable(label='Search Term' required=true)
        public String searchTerm;
    }
    
    public class PatientSearchResult {
        @InvocableVariable(label='Patient Found')
        public Boolean patientFound;
        
        @InvocableVariable(label='Patient Salesforce ID')
        public String patientId;
        
        @InvocableVariable(label='Patient Name')
        public String patientName;
        
        @InvocableVariable(label='Patient Details')
        public String patientDetails;
    }
}
```

### Apex Class: Slot Availability Checker

```apex
public class SlotAvailabilityChecker {
    
    @InvocableMethod(label='Check Available Slots' 
                     description='Get available time slots for a provider on a specific date')
    public static List<SlotCheckResult> checkSlots(List<SlotCheckRequest> requests) {
        List<SlotCheckResult> results = new List<SlotCheckResult>();
        
        for (SlotCheckRequest req : requests) {
            SlotCheckResult result = new SlotCheckResult();
            
            Date targetDate = Date.valueOf(req.preferredDate);
            
            // Get available slots for this provider on this date
            List<Time_Slot__c> availableSlots = [
                SELECT Id, Start_Time__c, End_Time__c, Slot_Type__c
                FROM Time_Slot__c
                WHERE Provider__c = :req.providerId
                AND Slot_Date__c = :targetDate
                AND Is_Available__c = TRUE
                AND Is_Booked__c = FALSE
                ORDER BY Start_Time__c ASC
            ];
            
            if (!availableSlots.isEmpty()) {
                result.slotCount = availableSlots.size();
                String slotList = '📅 Available slots on ' + targetDate.format() + ':\n\n';
                
                Integer counter = 1;
                for (Time_Slot__c slot : availableSlots) {
                    slotList += counter + '. 🕐 ' + slot.Start_Time__c + ' - ' + slot.End_Time__c;
                    if (slot.Slot_Type__c == 'Emergency') {
                        slotList += ' ⚡ (Emergency slot)';
                    }
                    slotList += '\n';
                    counter++;
                }
                
                slotList += '\nWhich time slot would you prefer?';
                result.availableSlots = slotList;
            } else {
                // No slots on this date — find next available dates
                List<Time_Slot__c> nextSlots = [
                    SELECT Slot_Date__c
                    FROM Time_Slot__c
                    WHERE Provider__c = :req.providerId
                    AND Slot_Date__c > :targetDate
                    AND Is_Available__c = TRUE
                    AND Is_Booked__c = FALSE
                    ORDER BY Slot_Date__c ASC
                    LIMIT 3
                ];
                
                result.slotCount = 0;
                String msg = '❌ No available slots on ' + targetDate.format() + '.\n\n';
                
                if (!nextSlots.isEmpty()) {
                    Set<Date> uniqueDates = new Set<Date>();
                    for (Time_Slot__c s : nextSlots) {
                        uniqueDates.add(s.Slot_Date__c);
                    }
                    msg += 'Next available dates:\n';
                    for (Date d : uniqueDates) {
                        msg += '📅 ' + d.format() + '\n';
                    }
                    msg += '\nWould you like to see slots on any of these dates?';
                } else {
                    msg += 'No upcoming availability found for this doctor. Would you like to try another doctor in the same department?';
                }
                
                result.availableSlots = msg;
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class SlotCheckRequest {
        @InvocableVariable(label='Provider ID' required=true)
        public String providerId;
        
        @InvocableVariable(label='Preferred Date (YYYY-MM-DD)' required=true)
        public String preferredDate;
    }
    
    public class SlotCheckResult {
        @InvocableVariable(label='Available Slots')
        public String availableSlots;
        
        @InvocableVariable(label='Slot Count')
        public Integer slotCount;
    }
}
```

### Apex Class: Create Appointment

```apex
public class AppointmentCreator {
    
    @InvocableMethod(label='Book Appointment' 
                     description='Create a new appointment record in Salesforce')
    public static List<BookingResult> createAppointment(List<BookingRequest> requests) {
        List<BookingResult> results = new List<BookingResult>();
        
        for (BookingRequest req : requests) {
            BookingResult result = new BookingResult();
            
            try {
                // Create the appointment
                Appointment__c apt = new Appointment__c();
                apt.Patient__c = req.patientId;
                apt.Provider__c = req.providerId;
                apt.Department__c = req.departmentId;
                apt.Hospital__c = req.hospitalId;
                apt.Appointment_Date__c = Date.valueOf(req.appointmentDate);
                apt.Appointment_Time__c = req.appointmentTime;
                apt.Status__c = 'Scheduled';
                apt.Type__c = req.visitType != null ? req.visitType : 'New Consultation';
                apt.Reason_for_Visit__c = req.visitReason;
                apt.Source_Channel__c = 'Web Chat';
                apt.Priority__c = 'Normal';
                apt.Confirmation_Status__c = 'Pending';
                apt.Duration__c = 30;
                
                // Check if this is the patient's first visit
                Integer priorVisits = [
                    SELECT COUNT() FROM Appointment__c 
                    WHERE Patient__c = :req.patientId 
                    AND Status__c IN ('Completed', 'Scheduled', 'Confirmed')
                ];
                apt.Is_First_Visit__c = (priorVisits == 0);
                
                insert apt;
                
                // Mark the time slot as booked
                List<Time_Slot__c> matchingSlots = [
                    SELECT Id FROM Time_Slot__c
                    WHERE Provider__c = :req.providerId
                    AND Slot_Date__c = :Date.valueOf(req.appointmentDate)
                    AND Start_Time__c = :req.appointmentTime
                    AND Is_Available__c = TRUE
                    LIMIT 1
                ];
                
                if (!matchingSlots.isEmpty()) {
                    matchingSlots[0].Is_Available__c = false;
                    matchingSlots[0].Is_Booked__c = true;
                    matchingSlots[0].Linked_Appointment__c = apt.Id;
                    update matchingSlots[0];
                }
                
                // Re-query to get the auto-number
                apt = [SELECT Id, Name, Appointment_Date__c, Appointment_Time__c,
                              Provider__r.Name, Department__r.Name, Hospital__r.Name,
                              Hospital__r.Address__c
                       FROM Appointment__c WHERE Id = :apt.Id];
                
                // Build confirmation message
                String confirmation = '✅ Appointment Booked Successfully!\n\n';
                confirmation += '📋 Appointment #: ' + apt.Name + '\n';
                confirmation += '👨‍⚕️ Doctor: ' + apt.Provider__r.Name + '\n';
                confirmation += '🏬 Department: ' + apt.Department__r.Name + '\n';
                confirmation += '🏥 Hospital: ' + apt.Hospital__r.Name + '\n';
                confirmation += '📍 Address: ' + apt.Hospital__r.Address__c + '\n';
                confirmation += '📅 Date: ' + apt.Appointment_Date__c.format() + '\n';
                confirmation += '🕐 Time: ' + apt.Appointment_Time__c + '\n';
                confirmation += '\n📌 Please remember to bring:\n';
                confirmation += '  • Valid photo ID\n';
                confirmation += '  • Insurance card & documents\n';
                confirmation += '  • Previous medical reports\n';
                confirmation += '  • List of current medications\n';
                confirmation += '\n📱 You will receive a reminder before your appointment.';
                confirmation += '\n\nIs there anything else I can help you with?';
                
                result.bookingConfirmation = confirmation;
                result.appointmentId = apt.Id;
                result.appointmentNumber = apt.Name;
                result.isSuccess = true;
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.bookingConfirmation = '❌ I apologize, but I encountered an error while booking your appointment: ' 
                    + e.getMessage() + '\n\nWould you like to try again, or shall I connect you with a human agent?';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class BookingRequest {
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
        
        @InvocableVariable(label='Provider ID' required=true)
        public String providerId;
        
        @InvocableVariable(label='Department ID' required=true)
        public String departmentId;
        
        @InvocableVariable(label='Hospital ID' required=true)
        public String hospitalId;
        
        @InvocableVariable(label='Appointment Date (YYYY-MM-DD)' required=true)
        public String appointmentDate;
        
        @InvocableVariable(label='Appointment Time' required=true)
        public String appointmentTime;
        
        @InvocableVariable(label='Visit Reason')
        public String visitReason;
        
        @InvocableVariable(label='Visit Type')
        public String visitType;
    }
    
    public class BookingResult {
        @InvocableVariable(label='Booking Confirmation')
        public String bookingConfirmation;
        
        @InvocableVariable(label='Appointment ID')
        public String appointmentId;
        
        @InvocableVariable(label='Appointment Number')
        public String appointmentNumber;
        
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
    }
}
```

### Apex Test Class

```apex
@isTest
public class AppointmentBookingServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Hospital
        Hospital__c hospital = new Hospital__c(
            Name = 'Test Hospital',
            Hospital_Code__c = 'TEST-001',
            City__c = 'Mumbai',
            Is_Active__c = true
        );
        insert hospital;
        
        // Create Department
        Department__c dept = new Department__c(
            Name = 'Test Oncology',
            Department_Code__c = 'TONC',
            Hospital__c = hospital.Id,
            Is_Active__c = true
        );
        insert dept;
        
        // Create Provider
        Provider__c provider = new Provider__c(
            Name = 'Dr. Test Doctor',
            Provider_Code__c = 'DOC-T01',
            Department__c = dept.Id,
            Hospital__c = hospital.Id,
            Specialization__c = 'Test Oncology',
            Is_Active__c = true,
            Experience_Years__c = 10
        );
        insert provider;
        
        // Create Patient Account
        Account patient = new Account(
            Name = 'Test Patient',
            Patient_ID__c = 'PAT-99999'
        );
        insert patient;
        
        // Create Time Slots
        List<Time_Slot__c> slots = new List<Time_Slot__c>();
        Date tomorrow = Date.today().addDays(1);
        for (String time : new List<String>{'09:00 AM', '10:00 AM', '11:00 AM'}) {
            slots.add(new Time_Slot__c(
                Provider__c = provider.Id,
                Slot_Date__c = tomorrow,
                Start_Time__c = time,
                End_Time__c = time.replace('09:', '09:30').replace('10:', '10:30').replace('11:', '11:30'),
                Is_Available__c = true,
                Is_Booked__c = false
            ));
        }
        insert slots;
    }
    
    @isTest
    static void testIdentifyPatientByID() {
        AppointmentBookingService.PatientSearchRequest req = new AppointmentBookingService.PatientSearchRequest();
        req.searchTerm = 'PAT-99999';
        
        List<AppointmentBookingService.PatientSearchResult> results = 
            AppointmentBookingService.identifyPatient(new List<AppointmentBookingService.PatientSearchRequest>{req});
        
        System.assertEquals(true, results[0].patientFound, 'Patient should be found');
        System.assertEquals('Test Patient', results[0].patientName);
    }
    
    @isTest
    static void testCheckSlots() {
        Provider__c provider = [SELECT Id FROM Provider__c LIMIT 1];
        
        SlotAvailabilityChecker.SlotCheckRequest req = new SlotAvailabilityChecker.SlotCheckRequest();
        req.providerId = provider.Id;
        req.preferredDate = String.valueOf(Date.today().addDays(1));
        
        List<SlotAvailabilityChecker.SlotCheckResult> results = 
            SlotAvailabilityChecker.checkSlots(new List<SlotAvailabilityChecker.SlotCheckRequest>{req});
        
        System.assert(results[0].slotCount > 0, 'Should have available slots');
    }
    
    @isTest
    static void testBookAppointment() {
        Account patient = [SELECT Id FROM Account WHERE Patient_ID__c = 'PAT-99999' LIMIT 1];
        Provider__c provider = [SELECT Id FROM Provider__c LIMIT 1];
        Department__c dept = [SELECT Id FROM Department__c LIMIT 1];
        Hospital__c hospital = [SELECT Id FROM Hospital__c LIMIT 1];
        
        AppointmentCreator.BookingRequest req = new AppointmentCreator.BookingRequest();
        req.patientId = patient.Id;
        req.providerId = provider.Id;
        req.departmentId = dept.Id;
        req.hospitalId = hospital.Id;
        req.appointmentDate = String.valueOf(Date.today().addDays(1));
        req.appointmentTime = '09:00 AM';
        req.visitReason = 'Follow-up consultation';
        req.visitType = 'Follow-up';
        
        List<AppointmentCreator.BookingResult> results = 
            AppointmentCreator.createAppointment(new List<AppointmentCreator.BookingRequest>{req});
        
        System.assertEquals(true, results[0].isSuccess, 'Booking should succeed');
        System.assertNotEquals(null, results[0].appointmentNumber, 'Should have appointment number');
        
        // Verify time slot is now booked
        Time_Slot__c slot = [SELECT Is_Booked__c FROM Time_Slot__c 
                             WHERE Provider__c = :provider.Id 
                             AND Start_Time__c = '09:00 AM'
                             AND Slot_Date__c = :Date.today().addDays(1)];
        System.assertEquals(true, slot.Is_Booked__c, 'Slot should be marked as booked');
    }
}
```

---

## 🖥️ 5. UI / Experience Layer

### Complete Demo Conversation Flow:

```
╔══════════════════════════════════════════════════════════╗
║  🏥 OncoAssist - AI Health Assistant                      ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  🤖 Hello! Welcome to Onco Global Cancer Care.            ║
║     I'm OncoAssist. How can I help you today?            ║
║                                                          ║
║  👤 I'd like to book an appointment                       ║
║                                                          ║
║  🤖 I'd be happy to help you book an appointment!         ║
║     Could you please share your name or Patient ID?      ║
║                                                          ║
║  👤 Rahul Verma, PAT-00001                                ║
║                                                          ║
║  🤖 Welcome back, Rahul! 😊                               ║
║     👤 Rahul Verma                                        ║
║     🆔 PAT-00001                                          ║
║     🏥 Preferred Hospital: Onco Global Main Campus        ║
║                                                          ║
║     Do you have a specific doctor in mind, or should      ║
║     I help you find the right one?                        ║
║                                                          ║
║  👤 I want to see Dr. Sunita Reddy for my lung cancer     ║
║     follow-up                                             ║
║                                                          ║
║  🤖 Great choice! Dr. Sunita Reddy is an excellent        ║
║     Medical Oncologist at HOSP-002 (Delhi).               ║
║                                                          ║
║     When would you like to visit? I can check             ║
║     her availability.                                     ║
║                                                          ║
║  👤 Sometime this week, what's available?                  ║
║                                                          ║
║  🤖 📅 Available slots this week for Dr. Sunita Reddy:    ║
║                                                          ║
║     Wednesday, April 18:                                  ║
║     1. 🕐 09:00 AM - 09:30 AM                            ║
║     2. 🕐 10:30 AM - 11:00 AM                            ║
║     3. 🕐 02:00 PM - 02:30 PM                            ║
║                                                          ║
║     Thursday, April 19:                                   ║
║     4. 🕐 09:30 AM - 10:00 AM                            ║
║     5. 🕐 11:00 AM - 11:30 AM                            ║
║     6. 🕐 03:00 PM - 03:30 PM                            ║
║                                                          ║
║     Which slot works best for you?                        ║
║                                                          ║
║  👤 I'll take slot 3, Wednesday 2 PM                      ║
║                                                          ║
║  🤖 Here's your appointment summary:                      ║
║                                                          ║
║     👨‍⚕️ Doctor: Dr. Sunita Reddy                          ║
║     🏥 Hospital: Onco Global North, Delhi                 ║
║     🏬 Department: Medical Oncology                       ║
║     📅 Date: Wednesday, April 18, 2026                    ║
║     🕐 Time: 02:00 PM                                    ║
║     📋 Reason: Lung cancer follow-up                      ║
║     💰 Consultation: ₹1,800                               ║
║                                                          ║
║     Shall I confirm this booking?                         ║
║                                                          ║
║  👤 Yes, please confirm                                   ║
║                                                          ║
║  🤖 ✅ Appointment Booked Successfully!                    ║
║                                                          ║
║     📋 Appointment #: APT-0006                            ║
║     👨‍⚕️ Doctor: Dr. Sunita Reddy                          ║
║     🏬 Department: Medical Oncology                       ║
║     🏥 Hospital: Onco Global North, Delhi                 ║
║     📍 45 Connaught Place, New Delhi 110001               ║
║     📅 Date: Wednesday, April 18, 2026                    ║
║     🕐 Time: 02:00 PM                                    ║
║                                                          ║
║     📌 Please remember to bring:                          ║
║       • Valid photo ID                                    ║
║       • Insurance card & documents                        ║
║       • Previous medical reports                          ║
║       • List of current medications                       ║
║                                                          ║
║     📱 You'll receive a reminder before your visit.       ║
║                                                          ║
║     Is there anything else I can help with?               ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

---

## 🧪 6. Testing

### Test Scenario 1: Happy Path — Complete Booking

**Steps:**
1. Say "Book an appointment"
2. Provide Patient ID: PAT-00001
3. Select doctor: Dr. Sunita Reddy
4. Choose a date
5. Pick a time slot
6. Confirm booking

**Expected:** Appointment created, confirmation shown with APT-XXXX number

### Test Scenario 2: Unknown Patient

**Input:** "I want to book, my name is John Doe"

**Expected:** "I wasn't able to find your record. Could you provide your Patient ID (PAT-XXXXX) or check the spelling?"

### Test Scenario 3: No Slots Available

**Input:** Choose a fully booked date

**Expected:** "No slots available on that date. Next available: [dates]. Want to check those?"

### Test Scenario 4: Full Flow from Symptoms

**Steps:**
1. "I have a headache and blurred vision"
2. Agent recommends Dr. Vikram Singh
3. "Yes, I'd like to book"
4. Agent identifies patient, shows slots, books

**Expected:** Seamless transition from discovery to booking

### Test Scenario 5: Past Date Attempt

**Input:** Try to book for yesterday

**Expected:** Validation rule fires — "Cannot book appointments in the past"

---

## 🎯 Summary

After completing Feature 4, you have:
- ✅ Complete appointment booking engine
- ✅ Patient identification system
- ✅ Real-time slot availability checking
- ✅ Automatic slot reservation on booking
- ✅ Auto-numbered appointment records (APT-XXXX)
- ✅ 3 Apex classes (PatientSearch, SlotChecker, AppointmentCreator)
- ✅ Test class with >75% coverage
- ✅ Validation rule preventing past-date bookings
- ✅ Time slot generator script for demo data
- ✅ Tested with 5 scenarios

**Next:** → Feature 5: Appointment Modify/Cancel Flow
