<p align="center">
  <img src="https://img.shields.io/badge/Salesforce-Agentforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white" />
  <img src="https://img.shields.io/badge/Data_Cloud-Patient_Intelligence-FF6B35?style=for-the-badge&logo=salesforce&logoColor=white" />
  <img src="https://img.shields.io/badge/Groq-Vision_AI-E44332?style=for-the-badge&logo=meta&logoColor=white" />
  <img src="https://img.shields.io/badge/Apex-Invocable_Actions-1798c1?style=for-the-badge&logo=salesforce&logoColor=white" />
</p>

<h1 align="center">🏥 OncoAssist — AI-Powered 360° Patient Intelligence Hub</h1>

<p align="center">
  <strong>An Agentforce-powered clinical assistant for Onco Global Cancer Care Network</strong><br/>
  <em>19 production-grade features • 1 intelligent agent • 5 specialized topics • Real-time prescription OCR</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Features-19-brightgreen?style=flat-square" />
  <img src="https://img.shields.io/badge/Apex_Classes-15+-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/Automated_Flows-3-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/Custom_Objects-6-purple?style=flat-square" />
  <img src="https://img.shields.io/badge/AI_Models-Llama_4_Scout-red?style=flat-square" />
</p>

---

## 🌟 Overview

**OncoAssist** reimagines the patient experience in oncology care by replacing fragmented, manual workflows with a unified, AI-driven clinical assistant built entirely on the Salesforce platform.

Cancer patients navigating treatment face a complex journey — from booking the right specialist, to managing waitlists, to reconciling medications from prior hospitals. OncoAssist solves all of this through a single conversational AI interface that **thinks, predicts, and protects**.

> **This is not a chatbot that answers FAQs. OncoAssist is a clinical intelligence platform that predicts patient behavior, reads medical documents, detects dangerous drug interactions, manages institutional capacity in real-time, and wraps it all in an empathetic, human-like conversational experience.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     ONCOASSIST AGENT                            │
│                   (Salesforce Agentforce)                        │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Appointment  │  │   Doctor     │  │     Emergency        │  │
│  │  Management   │  │  Discovery   │  │     Handling         │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                      │              │
│  ┌──────┴───────┐  ┌──────┴──────────────────────┴───────────┐  │
│  │  General FAQ  │  │     Medication Reconciliation           │  │
│  │  & Follow-Up  │  │     (Groq Vision AI Integration)       │  │
│  └──────┬───────┘  └──────────────┬──────────────────────────┘  │
└─────────┼──────────────────────────┼────────────────────────────┘
          │                          │
          ▼                          ▼
┌─────────────────────┐    ┌─────────────────────┐
│   Apex Invocable    │    │   Groq API          │
│   Actions (15+)     │    │   (Llama 4 Scout)   │
│                     │    │                     │
│ • SymptomMatcher    │    │ • Vision OCR        │
│ • SlotOptimizer     │    │ • Text Extraction   │
│ • WaitlistManager   │    │ • Drug Safety       │
│ • SentimentAnalyzer │    └─────────────────────┘
│ • CaregiverAuth     │
│ • MedicationGuard   │
│ • NoShowPredictor   │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────────────────────────────────┐
│              SALESFORCE DATA LAYER               │
│                                                  │
│  Person Accounts │ Appointments │ Departments    │
│  Providers       │ Time Slots   │ Waitlists      │
│  Symptom Maps    │ Triage Logs  │ Data Cloud      │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Feature Catalogue

### 📋 Foundation & Data Architecture
| # | Feature | Technology |
|---|---------|-----------|
| 01 | Health Cloud Data Setup & Custom Object Architecture | Custom Objects, Person Accounts, Lookups |
| 02 | Conversational AI Agent Setup | Agentforce Builder, Topics, Actions |
| 03 | Intelligent Doctor Discovery | Apex Invocable, SOQL |

### 📅 Smart Scheduling Engine
| # | Feature | Technology |
|---|---------|-----------|
| 04 | AI-Powered Appointment Booking | Apex, Record Creation, Slot Matching |
| 05 | Modify & Cancel with Context Awareness | Apex, Record Updates |
| 06 | Symptom-Based Department Routing | Custom Mapping Object, Apex |
| 07 | Smart Slot Optimization | Apex, Time-Gap Analysis |

### 🛡️ Patient Safety & Automation
| # | Feature | Technology |
|---|---------|-----------|
| 08 | Predictive No-Show Reduction | Data Cloud, Historical Analytics |
| 09 | SMS Telephony Channel — Omnichannel Access | Salesforce Messaging, Telephony Integration |
| 10 | Emergency Priority Triage | Keyword Detection, Auto-Escalation |
| 11 | Multi-Language Support | Translation Framework |
| 12 | Care Journey Tracking | Clinical Summary Generator |

### 🧠 Advanced AI & Intelligence
| # | Feature | Technology |
|---|---------|-----------|
| 13 | Data Cloud 360° Patient Intelligence | Data Cloud, Unified Profiles |
| 14 | Predictive No-Show Analytics | Apex, Statistical Risk Scoring |
| 15 | Sentiment Analysis & Empathy Routing | NLP, Keyword Detection |
| 16 | Smart Waitlist with Auto-Backfill | Record-Triggered Flow, Apex |
| 17 | Caregiver Authorization Hub | Role-Based Access, Apex |
| 18 | Post-Visit Follow-Up Automation | Scheduled Flow, Apex |

### 💊 The Killer Differentiator
| # | Feature | Technology |
|---|---------|-----------|
| 19 | **AI Prescription OCR & Drug Safety Guard** | **Groq Llama 4 Scout Vision AI**, Apex HTTP Callout |

### 📱 Omnichannel Access
| # | Feature | Technology |
|---|---------|-----------|
| 20 | SMS Telephony Channel | Salesforce Messaging Channel, Reserved Phone Number, Agent Routing |

---

## 💊 Feature 19 Deep Dive — AI Prescription OCR

This is the crown jewel of OncoAssist. It demonstrates real-time, multimodal AI integration within Salesforce:

```
Patient uploads prescription image
         │
         ▼
┌─────────────────────────┐
│ Salesforce Files API    │ ← ContentVersion.VersionData
│ (Retrieves latest file) │
└────────────┬────────────┘
             │ Base64 Encode
             ▼
┌─────────────────────────┐
│ Groq Vision AI          │ ← meta-llama/llama-4-scout-17b-16e-instruct
│ "Extract medicine names │
│  from this prescription"│
└────────────┬────────────┘
             │ Comma-separated list
             ▼
┌─────────────────────────┐
│ Drug Safety Checker     │ ← Cross-references with active treatment
│ (Aspirin + Chemo = ⚠️)  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ Account.External_       │ ← Persists to patient record
│ Medications__c updated  │
│ + Alert flag set        │
└─────────────────────────┘
```

**Two modes of operation:**
- 📸 **Vision Mode:** Upload a prescription photo → AI reads the image → extracts medicine names
- ⌨️ **Text Mode:** Type or paste medicine names → AI normalizes the list → safety check

---

## 🗂️ Project Structure

```
onco_global/
├── force-app/main/default/
│   ├── classes/                    # 15+ Apex Invocable Actions
│   │   ├── AdvancedSymptomRouter.cls
│   │   ├── AppointmentBookingService.cls
│   │   ├── AppointmentCanceller.cls
│   │   ├── AppointmentCreator.cls
│   │   ├── AppointmentModifier.cls
│   │   ├── AppointmentRescheduler.cls
│   │   ├── CaregiverAuthorizer.cls
│   │   ├── ClinicalSummaryGenerator.cls
│   │   ├── DataCloudPatientProfile.cls
│   │   ├── FollowUpManager.cls
│   │   ├── MedicationSafetyGuard.cls   ★ Groq Vision AI
│   │   ├── NoShowRiskCalculator.cls
│   │   ├── PatientSentimentAnalyzer.cls
│   │   ├── PostVisitCareLogic.cls
│   │   ├── SlotAvailabilityChecker.cls
│   │   ├── SmartSlotOptimizer.cls
│   │   ├── SymptomMatcher.cls
│   │   └── WaitlistManager.cls
│   ├── flows/                      # Automated Flows
│   │   ├── Waitlist_AutoBackfill_Notification.flow
│   │   └── Appointment_PostVisit_FollowUp.flow
│   └── objects/                    # Custom Objects
│       ├── Appointment__c/
│       ├── Department__c/
│       ├── Provider__c/
│       ├── Time_Slot__c/
│       ├── Waitlist__c/
│       └── Symptom_Department_Map__c/
├── docs/                           # Feature Implementation Guides
│   ├── Guide_Feature_01_HealthCloud_DataSetup.md
│   ├── Guide_Feature_02_BasicChatAgent.md
│   ├── ...
│   └── Guide_Feature_20_MedicationReconciliation.md
└── sfdx-project.json
```

---

## ⚙️ Tech Stack

- **Salesforce Agentforce** — Conversational AI agent with multi-topic routing
- **Salesforce Data Cloud** — Unified patient profiles & predictive analytics
- **Apex** — 15+ Invocable Actions powering intelligent clinical workflows
- **Salesforce Flows** — Record-Triggered & Scheduled automation
- **Groq API** — Llama 4 Scout Vision model for real-time prescription OCR
- **Salesforce Messaging** — SMS Telephony Channel for omnichannel patient access
- **Custom Objects** — 6 purpose-built clinical data objects
- **Person Accounts** — Patient-centric data architecture

---

## 🏥 Agentforce Configuration

**Agent:** OncoAssist Agent (1 Agent, 5 Topics)

| Topic | Purpose | Key Actions |
|-------|---------|-------------|
| Appointment Management | End-to-end scheduling | Booking, Rescheduling, Cancellation, Slot Optimization |
| Doctor Discovery | Find the right specialist | Provider search by department, specialty, availability |
| Emergency Handling | Triage critical situations | Keyword detection, auto-escalation, emergency contacts |
| General FAQ | Follow-ups & general queries | Post-visit check-in, sentiment analysis, care summaries |
| Medication Reconciliation | External medicine sync | Groq Vision OCR, drug safety checks, record updates |

---

## 🧪 Demo Scenarios

### Scenario 1: Intelligent Booking
```
Patient: "I've been having severe headaches and blurred vision."
Agent:   Routes to Neurology → Shows available slots → Books appointment
```

### Scenario 2: Prescription OCR
```
Patient: "I uploaded my old prescription from Apollo Hospital."
Agent:   Reads the image via Groq AI → Extracts "Aspirin, Metformin"
         → ⚠️ "WARNING: Aspirin may conflict with your chemo treatment!"
```

### Scenario 3: Post-Visit Follow-Up
```
Patient: "Hello, I'm Anil Kumar."
Agent:   "Welcome back! I see you visited Hematology yesterday.
          How are you feeling today?"
```

### Scenario 4: Smart Waitlist
```
[Appointment cancelled] → Flow auto-triggers →
Finds next waitlisted patient → Sends notification →
"A slot just opened up in Oncology! Would you like to book it?"
```

### Scenario 5: SMS Access
```
Patient texts reserved number: "I need to book an appointment"
Agentforce receives via Messaging Channel → Routes to Appointment Management
→ Full AI-powered scheduling via SMS
```

---

## 📄 License

This project was built for the **Salesforce Agentforce Hackathon 2025**.

---

<p align="center">
  <strong>Built with ❤️ for better patient care</strong><br/>
  <em>OncoAssist — Because every patient deserves intelligent, empathetic healthcare.</em>
</p>
