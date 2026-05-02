# Feature 18: Post-Visit Follow-Up & Treatment Adherence Automation

## 📚 1. Concept Explanation

**What we are building:**
An automated post-visit care continuity system that proactively reaches out to patients after every appointment to check on their well-being, remind them about prescribed follow-ups, track medication/treatment adherence, and auto-schedule the next appointment in their care journey. This turns the AI agent from a "booking tool" into a **continuous care companion**.

**Why this is a hackathon winner:**
- Extends the agent's value **beyond the appointment** — most competitors will stop at booking
- Demonstrates **continuity of care** — a core Health Cloud principle that judges will love
- Uses **proactive outreach** — the agent contacts the patient, not vice versa
- Directly reduces the "scheduling friction" pain point by auto-suggesting next steps
- Shows sophisticated **care pathway understanding** — chemo cycles, radiation schedules, follow-up intervals

**The Care Continuity Loop:**
```
Appointment Completed
    ↓
24h Post-Visit Check-In (automated)
    "How are you feeling after your visit with Dr. Sharma?"
    ↓
Capture patient's post-visit status
    ↓
Auto-generate follow-up recommendation based on visit type
    ↓
Offer to book the next appointment immediately
    ↓
Track adherence: Did patient actually book & attend?
    ↓
If non-adherent → Proactive nudge via WhatsApp/SMS
    ↓
Feed back into Data Cloud engagement score (Feature 13)
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Create Post-Visit Check-In Object

#### 📋 Custom Object: `Post_Visit_CheckIn__c`

**Purpose:** Records every post-visit interaction and patient-reported outcomes.

**Create the object:**
- **Label:** `Post Visit Check-In`
- **Plural Label:** `Post Visit Check-Ins`
- **Record Name:** `Check-In ID` (Auto Number, format: `PV-{00000}`)

**Fields:**

| Field Label | API Name | Data Type | Required | Description |
|------------|----------|-----------|----------|-------------|
| Appointment | `Appointment__c` | Lookup(Appointment__c) | ✅ Yes | Which visit this follows |
| Patient | `Patient__c` | Lookup(Account) | ✅ Yes | The patient |
| Provider | `Provider__c` | Lookup(Provider__c) | No | The doctor they saw |
| Check-In Status | `Status__c` | Picklist | ✅ Yes | Sent, Responded, No Response, Escalated |
| Patient Feeling | `Patient_Feeling__c` | Picklist | No | Great, Good, Okay, Unwell, Emergency |
| Reported Symptoms | `Reported_Symptoms__c` | Text Area(Long) | No | Any new symptoms post-visit |
| Pain Level | `Pain_Level__c` | Number(2,0) | No | 0-10 scale |
| Side Effects | `Side_Effects__c` | Text Area(500) | No | Post-treatment side effects |
| Follow-Up Recommended | `Follow_Up_Recommended__c` | Checkbox | No | Does the system recommend a follow-up? |
| Follow-Up Type | `Follow_Up_Type__c` | Picklist | No | Same Doctor, Lab Work, Imaging, Specialist |
| Follow-Up Window | `Follow_Up_Window__c` | Text(50) | No | "Within 2 weeks", "Next month" |
| Follow-Up Booked | `Follow_Up_Booked__c` | Checkbox | No | Was the follow-up actually scheduled? |
| Follow-Up Appointment | `Follow_Up_Appointment__c` | Lookup(Appointment__c) | No | Link to the follow-up appointment |
| Check-In Channel | `Channel__c` | Picklist | No | WhatsApp, SMS, Web Chat, Email |
| Check-In Timestamp | `CheckIn_Timestamp__c` | Date/Time | No | When the check-in was initiated |
| Response Timestamp | `Response_Timestamp__c` | Date/Time | No | When the patient responded |
| Requires Escalation | `Requires_Escalation__c` | Checkbox | No | Does this need doctor attention? |
| Escalation Reason | `Escalation_Reason__c` | Text(500) | No | Why escalated |

**Picklist Values:**

**Patient_Feeling__c:** Great, Good, Okay, Unwell, Emergency
**Follow_Up_Type__c:** Same Doctor Follow-Up, Lab Work, Imaging/Scan, Specialist Referral, Chemotherapy Cycle, Radiation Session

### Step 2.2: Create Follow-Up Rules Object

#### 📏 Custom Object: `Follow_Up_Rule__c`

**Purpose:** Defines automated follow-up scheduling rules by visit type.

| Field Label | API Name | Data Type | Required | Description |
|------------|----------|-----------|----------|-------------|
| Visit Type | `Visit_Type__c` | Text(100) | ✅ Yes | Matches Appointment.Type__c |
| Follow-Up Interval (days) | `Interval_Days__c` | Number(3,0) | ✅ Yes | Days until recommended follow-up |
| Follow-Up Type | `Follow_Up_Type__c` | Picklist | ✅ Yes | What type of follow-up |
| Same Provider | `Same_Provider__c` | Checkbox | No | Should the follow-up be with the same doctor? |
| Check-In Delay (hours) | `CheckIn_Delay_Hours__c` | Number(3,0) | No | When to send post-visit check-in (default 24h) |
| Is Mandatory | `Is_Mandatory__c` | Checkbox | No | Is this follow-up clinically important? |
| Priority | `Priority__c` | Picklist | No | Normal, High, Urgent |

**Sample Follow-Up Rules:**

| Visit Type | Follow-Up Interval | Follow-Up Type | Same Doctor? | Check-In Delay | Mandatory |
|-----------|-------------------|---------------|-------------|---------------|-----------|
| Chemotherapy | 14 days | Chemotherapy Cycle | ✅ Yes | 6 hours | ✅ Yes |
| Radiation | 7 days | Radiation Session | ✅ Yes | 12 hours | ✅ Yes |
| New Consultation | 30 days | Same Doctor Follow-Up | ✅ Yes | 24 hours | No |
| Follow-up | 30 days | Same Doctor Follow-Up | ✅ Yes | 24 hours | No |
| Surgery Pre-op | 3 days | Lab Work | No | 48 hours | ✅ Yes |
| Lab/Diagnostics | 7 days | Same Doctor Follow-Up | No | 24 hours | No |
| Second Opinion | 14 days | Same Doctor Follow-Up | ✅ Yes | 24 hours | No |

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Agent Action — Post-Visit Check-In

1. **Action Name:** `Post_Visit_CheckIn`
2. **Action Type:** Apex Invocable
3. **Description:** `Conduct a post-visit well-being check-in with the patient and capture their status.`
4. **Inputs:**
   - `appointment_id` (String)
   - `patient_feeling` (String) — Great/Good/Okay/Unwell/Emergency
   - `reported_symptoms` (String, optional)
   - `pain_level` (Number, optional)
   - `side_effects` (String, optional)
5. **Outputs:**
   - `checkin_response` (String) — Personalized response
   - `follow_up_suggestion` (String) — Recommended next step
   - `requires_escalation` (Boolean)

### Step 3.2: Agent Action — Auto-Schedule Follow-Up

1. **Action Name:** `Auto_Schedule_FollowUp`
2. **Action Type:** Apex Invocable
3. **Description:** `Based on the visit type and follow-up rules, suggest and book the next appointment.`
4. **Inputs:**
   - `appointment_id` (String) — The completed appointment
   - `patient_id` (String)
   - `follow_up_date_preference` (String, optional)
5. **Outputs:**
   - `follow_up_suggestion` (String) — Formatted recommendation
   - `available_slots` (String) — Available slots for the follow-up

### Step 3.3: Agent Instructions for Post-Visit Care

```
## Post-Visit Follow-Up Protocol

### Triggering Check-Ins
Post-visit check-ins are triggered automatically by a scheduled flow.
When the system initiates a proactive check-in, follow this protocol:

### Check-In Conversation Script:

"Hi [Patient Name]! This is OncoAssist from Onco Global. 🏥

You recently visited Dr. [Name] on [Date]. We'd like to check 
on how you're doing.

How are you feeling after your visit? 
😊 Great  🙂 Good  😐 Okay  😟 Unwell"

### Response Handling:

#### 😊 Great / 🙂 Good:
"That's wonderful to hear! 🎉

Based on your visit type, your next recommended follow-up is:
📅 [Follow-up type] in [X days/weeks]

Would you like me to book it now?"

#### 😐 Okay:
"Thank you for letting me know. Is there anything specific 
that's concerning you? Any new symptoms or side effects?

Based on your treatment, here are some things to watch for:
[List relevant side effects for their treatment type]

Your next follow-up is recommended in [X days]. Would you 
like to schedule it sooner?"

#### 😟 Unwell:
"I'm sorry to hear that. Your well-being is our priority.

Can you tell me more about how you're feeling?
- Any new pain? (Scale 1-10)
- Any side effects from treatment?
- Any symptoms that worry you?

I want to make sure we get you the right support."
→ If concerning → Escalate to care coordinator
→ If manageable → Suggest earlier follow-up appointment

#### 🚨 Emergency:
Immediately provide emergency contacts and escalate.

### Follow-Up Scheduling:
After the check-in, always offer to book the next recommended 
follow-up. Use the Auto_Schedule_FollowUp action to find the 
optimal slot.
```

---

## 🔄 4. Automation / Logic

### Apex Class: Post-Visit Check-In Engine

```apex
public class PostVisitCheckInEngine {
    
    @InvocableMethod(label='Post-Visit Check-In'
                     description='Process patient post-visit well-being check and generate follow-up')
    public static List<CheckInResult> processCheckIn(List<CheckInRequest> requests) {
        List<CheckInResult> results = new List<CheckInResult>();
        
        for (CheckInRequest req : requests) {
            CheckInResult result = new CheckInResult();
            
            try {
                // Get the completed appointment
                Appointment__c apt = [
                    SELECT Id, Name, Patient__c, Provider__c, Provider__r.Name,
                           Department__c, Department__r.Name, Hospital__c,
                           Type__c, Appointment_Date__c,
                           Patient__r.Name, Patient__r.Primary_Diagnosis__c,
                           Patient__r.Current_Treatment__c
                    FROM Appointment__c
                    WHERE Id = :req.appointmentId
                    LIMIT 1
                ];
                
                // Create the check-in record
                Post_Visit_CheckIn__c checkIn = new Post_Visit_CheckIn__c();
                checkIn.Appointment__c = apt.Id;
                checkIn.Patient__c = apt.Patient__c;
                checkIn.Provider__c = apt.Provider__c;
                checkIn.Patient_Feeling__c = req.patientFeeling;
                checkIn.Reported_Symptoms__c = req.reportedSymptoms;
                checkIn.Pain_Level__c = req.painLevel;
                checkIn.Side_Effects__c = req.sideEffects;
                checkIn.Status__c = 'Responded';
                checkIn.Channel__c = 'Web Chat';
                checkIn.CheckIn_Timestamp__c = DateTime.now();
                checkIn.Response_Timestamp__c = DateTime.now();
                
                // Determine escalation need
                Boolean needsEscalation = false;
                String escalationReason = '';
                
                if (req.patientFeeling == 'Emergency') {
                    needsEscalation = true;
                    escalationReason = 'Patient reported emergency status';
                } else if (req.patientFeeling == 'Unwell') {
                    if (req.painLevel != null && req.painLevel >= 7) {
                        needsEscalation = true;
                        escalationReason = 'High pain level (' + req.painLevel + '/10) reported';
                    }
                    if (req.sideEffects != null && 
                        (req.sideEffects.toLowerCase().contains('fever') || 
                         req.sideEffects.toLowerCase().contains('bleeding') ||
                         req.sideEffects.toLowerCase().contains('breathing'))) {
                        needsEscalation = true;
                        escalationReason += (escalationReason != '' ? '; ' : '') + 
                            'Concerning side effects reported';
                    }
                }
                
                checkIn.Requires_Escalation__c = needsEscalation;
                checkIn.Escalation_Reason__c = escalationReason;
                result.requiresEscalation = needsEscalation;
                
                // Get follow-up rule for this visit type
                List<Follow_Up_Rule__c> rules = [
                    SELECT Visit_Type__c, Interval_Days__c, Follow_Up_Type__c,
                           Same_Provider__c, Is_Mandatory__c, Priority__c
                    FROM Follow_Up_Rule__c
                    WHERE Visit_Type__c = :apt.Type__c
                    LIMIT 1
                ];
                
                String followUpSuggestion = '';
                if (!rules.isEmpty()) {
                    Follow_Up_Rule__c rule = rules[0];
                    Date recommendedDate = apt.Appointment_Date__c.addDays(rule.Interval_Days__c.intValue());
                    
                    checkIn.Follow_Up_Recommended__c = true;
                    checkIn.Follow_Up_Type__c = rule.Follow_Up_Type__c;
                    checkIn.Follow_Up_Window__c = 'Within ' + rule.Interval_Days__c.intValue() + ' days';
                    
                    followUpSuggestion = '📋 **Recommended Follow-Up:**\n';
                    followUpSuggestion += '🔄 Type: ' + rule.Follow_Up_Type__c + '\n';
                    followUpSuggestion += '📅 Recommended by: ' + recommendedDate.format() + '\n';
                    
                    if (rule.Same_Provider__c) {
                        followUpSuggestion += '👨‍⚕️ With: ' + apt.Provider__r.Name + '\n';
                    }
                    
                    if (rule.Is_Mandatory__c) {
                        followUpSuggestion += '⚠️ This follow-up is **strongly recommended** for your treatment plan.\n';
                    }
                    
                    followUpSuggestion += '\nWould you like me to book this follow-up now?';
                    
                    // If patient is unwell, suggest earlier follow-up
                    if (req.patientFeeling == 'Unwell' || req.patientFeeling == 'Okay') {
                        Integer earlierDays = Math.max(3, rule.Interval_Days__c.intValue() / 2);
                        Date earlierDate = Date.today().addDays(earlierDays);
                        followUpSuggestion += '\n\n💡 Given how you\'re feeling, I can also look for '
                            + 'an earlier appointment around ' + earlierDate.format() + '.';
                    }
                }
                
                checkIn.Follow_Up_Booked__c = false;
                insert checkIn;
                
                // Build response based on feeling
                String response = '';
                
                switch on req.patientFeeling {
                    when 'Great' {
                        response = '🎉 That\'s wonderful to hear! We\'re glad your visit with '
                            + apt.Provider__r.Name + ' went well.\n\n';
                    }
                    when 'Good' {
                        response = '😊 Good to know you\'re doing well after your visit with '
                            + apt.Provider__r.Name + '.\n\n';
                    }
                    when 'Okay' {
                        response = '🙏 Thank you for sharing. Your recovery is important to us. '
                            + 'Please don\'t hesitate to reach out if anything changes.\n\n';
                    }
                    when 'Unwell' {
                        response = '😟 I\'m sorry to hear you\'re not feeling well. ';
                        if (needsEscalation) {
                            response += 'I\'ve flagged this with your care team — '
                                + apt.Provider__r.Name + '\'s office will be in touch shortly.\n\n';
                            response += '📞 In the meantime, if it\'s urgent: 1800-ONCO-911\n\n';
                        } else {
                            response += 'Please keep monitoring your symptoms. ';
                            response += 'Some common post-visit effects for ' + apt.Type__c 
                                + ' may include mild fatigue or discomfort.\n\n';
                        }
                    }
                    when 'Emergency' {
                        response = '🚨 I\'m immediately alerting your care team!\n\n'
                            + '📞 Emergency: 1800-ONCO-911\n'
                            + '📞 National: 112\n\n'
                            + 'Please seek immediate medical attention.\n\n';
                    }
                }
                
                if (String.isNotBlank(followUpSuggestion)) {
                    response += followUpSuggestion;
                }
                
                result.checkinResponse = response;
                result.followUpSuggestion = followUpSuggestion;
                
                // Create escalation task if needed
                if (needsEscalation) {
                    Task escalation = new Task();
                    escalation.Subject = '🚨 Post-Visit Alert: ' + apt.Patient__r.Name 
                        + ' reports ' + req.patientFeeling;
                    escalation.Description = 'Patient Status: ' + req.patientFeeling
                        + '\nPain Level: ' + req.painLevel
                        + '\nSide Effects: ' + req.sideEffects
                        + '\nAppointment: ' + apt.Name + ' with ' + apt.Provider__r.Name
                        + '\nEscalation Reason: ' + escalationReason;
                    escalation.Priority = 'High';
                    escalation.Status = 'Not Started';
                    escalation.ActivityDate = Date.today();
                    escalation.WhatId = checkIn.Id;
                    insert escalation;
                }
                
            } catch (Exception e) {
                result.checkinResponse = 'Thank you for your response. We\'ll follow up soon.';
                result.requiresEscalation = false;
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class CheckInRequest {
        @InvocableVariable(label='Appointment ID' required=true)
        public String appointmentId;
        
        @InvocableVariable(label='Patient Feeling' required=true)
        public String patientFeeling;
        
        @InvocableVariable(label='Reported Symptoms')
        public String reportedSymptoms;
        
        @InvocableVariable(label='Pain Level (0-10)')
        public Integer painLevel;
        
        @InvocableVariable(label='Side Effects')
        public String sideEffects;
    }
    
    public class CheckInResult {
        @InvocableVariable(label='Check-In Response')
        public String checkinResponse;
        
        @InvocableVariable(label='Follow-Up Suggestion')
        public String followUpSuggestion;
        
        @InvocableVariable(label='Requires Escalation')
        public Boolean requiresEscalation;
    }
}
```

### Scheduled Flow: Trigger Post-Visit Check-Ins

**Flow Name:** `Trigger_Post_Visit_CheckIns`
**Schedule:** Every 2 hours

```
[START — Scheduled every 2 hours]
  ↓
[Get Records: Appointment__c]
  - Status__c = 'Completed'
  - No existing Post_Visit_CheckIn__c for this appointment
  - Completed within the last 24-48 hours (based on Follow_Up_Rule.CheckIn_Delay_Hours)
  ↓
[Loop: For each completed appointment]
  → [Get Follow_Up_Rule__c for this visit type]
  → [Decision: Check-in delay has elapsed?]
    ├── YES → [Send proactive check-in via preferred channel]
    │          WhatsApp/SMS: "Hi {Name}, how are you feeling 
    │          after your visit with Dr. {Provider}?"
    │          ↓
    │          [Create Post_Visit_CheckIn__c with Status = 'Sent']
    └── NO  → Skip (not time yet)
  ↓
[END]
```

### Scheduled Flow: Adherence Nudge

**Flow Name:** `Treatment_Adherence_Nudge`
**Schedule:** Daily at 10:00 AM

```
[START — Daily at 10 AM]
  ↓
[Get Records: Post_Visit_CheckIn__c]
  - Follow_Up_Recommended__c = TRUE
  - Follow_Up_Booked__c = FALSE
  - CheckIn_Timestamp__c is > 3 days ago
  ↓
[Loop: For each un-booked follow-up]
  → [Send WhatsApp/SMS nudge]
      "Hi {Name}, a friendly reminder: Your {follow-up type} 
       with Dr. {Provider} is recommended by {date}. 
       Want me to find a slot for you? Reply BOOK to schedule."
  ↓
[END]
```

---

## 🖥️ 5. UI / Experience Layer

### Demo: Proactive Post-Visit Check-In (WhatsApp)

```
📱 WhatsApp Message (24h after appointment):
━━━━━━━━━━━━━━━━━━━━━━━
🏥 Onco Global Care Check-In

Hi Priya! 👋 This is OncoAssist.

You visited Dr. Priya Sharma yesterday for your 
Chemotherapy session. We'd like to check on you:

How are you feeling today?
😊 Great  🙂 Good  😐 Okay  😟 Unwell

Reply with your answer or type any concerns.
━━━━━━━━━━━━━━━━━━━━━━━

📱 Patient Reply: "Okay, some nausea"

📱 Agent Reply:
━━━━━━━━━━━━━━━━━━━━━━━
Thank you, Priya. Mild nausea after chemotherapy is 
common. Here are some tips:
• Eat small, frequent meals
• Stay hydrated
• Ginger tea can help

If nausea persists > 48h or is severe, please contact us.

📋 Your next chemo cycle is recommended by May 12.
Dr. Sharma's available slots:
1. May 10 (Wed) 10:00 AM ⭐
2. May 11 (Thu) 02:00 PM
3. May 12 (Fri) 09:30 AM

Reply 1, 2, or 3 to book!
━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🧪 6. Testing

| Test | Input | Expected Result |
|------|-------|-----------------|
| Check-in trigger | Complete an appointment | Check-in sent after configured delay |
| Good response | Patient says "Great" | Positive acknowledgment + follow-up offer |
| Unwell response | Patient says "Unwell" + pain 8/10 | Escalation task created, care team alerted |
| Emergency response | Patient says "Emergency" | Immediate emergency contacts + case created |
| Follow-up rule | Chemo appointment completes | 14-day follow-up recommended |
| Auto-schedule | Patient accepts follow-up offer | Next appointment booked automatically |
| Adherence nudge | Follow-up not booked after 3 days | WhatsApp nudge sent |
| Data Cloud feed | Check-in completed | Data flows to engagement score calculation |

---

## 🎯 Summary

After completing Feature 18:
- ✅ `Post_Visit_CheckIn__c` object tracking patient well-being
- ✅ `Follow_Up_Rule__c` with 7 visit-type rules for automated scheduling
- ✅ Proactive check-in triggered automatically after every appointment
- ✅ Sentiment-based response engine (Great → Emergency handling)
- ✅ Auto-escalation for concerning patient-reported outcomes
- ✅ Treatment adherence nudging for un-booked follow-ups
- ✅ Seamless follow-up scheduling integrated with booking engine
- ✅ Data feeds into Data Cloud engagement score (Feature 13)

**Next:** → Feature 19: AI-Powered Cross-Network Second Opinion Routing
