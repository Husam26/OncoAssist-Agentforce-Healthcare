# Feature 12: Care Journey Tracking Dashboard

## 📚 1. Concept Explanation

**What we are building:**
The "Management View." This is a Salesforce Dashboard for the hospital administrators to see the impact of our AI agent. It tracks how many calls were deflected, appointment conversion rates, and no-show reductions.

**Why it matters:**
- Judges love "ROI" (Return on Investment). This proves your solution works at scale.
- Health Cloud's **Care Performance** relies on data visibility.

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Key Reports to Create

1. **Agent Self-Service Rate:** Count of Appointments created by `Source_Channel__c = Web Chat`.
2. **No-Show Comparison:** `Total_No_Shows__c` before vs after the system implementation.
3. **Symptom Routing Trend:** Group `Triage_Log__c` by `Matched_Department__c`.

### Step 2.2: Building the Dashboard

1. Go to **Dashboards** → **New Dashboard**.
2. Add **Components**:
   - **Gauge Chart:** "Monthly Appointments via AI Agent" (Target: 5,000).
   - **Donut Chart:** "Appointments by Department" (Shows which hospital wings are busiest).
   - **Bar Chart:** "No-Show Risk Distribution" (High vs Low risk patients).

---

## 🛠️ 3. "The Winning Slide" - Care Journey Mapping

Create a **Visual Flow** or **Lightning Component** on the Patient Account page:
- Show a timeline of: *Inquiry → AI Symptom Match → Appointment Booked → Reminder Sent → Appointment Completed.*

---

## 🧪 4. Testing

- Create 5 mock appointments via the chat.
- Refresh the Dashboard and verify the numbers increase.
