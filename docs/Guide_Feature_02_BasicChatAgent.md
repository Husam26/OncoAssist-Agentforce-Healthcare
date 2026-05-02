# Feature 2: Basic Patient Chat Agent (FAQ + Navigation)

## 📚 1. Concept Explanation

**What we are building:**
A conversational AI agent that patients can chat with on the Onco Global website. In this phase, the agent handles simple FAQs ("What are your visiting hours?") and basic navigation ("I want to book an appointment").

**Why it matters:**
- ~60% of call center calls are basic FAQs that don't need a human
- This immediately reduces call load
- It's the "front door" — every patient interaction starts here
- Sets the foundation for all advanced features (booking, routing, etc.)

**What the agent can do after this step:**
- Greet patients by name (if logged in)
- Answer FAQs about hospitals, departments, and visiting hours
- Guide patients to the right action (book, reschedule, cancel)
- Escalate to a human agent if it can't help

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Enable Agentforce / Einstein Copilot

1. Go to **Setup** → Quick Find → **"Einstein Setup"**
2. Enable **Einstein** if not already enabled
3. Go to **Setup** → Quick Find → **"Agents"** (or **"Agentforce"**)
4. If you see **"Agentforce"** or **"Agent Builder"**, you're ready
5. If not, go to **Setup** → **Einstein Copilot** → Enable it

> [!IMPORTANT]
> Agentforce requires specific licenses. In a Developer Edition with AI features enabled, you should have access. If you don't see it:
> - Check **Setup → Company Information → Feature Licenses** for "Einstein" or "Agentforce"
> - You may need to enable it via **Setup → Einstein → Einstein for Platform** → Turn On

### Step 2.2: Create the Knowledge Base for FAQs

We need FAQ articles so the agent can answer common questions.

#### Create a Knowledge Base:

1. Go to **Setup** → Quick Find → **"Knowledge Settings"**
2. Enable **Salesforce Knowledge** if not already enabled
3. Click **Enable Knowledge**
4. Select the user profile that should be a Knowledge User (e.g., System Administrator)

#### Create FAQ Articles:

1. Go to **App Launcher** → search for **"Knowledge"**
2. Click **New** to create articles

**Create these FAQ articles:**

---

**Article 1: Visiting Hours**
- **Title:** What are the visiting hours at Onco Global hospitals?
- **Body:**
```
Our visiting hours vary by hospital. Generally:
- Mumbai Main Campus (HOSP-001): Monday to Saturday, 7:00 AM – 9:00 PM
- Delhi North (HOSP-002): Monday to Saturday, 8:00 AM – 8:00 PM  
- Bangalore South (HOSP-003): Monday to Saturday, 8:00 AM – 8:00 PM

For specific hospital timings, please ask me about the hospital by name.
Visiting hours for patient wards: 10:00 AM – 12:00 PM and 4:00 PM – 6:00 PM daily.
```
- **Keywords:** visiting hours, timing, when open, hospital hours, OPD timing

---

**Article 2: How to Book an Appointment**
- **Title:** How do I book an appointment?
- **Body:**
```
You can book an appointment in several ways:
1. Chat with me right here! Just say "Book an appointment" and I'll guide you through it.
2. Call our helpline: 1800-ONCO-CARE (1800-6626-2273)
3. Visit the hospital reception desk
4. Use our WhatsApp booking: +91-XXXXXXXXXX

To book with me, I'll need:
- Your name or Patient ID
- The department or doctor you want to see
- Your preferred date and time
```
- **Keywords:** book appointment, schedule, new appointment, how to book, appointment booking

---

**Article 3: Departments Available**
- **Title:** What departments are available at Onco Global?
- **Body:**
```
Onco Global offers comprehensive cancer care through these departments:
1. Medical Oncology – Chemotherapy and medical cancer treatment
2. Radiation Oncology – Radiation therapy and radiotherapy
3. Surgical Oncology – Cancer surgeries and tumor removal
4. Hematology – Blood cancers and blood disorders
5. Diagnostics & Pathology – Lab tests, MRI, CT, PET scans
6. Palliative Care – Pain management and comfort care
7. Pediatric Oncology – Childhood cancer treatment
8. Gynecological Oncology – Women's cancer care
9. Neuro-Oncology – Brain tumors and neurological cancers
10. Supportive Care & Nutrition – Diet and nutrition support

Tell me your symptoms and I can recommend the right department!
```
- **Keywords:** departments, specialties, which department, what departments, cancer types

---

**Article 4: Insurance & Payment**
- **Title:** What insurance do you accept?
- **Body:**
```
Onco Global accepts most major insurance providers including:
- Government: Ayushman Bharat, CGHS, ECHS
- Private: Star Health, HDFC ERGO, ICICI Lombard, Bajaj Allianz, Max Bupa, New India Assurance
- Corporate: Most company group insurance policies
- International: Select international health insurance plans

We also offer:
- EMI payment options
- Financial counseling for treatment costs
- Charity care programs for eligible patients

Please bring your insurance card and policy documents for your visit.
```
- **Keywords:** insurance, payment, TPA, cashless, billing, cost, fees

---

**Article 5: Emergency Contact**
- **Title:** What should I do in an emergency?
- **Body:**
```
🚨 For medical emergencies:
1. Call our 24/7 Emergency Helpline: 1800-ONCO-911
2. Visit the nearest Onco Global Emergency Department – open 24/7
3. Call national emergency: 112

Our emergency departments are equipped for:
- Acute cancer complications
- Chemotherapy side effects (severe nausea, infections, fever)
- Post-surgery emergencies
- Severe pain crises

⚠️ If you are experiencing chest pain, difficulty breathing, high fever with low immunity, or uncontrolled bleeding, please seek emergency care immediately.
```
- **Keywords:** emergency, urgent, 911, critical, ambulance, fever, bleeding

---

**Article 6: Cancellation Policy**
- **Title:** What is the appointment cancellation policy?
- **Body:**
```
You can cancel or reschedule your appointment for free by:
- Giving us at least 24 hours notice
- Using this chat – just say "Cancel my appointment"
- Calling our helpline: 1800-ONCO-CARE

Cancellation guidelines:
- Cancellations within 24 hours: No penalty, but please consider other patients
- No-shows: Repeated no-shows may affect priority scheduling
- Chemotherapy & Surgery: Must cancel at least 48 hours in advance due to preparation requirements

To reschedule, just tell me your new preferred date and time!
```
- **Keywords:** cancel, cancellation, reschedule, change appointment, modify

---

**Publish all articles:**
1. After creating each article, click **Publish**
2. Make sure the **Channel** includes your website/community (if applicable)

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Create the Agent

1. Go to **Setup** → Quick Find → **"Agent Builder"** (or **"Agentforce"**)
2. Click **New Agent**
3. Configure:
   - **Agent Name:** `Patient Scheduling Agent`
   - **API Name:** `Patient_Scheduling_Agent`
   - **Description:** `AI-powered patient assistant for Onco Global Cancer Care Network. Handles appointment booking, doctor discovery, FAQs, and patient self-service.`
   - **Agent Type:** Select **External** or **Customer-Facing** (this is for patients, not internal staff)

> [!NOTE]
> If you see "Einstein Copilot" instead of "Agent Builder," create a new Copilot and configure it similarly. The concepts are the same; Salesforce has been renaming these features.

### Step 3.2: Configure the System Prompt (Agent Instructions)

This is the most critical part — it defines YOUR agent's personality and behavior.

In the Agent Builder, find the **Instructions / System Prompt** section and enter:

```
You are "OncoAssist," the AI-powered digital assistant for Onco Global Cancer Care Network.

## Your Identity
- Name: OncoAssist
- Role: Patient-facing AI assistant
- Tone: Warm, empathetic, professional, calm
- Organization: Onco Global Cancer Care (a network of 10+ hospitals across India)

## Core Behavioral Guidelines
1. Always be empathetic — you are speaking to cancer patients and their families
2. Never provide medical diagnoses or treatment advice
3. Always recommend consulting a doctor for medical questions
4. Be concise but thorough — patients may be anxious
5. Use simple, clear language — avoid medical jargon unless necessary
6. If you detect urgency or emergency language, immediately provide emergency contact info
7. If you cannot help, offer to connect to a human agent

## Your Capabilities
You can help patients with:
- Answering frequently asked questions (visiting hours, departments, insurance, etc.)
- Finding the right doctor or department based on symptoms
- Booking new appointments
- Rescheduling or cancelling existing appointments
- Checking appointment status
- Providing hospital information (location, hours, contact)

## What You CANNOT Do
- Provide medical diagnoses
- Prescribe medications
- Access detailed medical records beyond appointment history
- Process payments

## Greeting Behavior
- Always start by greeting the patient warmly
- If you know their name, use it: "Hello [Name], welcome back to Onco Global!"
- If you don't know them: "Hello! Welcome to Onco Global Cancer Care. I'm OncoAssist, your AI assistant. How can I help you today?"

## Emergency Detection
If the patient mentions any of these keywords, IMMEDIATELY provide emergency info:
Keywords: emergency, bleeding, can't breathe, chest pain, unconscious, severe pain, high fever with cancer, 911
Response: Provide emergency helpline (1800-ONCO-911) and advise seeking immediate medical attention.

## Language Support
- Default language: English
- If the patient writes in Hindi: Respond in Hindi
- If the patient writes in Hinglish (mixed Hindi-English): Respond in Hinglish
- Detect language from the first message and maintain consistency
```

### Step 3.3: Define Topics

Topics in Agentforce group related intents together. Create these topics:

#### Topic 1: General FAQs

1. In Agent Builder, go to **Topics** → **New Topic**
2. **Topic Name:** `General FAQs`
3. **Description:** `Handles frequently asked questions about Onco Global hospitals, visiting hours, departments, insurance, and general information.`
4. **Scope / Instructions for this topic:**
```
When a patient asks general questions about:
- Hospital information (hours, location, contact)
- Department listings
- Insurance and payment
- Cancellation policies
- General processes

Search the Knowledge base for relevant articles and present the information clearly.
Always offer to help with additional questions after answering.
```

#### Topic 2: Appointment Management

1. **Topic Name:** `Appointment Management`
2. **Description:** `Handles booking, rescheduling, cancelling, and checking status of appointments.`
3. **Scope:**
```
Handle all appointment-related requests:
- New booking: Collect patient info, department/doctor preference, date/time
- Reschedule: Find existing appointment, propose new times
- Cancel: Find existing appointment, confirm cancellation
- Status check: Look up appointment details

Always confirm details with the patient before making changes.
```

#### Topic 3: Doctor & Department Discovery

1. **Topic Name:** `Doctor Discovery`
2. **Description:** `Helps patients find the right doctor or department based on symptoms, preferences, or specific needs.`
3. **Scope:**
```
Help patients find doctors by:
- Symptom description → Match to department/doctor specialization
- Department name → List available doctors
- Doctor name → Show doctor details
- Location preference → Filter by hospital

Present doctor information including: name, specialization, experience, languages, and availability.
```

#### Topic 4: Emergency Handling

1. **Topic Name:** `Emergency Handling`
2. **Description:** `Detects emergency situations and provides immediate emergency contact information.`
3. **Scope:**
```
PRIORITY: If any message suggests a medical emergency, immediately:
1. Provide the emergency helpline: 1800-ONCO-911
2. Advise calling national emergency: 112
3. Identify the nearest Onco Global hospital with 24/7 emergency services
4. Offer to connect to a human agent immediately

Emergency indicators: severe pain, breathing difficulty, heavy bleeding, loss of consciousness, high fever during chemotherapy, seizures.
```

### Step 3.4: Create Actions

Actions are what the agent can actually DO. For this basic phase:

#### Action 1: Search Knowledge Base

1. In Agent Builder → **Actions** → **New Action**
2. **Action Name:** `Search_Knowledge_Base`
3. **Action Type:** Select **Flow** or **Knowledge Search**
4. If using Knowledge Search:
   - **Description:** `Search FAQ articles to answer patient questions`
   - **Input:** `query` (String) — The patient's question
   - **Output:** `answer` (String) — The matching article content
5. **Instructions for the agent:**
```
Use this action when the patient asks a general question about Onco Global, 
visiting hours, departments, insurance, or any topic that might be covered 
in our FAQ knowledge base. Pass the patient's question as the search query.
```

#### Action 2: Query Hospital Information

1. **Action Name:** `Get_Hospital_Info`
2. **Action Type:** **Flow** (we'll create this Flow next)
3. **Description:** `Retrieve information about a specific Onco Global hospital`
4. **Inputs:**
   - `hospital_name` (String) — Name or code of the hospital
5. **Outputs:**
   - `hospital_details` (String) — Formatted hospital information

#### Action 3: Escalate to Human Agent

1. **Action Name:** `Escalate_to_Human`
2. **Action Type:** **System Action** (Transfer to Agent/Queue)
3. **Description:** `Transfer the conversation to a human agent when the AI cannot help`
4. **Instructions:**
```
Use this action when:
- The patient explicitly asks to speak to a human
- You cannot answer the patient's question after 2 attempts
- The situation is an emergency
- The patient is frustrated or upset
Before transferring, inform the patient: "I'm connecting you with a member of our care team. Please hold on."
```

---

## 🔄 4. Automation / Logic

### Flow 1: Get Hospital Information

**Purpose:** When a patient asks about a specific hospital, this flow fetches and returns the details.

#### Create the Flow:

1. Go to **Setup** → Quick Find → **"Flows"** → **New Flow**
2. Select **Autolaunched Flow (No Trigger)**
3. Name it: `Get_Hospital_Information`

#### Flow Structure:

```
[START]
  ↓
[Input Variable: hospital_search_term (Text)]
  ↓
[Get Records: Hospital__c]
  - Filter: Hospital Name CONTAINS {hospital_search_term}
  - OR Hospital_Code__c EQUALS {hospital_search_term}
  - Store: First record → hospitalRecord
  ↓
[Decision: Was hospital found?]
  ├── YES → [Assignment: Build response string]
  │          hospitalDetails = "🏥 " + hospitalRecord.Name + 
  │          "\n📍 Address: " + hospitalRecord.Address__c +
  │          "\n🕐 Hours: " + hospitalRecord.Operating_Hours__c +
  │          "\n📞 Phone: " + hospitalRecord.Phone__c +
  │          "\n🏙️ City: " + hospitalRecord.City__c
  │            ↓
  │          [Output Variable: hospital_details (Text)]
  │            ↓
  │          [END]
  │
  └── NO → [Assignment: hospitalDetails = "I couldn't find that hospital. Our hospitals are in Mumbai, Delhi, Bangalore, Kolkata, Ahmedabad, Hyderabad, Pune, Chennai, Jaipur, and Lucknow. Which one are you looking for?"]
            ↓
           [Output Variable: hospital_details (Text)]
            ↓
           [END]
```

#### Detailed Flow Steps:

1. **Add Input Variable:**
   - Click **Manager** tab → **New Resource** → **Variable**
   - **API Name:** `hospital_search_term`
   - **Data Type:** Text
   - **Available for Input:** ✅ Yes

2. **Add Get Records Element:**
   - Drag **Get Records** onto canvas
   - **Object:** Hospital__c
   - **Filter Conditions:**
     - `Name` contains `{!hospital_search_term}`
   - **How Many Records:** Only the first record
   - **Store:** In separate variables

3. **Add Decision Element:**
   - Drag **Decision** onto canvas
   - **Outcome 1 (Hospital Found):** `{!hospitalRecord}` is not null
   - **Default Outcome:** Hospital Not Found

4. **Add Assignment (Hospital Found path):**
   - Create a text variable `hospital_details`
   - Set it to a formula combining all hospital fields

5. **Add Output Variable:**
   - Make `hospital_details` Available for Output ✅

6. **Save and Activate** the flow

---

### Flow 2: Get Department List

**Purpose:** Return all departments for a given hospital.

1. **Flow Name:** `Get_Department_List`
2. **Input:** `hospital_name` (Text)
3. **Logic:**
   - Get Records → Hospital__c (find the hospital by name)
   - Get Records → Department__c WHERE Hospital__c = {hospital ID} AND Is_Active__c = TRUE
   - Loop through departments, build a numbered list string
   - Output the list

#### Key Elements:

```
[Get Records: Hospital__c WHERE Name CONTAINS input]
  ↓
[Get Records: Department__c WHERE Hospital__c = hospital.Id AND Is_Active__c = TRUE]
  ↓
[Loop: for each department in departments]
  → Append to deptList: counter + ". " + dept.Name + " - " + dept.Description__c + "\n"
  ↓
[Output: department_list (Text)]
```

---

## 🖥️ 5. UI / Experience Layer

### Option A: Embedded Chat Widget (Recommended for Demo)

#### Set Up an Embedded Service Deployment:

1. Go to **Setup** → Quick Find → **"Embedded Service Deployments"**
2. Click **New Deployment**
3. Choose **Embedded Service**
4. Configure:
   - **Name:** `Onco_Global_Chat`
   - **API Name:** `Onco_Global_Chat`
   - **Site:** Select your Experience Site (or Visualforce page)
5. Under **Chat Settings:**
   - **Agent:** Select your `Patient Scheduling Agent`
   - **Pre-chat Form:** Enable if you want to collect patient name/ID before chat
6. **Customize the look:**
   - **Primary Color:** `#1B5E20` (Onco Global green) or `#0D47A1` (medical blue)
   - **Chat Window Title:** `OncoAssist – AI Health Assistant`
   - **Welcome Message:** `Hello! I'm OncoAssist, your Onco Global AI assistant. How can I help you today? 🏥`

#### Deploy the Chat Widget:

1. After saving, you'll get a **code snippet** (JavaScript)
2. Copy this snippet
3. Paste it into your website's HTML (or Experience Cloud site)

```html
<!-- Example snippet (your actual snippet will be different) -->
<script>
  // Salesforce Chat Widget Deployment
  // Paste the exact snippet from Setup → Embedded Service Deployments
</script>
```

### Option B: Experience Cloud Site (For a more complete demo)

1. Go to **Setup** → Quick Find → **"Digital Experiences"** → **All Sites**
2. Click **New** → Select **"Help Center"** template
3. Name it: `Onco Global Patient Portal`
4. In the **Experience Builder:**
   - Add the **Embedded Chat** component to the page
   - Customize branding (logo, colors, fonts)
   - Add pages for: Hospitals, Departments, My Appointments

### Option C: Agent Builder Preview (Quickest for testing)

1. In **Agent Builder**, there is a **Preview** pane on the right
2. You can test conversations directly here
3. This is the fastest way to test during development

---

## 🧪 6. Testing

### Test Scenario 1: Greeting

**Input:** "Hi"

**Expected Output:**
```
Hello! Welcome to Onco Global Cancer Care. I'm OncoAssist, your AI assistant. 
I can help you with:
- 📋 Booking, rescheduling, or cancelling appointments
- 🔍 Finding the right doctor or department
- 🏥 Hospital information and visiting hours
- ❓ Answering your questions

How can I help you today?
```

---

### Test Scenario 2: FAQ - Visiting Hours

**Input:** "What are your visiting hours?"

**Expected Output:**
```
Our visiting hours vary by hospital. Generally:
🏥 Mumbai Main Campus: Mon-Sat, 7:00 AM – 9:00 PM
🏥 Delhi North: Mon-Sat, 8:00 AM – 8:00 PM
🏥 Bangalore South: Mon-Sat, 8:00 AM – 8:00 PM

Patient ward visiting hours: 10:00 AM – 12:00 PM and 4:00 PM – 6:00 PM daily.

Would you like information about a specific hospital?
```

---

### Test Scenario 3: Department Inquiry

**Input:** "What departments do you have?"

**Expected Output:**
Agent should list all departments from the Knowledge article, ending with an offer to help find the right one.

---

### Test Scenario 4: Emergency Detection

**Input:** "My mother who is on chemo has very high fever and is barely breathing"

**Expected Output:**
```
🚨 This sounds like it could be a medical emergency.

PLEASE ACT IMMEDIATELY:
📞 Emergency Helpline: 1800-ONCO-911
📞 National Emergency: 112

High fever during chemotherapy can indicate a serious infection. 
Please seek immediate medical attention at the nearest emergency department.

Would you like me to connect you with our emergency care team right now?
```

---

### Test Scenario 5: Unknown Question

**Input:** "What is the meaning of life?"

**Expected Output:**
```
That's a profound question! 😊 However, I'm specialized in helping with 
Onco Global healthcare services. 

I can help you with:
- Booking appointments
- Finding the right doctor
- Hospital information
- Medical service inquiries

Is there anything related to your healthcare needs I can help with?
```

---

### Test Scenario 6: Escalation Request

**Input:** "I want to speak to a real person"

**Expected Output:**
```
Of course! I'm connecting you with a member of our care team right now. 
Please hold on for just a moment. 

While you wait, could you briefly describe what you need help with? 
This will help our team assist you faster.
```
(Agent should trigger Transfer to Human action)

---

## 🎯 Summary

After completing Feature 2, you have:
- ✅ Agentforce Agent configured with system prompt
- ✅ 4 Topics defined (FAQs, Appointments, Discovery, Emergency)
- ✅ Knowledge Base with 6+ FAQ articles
- ✅ 3 Agent Actions (Knowledge Search, Hospital Info, Escalate)
- ✅ 2 Flows (Hospital Info, Department List)
- ✅ Chat widget ready for deployment
- ✅ Agent tested with 6 scenarios

**Next:** → Feature 3: Doctor & Department Discovery System
