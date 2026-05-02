# Feature 5: Appointment Modify/Cancel Flow

## 📚 1. Concept Explanation

**What we are building:**
The ability for patients to reschedule or cancel their existing appointments entirely through the AI chat agent — no phone call needed. The agent looks up their appointment, confirms the change, and updates the record.

**Why it matters:**
- ~20% of call center calls are reschedule/cancel requests — fully automatable
- Immediate rebooking frees the cancelled slot for other patients
- Tracking cancellation reasons helps improve service
- A professional cancel/reschedule flow shows judges you've thought about the full lifecycle

**User Stories:**
```
"I need to move my appointment to next week"     → Reschedule
"I can't make it to my appointment tomorrow"     → Cancel
"Can I change my appointment to a different doctor?" → Modify + Reschedule
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Verify Fields on Appointment__c

Ensure these fields exist from Feature 1:

| Field | Purpose for Modify/Cancel |
|-------|--------------------------|
| `Status__c` | Will change to "Cancelled" or "Rescheduled" |
| `Cancellation_Reason__c` | Store why the patient cancelled |
| `Rescheduled_From__c` | Self-lookup linking new apt → old apt |

### Step 2.2: Add a Field History Tracking

Track changes to the Status field:

1. Go to **Object Manager** → **Appointment__c** → **Fields & Relationships**
2. Click on **Status__c** → **Edit**
3. Under **Field History Tracking** → ✅ Enable
4. This logs every status change with timestamp and user

### Step 2.3: Create a Custom Field for Modification Count

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Times Modified | `Times_Modified__c` | Number(3,0) | How many times this appointment was changed |

---

## 🤖 3. Agentforce Implementation

### Step 3.1: New Agent Actions

#### Action: Lookup Patient Appointments

1. **Action Name:** `Lookup_Patient_Appointments`
2. **Action Type:** Apex Invocable
3. **Description:** `Find upcoming appointments for a patient`
4. **Inputs:**
   - `patient_id` (String) — Patient's Salesforce Record ID
   - `status_filter` (String) — Optional: "Scheduled", "Confirmed", "All"
5. **Outputs:**
   - `appointment_list` (String) — Formatted list of appointments
   - `appointment_count` (Number)
6. **Agent Instructions:**
```
Use this action when a patient wants to reschedule, cancel, or check 
their appointment status. Always identify the patient first using 
Identify_Patient, then use this action to retrieve their appointments.

If the patient has multiple appointments, present them as a numbered 
list and ask which one they want to modify.
```

#### Action: Cancel Appointment

1. **Action Name:** `Cancel_Appointment`
2. **Action Type:** Apex Invocable
3. **Description:** `Cancel an existing appointment and free up the time slot`
4. **Inputs:**
   - `appointment_id` (String)
   - `cancellation_reason` (String)
5. **Outputs:**
   - `cancellation_confirmation` (String)
   - `is_success` (Boolean)
6. **Agent Instructions:**
```
Use this action ONLY after:
1. Identifying the patient
2. Looking up their appointments
3. The patient has confirmed WHICH appointment to cancel
4. You have asked for the reason for cancellation
5. You have confirmed: "Are you sure you want to cancel your 
   appointment with [Doctor] on [Date] at [Time]?"
6. The patient confirms YES

After cancellation, offer to rebook at a different time.
```

#### Action: Reschedule Appointment

1. **Action Name:** `Reschedule_Appointment`
2. **Action Type:** Apex Invocable
3. **Description:** `Cancel the old appointment and create a new one with different date/time`
4. **Inputs:**
   - `old_appointment_id` (String)
   - `new_date` (String)
   - `new_time` (String)
   - `new_provider_id` (String, optional — if changing doctor)
5. **Outputs:**
   - `reschedule_confirmation` (String)
   - `new_appointment_id` (String)
   - `is_success` (Boolean)

### Step 3.2: Update Appointment Management Topic

Add these instructions to the existing topic:

```
## Appointment Cancellation Flow

1. Identify the patient (use Identify_Patient)
2. Look up their upcoming appointments (use Lookup_Patient_Appointments)
3. Ask which appointment they want to cancel
4. Ask for the reason: "I'm sorry to hear that. Could you share why 
   you need to cancel? This helps us improve our service."
5. Confirm the cancellation details
6. Execute Cancel_Appointment
7. After cancellation, proactively ask: "Would you like to rebook at 
   a different time?"

## Appointment Reschedule Flow

1. Identify the patient
2. Look up their upcoming appointments
3. Ask which appointment they want to reschedule
4. Ask for the new preferred date/time
5. Check available slots on the new date (same doctor)
6. Present available options
7. On patient selection, confirm details
8. Execute Reschedule_Appointment (cancels old, creates new)
9. Show new appointment confirmation

## Important Rules
- Never cancel without explicit patient confirmation
- Always ask for a cancellation reason
- For rescheduling, try to keep the same doctor unless patient requests otherwise
- If the appointment is within 24 hours, warn: "Your appointment is within 
  24 hours. While you can still cancel, we recommend rescheduling instead."
- For chemo/surgery appointments, warn about 48-hour policy
```

---

## 🔄 4. Automation / Logic

### Apex Class: Appointment Modifier

```apex
public class AppointmentModifier {
    
    // ==========================================
    // LOOKUP PATIENT APPOINTMENTS
    // ==========================================
    @InvocableMethod(label='Lookup Patient Appointments'
                     description='Get upcoming appointments for a patient')
    public static List<AppointmentListResult> lookupAppointments(List<AppointmentLookupRequest> requests) {
        List<AppointmentListResult> results = new List<AppointmentListResult>();
        
        for (AppointmentLookupRequest req : requests) {
            AppointmentListResult result = new AppointmentListResult();
            
            String query = 'SELECT Id, Name, Appointment_Date__c, Appointment_Time__c, '
                + 'Provider__r.Name, Department__r.Name, Hospital__r.Name, '
                + 'Status__c, Type__c, Priority__c '
                + 'FROM Appointment__c '
                + 'WHERE Patient__c = :patientId ';
            
            if (req.statusFilter != null && req.statusFilter != 'All') {
                query += 'AND Status__c = :statusFilter ';
            } else {
                query += 'AND Status__c IN (\'Scheduled\', \'Confirmed\') ';
            }
            
            query += 'AND Appointment_Date__c >= TODAY '
                + 'ORDER BY Appointment_Date__c ASC, Appointment_Time__c ASC '
                + 'LIMIT 10';
            
            Id patientId = Id.valueOf(req.patientId);
            String statusFilter = req.statusFilter;
            
            List<Appointment__c> appointments = Database.query(query);
            
            if (!appointments.isEmpty()) {
                result.appointmentCount = appointments.size();
                String aptList = '📋 Your upcoming appointments:\n\n';
                
                Integer counter = 1;
                for (Appointment__c apt : appointments) {
                    aptList += counter + '. 📅 ' + apt.Appointment_Date__c.format() 
                        + ' at ' + apt.Appointment_Time__c + '\n';
                    aptList += '   👨‍⚕️ ' + apt.Provider__r.Name + '\n';
                    aptList += '   🏬 ' + apt.Department__r.Name + '\n';
                    aptList += '   🏥 ' + apt.Hospital__r.Name + '\n';
                    aptList += '   📋 ' + apt.Name + ' | Status: ' + apt.Status__c + '\n';
                    if (apt.Priority__c != 'Normal') {
                        aptList += '   ⚠️ Priority: ' + apt.Priority__c + '\n';
                    }
                    aptList += '\n';
                    counter++;
                }
                
                aptList += 'Which appointment would you like to manage?';
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
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
        
        @InvocableVariable(label='Status Filter')
        public String statusFilter;
    }
    
    public class AppointmentListResult {
        @InvocableVariable(label='Appointment List')
        public String appointmentList;
        
        @InvocableVariable(label='Appointment Count')
        public Integer appointmentCount;
    }
}
```

### Apex Class: Cancel Appointment

```apex
public class AppointmentCanceller {
    
    @InvocableMethod(label='Cancel Appointment'
                     description='Cancel an existing appointment and free the time slot')
    public static List<CancelResult> cancelAppointment(List<CancelRequest> requests) {
        List<CancelResult> results = new List<CancelResult>();
        
        for (CancelRequest req : requests) {
            CancelResult result = new CancelResult();
            
            try {
                // Fetch the appointment
                Appointment__c apt = [
                    SELECT Id, Name, Status__c, Appointment_Date__c, 
                           Appointment_Time__c, Provider__r.Name,
                           Department__r.Name, Hospital__r.Name,
                           Patient__c, Provider__c
                    FROM Appointment__c
                    WHERE Id = :req.appointmentId
                    LIMIT 1
                ];
                
                // Validate — can't cancel already cancelled/completed
                if (apt.Status__c == 'Cancelled') {
                    result.isSuccess = false;
                    result.cancellationConfirmation = 'This appointment (' + apt.Name + ') is already cancelled.';
                    results.add(result);
                    continue;
                }
                if (apt.Status__c == 'Completed') {
                    result.isSuccess = false;
                    result.cancellationConfirmation = 'This appointment (' + apt.Name + ') has already been completed and cannot be cancelled.';
                    results.add(result);
                    continue;
                }
                
                // Update appointment status
                apt.Status__c = 'Cancelled';
                apt.Cancellation_Reason__c = req.cancellationReason;
                update apt;
                
                // Free up the time slot
                List<Time_Slot__c> linkedSlots = [
                    SELECT Id FROM Time_Slot__c
                    WHERE Linked_Appointment__c = :apt.Id
                    LIMIT 1
                ];
                if (!linkedSlots.isEmpty()) {
                    linkedSlots[0].Is_Available__c = true;
                    linkedSlots[0].Is_Booked__c = false;
                    linkedSlots[0].Linked_Appointment__c = null;
                    update linkedSlots[0];
                }
                
                // Build confirmation
                String conf = '✅ Appointment Cancelled Successfully\n\n';
                conf += '📋 Appointment #: ' + apt.Name + '\n';
                conf += '👨‍⚕️ Doctor: ' + apt.Provider__r.Name + '\n';
                conf += '📅 Was scheduled for: ' + apt.Appointment_Date__c.format() 
                    + ' at ' + apt.Appointment_Time__c + '\n';
                conf += '💬 Reason: ' + req.cancellationReason + '\n\n';
                conf += 'The time slot has been freed for other patients.\n';
                conf += 'Would you like to rebook at a different time?';
                
                result.cancellationConfirmation = conf;
                result.isSuccess = true;
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.cancellationConfirmation = '❌ Error cancelling appointment: ' + e.getMessage();
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class CancelRequest {
        @InvocableVariable(label='Appointment ID' required=true)
        public String appointmentId;
        
        @InvocableVariable(label='Cancellation Reason' required=true)
        public String cancellationReason;
    }
    
    public class CancelResult {
        @InvocableVariable(label='Cancellation Confirmation')
        public String cancellationConfirmation;
        
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
    }
}
```

### Apex Class: Reschedule Appointment

```apex
public class AppointmentRescheduler {
    
    @InvocableMethod(label='Reschedule Appointment'
                     description='Cancel old appointment and create new one with different date/time')
    public static List<RescheduleResult> rescheduleAppointment(List<RescheduleRequest> requests) {
        List<RescheduleResult> results = new List<RescheduleResult>();
        
        for (RescheduleRequest req : requests) {
            RescheduleResult result = new RescheduleResult();
            
            Savepoint sp = Database.setSavepoint();
            
            try {
                // Fetch original appointment with all details
                Appointment__c oldApt = [
                    SELECT Id, Name, Patient__c, Provider__c, Department__c, 
                           Hospital__c, Type__c, Reason_for_Visit__c,
                           Appointment_Date__c, Appointment_Time__c,
                           Provider__r.Name, Department__r.Name, 
                           Hospital__r.Name, Hospital__r.Address__c,
                           Priority__c, Language_Preference__c, Symptoms__c,
                           Times_Modified__c
                    FROM Appointment__c
                    WHERE Id = :req.oldAppointmentId
                    LIMIT 1
                ];
                
                // Determine the provider for the new appointment
                Id newProviderId = (req.newProviderId != null && req.newProviderId != '') 
                    ? Id.valueOf(req.newProviderId) 
                    : oldApt.Provider__c;
                
                Date newDate = Date.valueOf(req.newDate);
                
                // Verify the new slot is available
                List<Time_Slot__c> newSlots = [
                    SELECT Id FROM Time_Slot__c
                    WHERE Provider__c = :newProviderId
                    AND Slot_Date__c = :newDate
                    AND Start_Time__c = :req.newTime
                    AND Is_Available__c = TRUE
                    AND Is_Booked__c = FALSE
                    LIMIT 1
                ];
                
                if (newSlots.isEmpty()) {
                    result.isSuccess = false;
                    result.rescheduleConfirmation = '❌ Sorry, the slot on ' + newDate.format() 
                        + ' at ' + req.newTime + ' is no longer available. Please choose another time.';
                    results.add(result);
                    continue;
                }
                
                // Mark old appointment as rescheduled
                oldApt.Status__c = 'Rescheduled';
                update oldApt;
                
                // Free old time slot
                List<Time_Slot__c> oldSlots = [
                    SELECT Id FROM Time_Slot__c
                    WHERE Linked_Appointment__c = :oldApt.Id
                    LIMIT 1
                ];
                if (!oldSlots.isEmpty()) {
                    oldSlots[0].Is_Available__c = true;
                    oldSlots[0].Is_Booked__c = false;
                    oldSlots[0].Linked_Appointment__c = null;
                    update oldSlots[0];
                }
                
                // Create new appointment
                Appointment__c newApt = new Appointment__c();
                newApt.Patient__c = oldApt.Patient__c;
                newApt.Provider__c = newProviderId;
                newApt.Department__c = oldApt.Department__c;
                newApt.Hospital__c = oldApt.Hospital__c;
                newApt.Appointment_Date__c = newDate;
                newApt.Appointment_Time__c = req.newTime;
                newApt.Status__c = 'Scheduled';
                newApt.Type__c = oldApt.Type__c;
                newApt.Reason_for_Visit__c = oldApt.Reason_for_Visit__c;
                newApt.Priority__c = oldApt.Priority__c;
                newApt.Source_Channel__c = 'Web Chat';
                newApt.Rescheduled_From__c = oldApt.Id;
                newApt.Language_Preference__c = oldApt.Language_Preference__c;
                newApt.Symptoms__c = oldApt.Symptoms__c;
                newApt.Times_Modified__c = (oldApt.Times_Modified__c != null ? oldApt.Times_Modified__c : 0) + 1;
                newApt.Confirmation_Status__c = 'Pending';
                newApt.Duration__c = 30;
                
                insert newApt;
                
                // Book the new time slot
                newSlots[0].Is_Available__c = false;
                newSlots[0].Is_Booked__c = true;
                newSlots[0].Linked_Appointment__c = newApt.Id;
                update newSlots[0];
                
                // Re-query for auto-number
                newApt = [SELECT Id, Name, Appointment_Date__c, Appointment_Time__c,
                                 Provider__r.Name, Department__r.Name, 
                                 Hospital__r.Name, Hospital__r.Address__c
                          FROM Appointment__c WHERE Id = :newApt.Id];
                
                // Build confirmation
                String conf = '✅ Appointment Rescheduled Successfully!\n\n';
                conf += '🔄 Old: ' + oldApt.Name + ' → ' + oldApt.Appointment_Date__c.format() 
                    + ' at ' + oldApt.Appointment_Time__c + ' (Cancelled)\n';
                conf += '✨ New: ' + newApt.Name + '\n\n';
                conf += '👨‍⚕️ Doctor: ' + newApt.Provider__r.Name + '\n';
                conf += '🏬 Department: ' + newApt.Department__r.Name + '\n';
                conf += '🏥 Hospital: ' + newApt.Hospital__r.Name + '\n';
                conf += '📍 Address: ' + newApt.Hospital__r.Address__c + '\n';
                conf += '📅 New Date: ' + newApt.Appointment_Date__c.format() + '\n';
                conf += '🕐 New Time: ' + newApt.Appointment_Time__c + '\n';
                conf += '\n📱 You will receive a new reminder for this appointment.';
                conf += '\nIs there anything else I can help with?';
                
                result.rescheduleConfirmation = conf;
                result.newAppointmentId = newApt.Id;
                result.newAppointmentNumber = newApt.Name;
                result.isSuccess = true;
                
            } catch (Exception e) {
                Database.rollback(sp);
                result.isSuccess = false;
                result.rescheduleConfirmation = '❌ Error rescheduling: ' + e.getMessage() 
                    + '\nWould you like to try again or speak with a human agent?';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class RescheduleRequest {
        @InvocableVariable(label='Old Appointment ID' required=true)
        public String oldAppointmentId;
        
        @InvocableVariable(label='New Date (YYYY-MM-DD)' required=true)
        public String newDate;
        
        @InvocableVariable(label='New Time' required=true)
        public String newTime;
        
        @InvocableVariable(label='New Provider ID')
        public String newProviderId;
    }
    
    public class RescheduleResult {
        @InvocableVariable(label='Reschedule Confirmation')
        public String rescheduleConfirmation;
        
        @InvocableVariable(label='New Appointment ID')
        public String newAppointmentId;
        
        @InvocableVariable(label='New Appointment Number')
        public String newAppointmentNumber;
        
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
    }
}
```

### Flow: Post-Cancellation Automation

Create a **Record-Triggered Flow** that fires when an Appointment is cancelled:

**Flow Name:** `Appointment_Post_Cancellation`
**Trigger:** When `Appointment__c` record is updated, `Status__c` changes to `Cancelled`

```
[TRIGGER: Appointment Status changed to "Cancelled"]
  ↓
[Update Patient Account]
  - If No_Show tracking needed, update counters
  ↓
[Decision: Was this a chemo/surgery appointment?]
  ├── YES → [Create Task for Care Coordinator]
  │          Subject: "Cancelled chemo/surgery - follow up with patient"
  │          Assigned to: Care Team queue
  │
  └── NO → Continue
  ↓
[Send Cancellation Confirmation Email/SMS]
  - Template: "Your appointment APT-XXXX has been cancelled"
  ↓
[END]
```

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — Cancel Flow

```
👤 I need to cancel my appointment
🤖 I can help with that. Could you share your name or Patient ID?
👤 PAT-00001
🤖 Hi Rahul! Here are your upcoming appointments:

   1. 📅 April 17, 2026 at 10:00 AM
      👨‍⚕️ Dr. Sunita Reddy
      🏬 Medical Oncology | 🏥 Onco Global North, Delhi
      📋 APT-0001 | Status: Scheduled

   Which appointment would you like to cancel?

👤 That one, APT-0001
🤖 I'm sorry to hear that. Before I cancel, could you share the reason?
   This helps us improve our service.

👤 I have a schedule conflict at work

🤖 I understand. Just to confirm:
   Cancel appointment APT-0001 with Dr. Sunita Reddy on April 17 at 10:00 AM?

👤 Yes, please cancel it

🤖 ✅ Appointment Cancelled Successfully
   📋 APT-0001 with Dr. Sunita Reddy has been cancelled.
   💬 Reason: Schedule conflict at work

   Would you like to rebook at a different time?
```

### Demo Conversation — Reschedule Flow

```
👤 I want to reschedule my appointment to next Monday
🤖 Sure! Let me look up your appointments. What's your Patient ID?
👤 PAT-00003
🤖 Hi Anil! Here's your upcoming appointment:

   1. 📅 April 18, 2026 at 09:00 AM
      👨‍⚕️ Dr. Mohammed Khan | Hematology
      📋 APT-0003

   Would you like to reschedule this one?

👤 Yes, to Monday

🤖 Let me check Dr. Khan's availability on Monday, April 21:

   1. 🕐 09:30 AM
   2. 🕐 11:00 AM
   3. 🕐 02:30 PM
   4. 🕐 04:00 PM

   Which time works for you?

👤 11 AM please

🤖 ✅ Appointment Rescheduled!
   🔄 Old: APT-0003 (April 18, 09:00 AM) → Cancelled
   ✨ New: APT-0008
   📅 Monday, April 21, 2026 at 11:00 AM
   👨‍⚕️ Dr. Mohammed Khan | Hematology
   🏥 Onco Global Main Campus, Mumbai

   📱 You'll receive a new reminder. Anything else?
```

---

## 🧪 6. Testing

| Test | Input | Expected Result |
|------|-------|-----------------|
| Cancel happy path | Cancel APT-0001 with reason | Status → Cancelled, slot freed |
| Cancel already cancelled | Try to cancel APT-0001 again | "Already cancelled" message |
| Reschedule happy path | Reschedule APT-0003 to Monday 11 AM | Old apt → Rescheduled, new apt created |
| Reschedule unavailable slot | Choose a booked slot | "Slot no longer available, choose another" |
| Multiple appointments | Patient has 3 upcoming | All 3 shown, patient picks one |
| No appointments | Patient with no upcoming | "No upcoming appointments. Book new?" |
| Within 24 hours | Cancel tomorrow's appointment | Warning shown, but allowed |

---

## 🎯 Summary

After completing Feature 5:
- ✅ Appointment lookup by patient
- ✅ Cancel flow with reason tracking and slot freeing
- ✅ Reschedule flow with atomic old-cancel + new-create (with savepoint)
- ✅ Post-cancellation automation (email + care coordinator alert)
- ✅ 3 new Apex classes (Modifier, Canceller, Rescheduler)
- ✅ Modification count tracking

**Next:** → Feature 6: AI Symptom-based Routing
