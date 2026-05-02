# Feature 10: Emergency Priority Handling

## 📚 1. Concept Explanation

**What we are building:**
A "Fast Track" system within the AI agent. If a patient mentions high-risk symptoms (e.g., "severe bleeding", "difficulty breathing"), the AI stops its normal scheduling flow and triggers an emergency protocol.

**Why it matters:**
- In oncology, timing is everything. A delay in an emergency can be fatal.
- Automated escalation ensures the clinical team is alerted immediately.
- It proves the AI is "Responsible" and "Safe" — a critical point for judges.

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Emergency Queue

1. **Setup** → **Queues** → **New**.
2. **Label:** `Emergency Care Team`.
3. **Supported Objects:** `Case`, `Appointment__c`.

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Instruction Update (The "Guardrail")

In the **System Prompt**, add:
```text
CRITICAL: If a patient mentions "Emergency", "Sharp Pain", "Bleeding", or "Seizure", DO NOT collect booking info. 
Use the 'Escalate_Emergency' action immediately.
```

### Step 3.2: Action — Escalate Emergency

1. **Name:** `Escalate_Emergency`
2. **Type:** Flow.
3. **Action:** Creates a high-priority **Case** in Salesforce and alerts the **Emergency Care Team** queue.

---

## 🔄 4. Automation / Logic

### Flow: Emergency Escalation

1. **Trigger:** Action called by Agent.
2. **Action 1:** Create **Case** record (Priority = Urgent, Subject = "AI Triage Emergency").
3. **Action 2:** Send a **Slack/Notification** to the medical staff.
4. **Action 3:** Output to Agent: *"I have alerted our emergency team. Please keep this line open or call 1800-ONCO-911 now."*

---

## 🖥️ 5. UI / Experience Layer

**Demo:**
- User: *"I'm having sudden sharp chest pain during my chemo wait."*
- Agent: *"🚨 This is an emergency. I've alerted our clinical team. They are reviewing your chart now. Please proceed to the nearest nurse station or call 1800-ONCO-911."*

---

## 🧪 6. Testing

- Type "I can't breathe" into the chat.
- Verify that a `Case` is created in Salesforce with `Priority = Urgent`.
