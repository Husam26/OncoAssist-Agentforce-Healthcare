# Feature 20: AI-Powered Medication Reconciliation & Safety Guard

## 🎯 Overview
This feature enables patients to sync their external medications (from previous hospitals/clinics) into the Onco Global system using **Groq Vision AI**. The system can read actual prescription images uploaded to Salesforce Files, extract medicine names using AI, and perform a real-time clinical safety check for dangerous drug interactions.

**Why it's a Killer Feature:** This is the only feature in the project that integrates a **third-party AI Vision API (Groq + Llama 4 Scout)** directly into Salesforce Apex — demonstrating real-world AI/ML integration at the platform level.

---

## 🏗️ Architecture

```
Patient uploads prescription image
        ↓
Salesforce Files (ContentVersion)
        ↓
Agentforce Agent (Medication Reconciliation Topic)
        ↓
MedicationSafetyGuard.cls (Apex Invocable Action)
        ↓
    ┌───────────────────┐
    │  BRANCH A: Image  │──→ Base64 Encode → Groq Vision AI (Llama 4 Scout)
    │  BRANCH B: Text   │──→ Groq Text AI (Llama 3.1 8B)
    └───────────────────┘
        ↓
Extract Medicine Names (Comma-separated list)
        ↓
Save to Account.External_Medications__c
        ↓
Clinical Safety Check (Drug Interaction Alert)
        ↓
Response to Patient via Agentforce
```

---

## 🛠️ Components

### 1. Custom Fields (Account / Person Account)

| Field Name | API Name | Data Type | Purpose |
|---|---|---|---|
| External Medications | `External_Medications__c` | Long Text Area | Stores AI-extracted medication list |
| Medication Alert Flag | `Medication_Alert_Flag__c` | Checkbox | Flags dangerous interactions for doctors |

---

### 2. Apex Class: `MedicationSafetyGuard`

**Label:** `Groq: Extract and Sync Meds`

**What it does:**
- **Image Path:** Finds the latest file uploaded to the patient's Account → converts to Base64 → sends to Groq Vision AI → extracts medicine names
- **Text Path:** Takes raw text from chat → sends to Groq Text AI → extracts medicine names
- **Safety Check:** Scans extracted meds for known dangerous interactions (e.g., Aspirin + Chemotherapy)

**Key Constants:**
```apex
GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions'
VISION_MODEL  = 'meta-llama/llama-4-scout-17b-16e-instruct'
TEXT_MODEL    = 'llama-3.1-8b-instant'
```

**Inputs:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `patientName` | String | Yes | Full name of the patient Account |
| `rawInput` | String | No | Raw text of medications (for manual entry) |
| `processLatestFile` | Boolean | Yes | `TRUE` = scan uploaded file, `FALSE` = use rawInput text |

**Output:**

| Parameter | Type | Description |
|---|---|---|
| `safetyMessage` | String | AI result with extracted meds and any safety warnings |

---

### 3. Remote Site Setting

| Setting | Value |
|---|---|
| Name | `Groq_API` |
| URL | `https://api.groq.com` |
| Active | ✅ |

---

### 4. Agentforce Topic: `Medication Reconciliation`

**Classification Description:**
> "Use this topic when a patient wants to share medicines they are taking from another clinic, upload an old prescription, or update their medication list for safety checks."

**Scope:**
> "Your job is to assist patients in digitizing and syncing medications from external sources, such as other clinics or old prescriptions. You are responsible for extracting the medicine names accurately and performing a clinical safety check against their Onco Global treatment plan. You must proactively flag dangerous drug interactions for the doctor's review. Your scope is limited to medication data entry and safety alerts; do not provide clinical diagnoses."

**Instructions:**
```
## Medication Safety & Sync Protocol (STRICT)
- If the patient says they have UPLOADED a file, prescription, or image to their record:
  1. You MUST immediately call the 'Groq: Extract and Sync Meds' action.
  2. Set 'processLatestFile' to TRUE.
  3. Set 'patientName' to their full name.
  4. DO NOT ask them for the text if they say the file is already uploaded.
- If the patient provides the medication names directly in the chat:
  1. Call the 'Groq: Extract and Sync Meds' action.
  2. Set 'processLatestFile' to FALSE.
  3. Set 'rawInput' to the text they provided.
- ONCE THE ACTION RETURNS:
  - Read the 'safetyMessage' to the patient.
  - If there is a ⚠️ WARNING, emphasize that they should consult their doctor.
```

**Action Configuration:**

| Setting | Value |
|---|---|
| Action Instructions | Use this action when a patient provides text from a prescription or lists medicines from another clinic. |
| Loading Text | "Groq AI is digitizing and analyzing your medications..." |
| `patientName` input | The full name of the patient record to update. |
| `rawInput` input | The raw text of medications provided by the user. Leave empty if scanning a file. |
| `processLatestFile` input | Set TRUE if user uploaded a file, FALSE if they typed text. |
| `safetyMessage` output | The clinical safety result. Read this to the patient. |

---

## 🧪 Testing

### Test Case A: Image Upload (Vision AI)
1. Go to a Patient Account (e.g., Rahul Verma)
2. Click **Files** related list → **Upload** a prescription image (JPG/PNG, under 4MB)
3. Open Agentforce Chat:
   - **User:** "Hi, I'm Rahul Verma. I just uploaded my old prescription file to my record. Can you sync the medicines from it?"
   - **Expected:** Agent calls the action with `processLatestFile = True`, reads the image via Groq Vision AI, extracts medicine names, and saves them to `External_Medications__c`

### Test Case B: Manual Text Entry
1. Open Agentforce Chat:
   - **User:** "I'm taking Aspirin 500mg and some Vitamin D capsules. Please add these to my records."
   - **Expected:** Agent calls the action with `processLatestFile = False`, Groq extracts "Aspirin, Vitamin D", saves to field, and returns ⚠️ WARNING about Aspirin conflicting with Oncology treatment.

---

## ⚠️ Limitations & Notes

- **Image size limit:** Groq enforces a **4MB max** for base64-encoded images. Use compressed JPG/PNG files.
- **Apex Heap Size:** Very large images may hit Salesforce's 12MB heap limit. Keep prescription images small and clear.
- **Safety Logic:** The drug interaction checker currently flags Aspirin as a demo. In production, this would connect to a full drug interaction database (e.g., RxNorm, DrugBank).
- **API Key:** Stored as a constant in Apex for hackathon speed. In production, use **Named Credentials** for secure API key management.

---

## 🌟 Innovation Highlights (For Judges)

1. **Real AI Vision Integration:** Not a mock — actual Groq Llama 4 Scout model reading prescription images in real-time.
2. **Clinical Safety Guard:** Proactive drug interaction detection that could prevent adverse events.
3. **Dual Input Modes:** Supports both image upload (OCR) and manual text entry for flexibility.
4. **Seamless Salesforce Integration:** Uses native Files related list for uploads — no external UI needed.
5. **Enterprise-Ready Architecture:** Apex → External API → Database update → Agent response, all in one transaction.
