# Feature 15: Patient Sentiment Analysis & CSAT Feedback Loop

## 📚 1. Concept Explanation

**What we are building:**
An automated **Patient Satisfaction (CSAT)** system that captures real-time sentiment during AI conversations, triggers post-visit feedback surveys, and feeds the results back into Data Cloud to continuously improve the agent's behavior and hospital operations.

**Why it matters for hackathon judges:**
- Proves the solution is **measurable** — judges want to see ROI and impact metrics
- Demonstrates a **closed feedback loop** — AI learns and improves from patient feedback
- Shows **responsible AI** — monitoring agent quality and patient satisfaction
- Adds a "Voice of the Customer" dimension that competitors will likely miss
- Uses Data Cloud as the central hub for sentiment aggregation — reinforces Feature 13

**The Feedback Loop:**
```
Patient interacts with AI Agent
    ↓
Real-time sentiment detected during conversation
    ↓
Post-interaction CSAT survey triggered (1-5 stars + comment)
    ↓
Feedback stored in Salesforce + streamed to Data Cloud
    ↓
Calculated Insights: Agent performance trends, department satisfaction
    ↓
Insights feed back to agent behavior + operational improvements
    ↓
Loop continues → Agent gets better over time
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Create Feedback Custom Object

#### 📝 Custom Object: `Patient_Feedback__c`

**Purpose:** Captures every feedback interaction from patients after AI conversations.

**Create the object:**
- **Label:** `Patient Feedback`
- **Plural Label:** `Patient Feedbacks`
- **Record Name:** `Feedback ID` (Auto Number, format: `FB-{00000}`)

**Fields:**

| Field Label | API Name | Data Type | Required | Description |
|------------|----------|-----------|----------|-------------|
| Patient | `Patient__c` | Lookup(Account) | ✅ Yes | Who gave the feedback |
| Related Appointment | `Appointment__c` | Lookup(Appointment__c) | No | Linked appointment (if applicable) |
| CSAT Score | `CSAT_Score__c` | Number(1,0) | ✅ Yes | 1-5 star rating |
| NPS Score | `NPS_Score__c` | Number(2,0) | No | 0-10 Net Promoter Score |
| Sentiment | `Sentiment__c` | Picklist | No | Positive, Neutral, Negative |
| Feedback Text | `Feedback_Text__c` | Text Area(Long) | No | Free-form patient comment |
| Interaction Channel | `Channel__c` | Picklist | No | Web Chat, WhatsApp, SMS |
| Interaction Type | `Interaction_Type__c` | Picklist | No | Booking, Cancellation, Inquiry, Triage |
| Agent Handling | `Agent_Handling__c` | Picklist | No | AI Only, AI + Human, Human Only |
| Resolution Status | `Resolution__c` | Picklist | No | Resolved, Unresolved, Escalated |
| Response Time (seconds) | `Response_Time__c` | Number(5,0) | No | How fast the agent responded |
| Conversation Transcript ID | `Transcript_ID__c` | Text(50) | No | Link to chat transcript |
| Department | `Department__c` | Lookup(Department__c) | No | Department involved |
| Hospital | `Hospital__c` | Lookup(Hospital__c) | No | Hospital involved |
| Feedback Timestamp | `Feedback_Timestamp__c` | Date/Time | No | When feedback was submitted |
| Follow-Up Required | `Follow_Up_Required__c` | Checkbox | No | Does this need human attention? |
| Follow-Up Notes | `Follow_Up_Notes__c` | Text Area(500) | No | Notes from follow-up |

**Picklist Values:**

**Sentiment__c:** Positive, Neutral, Negative
**Interaction_Type__c:** Booking, Cancellation, Reschedule, Inquiry, Triage, Emergency, General FAQ
**Agent_Handling__c:** AI Only, AI + Human Escalation, Human Only
**Resolution__c:** Resolved by AI, Resolved by Human, Unresolved, Escalated

### Step 2.2: Add Sentiment Fields to Account (Patient)

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Average CSAT | `Avg_CSAT__c` | Number(2,1) | Rolling average of all CSAT scores |
| Last Feedback Date | `Last_Feedback_Date__c` | Date | When they last gave feedback |
| Feedback Count | `Feedback_Count__c` | Number(4,0) | Total number of feedbacks given |
| Patient Sentiment Trend | `Sentiment_Trend__c` | Picklist | Improving, Stable, Declining |

### Step 2.3: Create CSAT Survey Flow (Post-Interaction)

Create a **Screen Flow** that can be embedded in the chat widget:

**Flow Name:** `Post_Interaction_CSAT_Survey`

```
[START]
  ↓
[Screen 1: Star Rating]
  "How was your experience with OncoAssist today?"
  ⭐ Component: Star Rating (1-5)
  ↓
[Decision: Score <= 2?]
  ├── YES → [Screen 2a: What went wrong?]
  │          Text Area: "We're sorry to hear that. 
  │          What could we have done better?"
  │          → Flag Follow_Up_Required = TRUE
  │
  └── NO → [Screen 2b: Optional comment]
           Text Area: "Any additional comments? (Optional)"
  ↓
[Create Record: Patient_Feedback__c]
  - Map all collected data
  - Auto-fill: Channel, Patient, Appointment, Department
  ↓
[Screen 3: Thank You]
  "Thank you for your feedback! Your input helps us 
   provide better care. 🙏"
  ↓
[END]
```

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Real-Time Sentiment Detection

Add to the Agent System Prompt:

```
## Real-Time Sentiment Monitoring

During every conversation, actively monitor patient sentiment through:

### Negative Sentiment Indicators:
- Frustration words: "frustrated", "annoyed", "waste of time", "useless"
- Repeated questions (patient asking the same thing twice = confusion)
- Use of caps lock or exclamation marks: "THIS IS RIDICULOUS!"
- Explicit dissatisfaction: "this isn't helping", "I want a human"
- Long wait expressions: "I've been waiting", "how long"

### Positive Sentiment Indicators:
- Gratitude: "thank you", "that's helpful", "great"
- Satisfaction: "perfect", "excellent", "exactly what I needed"
- Engagement: Asking follow-up questions, exploring more features

### Response Protocol:
- If negative sentiment detected → Acknowledge and adapt:
  "I sense this isn't meeting your expectations. Let me try a different 
  approach, or I can connect you with a team member right away."
- If positive sentiment detected → Reinforce:
  "I'm glad I could help! Is there anything else you need?"
- At the END of every conversation (after resolution), trigger the 
  CSAT survey by calling Trigger_CSAT_Survey action.
```

### Step 3.2: Agent Action — Trigger CSAT Survey

1. **Action Name:** `Trigger_CSAT_Survey`
2. **Action Type:** Flow
3. **Description:** `Present a quick satisfaction survey at the end of the conversation.`
4. **Inputs:**
   - `patient_id` (String)
   - `interaction_type` (String) — Booking, Inquiry, etc.
   - `appointment_id` (String, optional)
   - `detected_sentiment` (String) — AI's assessment: Positive/Neutral/Negative
5. **Outputs:**
   - `survey_response` (String) — Formatted survey prompt

### Step 3.3: Agent Action — Log Conversation Sentiment

1. **Action Name:** `Log_Sentiment`
2. **Action Type:** Apex Invocable
3. **Description:** `Create a feedback record based on conversation analysis.`
4. **Inputs:**
   - `patient_id` (String)
   - `csat_score` (Number) — 1-5
   - `sentiment` (String) — Positive/Neutral/Negative
   - `feedback_text` (String, optional)
   - `interaction_type` (String)
   - `channel` (String)
   - `appointment_id` (String, optional)

---

## 🔄 4. Automation / Logic

### Apex Class: Sentiment Logger & Analyzer

```apex
public class PatientSentimentEngine {
    
    @InvocableMethod(label='Log Patient Sentiment'
                     description='Create feedback record and analyze sentiment trends')
    public static List<SentimentResult> logSentiment(List<SentimentRequest> requests) {
        List<SentimentResult> results = new List<SentimentResult>();
        
        for (SentimentRequest req : requests) {
            SentimentResult result = new SentimentResult();
            
            try {
                // Create the feedback record
                Patient_Feedback__c feedback = new Patient_Feedback__c();
                feedback.Patient__c = req.patientId;
                feedback.CSAT_Score__c = req.csatScore;
                feedback.Sentiment__c = req.sentiment;
                feedback.Feedback_Text__c = req.feedbackText;
                feedback.Interaction_Type__c = req.interactionType;
                feedback.Channel__c = req.channel;
                feedback.Agent_Handling__c = 'AI Only';
                feedback.Feedback_Timestamp__c = DateTime.now();
                
                if (req.appointmentId != null && req.appointmentId != '') {
                    feedback.Appointment__c = req.appointmentId;
                    
                    // Get department and hospital from appointment
                    Appointment__c apt = [
                        SELECT Department__c, Hospital__c
                        FROM Appointment__c WHERE Id = :req.appointmentId LIMIT 1
                    ];
                    feedback.Department__c = apt.Department__c;
                    feedback.Hospital__c = apt.Hospital__c;
                }
                
                // Auto-determine resolution
                if (req.csatScore >= 4) {
                    feedback.Resolution__c = 'Resolved by AI';
                } else if (req.csatScore <= 2) {
                    feedback.Resolution__c = 'Unresolved';
                    feedback.Follow_Up_Required__c = true;
                } else {
                    feedback.Resolution__c = 'Resolved by AI';
                }
                
                insert feedback;
                
                // Update patient's rolling CSAT average
                List<AggregateResult> avgResult = [
                    SELECT AVG(CSAT_Score__c) avgScore, COUNT(Id) totalCount
                    FROM Patient_Feedback__c
                    WHERE Patient__c = :req.patientId
                ];
                
                Account patientUpdate = new Account(Id = req.patientId);
                patientUpdate.Avg_CSAT__c = (Decimal) avgResult[0].get('avgScore');
                patientUpdate.Last_Feedback_Date__c = Date.today();
                patientUpdate.Feedback_Count__c = (Integer) avgResult[0].get('totalCount');
                
                // Calculate sentiment trend
                List<Patient_Feedback__c> recentFeedbacks = [
                    SELECT CSAT_Score__c, Feedback_Timestamp__c
                    FROM Patient_Feedback__c
                    WHERE Patient__c = :req.patientId
                    ORDER BY Feedback_Timestamp__c DESC
                    LIMIT 5
                ];
                
                if (recentFeedbacks.size() >= 3) {
                    Decimal recent = 0, older = 0;
                    Integer mid = recentFeedbacks.size() / 2;
                    for (Integer i = 0; i < mid; i++) {
                        recent += recentFeedbacks[i].CSAT_Score__c;
                    }
                    for (Integer i = mid; i < recentFeedbacks.size(); i++) {
                        older += recentFeedbacks[i].CSAT_Score__c;
                    }
                    recent /= mid;
                    older /= (recentFeedbacks.size() - mid);
                    
                    if (recent > older + 0.5) patientUpdate.Sentiment_Trend__c = 'Improving';
                    else if (recent < older - 0.5) patientUpdate.Sentiment_Trend__c = 'Declining';
                    else patientUpdate.Sentiment_Trend__c = 'Stable';
                }
                
                update patientUpdate;
                
                // Build result
                result.isSuccess = true;
                result.feedbackId = feedback.Id;
                
                if (feedback.Follow_Up_Required__c) {
                    result.followUpAlert = '⚠️ Low CSAT score detected (' + req.csatScore 
                        + '/5). A care coordinator will review this feedback and follow up.';
                    
                    // Create a Task for follow-up
                    Task followUp = new Task();
                    followUp.Subject = '⚠️ Low CSAT Feedback: ' + feedback.Name;
                    followUp.Description = 'Patient gave a ' + req.csatScore 
                        + '/5 rating. Feedback: ' + req.feedbackText;
                    followUp.Priority = 'High';
                    followUp.Status = 'Not Started';
                    followUp.ActivityDate = Date.today().addDays(1);
                    followUp.WhatId = feedback.Id;
                    insert followUp;
                } else {
                    result.followUpAlert = '';
                }
                
                result.responseMessage = '🙏 Thank you for your feedback! ';
                if (req.csatScore >= 4) {
                    result.responseMessage += 'We\'re thrilled you had a great experience!';
                } else if (req.csatScore == 3) {
                    result.responseMessage += 'We appreciate your input and will work to do better.';
                } else {
                    result.responseMessage += 'We\'re sorry your experience wasn\'t ideal. ' +
                        'A member of our team will reach out to make things right.';
                }
                
            } catch (Exception e) {
                result.isSuccess = false;
                result.responseMessage = 'Thank you for your feedback.';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class SentimentRequest {
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
        
        @InvocableVariable(label='CSAT Score (1-5)' required=true)
        public Integer csatScore;
        
        @InvocableVariable(label='Sentiment')
        public String sentiment;
        
        @InvocableVariable(label='Feedback Text')
        public String feedbackText;
        
        @InvocableVariable(label='Interaction Type')
        public String interactionType;
        
        @InvocableVariable(label='Channel')
        public String channel;
        
        @InvocableVariable(label='Appointment ID')
        public String appointmentId;
    }
    
    public class SentimentResult {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Feedback Record ID')
        public String feedbackId;
        
        @InvocableVariable(label='Response Message')
        public String responseMessage;
        
        @InvocableVariable(label='Follow-Up Alert')
        public String followUpAlert;
    }
}
```

### Record-Triggered Flow: Negative Feedback Escalation

**Flow Name:** `Negative_Feedback_Escalation`
**Trigger:** When `Patient_Feedback__c` is created with `CSAT_Score__c <= 2`

```
[TRIGGER: New Feedback with Score <= 2]
  ↓
[Create Case]
  - Subject: "Patient Satisfaction Alert: {Patient.Name}"
  - Priority: High
  - Description: Include feedback text and interaction details
  - Assigned To: Patient Experience Queue
  ↓
[Send Email Alert]
  - To: Hospital Patient Relations Manager
  - Subject: "⚠️ Low CSAT Alert"
  - Body: Feedback summary with patient details
  ↓
[END]
```

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — End-of-Chat CSAT

```
🤖 ✅ Your appointment has been booked successfully!
   📋 APT-0015 with Dr. Priya Sharma on May 2 at 10:00 AM.
   
   Is there anything else I can help you with?

👤 No, that's all. Thank you!

🤖 You're welcome! 😊 Before you go, I'd love your quick 
   feedback to help us improve:

   How would you rate today's experience? (1-5 ⭐)
   
   ⭐ Poor  ⭐⭐ Fair  ⭐⭐⭐ OK  ⭐⭐⭐⭐ Good  ⭐⭐⭐⭐⭐ Excellent

👤 ⭐⭐⭐⭐⭐

🤖 🎉 Thank you so much! We're thrilled you had a great 
   experience. Your feedback helps us serve patients better.
   
   Take care, and we'll see you on May 2! 🏥
```

### CSAT Dashboard Components

Add to the Care Journey Dashboard:

1. **KPI Card:** "AI Agent CSAT Score" — rolling 30-day average (target: 4.2+)
2. **Line Chart:** "CSAT Trend Over Time" — daily/weekly averages
3. **Donut Chart:** "Sentiment Distribution" — Positive vs Neutral vs Negative
4. **Bar Chart:** "CSAT by Interaction Type" — which flows patients love/hate
5. **Table:** "Recent Negative Feedback" — for immediate follow-up

---

## 🧪 6. Testing

| Test | Input | Expected Result |
|------|-------|-----------------|
| 5-star feedback | Submit 5/5 after booking | Feedback record created, Avg_CSAT updated |
| 1-star feedback | Submit 1/5 with comment | Follow-up Task created, Case created, email alert |
| Sentiment trend | 3 good feedbacks then 2 bad | Sentiment_Trend__c = "Declining" |
| CSAT by channel | Submit feedback from different channels | Channel field correctly populated |
| Rolling average | Multiple feedbacks | Avg_CSAT__c reflects accurate rolling average |
| Survey trigger | Complete any agent interaction | CSAT survey presented before session end |

---

## 🎯 Summary

After completing Feature 15:
- ✅ `Patient_Feedback__c` custom object with 17 fields
- ✅ Real-time sentiment detection in agent conversations
- ✅ Post-interaction CSAT survey (1-5 stars + optional comment)
- ✅ Automatic rolling CSAT calculation per patient
- ✅ Sentiment trend analysis (Improving/Stable/Declining)
- ✅ Negative feedback auto-escalation (Case + Task + Email)
- ✅ NPS-ready framework for future expansion
- ✅ 5 dashboard components for CSAT analytics

**Next:** → Feature 16: Smart Waitlist & Cancellation Backfill Engine
