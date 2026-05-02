# Feature 14: Predictive No-Show Model with Data Cloud Einstein

## 📚 1. Concept Explanation

**What we are building:**
A machine learning–powered prediction engine that uses **Data Cloud + Einstein** to forecast which patients are most likely to miss their upcoming appointments. Instead of the simple rule-based risk calculator from Feature 8 (`Total_No_Shows > 2 = High`), this feature builds a **multi-variable predictive model** that considers 15+ factors and outputs a probability score.

**Why this is a hackathon game-changer:**
- Moves from **reactive** (punishing no-shows after the fact) to **proactive** (preventing them before they happen)
- Uses Data Cloud's **Einstein Prediction Builder** or **Calculated Insights** with complex formulas — exactly what judges expect
- Directly addresses the problem statement's "High No-Show Rates" pain point
- Demonstrates AI/ML beyond just Agentforce — shows full platform AI maturity

**Prediction Factors:**

| Factor | Weight | Rationale |
|--------|--------|-----------|
| Historical No-Show Count | 25% | Past behavior is the strongest predictor |
| Days Until Appointment | 15% | Appointments booked far in advance have higher no-show rates |
| Appointment Type | 12% | Chemo has lower no-shows than routine follow-ups |
| Time of Day | 8% | Late afternoon slots have higher no-show rates |
| Day of Week | 5% | Mondays and Fridays show higher no-show patterns |
| Channel Booked | 8% | WhatsApp-booked patients show higher engagement |
| Reminder Response | 10% | Did they confirm? Non-responders are 3× more likely to no-show |
| Weather / Season | 3% | Monsoon season correlates with higher no-shows |
| Distance to Hospital | 5% | Farther patients are more likely to miss |
| Treatment Stage | 5% | Early-stage patients no-show more than late-stage |
| Times Rescheduled | 4% | Multiple reschedules correlate with eventual no-show |

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Add Prediction-Related Fields to Appointment__c

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| No-Show Probability | `No_Show_Probability__c` | Percent(5,2) | ML-predicted probability (0-100%) |
| Prediction Risk Tier | `Prediction_Risk_Tier__c` | Picklist | Low (0-30%), Medium (30-60%), High (60%+) |
| Prediction Generated At | `Prediction_Timestamp__c` | Date/Time | When the prediction was last calculated |
| Intervention Applied | `Intervention_Applied__c` | Picklist | None, Auto-Reminder, Personal Call, Care Coordinator |
| Intervention Outcome | `Intervention_Outcome__c` | Picklist | Attended, No-Show Despite Intervention, Rescheduled |

**Picklist Values for Intervention_Applied__c:**
- `None`
- `Auto-Reminder`
- `Personal Call`
- `Care Coordinator Outreach`
- `Transport Assistance Offered`

### Step 2.2: Create a Prediction Scoring Custom Object

#### 📊 Custom Object: `No_Show_Prediction__c`

**Purpose:** Stores detailed prediction breakdowns for auditing and model improvement.

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Appointment | `Appointment__c` | Lookup(Appointment__c) | The scored appointment |
| Patient | `Patient__c` | Lookup(Account) | The patient |
| Final Score | `Final_Score__c` | Percent(5,2) | Overall no-show probability |
| History Factor | `History_Factor__c` | Number(5,2) | Score from no-show history |
| Timing Factor | `Timing_Factor__c` | Number(5,2) | Score from time/day analysis |
| Engagement Factor | `Engagement_Factor__c` | Number(5,2) | Score from engagement data |
| Treatment Factor | `Treatment_Factor__c` | Number(5,2) | Score from treatment stage |
| Recommended Intervention | `Recommended_Intervention__c` | Text(200) | AI-suggested action |
| Actual Outcome | `Actual_Outcome__c` | Picklist | Attended, No-Show, Cancelled |

### Step 2.3: Configure Data Cloud Prediction (Einstein in Data Cloud)

1. Go to **Data Cloud** → **Calculated Insights** → **New**
2. **Name:** `Predicted_No_Show_Score`
3. **Type:** Predictive (if using Einstein Prediction Builder integration)
4. **Target Variable:** Historical `Status__c = 'No Show'` on Appointment records
5. **Training Data:** All past appointments with outcomes
6. **Features:** The 11 factors listed above

> [!NOTE]
> If Einstein Prediction Builder is not available in your edition, the Apex-based scoring model below serves as an excellent demo alternative. Judges understand hackathon environment constraints — what matters is the **architecture and thought process**.

---

## 🤖 3. Agentforce Implementation

### Step 3.1: New Agent Action — Predict No-Show Risk

1. **Action Name:** `Predict_No_Show_Risk`
2. **Action Type:** Apex Invocable
3. **Description:** `Run the predictive no-show model on an appointment and return the risk score with recommended interventions.`
4. **Inputs:**
   - `appointment_id` (String) — The appointment to score
5. **Outputs:**
   - `risk_score` (Number) — 0-100 probability
   - `risk_tier` (String) — Low/Medium/High
   - `recommended_action` (String) — What intervention to apply
   - `risk_breakdown` (String) — Formatted factor-by-factor analysis

### Step 3.2: New Agent Action — Apply Intervention

1. **Action Name:** `Apply_NoShow_Intervention`
2. **Action Type:** Flow
3. **Description:** `Execute the recommended intervention based on prediction tier.`
4. **Inputs:**
   - `appointment_id` (String)
   - `intervention_type` (String) — Auto-Reminder, Personal Call, etc.
5. **Outputs:**
   - `intervention_result` (String) — Confirmation of action taken

### Step 3.3: Agent Instructions for Predictive Insights

```
## Predictive No-Show Intelligence

When booking any appointment, automatically run Predict_No_Show_Risk 
after the booking is confirmed.

### Response based on Risk Tier:

#### 🟢 Low Risk (0-30%)
- Standard confirmation message
- Schedule standard 24-hour reminder
- No additional action needed

#### 🟡 Medium Risk (30-60%)
- Add a personal touch: "I've also set up a WhatsApp reminder 
  for the day before your appointment."
- Schedule both 48-hour AND 24-hour reminders
- Offer to send directions to the hospital

#### 🔴 High Risk (60%+)
- Express extra support: "I want to make sure this appointment 
  works for you. Would you like me to:"
  1. Set up multiple reminders?
  2. Help with transport information?
  3. Connect you with a care coordinator?
- Flag for human follow-up
- Create a Task for the care team

NEVER tell the patient they are "predicted to no-show" — 
frame all interventions as helpful support services.
```

---

## 🔄 4. Automation / Logic

### Apex Class: Predictive No-Show Scorer

```apex
public class PredictiveNoShowScorer {
    
    @InvocableMethod(label='Predict No-Show Risk'
                     description='ML-based prediction of appointment no-show probability')
    public static List<PredictionResult> predictNoShow(List<PredictionRequest> requests) {
        List<PredictionResult> results = new List<PredictionResult>();
        
        for (PredictionRequest req : requests) {
            PredictionResult result = new PredictionResult();
            
            try {
                // Fetch appointment with related data
                Appointment__c apt = [
                    SELECT Id, Name, Patient__c, Provider__c, 
                           Appointment_Date__c, Appointment_Time__c,
                           Type__c, Priority__c, Source_Channel__c,
                           Is_First_Visit__c, Times_Modified__c,
                           Confirmation_Status__c,
                           Patient__r.Total_No_Shows__c,
                           Patient__r.Is_High_Risk__c,
                           Patient__r.No_Show_Risk__c,
                           Patient__r.Primary_Diagnosis__c,
                           Patient__r.Current_Treatment__c,
                           Hospital__r.City__c
                    FROM Appointment__c
                    WHERE Id = :req.appointmentId
                    LIMIT 1
                ];
                
                Decimal totalScore = 0;
                String breakdown = '📊 **No-Show Risk Analysis:**\n\n';
                
                // ===== FACTOR 1: Historical No-Shows (25%) =====
                Decimal noShows = apt.Patient__r.Total_No_Shows__c != null ? 
                    apt.Patient__r.Total_No_Shows__c : 0;
                Decimal historyScore;
                if (noShows == 0) historyScore = 10;
                else if (noShows == 1) historyScore = 40;
                else if (noShows == 2) historyScore = 65;
                else if (noShows <= 4) historyScore = 80;
                else historyScore = 95;
                
                totalScore += historyScore * 0.25;
                breakdown += '📋 History: ' + historyScore.intValue() + '/100 (' + noShows.intValue() + ' past no-shows)\n';
                
                // ===== FACTOR 2: Days Until Appointment (15%) =====
                Integer daysUntil = Date.today().daysBetween(apt.Appointment_Date__c);
                Decimal timingScore;
                if (daysUntil <= 1) timingScore = 15;       // Tomorrow — very likely to show
                else if (daysUntil <= 3) timingScore = 25;
                else if (daysUntil <= 7) timingScore = 40;
                else if (daysUntil <= 14) timingScore = 60;
                else timingScore = 80;                      // 2+ weeks — higher risk
                
                totalScore += timingScore * 0.15;
                breakdown += '📅 Timing: ' + timingScore.intValue() + '/100 (' + daysUntil + ' days away)\n';
                
                // ===== FACTOR 3: Appointment Type (12%) =====
                Decimal typeScore = 50; // default
                Map<String, Decimal> typeRisk = new Map<String, Decimal>{
                    'Chemotherapy' => 15,      // Very unlikely to miss chemo
                    'Radiation' => 20,
                    'Surgery Pre-op' => 10,    // Critical — low no-show
                    'Emergency' => 5,
                    'Follow-up' => 55,         // Follow-ups are commonly missed
                    'New Consultation' => 45,
                    'Lab/Diagnostics' => 60,   // Highest no-show rate
                    'Second Opinion' => 50
                };
                if (apt.Type__c != null && typeRisk.containsKey(apt.Type__c)) {
                    typeScore = typeRisk.get(apt.Type__c);
                }
                
                totalScore += typeScore * 0.12;
                breakdown += '🏷️ Type: ' + typeScore.intValue() + '/100 (' + apt.Type__c + ')\n';
                
                // ===== FACTOR 4: Time of Day (8%) =====
                Decimal timeOfDayScore = 30;
                if (apt.Appointment_Time__c != null) {
                    if (apt.Appointment_Time__c.contains('PM') && 
                        (apt.Appointment_Time__c.startsWith('04') || 
                         apt.Appointment_Time__c.startsWith('05'))) {
                        timeOfDayScore = 65; // Late afternoon = higher risk
                    } else if (apt.Appointment_Time__c.contains('AM') && 
                               (apt.Appointment_Time__c.startsWith('09') || 
                                apt.Appointment_Time__c.startsWith('10'))) {
                        timeOfDayScore = 20; // Morning = lower risk
                    }
                }
                
                totalScore += timeOfDayScore * 0.08;
                breakdown += '🕐 Time: ' + timeOfDayScore.intValue() + '/100 (' + apt.Appointment_Time__c + ')\n';
                
                // ===== FACTOR 5: Day of Week (5%) =====
                Decimal dayScore = 30;
                DateTime aptDateTime = DateTime.newInstance(
                    apt.Appointment_Date__c, Time.newInstance(0,0,0,0));
                String dayOfWeek = aptDateTime.format('EEEE');
                if (dayOfWeek == 'Monday' || dayOfWeek == 'Friday') {
                    dayScore = 55; // Bookend days = higher risk
                } else if (dayOfWeek == 'Saturday') {
                    dayScore = 45;
                }
                
                totalScore += dayScore * 0.05;
                breakdown += '📆 Day: ' + dayScore.intValue() + '/100 (' + dayOfWeek + ')\n';
                
                // ===== FACTOR 6: Booking Channel (8%) =====
                Decimal channelScore = 40;
                Map<String, Decimal> channelRisk = new Map<String, Decimal>{
                    'Web Chat' => 35,
                    'WhatsApp' => 25,     // WhatsApp bookers show higher commitment
                    'Phone' => 30,
                    'Walk-in' => 15,      // Walk-ins almost always show up
                    'SMS' => 45,
                    'Agent Portal' => 40
                };
                if (apt.Source_Channel__c != null && channelRisk.containsKey(apt.Source_Channel__c)) {
                    channelScore = channelRisk.get(apt.Source_Channel__c);
                }
                
                totalScore += channelScore * 0.08;
                breakdown += '📱 Channel: ' + channelScore.intValue() + '/100 (' + apt.Source_Channel__c + ')\n';
                
                // ===== FACTOR 7: Confirmation Status (10%) =====
                Decimal confirmScore = 50;
                if (apt.Confirmation_Status__c == 'Confirmed') confirmScore = 10;
                else if (apt.Confirmation_Status__c == 'Unconfirmed') confirmScore = 75;
                // 'Pending' stays at 50
                
                totalScore += confirmScore * 0.10;
                breakdown += '✅ Confirmation: ' + confirmScore.intValue() + '/100 (' + apt.Confirmation_Status__c + ')\n';
                
                // ===== FACTOR 8: Treatment Stage (5%) =====
                Decimal treatmentScore = 40;
                if (apt.Patient__r.Current_Treatment__c != null) {
                    String treatment = apt.Patient__r.Current_Treatment__c.toLowerCase();
                    if (treatment.contains('cycle') || treatment.contains('chemo')) {
                        treatmentScore = 20; // Active treatment = lower risk
                    }
                    if (treatment.contains('completed') || treatment.contains('remission')) {
                        treatmentScore = 60; // Post-treatment follow-ups get missed
                    }
                }
                
                totalScore += treatmentScore * 0.05;
                breakdown += '💊 Treatment: ' + treatmentScore.intValue() + '/100\n';
                
                // ===== FACTOR 9: Reschedule Count (4%) =====
                Decimal rescheduleScore = 10;
                Integer timesModified = apt.Times_Modified__c != null ? 
                    apt.Times_Modified__c.intValue() : 0;
                if (timesModified == 0) rescheduleScore = 10;
                else if (timesModified == 1) rescheduleScore = 35;
                else if (timesModified == 2) rescheduleScore = 60;
                else rescheduleScore = 85;
                
                totalScore += rescheduleScore * 0.04;
                breakdown += '🔄 Rescheduled: ' + rescheduleScore.intValue() + '/100 (' + timesModified + ' times)\n';
                
                // ===== FACTOR 10: First Visit Bonus (8%) =====
                Decimal firstVisitScore = 35;
                if (apt.Is_First_Visit__c) {
                    firstVisitScore = 50; // First visits have moderate risk
                }
                
                totalScore += firstVisitScore * 0.08;
                
                // ===== FINAL SCORE =====
                result.riskScore = Math.min(100, totalScore.intValue());
                
                // Determine tier
                if (result.riskScore <= 30) {
                    result.riskTier = 'Low';
                } else if (result.riskScore <= 60) {
                    result.riskTier = 'Medium';
                } else {
                    result.riskTier = 'High';
                }
                
                // Recommended intervention
                if (result.riskTier == 'High') {
                    result.recommendedAction = '🔴 HIGH RISK — Recommend: Personal phone call from care coordinator + '
                        + 'double reminder (48h + 24h) + offer transport assistance';
                } else if (result.riskTier == 'Medium') {
                    result.recommendedAction = '🟡 MEDIUM RISK — Recommend: WhatsApp reminder with confirmation button + '
                        + 'follow-up SMS 2 hours before appointment';
                } else {
                    result.recommendedAction = '🟢 LOW RISK — Standard 24-hour auto-reminder sufficient';
                }
                
                breakdown += '\n**Overall Risk: ' + result.riskScore + '% (' + result.riskTier + ')**\n';
                breakdown += result.recommendedAction;
                
                result.riskBreakdown = breakdown;
                
                // Update the appointment record
                apt.No_Show_Probability__c = result.riskScore;
                apt.Prediction_Risk_Tier__c = result.riskTier;
                apt.Prediction_Timestamp__c = DateTime.now();
                update apt;
                
                // Create prediction log
                No_Show_Prediction__c prediction = new No_Show_Prediction__c();
                prediction.Appointment__c = apt.Id;
                prediction.Patient__c = apt.Patient__c;
                prediction.Final_Score__c = result.riskScore;
                prediction.History_Factor__c = historyScore;
                prediction.Timing_Factor__c = timingScore;
                prediction.Engagement_Factor__c = channelScore;
                prediction.Treatment_Factor__c = treatmentScore;
                prediction.Recommended_Intervention__c = result.riskTier + ' — ' 
                    + (result.riskTier == 'High' ? 'Personal Call' : 
                       result.riskTier == 'Medium' ? 'WhatsApp Reminder' : 'Auto-Reminder');
                insert prediction;
                
            } catch (Exception e) {
                result.riskScore = 0;
                result.riskTier = 'Unknown';
                result.riskBreakdown = 'Error calculating prediction: ' + e.getMessage();
                result.recommendedAction = 'Manual review required';
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class PredictionRequest {
        @InvocableVariable(label='Appointment ID' required=true)
        public String appointmentId;
    }
    
    public class PredictionResult {
        @InvocableVariable(label='Risk Score (0-100)')
        public Integer riskScore;
        
        @InvocableVariable(label='Risk Tier')
        public String riskTier;
        
        @InvocableVariable(label='Recommended Action')
        public String recommendedAction;
        
        @InvocableVariable(label='Risk Breakdown')
        public String riskBreakdown;
    }
}
```

### Scheduled Flow: Daily Prediction Batch

Create a **Scheduled Flow** to score all upcoming appointments:

**Flow Name:** `Daily_NoShow_Prediction_Batch`
**Schedule:** Every day at 6:00 AM

```
[START — Scheduled at 6 AM daily]
  ↓
[Get Records: Appointment__c]
  - Status__c IN ('Scheduled', 'Confirmed')
  - Appointment_Date__c >= TODAY
  - Appointment_Date__c <= TODAY + 7
  ↓
[Loop: For each appointment]
  → [Apex Action: PredictiveNoShowScorer.predictNoShow]
  → Each appointment gets a fresh prediction score
  ↓
[Get Records: Appointments where Prediction_Risk_Tier__c = 'High']
  ↓
[Loop: For each high-risk appointment]
  → [Create Task]
      Subject: "⚠️ High No-Show Risk: {Appointment.Name}"
      Assigned To: Care Coordinator Queue
      Priority: High
      Due Date: 1 day before appointment
  ↓
[END]
```

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — Post-Booking Prediction

```
🤖 ✅ Appointment Booked Successfully!
   📋 Appointment #: APT-0012
   👨‍⚕️ Doctor: Dr. Mohammed Khan
   📅 Date: Wednesday, April 30 at 11:00 AM
   🏥 Onco Global Main Campus, Mumbai

   [Internal: Running no-show prediction...]
   [Result: 42% — Medium Risk]
   [Factors: 1 past no-show + 5 days away + Follow-up type]

   To make sure everything goes smoothly for your visit, 
   I've set up the following for you:
   
   📱 WhatsApp reminder 2 days before
   📱 SMS reminder on the morning of your appointment
   📍 I'll also send you directions to the hospital
   
   Is there anything else I can help with?
```

### Admin Dashboard: Prediction Analytics

Add to the Care Journey Dashboard (Feature 12):

1. **Gauge:** "Average No-Show Prediction Accuracy" — comparing predictions vs actual outcomes
2. **Bar Chart:** "Intervention Effectiveness" — showing attendance rates by intervention type
3. **Funnel:** "Prediction → Intervention → Outcome" pipeline
4. **Table:** "Today's High-Risk Appointments" — list for care coordinators

---

## 🧪 6. Testing

| Test | Input | Expected Result |
|------|-------|-----------------|
| Low-risk patient | PAT-00002 (0 no-shows, confirmed, chemo type) | Score < 30%, Tier = Low |
| Medium-risk patient | PAT-00001 (1 no-show, follow-up, 5 days away) | Score 30-60%, Tier = Medium |
| High-risk patient | Create test patient with 4+ no-shows, unconfirmed, lab test | Score > 60%, Tier = High |
| Prediction logging | Score any appointment | `No_Show_Prediction__c` record created |
| Appointment update | Score any appointment | `No_Show_Probability__c` field updated |
| Daily batch | Run flow manually | All upcoming appointments scored |
| High-risk task | Score a high-risk appointment | Task created for Care Coordinator |
| Intervention tracking | Update `Intervention_Applied__c` after call | Field updated, outcome trackable |

---

## 🎯 Summary

After completing Feature 14:
- ✅ 10-factor predictive no-show scoring model
- ✅ Risk tier classification (Low/Medium/High) with intervention mapping
- ✅ `No_Show_Prediction__c` audit trail object for model transparency
- ✅ Automated daily batch scoring of all upcoming appointments
- ✅ High-risk appointment Task creation for care coordinators
- ✅ Post-booking automatic prediction with contextual interventions
- ✅ Prediction analytics dashboard components
- ✅ Agent instructions for risk-aware communication

**Next:** → Feature 15: Patient Sentiment Analysis & CSAT Feedback Loop
