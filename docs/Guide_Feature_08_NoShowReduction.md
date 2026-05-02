# Feature 8: No-Show Reduction System

## 📚 1. Concept Explanation

**What we are building:**
A proactive system designed to ensure patients show up for their appointments. It includes automated reminders, a simple confirmation mechanism (Yes/No/Reschedule), and intelligent "nudges" for patients with a history of missed appointments.

**Why it matters:**
- No-shows cost healthcare providers billions annually and prevent other patients from getting care.
- AI-powered reminders are more effective than static templates.
- Automated rescheduling for cancellations keeps the hospital schedule full.

**The Workflow:**
1. **24-Hour Reminder:** Sent via SMS/WhatsApp with a "Confirm" button.
2. **2-Hour Final Nudge:** Sent to high-risk or specific procedure patients.
3. **Auto-Reschedule:** If a patient cancels, the AI immediately offers 3 new slots.
4. **Risk Scoring:** AI identifies "high-risk" no-show patients (based on past behavior) and flags them for a human call.

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Enhance Patient Account for Risk Scoring

Add these fields to the **Account** object:

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| No-Show Probability | `No_Show_Prob__c` | Percent(3,0) | AI-calculated risk of missing appointment |
| No-Show Risk Level | `No_Show_Risk__c` | Picklist | Low, Medium, High |
| Last Reminder Sent | `Last_Reminder__c` | Date/Time | Timestamp of the last outbound nudge |

### Step 2.2: Create a No-Show Trigger Flow

Create a **Scheduled Flow** that runs daily:

1. **Flow Name:** `Daily_Appointment_Reminders`
2. **Trigger:** Every day at 8:00 AM.
3. **Object:** `Appointment__c`
4. **Conditions:**
   - `Status__c` Equals `Scheduled`
   - `Appointment_Date__c` Equals `TODAY + 1` (Tomorrow)
   - `Confirmation_Status__c` Not Equal to `Confirmed`

**Flow Logic:**
- Loop through matching appointments.
- Send SMS/WhatsApp (using an Apex Action or Digital Engagement).
- Update `Reminder_Sent__c` to TRUE.
- Update `Confirmation_Status__c` to `Pending`.

---

## 🤖 3. Agentforce Implementation

### Step 3.1: New Agent Action — Confirmation Handler

1. **Action Name:** `Handle_Appointment_Confirmation`
2. **Action Type:** Apex Invocable
3. **Description:** `Processes a patient's response to a reminder (Confirm, Reschedule, Cancel).`
4. **Inputs:**
   - `appointment_id` (String)
   - `patient_response` (String) — "Yes", "No", "Later"
5. **Outputs:**
   - `confirmation_message` (String)
   - `requires_action` (Boolean)

### Step 3.2: Updated Agent Prompting

Add a new behavior for "Proactive Outreach" in the Agent Builder:

```text
## Proactive Confirmation Handling
When a patient responds to an automated reminder:
1. If "Yes/Confirm": Update appointment status to "Confirmed" and thank them.
2. If "No/Cancel": Ask for the reason, cancel, and immediately use the Smart_Slot_Optimization tool to suggest 3 new times.
3. If "Reschedule": Seamlessly transition to the Reschedule flow (Feature 5).
```

---

## 🔄 4. Automation / Logic

### Apex Class: No-Show Risk Calculator

This simple logic calculates risk based on `Total_No_Shows__c`. In a real production app, this would be a Data Cloud/Tableau CRM model.

```apex
public class NoShowRiskCalculator {

    @InvocableMethod(label='Calculate No-Show Risk' description='Calculates risk level based on patient history')
    public static void calculateRisk(List<Id> accountIds) {
        List<Account> patients = [SELECT Id, Total_No_Shows__c FROM Account WHERE Id IN :accountIds];
        for (Account p : patients) {
            if (p.Total_No_Shows__c == 0) p.No_Show_Risk__c = 'Low';
            else if (p.Total_No_Shows__c < 2) p.No_Show_Risk__c = 'Medium';
            else p.No_Show_Risk__c = 'High';
        }
        update patients;
    }
}
```

---

## 🖥️ 5. UI / Experience Layer (Demo Scenario)

**The Nudge Flow:**
1. Patient receives WhatsApp: *"Hi Rahul, you have an appointment with Dr. Sharma tomorrow at 10 AM. Will you be attending? Reply YES to confirm or NO to reschedule."*
2. Patient replies: *"NO"*
3. AI Agent (via WhatsApp): *"I understand. I've cancelled your slot. Since it's important to see Dr. Sharma for your follow-up, here are 3 available times for next week..."*

---

## 🧪 6. Testing

- **Scenario:** Run the reminder flow manually in debug mode for a "tomorrow" appointment.
- **Expected:** The `Reminder_Sent__c` field on the appointment turns checked.
- **Scenario:** Change a sample patient's `Total_No_Shows__c` to 3.
- **Expected:** The Risk Level field updates to `High`.
