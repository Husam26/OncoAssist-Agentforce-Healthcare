# Feature 13: Data Cloud — 360° Patient Intelligence Hub

## 📚 1. Concept Explanation

**What we are building:**
A unified patient intelligence layer powered by **Salesforce Data Cloud** that ingests data from multiple sources — CRM records, appointment history, triage logs, channel interactions, and external HIS/EMR systems — and creates a **Unified Patient Profile** with calculated insights. This profile feeds the Agentforce Agent with real-time, hyper-personalized context for every interaction.

**Why this is the #1 Hackathon Differentiator:**
- Data Cloud is an **explicit judging criteria** for "Additional Features"
- Moves beyond basic CRM to a true **Customer Data Platform (CDP)**
- Enables **Calculated Insights** that power every other feature (predictive no-show, sentiment, engagement scoring)
- Demonstrates the full Salesforce platform vision: Health Cloud + Agentforce + Data Cloud working in harmony
- Judges at a national level will expect sophisticated data unification, not just stored records

**What the Unified Profile Unlocks:**

| Insight | Source Data | Value for Patient |
|---------|-----------|-------------------|
| Engagement Score | Channel interactions, appointment history | Proactive outreach to disengaged patients |
| Treatment Adherence Index | Appointment completions, follow-up gaps | Agent warns about missed follow-ups |
| Preferred Communication Profile | WhatsApp vs Web vs SMS usage | Agent uses the right channel automatically |
| Risk Stratification | No-show history, diagnosis, demographics | High-risk patients get priority slots |
| Lifetime Journey Map | All touchpoints across the network | Agent knows full context instantly |

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Enable Data Cloud

1. Go to **Setup** → Quick Find → **"Data Cloud Setup"**
2. Click **Enable Data Cloud**
3. Accept the terms and wait for provisioning (may take 10-15 minutes)
4. Once enabled, you'll see **Data Cloud** in the App Launcher

> [!IMPORTANT]
> Data Cloud requires a specific license. In hackathon Developer Editions with Data Cloud trial enabled, you should have access. Check **Setup → Company Information → Feature Licenses** for "Data Cloud" or "Customer Data Platform."

### Step 2.2: Create a Data Cloud Data Space

1. Go to **App Launcher** → **Data Cloud**
2. Navigate to **Data Spaces** → **New Data Space**
3. **Name:** `Onco_Global_Patient_Space`
4. **Description:** `Unified patient data space for Onco Global Cancer Care Network`

### Step 2.3: Connect CRM Data as Data Streams

We'll ingest key Salesforce objects as **Data Streams** into Data Cloud:

#### Data Stream 1: Patient Profiles

1. Go to **Data Cloud** → **Data Streams** → **New**
2. **Source:** Salesforce CRM
3. **Object:** `Account` (with Patient fields)
4. **Fields to include:**

| CRM Field | Data Cloud Mapping | Category |
|-----------|-------------------|----------|
| `Name` | Individual Name | Profile |
| `Patient_ID__c` | Party Identification | Profile |
| `Phone` | Contact Point Phone | Profile |
| `PersonEmail` | Contact Point Email | Profile |
| `Date_of_Birth__c` | Birth Date | Profile |
| `Gender__c` | Gender | Profile |
| `Primary_Diagnosis__c` | Custom: Diagnosis | Clinical |
| `Current_Treatment__c` | Custom: Treatment | Clinical |
| `Preferred_Hospital__c` | Custom: Preferred Facility | Preference |
| `Preferred_Language__c` | Custom: Language | Preference |
| `Total_No_Shows__c` | Custom: No Show Count | Behavioral |
| `Is_High_Risk__c` | Custom: Risk Flag | Clinical |
| `Insurance_Provider__c` | Custom: Insurance | Financial |

5. **Refresh Schedule:** Every 1 hour (or Real-time if available)

#### Data Stream 2: Appointment History

1. **Source:** Salesforce CRM
2. **Object:** `Appointment__c`
3. **Key Fields:**

| CRM Field | Data Cloud Mapping |
|-----------|-------------------|
| `Name` (APT-XXXX) | Engagement ID |
| `Patient__c` | Individual Reference |
| `Provider__r.Name` | Custom: Provider |
| `Department__r.Name` | Custom: Department |
| `Hospital__r.Name` | Custom: Facility |
| `Appointment_Date__c` | Engagement Timestamp |
| `Status__c` | Custom: Status |
| `Type__c` | Custom: Visit Type |
| `Source_Channel__c` | Custom: Channel |
| `No_Show_Count__c` | Custom: No Show Flag |
| `Cancellation_Reason__c` | Custom: Cancel Reason |

#### Data Stream 3: Triage Interactions

1. **Source:** Salesforce CRM
2. **Object:** `Triage_Log__c`
3. **Key Fields:**

| CRM Field | Data Cloud Mapping |
|-----------|-------------------|
| `Patient__c` | Individual Reference |
| `Symptoms_Reported__c` | Custom: Symptoms |
| `Matched_Department__c` | Custom: Routed Department |
| `Confidence_Score__c` | Custom: AI Confidence |
| `Severity_Level__c` | Custom: Severity |
| `Red_Flag_Detected__c` | Custom: Emergency Flag |
| `Channel__c` | Custom: Channel |
| `Triage_Timestamp__c` | Engagement Timestamp |

#### Data Stream 4: Channel Engagement (WhatsApp/SMS/Web)

1. **Source:** Salesforce CRM
2. **Object:** `MessagingSession` (from Digital Engagement)
3. **Key Fields:** Session start, duration, channel type, resolution status

### Step 2.4: Create Data Model Objects (DMOs) in Data Cloud

Map the ingested streams to Data Cloud's **Data Model**:

1. **Individual** → Patient profile (unified identity)
2. **Engagement** → Every appointment, triage, and channel interaction
3. **Custom: Clinical Profile** → Diagnosis, treatment, risk data

### Step 2.5: Configure Identity Resolution

This is the **magic** of Data Cloud — unifying patient records across channels:

1. Go to **Data Cloud** → **Identity Resolution** → **New Ruleset**
2. **Ruleset Name:** `Patient_Identity_Match`
3. **Match Rules:**

| Rule | Match On | Threshold |
|------|----------|-----------|
| Rule 1: Exact ID | `Patient_ID__c` | Exact Match |
| Rule 2: Email + DOB | `PersonEmail` + `Date_of_Birth__c` | Exact Match |
| Rule 3: Phone + Name | `Phone` + `Name` (fuzzy) | High Confidence |
| Rule 4: Name + DOB + Gender | All three fields | Medium Confidence |

4. **Reconciliation Rules:** Most recent record wins for mutable fields (address, phone)
5. **Run the Identity Resolution job** → This creates **Unified Individual** profiles

> [!TIP]
> Identity Resolution is a key Data Cloud differentiator. It means if a patient called from one phone, WhatsApped from another, and booked via web — Data Cloud recognizes them as the SAME patient and merges insights. Demo this explicitly to judges.

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Create Calculated Insights

Calculated Insights are powerful aggregations that run on Data Cloud data. Create these:

#### Calculated Insight 1: Patient Engagement Score

**Name:** `Patient_Engagement_Score`
**Logic:** A composite score (0-100) based on:

```sql
-- Pseudo-SQL for the Calculated Insight builder
SELECT 
  Individual.Id,
  (
    -- Appointment completion rate (40% weight)
    (COUNT(CASE WHEN Appointment.Status = 'Completed' THEN 1 END) * 1.0 / 
     NULLIF(COUNT(Appointment.Id), 0)) * 40
    +
    -- Recency of last interaction (30% weight)  
    CASE 
      WHEN DATEDIFF(day, MAX(Engagement.Timestamp), CURRENT_DATE) <= 7 THEN 30
      WHEN DATEDIFF(day, MAX(Engagement.Timestamp), CURRENT_DATE) <= 30 THEN 20
      WHEN DATEDIFF(day, MAX(Engagement.Timestamp), CURRENT_DATE) <= 90 THEN 10
      ELSE 0
    END
    +
    -- Multi-channel usage (15% weight)
    COUNT(DISTINCT Engagement.Channel) * 5   -- max 15 for 3+ channels
    +
    -- On-time arrival rate (15% weight)
    (1 - (Individual.No_Show_Count * 1.0 / NULLIF(COUNT(Appointment.Id), 0))) * 15
  ) AS engagement_score
FROM Individual
LEFT JOIN Engagement ON Individual.Id = Engagement.IndividualId
GROUP BY Individual.Id
```

**In Data Cloud UI:**
1. Go to **Data Cloud** → **Calculated Insights** → **New**
2. Name: `Patient_Engagement_Score`
3. Build using the visual builder or SQL mode
4. **Dimensions:** Individual ID
5. **Measures:** Engagement Score (0-100)
6. **Schedule:** Refresh every 6 hours

#### Calculated Insight 2: Treatment Adherence Index

**Name:** `Treatment_Adherence_Index`
**Logic:**
- Measures whether the patient keeps follow-up appointments on schedule
- Calculates gap between recommended follow-up dates and actual visit dates
- Factors in chemotherapy cycle completion rates

```sql
SELECT
  Individual.Id,
  COUNT(CASE WHEN Appointment.Status = 'Completed' AND Appointment.Type = 'Follow-up' THEN 1 END) AS completed_followups,
  COUNT(CASE WHEN Appointment.Type = 'Follow-up' THEN 1 END) AS total_followups,
  ROUND(
    COUNT(CASE WHEN Appointment.Status = 'Completed' AND Appointment.Type = 'Follow-up' THEN 1 END) * 100.0 /
    NULLIF(COUNT(CASE WHEN Appointment.Type = 'Follow-up' THEN 1 END), 0),
    0
  ) AS adherence_index
FROM Individual
LEFT JOIN Engagement AS Appointment ON Individual.Id = Appointment.IndividualId
GROUP BY Individual.Id
```

#### Calculated Insight 3: Channel Preference Profile

**Name:** `Channel_Preference_Profile`
**Logic:**
- Tracks which channels the patient uses most
- Identifies optimal outreach channel
- Feeds into the agent's communication strategy

```sql
SELECT
  Individual.Id,
  MODE(Engagement.Channel) AS preferred_channel,
  COUNT(CASE WHEN Engagement.Channel = 'WhatsApp' THEN 1 END) AS whatsapp_count,
  COUNT(CASE WHEN Engagement.Channel = 'Web Chat' THEN 1 END) AS webchat_count,
  COUNT(CASE WHEN Engagement.Channel = 'SMS' THEN 1 END) AS sms_count,
  COUNT(CASE WHEN Engagement.Channel = 'Phone' THEN 1 END) AS phone_count
FROM Individual
LEFT JOIN Engagement ON Individual.Id = Engagement.IndividualId
GROUP BY Individual.Id
```

### Step 3.2: Surface Data Cloud Insights in Agentforce

#### New Agent Action: Get Patient 360 Profile

1. **Action Name:** `Get_Patient_360_Profile`
2. **Action Type:** Apex Invocable (queries Data Cloud via Connect API)
3. **Description:** `Retrieve the unified 360° patient profile from Data Cloud including engagement score, treatment adherence, channel preference, and risk indicators.`
4. **Inputs:**
   - `patient_id` (String) — Patient ID or Salesforce Record ID
5. **Outputs:**
   - `profile_summary` (String) — Formatted patient intelligence brief
   - `engagement_score` (Number) — 0-100
   - `risk_level` (String) — Low/Medium/High
   - `preferred_channel` (String) — Best channel to reach patient
   - `adherence_alert` (String) — Any treatment adherence concerns

### Step 3.3: Update Agent System Prompt for Data Cloud Context

Add to the agent's system instructions:

```
## Data Cloud Personalization Protocol

Before ANY patient interaction that involves identifying a patient, call 
Get_Patient_360_Profile to load their unified profile.

### How to use the 360° Profile:

1. **Engagement Score:**
   - 80-100 (Highly Engaged): Standard greeting, efficient service
   - 50-79 (Moderately Engaged): Extra warmth, ask about their experience
   - 0-49 (Disengaged): Proactive care — "We noticed it's been a while 
     since your last visit. Your health is important to us."

2. **Treatment Adherence:**
   - If adherence < 70%: Gently remind about the importance of follow-ups
   - If missed chemo cycles: Flag as high priority, suggest immediate booking

3. **Channel Preference:**
   - If patient's preferred channel is WhatsApp but they're on Web Chat:
     "Would you also like me to send appointment details to your WhatsApp?"

4. **Risk Level:**
   - High Risk: Prioritize earlier slots, offer care coordinator connection
   - Medium Risk: Standard with gentle nudges
   - Low Risk: Standard service

NEVER share the raw scores with the patient. Use them internally to 
personalize your tone, urgency, and recommendations.
```

---

## 🔄 4. Automation / Logic

### Apex Class: Data Cloud Patient Profile Fetcher

```apex
public class DataCloudPatientProfile {
    
    @InvocableMethod(label='Get Patient 360 Profile' 
                     description='Fetch unified patient profile from Data Cloud calculated insights')
    public static List<ProfileResult> getProfile(List<ProfileRequest> requests) {
        List<ProfileResult> results = new List<ProfileResult>();
        
        for (ProfileRequest req : requests) {
            ProfileResult result = new ProfileResult();
            
            try {
                // Step 1: Fetch core patient data from CRM
                List<Account> patients = [
                    SELECT Id, Name, Patient_ID__c, Phone, PersonEmail,
                           Date_of_Birth__c, Gender__c, Primary_Diagnosis__c,
                           Current_Treatment__c, Preferred_Hospital__r.Name,
                           Preferred_Language__c, Total_No_Shows__c,
                           Is_High_Risk__c, Insurance_Provider__c,
                           No_Show_Risk__c, No_Show_Prob__c,
                           Preferred_Time__c
                    FROM Account
                    WHERE Id = :req.patientId
                    OR Patient_ID__c = :req.patientId
                    LIMIT 1
                ];
                
                if (patients.isEmpty()) {
                    result.profileSummary = 'Patient profile not found.';
                    result.engagementScore = 0;
                    results.add(result);
                    continue;
                }
                
                Account patient = patients[0];
                
                // Step 2: Calculate engagement metrics from appointment history
                List<AggregateResult> aptStats = [
                    SELECT 
                        COUNT(Id) totalApts,
                        SUM(CASE WHEN Status__c = 'Completed' THEN 1 ELSE 0 END) completedApts,
                        SUM(CASE WHEN Status__c = 'No Show' THEN 1 ELSE 0 END) noShowApts,
                        SUM(CASE WHEN Status__c = 'Cancelled' THEN 1 ELSE 0 END) cancelledApts,
                        SUM(CASE WHEN Type__c = 'Follow-up' AND Status__c = 'Completed' THEN 1 ELSE 0 END) completedFollowups,
                        SUM(CASE WHEN Type__c = 'Follow-up' THEN 1 ELSE 0 END) totalFollowups,
                        MAX(Appointment_Date__c) lastVisit,
                        COUNT_DISTINCT(Source_Channel__c) channelCount
                    FROM Appointment__c
                    WHERE Patient__c = :patient.Id
                ];
                
                Integer totalApts = (Integer) aptStats[0].get('totalApts');
                Integer completedApts = aptStats[0].get('completedApts') != null ? 
                    (Integer) aptStats[0].get('completedApts') : 0;
                Integer noShows = aptStats[0].get('noShowApts') != null ? 
                    (Integer) aptStats[0].get('noShowApts') : 0;
                Integer totalFollowups = aptStats[0].get('totalFollowups') != null ? 
                    (Integer) aptStats[0].get('totalFollowups') : 0;
                Integer completedFollowups = aptStats[0].get('completedFollowups') != null ? 
                    (Integer) aptStats[0].get('completedFollowups') : 0;
                Integer channelCount = (Integer) aptStats[0].get('channelCount');
                Date lastVisit = (Date) aptStats[0].get('lastVisit');
                
                // Step 3: Calculate Engagement Score (0-100)
                Decimal engScore = 0;
                
                // Completion rate (40%)
                if (totalApts > 0) {
                    engScore += (Decimal.valueOf(completedApts) / totalApts) * 40;
                }
                
                // Recency (30%)
                if (lastVisit != null) {
                    Integer daysSince = lastVisit.daysBetween(Date.today());
                    if (daysSince <= 7) engScore += 30;
                    else if (daysSince <= 30) engScore += 20;
                    else if (daysSince <= 90) engScore += 10;
                }
                
                // Multi-channel (15%)
                engScore += Math.min(15, channelCount * 5);
                
                // On-time rate (15%)
                if (totalApts > 0) {
                    engScore += (1 - (Decimal.valueOf(noShows) / totalApts)) * 15;
                }
                
                result.engagementScore = engScore.intValue();
                
                // Step 4: Calculate Treatment Adherence
                Decimal adherenceIndex = 100;
                String adherenceAlert = '';
                if (totalFollowups > 0) {
                    adherenceIndex = (Decimal.valueOf(completedFollowups) / totalFollowups) * 100;
                    if (adherenceIndex < 70) {
                        adherenceAlert = '⚠️ Treatment adherence is low (' + adherenceIndex.intValue() 
                            + '%). Patient has missed ' + (totalFollowups - completedFollowups) 
                            + ' follow-up appointments.';
                    }
                }
                result.adherenceAlert = adherenceAlert;
                
                // Step 5: Determine channel preference
                List<AggregateResult> channelStats = [
                    SELECT Source_Channel__c channel, COUNT(Id) cnt
                    FROM Appointment__c
                    WHERE Patient__c = :patient.Id
                    AND Source_Channel__c != null
                    GROUP BY Source_Channel__c
                    ORDER BY COUNT(Id) DESC
                    LIMIT 1
                ];
                result.preferredChannel = !channelStats.isEmpty() ? 
                    (String) channelStats[0].get('channel') : 'Web Chat';
                
                // Step 6: Risk assessment
                if (patient.Is_High_Risk__c || noShows >= 3 || engScore < 30) {
                    result.riskLevel = 'High';
                } else if (noShows >= 1 || engScore < 60) {
                    result.riskLevel = 'Medium';
                } else {
                    result.riskLevel = 'Low';
                }
                
                // Step 7: Build the 360° summary
                String profile = '📊 **Patient 360° Intelligence Brief**\n\n';
                profile += '👤 ' + patient.Name + ' (' + patient.Patient_ID__c + ')\n';
                profile += '🩺 Diagnosis: ' + (patient.Primary_Diagnosis__c != null ? patient.Primary_Diagnosis__c : 'Not specified') + '\n';
                profile += '💊 Treatment: ' + (patient.Current_Treatment__c != null ? patient.Current_Treatment__c : 'Not specified') + '\n\n';
                
                profile += '📈 **Engagement Score:** ' + result.engagementScore + '/100';
                if (result.engagementScore >= 80) profile += ' 🟢 Highly Engaged\n';
                else if (result.engagementScore >= 50) profile += ' 🟡 Moderate\n';
                else profile += ' 🔴 Disengaged — needs proactive outreach\n';
                
                profile += '🔄 **Treatment Adherence:** ' + adherenceIndex.intValue() + '%';
                if (adherenceIndex >= 80) profile += ' ✅\n';
                else profile += ' ⚠️ Needs attention\n';
                
                profile += '📱 **Preferred Channel:** ' + result.preferredChannel + '\n';
                profile += '⚡ **Risk Level:** ' + result.riskLevel + '\n';
                profile += '📅 **Total Visits:** ' + totalApts + ' (Completed: ' + completedApts + ')\n';
                profile += '📅 **Last Visit:** ' + (lastVisit != null ? lastVisit.format() : 'Never') + '\n';
                
                if (String.isNotBlank(adherenceAlert)) {
                    profile += '\n' + adherenceAlert;
                }
                
                // Upcoming appointments
                List<Appointment__c> upcoming = [
                    SELECT Name, Appointment_Date__c, Appointment_Time__c, 
                           Provider__r.Name, Department__r.Name
                    FROM Appointment__c
                    WHERE Patient__c = :patient.Id
                    AND Appointment_Date__c >= TODAY
                    AND Status__c IN ('Scheduled', 'Confirmed')
                    ORDER BY Appointment_Date__c ASC
                    LIMIT 3
                ];
                
                if (!upcoming.isEmpty()) {
                    profile += '\n📋 **Upcoming Appointments:**\n';
                    for (Appointment__c apt : upcoming) {
                        profile += '  • ' + apt.Name + ': ' + apt.Appointment_Date__c.format() 
                            + ' at ' + apt.Appointment_Time__c + ' with ' + apt.Provider__r.Name + '\n';
                    }
                }
                
                result.profileSummary = profile;
                
            } catch (Exception e) {
                result.profileSummary = 'Error fetching patient profile: ' + e.getMessage();
                result.engagementScore = 0;
                result.riskLevel = 'Unknown';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class ProfileRequest {
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
    }
    
    public class ProfileResult {
        @InvocableVariable(label='Profile Summary')
        public String profileSummary;
        
        @InvocableVariable(label='Engagement Score')
        public Integer engagementScore;
        
        @InvocableVariable(label='Risk Level')
        public String riskLevel;
        
        @InvocableVariable(label='Preferred Channel')
        public String preferredChannel;
        
        @InvocableVariable(label='Adherence Alert')
        public String adherenceAlert;
    }
}
```

### Data Cloud → CRM Writeback (Activation)

Create a **Data Cloud Activation** to push calculated insights back to CRM:

1. Go to **Data Cloud** → **Activations** → **New**
2. **Target:** Salesforce CRM (Account object)
3. **Mapping:**

| Data Cloud Insight | CRM Field |
|-------------------|-----------|
| Engagement Score | `Engagement_Score__c` (new field on Account) |
| Treatment Adherence | `Treatment_Adherence__c` (new field) |
| Preferred Channel | `Preferred_Channel__c` (new field) |
| Risk Stratification | `No_Show_Risk__c` |

4. **Schedule:** Every 6 hours

> [!TIP]
> This writeback is what makes Data Cloud powerful — insights computed in Data Cloud flow back into CRM fields that the Agentforce Agent can query in real-time without needing to call Data Cloud APIs directly.

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — Data Cloud-Powered Personalization

```
👤 Hi, this is Rahul Verma

🤖 Welcome back, Rahul! 😊
   
   [Internal: 360° Profile loaded]
   [Engagement: 72/100 — Moderate]
   [Adherence: 85% — Good]
   [Risk: Medium]
   [Preferred Channel: WhatsApp]
   
   I see you have a follow-up with Dr. Sunita Reddy coming up 
   on Thursday. Is everything on track for that visit?

👤 Actually, I wanted to check on my treatment schedule

🤖 Of course! Based on your records, you're currently on 
   Chemotherapy Cycle 3 for lung cancer treatment at our 
   Delhi center.
   
   📋 Your upcoming appointments:
   • APT-0006: Thursday at 02:00 PM — Dr. Sunita Reddy 
     (Medical Oncology)
   
   Your treatment adherence has been good at 85% — that's 
   great, Rahul! Consistent follow-ups are really important 
   for your treatment plan.
   
   Would you like me to also send these details to your 
   WhatsApp for easy reference? 📱

👤 Yes please, that would be helpful

🤖 Done! I've sent the appointment summary to your WhatsApp.
   
   Is there anything else I can help you with today?
```

### Data Cloud Dashboard Components

Add these to the Feature 12 dashboard:

1. **Engagement Score Distribution** — Pie chart showing patient engagement tiers
2. **Channel Usage Trends** — Line chart showing Web vs WhatsApp vs SMS over time
3. **Treatment Adherence Heatmap** — By department, showing which specialties have adherence gaps
4. **Unified Profile Count** — KPI showing how many profiles Data Cloud has deduplicated

---

## 🧪 6. Testing

| Test | How to Verify | Expected Result |
|------|--------------|-----------------|
| Data Streams active | Data Cloud → Data Streams → Check status | All 4 streams showing "Active" with recent sync |
| Identity Resolution | Data Cloud → Unified Individuals | Patient records merged correctly (e.g., phone + email = same person) |
| Engagement Score | Query Patient 360 for PAT-00001 | Score between 0-100 based on appointment history |
| Adherence Alert | Patient with missed follow-ups | Alert message generated with % and missed count |
| Channel Preference | Patient who mostly uses Web Chat | Preferred channel = "Web Chat" |
| Risk Level | Patient with 3+ no-shows | Risk = "High" |
| CRM Writeback | Check Account record fields | `Engagement_Score__c` populated from Data Cloud |
| Agent Personalization | Chat as a disengaged patient | Agent tone shifts to proactive care outreach |

---

## 🎯 Summary

After completing Feature 13, you have:
- ✅ Data Cloud enabled with dedicated Data Space
- ✅ 4 Data Streams ingesting CRM data (Patients, Appointments, Triage, Channel)
- ✅ Identity Resolution ruleset merging multi-channel patient records
- ✅ 3 Calculated Insights (Engagement Score, Treatment Adherence, Channel Preference)
- ✅ Apex class fetching unified 360° profiles for the Agent
- ✅ CRM Writeback activation pushing insights back to Account records
- ✅ Agent personalization protocol using Data Cloud insights
- ✅ Dashboard components visualizing Data Cloud analytics

**Next:** → Feature 14: Predictive No-Show Model with Data Cloud
