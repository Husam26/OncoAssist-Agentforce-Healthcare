# Feature 16: Smart Waitlist & Cancellation Backfill Engine

## 📚 1. Concept Explanation

**What we are building:**
An intelligent waitlist system that automatically detects cancellations and instantly notifies patients who are waiting for the same doctor/department/time slot. When a cancellation creates an opening, the system proactively reaches out to waitlisted patients in priority order and auto-fills the vacant slot — maximizing clinical utilization and reducing patient wait times.

**Why this is a hackathon standout:**
- Solves a **real operational problem** — empty slots after cancellations waste clinical resources
- Creates a **virtuous cycle**: Feature 5 (cancellation) → Feature 16 (auto-backfill) → 0% wasted slots
- Demonstrates **proactive AI** — the agent reaches out to patients, not the other way around
- No competitor will have this — it's an advanced optimization that shows systems thinking
- Directly addresses the problem statement's "wasting vital clinical slots" concern

**How it works:**
```
Patient cancels appointment (Feature 5)
    ↓
System detects freed slot
    ↓
Query Waitlist: Who wants this doctor/dept/time?
    ↓
Rank waitlisted patients by: urgency, wait duration, preference match
    ↓
Notify #1 patient via preferred channel (WhatsApp/SMS/Web)
    ↓
Patient accepts → Auto-book | Patient declines → Notify #2
    ↓
Slot filled within minutes instead of staying empty
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Create Waitlist Custom Object

#### 📋 Custom Object: `Waitlist_Entry__c`

**Purpose:** Tracks patients who want an appointment but couldn't find a suitable slot.

**Create the object:**
- **Label:** `Waitlist Entry`
- **Plural Label:** `Waitlist Entries`
- **Record Name:** `Waitlist ID` (Auto Number, format: `WL-{00000}`)

**Fields:**

| Field Label | API Name | Data Type | Required | Description |
|------------|----------|-----------|----------|-------------|
| Patient | `Patient__c` | Lookup(Account) | ✅ Yes | Who is waiting |
| Desired Provider | `Desired_Provider__c` | Lookup(Provider__c) | No | Specific doctor (if any) |
| Desired Department | `Desired_Department__c` | Lookup(Department__c) | ✅ Yes | Required department |
| Desired Hospital | `Desired_Hospital__c` | Lookup(Hospital__c) | No | Preferred hospital |
| Earliest Date | `Earliest_Date__c` | Date | ✅ Yes | Won't accept before this date |
| Latest Date | `Latest_Date__c` | Date | ✅ Yes | Won't accept after this date |
| Preferred Time | `Preferred_Time__c` | Picklist | No | Morning, Afternoon, Evening, Any |
| Urgency Level | `Urgency_Level__c` | Picklist | No | Normal, High, Urgent |
| Reason for Visit | `Reason__c` | Text Area(500) | No | Why they need the appointment |
| Status | `Status__c` | Picklist | ✅ Yes | Active, Offered, Booked, Expired, Cancelled |
| Date Added | `Date_Added__c` | Date/Time | No | When they joined the waitlist |
| Notification Count | `Notification_Count__c` | Number(2,0) | No | How many times we've reached out |
| Last Notified | `Last_Notified__c` | Date/Time | No | When we last contacted them |
| Preferred Channel | `Preferred_Channel__c` | Picklist | No | WhatsApp, SMS, Web Chat, Email |
| Priority Score | `Priority_Score__c` | Number(5,2) | No | Auto-calculated priority ranking |
| Visit Type | `Visit_Type__c` | Picklist | No | New Consultation, Follow-up, etc. |
| Linked Appointment | `Linked_Appointment__c` | Lookup(Appointment__c) | No | The appointment created when matched |

**Picklist Values:**

**Status__c:** Active, Offered, Booked, Expired, Cancelled
**Urgency_Level__c:** Normal, High, Urgent
**Preferred_Time__c:** Morning (8AM-12PM), Afternoon (12PM-4PM), Evening (4PM-8PM), Any

### Step 2.2: Add Waitlist Count to Provider

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Active Waitlist Count | `Active_Waitlist__c` | Number(4,0) | Rollup of active waitlist entries |

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Agent Action — Add to Waitlist

1. **Action Name:** `Add_To_Waitlist`
2. **Action Type:** Apex Invocable
3. **Description:** `Add a patient to the smart waitlist when no suitable slot is available.`
4. **Inputs:**
   - `patient_id` (String)
   - `department_id` (String)
   - `provider_id` (String, optional)
   - `earliest_date` (String)
   - `latest_date` (String)
   - `preferred_time` (String)
   - `urgency_level` (String)
   - `reason` (String)
5. **Outputs:**
   - `waitlist_confirmation` (String)
   - `waitlist_position` (Number)
   - `estimated_wait` (String)

### Step 3.2: Agent Action — Check Waitlist for Backfill

1. **Action Name:** `Check_Waitlist_For_Backfill`
2. **Action Type:** Apex Invocable
3. **Description:** `When a slot is freed, find the best matching waitlisted patient.`
4. **Inputs:**
   - `provider_id` (String)
   - `department_id` (String)
   - `slot_date` (String)
   - `slot_time` (String)
5. **Outputs:**
   - `match_found` (Boolean)
   - `matched_patient_details` (String)
   - `waitlist_entry_id` (String)

### Step 3.3: Agent Instructions for Waitlist

```
## Smart Waitlist Management

### When NO slots are available:
After exhausting all slot options (same doctor, same department, 
cross-hospital), offer the waitlist:

"I don't have any available slots that match right now, but I can 
add you to our Smart Waitlist. If any cancellation opens up a slot 
with [doctor/department], I'll notify you immediately via 
[WhatsApp/SMS]. You'll be offered the slot before anyone else.

Would you like to join the waitlist?"

### When a cancellation happens:
After any successful cancellation (Feature 5), automatically call 
Check_Waitlist_For_Backfill to find a matching waitlisted patient.
If a match is found, proactively reach out:

"Hi [Patient Name]! Great news — a slot just opened up with 
Dr. [Name] on [Date] at [Time]. Would you like to book it? 
Reply YES to confirm!"

### Waitlist Rules:
- Maximum 30-day waitlist window
- Auto-expire entries after Latest_Date passes
- Never notify the same patient more than 3 times
- Priority order: Urgent > High > Normal, then by Date Added (FIFO)
```

---

## 🔄 4. Automation / Logic

### Apex Class: Waitlist Manager

```apex
public class WaitlistManager {
    
    @InvocableMethod(label='Add To Waitlist'
                     description='Add a patient to the smart waitlist')
    public static List<WaitlistResult> addToWaitlist(List<WaitlistRequest> requests) {
        List<WaitlistResult> results = new List<WaitlistResult>();
        
        for (WaitlistRequest req : requests) {
            WaitlistResult result = new WaitlistResult();
            
            try {
                // Check for duplicate waitlist entry
                List<Waitlist_Entry__c> existing = [
                    SELECT Id FROM Waitlist_Entry__c
                    WHERE Patient__c = :req.patientId
                    AND Desired_Department__c = :req.departmentId
                    AND Status__c = 'Active'
                    LIMIT 1
                ];
                
                if (!existing.isEmpty()) {
                    result.waitlistConfirmation = 'You\'re already on the waitlist for this department. '
                        + 'We\'ll notify you as soon as a slot opens up!';
                    result.waitlistPosition = getPosition(existing[0].Id, req.departmentId);
                    results.add(result);
                    continue;
                }
                
                // Create waitlist entry
                Waitlist_Entry__c entry = new Waitlist_Entry__c();
                entry.Patient__c = req.patientId;
                entry.Desired_Department__c = req.departmentId;
                entry.Earliest_Date__c = Date.valueOf(req.earliestDate);
                entry.Latest_Date__c = Date.valueOf(req.latestDate);
                entry.Preferred_Time__c = req.preferredTime;
                entry.Urgency_Level__c = req.urgencyLevel != null ? req.urgencyLevel : 'Normal';
                entry.Reason__c = req.reason;
                entry.Status__c = 'Active';
                entry.Date_Added__c = DateTime.now();
                entry.Notification_Count__c = 0;
                entry.Preferred_Channel__c = 'WhatsApp'; // Default
                entry.Visit_Type__c = 'New Consultation';
                
                if (req.providerId != null && req.providerId != '') {
                    entry.Desired_Provider__c = req.providerId;
                }
                
                // Calculate priority score
                Decimal priorityScore = 50; // base
                if (entry.Urgency_Level__c == 'Urgent') priorityScore += 40;
                else if (entry.Urgency_Level__c == 'High') priorityScore += 20;
                
                // Tighter date window = higher priority
                Integer dateRange = entry.Earliest_Date__c.daysBetween(entry.Latest_Date__c);
                if (dateRange <= 3) priorityScore += 15;
                else if (dateRange <= 7) priorityScore += 10;
                
                entry.Priority_Score__c = priorityScore;
                
                insert entry;
                
                // Calculate position
                Integer position = getPosition(entry.Id, req.departmentId);
                result.waitlistPosition = position;
                
                // Estimate wait time
                String estimatedWait = estimateWait(req.departmentId);
                result.estimatedWait = estimatedWait;
                
                // Build confirmation
                String conf = '📋 You\'ve been added to the Smart Waitlist!\n\n';
                conf += '🔢 Waitlist Position: #' + position + '\n';
                conf += '🏬 Department: ';
                
                Department__c dept = [SELECT Name FROM Department__c WHERE Id = :req.departmentId LIMIT 1];
                conf += dept.Name + '\n';
                
                if (req.providerId != null && req.providerId != '') {
                    Provider__c doc = [SELECT Name FROM Provider__c WHERE Id = :req.providerId LIMIT 1];
                    conf += '👨‍⚕️ Preferred Doctor: ' + doc.Name + '\n';
                }
                
                conf += '📅 Date Window: ' + entry.Earliest_Date__c.format() 
                    + ' to ' + entry.Latest_Date__c.format() + '\n';
                conf += '⏰ Preferred Time: ' + entry.Preferred_Time__c + '\n';
                conf += '⏱️ Estimated Wait: ' + estimatedWait + '\n\n';
                conf += '📱 I\'ll notify you immediately via WhatsApp when a slot opens up!\n';
                conf += '💡 Tip: You can also check your waitlist status anytime by asking me.';
                
                result.waitlistConfirmation = conf;
                
            } catch (Exception e) {
                result.waitlistConfirmation = '❌ Error adding to waitlist: ' + e.getMessage();
            }
            
            results.add(result);
        }
        return results;
    }
    
    // Calculate position in the waitlist
    private static Integer getPosition(Id entryId, String departmentId) {
        List<Waitlist_Entry__c> ahead = [
            SELECT Id FROM Waitlist_Entry__c
            WHERE Desired_Department__c = :departmentId
            AND Status__c = 'Active'
            AND (Priority_Score__c > (SELECT Priority_Score__c 
                FROM Waitlist_Entry__c WHERE Id = :entryId)
                OR (Priority_Score__c = (SELECT Priority_Score__c 
                FROM Waitlist_Entry__c WHERE Id = :entryId)
                AND Date_Added__c < (SELECT Date_Added__c 
                FROM Waitlist_Entry__c WHERE Id = :entryId)))
        ];
        return ahead.size() + 1;
    }
    
    // Estimate wait time based on historical cancellation rate
    private static String estimateWait(String departmentId) {
        // Count recent cancellations for this department (last 30 days)
        Integer cancellations = [
            SELECT COUNT() FROM Appointment__c
            WHERE Department__c = :departmentId
            AND Status__c = 'Cancelled'
            AND Appointment_Date__c >= :Date.today().addDays(-30)
        ];
        
        if (cancellations > 20) return '1-2 days (high cancellation rate)';
        else if (cancellations > 10) return '3-5 days';
        else if (cancellations > 5) return '5-7 days';
        else return '7-14 days';
    }
}
```

### Apex Class: Waitlist Backfill Engine

```apex
public class WaitlistBackfillEngine {
    
    @InvocableMethod(label='Check Waitlist For Backfill'
                     description='Find the best waitlisted patient for a freed slot')
    public static List<BackfillResult> findBackfillMatch(List<BackfillRequest> requests) {
        List<BackfillResult> results = new List<BackfillResult>();
        
        for (BackfillRequest req : requests) {
            BackfillResult result = new BackfillResult();
            
            Date slotDate = Date.valueOf(req.slotDate);
            
            // Query active waitlist entries matching the freed slot
            List<Waitlist_Entry__c> candidates = [
                SELECT Id, Patient__c, Patient__r.Name, Patient__r.Patient_ID__c,
                       Patient__r.Phone, Desired_Provider__c, Desired_Department__c,
                       Preferred_Time__c, Urgency_Level__c, Priority_Score__c,
                       Date_Added__c, Notification_Count__c, Preferred_Channel__c,
                       Reason__c
                FROM Waitlist_Entry__c
                WHERE Desired_Department__c = :req.departmentId
                AND Status__c = 'Active'
                AND Earliest_Date__c <= :slotDate
                AND Latest_Date__c >= :slotDate
                AND Notification_Count__c < 3
                AND (Desired_Provider__c = :req.providerId 
                     OR Desired_Provider__c = null)
                ORDER BY Priority_Score__c DESC, Date_Added__c ASC
                LIMIT 5
            ];
            
            // Filter by time preference
            List<Waitlist_Entry__c> timeMatched = new List<Waitlist_Entry__c>();
            for (Waitlist_Entry__c wl : candidates) {
                if (wl.Preferred_Time__c == 'Any' || wl.Preferred_Time__c == null) {
                    timeMatched.add(wl);
                    continue;
                }
                
                Boolean isMorning = req.slotTime.contains('AM');
                Boolean isAfternoon = req.slotTime.contains('PM') && 
                    !req.slotTime.startsWith('04') && !req.slotTime.startsWith('05');
                Boolean isEvening = req.slotTime.startsWith('04') || req.slotTime.startsWith('05');
                
                if ((wl.Preferred_Time__c == 'Morning' && isMorning) ||
                    (wl.Preferred_Time__c == 'Afternoon' && isAfternoon) ||
                    (wl.Preferred_Time__c == 'Evening' && isEvening)) {
                    timeMatched.add(wl);
                }
            }
            
            if (!timeMatched.isEmpty()) {
                Waitlist_Entry__c bestMatch = timeMatched[0];
                
                result.matchFound = true;
                result.waitlistEntryId = bestMatch.Id;
                
                // Update waitlist entry status
                bestMatch.Status__c = 'Offered';
                bestMatch.Last_Notified__c = DateTime.now();
                bestMatch.Notification_Count__c += 1;
                update bestMatch;
                
                // Get provider details
                Provider__c provider = [
                    SELECT Name, Department__r.Name, Hospital__r.Name
                    FROM Provider__c WHERE Id = :req.providerId LIMIT 1
                ];
                
                // Build notification
                String notification = '🎉 Great news, ' + bestMatch.Patient__r.Name + '!\n\n';
                notification += 'A slot just opened up:\n';
                notification += '👨‍⚕️ Doctor: ' + provider.Name + '\n';
                notification += '🏬 Department: ' + provider.Department__r.Name + '\n';
                notification += '🏥 Hospital: ' + provider.Hospital__r.Name + '\n';
                notification += '📅 Date: ' + slotDate.format() + '\n';
                notification += '🕐 Time: ' + req.slotTime + '\n\n';
                notification += '⚡ This slot won\'t last long!\n';
                notification += 'Reply YES to book immediately, or NO to pass.\n';
                notification += '(You\'ll remain on the waitlist if you pass.)';
                
                result.matchedPatientDetails = notification;
            } else {
                result.matchFound = false;
                result.matchedPatientDetails = 'No matching waitlisted patients found for this slot.';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class BackfillRequest {
        @InvocableVariable(label='Provider ID' required=true)
        public String providerId;
        
        @InvocableVariable(label='Department ID' required=true)
        public String departmentId;
        
        @InvocableVariable(label='Slot Date' required=true)
        public String slotDate;
        
        @InvocableVariable(label='Slot Time' required=true)
        public String slotTime;
    }
    
    public class BackfillResult {
        @InvocableVariable(label='Match Found')
        public Boolean matchFound;
        
        @InvocableVariable(label='Matched Patient Details')
        public String matchedPatientDetails;
        
        @InvocableVariable(label='Waitlist Entry ID')
        public String waitlistEntryId;
    }
}
```

### Record-Triggered Flow: Auto-Backfill on Cancellation

**Flow Name:** `Auto_Backfill_On_Cancellation`
**Trigger:** When `Appointment__c.Status__c` changes to `Cancelled` or `Rescheduled`

```
[TRIGGER: Appointment Status → Cancelled/Rescheduled]
  ↓
[Apex Action: WaitlistBackfillEngine.findBackfillMatch]
  - provider_id: {Appointment.Provider__c}
  - department_id: {Appointment.Department__c}
  - slot_date: {Appointment.Appointment_Date__c}
  - slot_time: {Appointment.Appointment_Time__c}
  ↓
[Decision: Match found?]
  ├── YES → [Send Notification]
  │          Channel: {WaitlistEntry.Preferred_Channel__c}
  │          Message: {matchedPatientDetails}
  │          ↓
  │          [Wait for Response — 2 hours]
  │          ↓
  │          [Decision: Patient accepted?]
  │            ├── YES → [Book Appointment for waitlisted patient]
  │            │          [Update Waitlist Status → "Booked"]
  │            └── NO  → [Offer to next candidate]
  │
  └── NO → [Log: "No waitlist match for freed slot"]
  ↓
[END]
```

### Scheduled Flow: Waitlist Cleanup

**Flow Name:** `Waitlist_Expiry_Cleanup`
**Schedule:** Daily at midnight

```
[Get Records: Waitlist_Entry__c]
  - Status__c = 'Active'
  - Latest_Date__c < TODAY
  ↓
[Loop: Update each → Status = 'Expired']
  ↓
[Optionally: Send "Your waitlist entry has expired" notification]
  ↓
[END]
```

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — Joining the Waitlist

```
🤖 I've checked Dr. Priya Sharma's availability for the next 
   2 weeks, but unfortunately all slots are currently booked.

   However, I can add you to our Smart Waitlist! If any 
   cancellation opens up a slot with Dr. Sharma, I'll notify 
   you immediately via WhatsApp.

   Would you like to join the waitlist?

👤 Yes, please add me

🤖 📋 You've been added to the Smart Waitlist!

   🔢 Waitlist Position: #2
   🏬 Department: Medical Oncology
   👨‍⚕️ Preferred Doctor: Dr. Priya Sharma
   📅 Date Window: April 28 to May 12
   ⏰ Preferred Time: Morning
   ⏱️ Estimated Wait: 3-5 days

   📱 I'll notify you immediately via WhatsApp when a 
   slot opens up!
   
   💡 Tip: You can check your waitlist status anytime 
   by asking me.
```

### Demo: Auto-Backfill Notification (WhatsApp)

```
📱 WhatsApp Message:
━━━━━━━━━━━━━━━━━━━━━━━
🎉 Great news, Priya!

A slot just opened up:
👨‍⚕️ Doctor: Dr. Priya Sharma
🏬 Department: Medical Oncology
🏥 Hospital: Onco Global Main Campus
📅 Date: Wednesday, May 1
🕐 Time: 10:00 AM

⚡ This slot won't last long!
Reply YES to book immediately.
━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🧪 6. Testing

| Test | Input | Expected Result |
|------|-------|-----------------|
| Add to waitlist | No slots → join waitlist | Entry created, position shown |
| Duplicate prevention | Try joining waitlist twice | "Already on waitlist" message |
| Priority ordering | Urgent patient joins after Normal patient | Urgent patient gets position #1 |
| Auto-backfill | Cancel an appointment with a matching waitlister | Notification sent to waitlisted patient |
| Time preference | Backfill AM slot, waitlister wants PM | Waitlister is skipped, next candidate checked |
| Expiry | Waitlist entry past latest_date | Status auto-set to "Expired" |
| Notification cap | Patient notified 3 times without accepting | No more notifications sent |
| Backfill booking | Waitlisted patient replies YES | Appointment created, waitlist status = "Booked" |

---

## 🎯 Summary

After completing Feature 16:
- ✅ `Waitlist_Entry__c` custom object with priority scoring
- ✅ Smart priority algorithm (urgency + FIFO + time preference)
- ✅ Automatic backfill trigger on every cancellation
- ✅ Multi-channel notification (WhatsApp, SMS, Web Chat)
- ✅ Notification cap (max 3 per patient) to prevent spam
- ✅ Waitlist expiry cleanup automation
- ✅ Estimated wait time based on historical cancellation rates
- ✅ Seamless integration with Feature 5 (Cancel) and Feature 9 (WhatsApp)

**Next:** → Feature 17: Family & Caregiver Appointment Management
