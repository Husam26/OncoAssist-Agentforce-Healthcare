# Feature 9: WhatsApp & SMS Integration

## 📚 1. Concept Explanation

**What we are building:**
Bridging the gap between Salesforce and the patient's phone. While the Web Chat is great, WhatsApp is where patients live. We'll set up the concept of **Digital Engagement** so the Agentforce Agent can talk directly over SMS/WhatsApp.

**Why it matters:**
- Higher open rates (98% for WhatsApp vs 20% for Email).
- Frictionless communication — no need to download an app.
- "Conversational Commerce" — booking a life-saving appointment should be as easy as texting a friend.

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Enable Digital Engagement

1. Go to **Setup** → **Digital Engagement** → **Settings**.
2. Toggle **Digital Engagement** to **Enabled**.

### Step 2.2: Create Messaging Channels

> [!NOTE]
> For a live hackathon demo, you usually use a "WhatsApp Sandbox" or "SMS Sandbox" if you don't have a live number.

1. **Setup** → **Messaging Settings**.
2. Click **New Channel** → Choose **WhatsApp** or **SMS**.
3. Follow the wizard to link your Facebook Business Manager (for WhatsApp) or request an SMS Number.

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Connect Agent to Messaging

1. In **Agent Builder**, go to the **Channels** tab.
2. Add your newly created WhatsApp/SMS Messaging Channel.
3. This allows the AI to "own" the phone number. When a patient texts the number, the Agentforce Agent responds.

---

## 🔄 4. Automation / Logic

### Flow: Inbound Message Router

Create a **Messaging Triggered Flow**:
- **Trigger:** When a new Message is received.
- **Action:** Route the message to your `Patient_Scheduling_Agent`.

---

## 🖥️ 5. UI / Experience Layer

**Demo Flow:**
1. Open your personal WhatsApp.
2. Text "Hi" to your demo number.
3. The Agentforce Agent replies: *"Hello! I'm OncoAssist. I see you have a pending follow-up. Would you like to schedule it?"*

---

## 🧪 6. Testing

- Send a text message "Book appointment" to the configured number.
- Verify the Agent follows the Feature 4 (Booking) logic exactly as it did in the web chat.
