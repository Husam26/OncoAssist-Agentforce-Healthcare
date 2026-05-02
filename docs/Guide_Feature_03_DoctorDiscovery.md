# Feature 3: Doctor & Department Discovery System

## 📚 1. Concept Explanation

**What we are building:**
An intelligent system where patients describe what they need — either by symptoms, department name, or doctor preference — and the AI recommends the right doctor(s) with availability info.

**Why it matters:**
- Patients often don't know which department handles their condition
- Cancer care is specialized — sending a patient to the wrong department wastes time
- Judges love intelligent routing — this is where AI shows its value
- Reduces call-center load by ~30% (agent-handled discovery calls)

**User Experience:**
```
Patient: "I've been having severe headaches and blurred vision"
Agent:   "Based on your symptoms, I recommend consulting our Neuro-Oncology 
          department. Dr. Vikram Singh at HOSP-002 (Delhi) specializes in 
          brain tumors and neurological conditions. He has 25 years of 
          experience. Would you like to book an appointment with him?"
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Ensure Symptom Keywords Are Populated

Go to each Provider record and make sure the **Symptom_Keywords__c** field is populated. This is critical for matching.

**Quick reference of what we loaded in Feature 1:**

| Doctor | Symptom Keywords |
|--------|-----------------|
| Dr. Priya Sharma | breast cancer, chemotherapy, breast lump, tumor, HER2, hormone therapy |
| Dr. Rajesh Patel | radiation, radiotherapy, prostate cancer, head neck cancer |
| Dr. Ananya Krishnan | surgery, tumor removal, mastectomy, biopsy, lump removal |
| Dr. Mohammed Khan | blood cancer, leukemia, lymphoma, anemia, low platelet |
| Dr. Sunita Reddy | lung cancer, cough, breathing difficulty, chest pain, smoking |
| Dr. Vikram Singh | brain tumor, headache, seizure, vision problem, glioblastoma |
| Dr. Meera Nair | cervical cancer, ovarian cancer, irregular bleeding, pelvic pain |
| Dr. Arjun Mehta | childhood cancer, child tumor, neuroblastoma, kid cancer |
| Dr. Kavitha Iyer | pain, pain management, palliative, end of life, comfort |
| Dr. Amit Joshi | blood test, scan, MRI, CT, PET scan, biopsy report, lab |

### Step 2.2: Ensure Department Specialty Tags Are Populated

Similarly, verify **Specialty_Tags__c** on each `Department__c` record.

### Step 2.3: Add a Custom Object for Symptom Mapping (Optional but Powerful)

#### 🗂️ Custom Object: `Symptom_Department_Map__c`

**Purpose:** A dedicated mapping table that explicitly connects symptoms → departments. This is more structured than keyword matching and impresses judges.

**Create the object:**
- **Label:** `Symptom Department Map`
- **Plural Label:** `Symptom Department Maps`
- **Record Name:** `Mapping Name` (Text)

**Fields:**

| Field Label | API Name | Data Type | Required | Description |
|------------|----------|-----------|----------|-------------|
| Symptom | `Symptom__c` | Text(200) | ✅ Yes | e.g., "headache" |
| Department | `Department__c` | Lookup(Department__c) | ✅ Yes | Recommended department |
| Priority Provider | `Priority_Provider__c` | Lookup(Provider__c) | No | Best doctor for this symptom |
| Confidence Level | `Confidence_Level__c` | Picklist | No | High, Medium, Low |
| Severity Indicator | `Severity_Indicator__c` | Picklist | No | Routine, Moderate, Urgent, Emergency |
| Notes | `Notes__c` | Text Area(500) | No | Additional context for the agent |

**Sample Mappings:**

| Symptom | Department | Priority Provider | Confidence | Severity |
|---------|-----------|-------------------|------------|----------|
| headache | Neuro-Oncology | Dr. Vikram Singh | High | Moderate |
| breast lump | Medical Oncology | Dr. Priya Sharma | High | Urgent |
| blood in urine | Surgical Oncology | Dr. Ananya Krishnan | Medium | Urgent |
| persistent cough | Medical Oncology | Dr. Sunita Reddy | Medium | Moderate |
| chest pain | Medical Oncology | Dr. Sunita Reddy | Medium | Urgent |
| irregular bleeding | Gynecological Oncology | Dr. Meera Nair | High | Moderate |
| seizures | Neuro-Oncology | Dr. Vikram Singh | High | Emergency |
| fatigue and weight loss | Medical Oncology | Dr. Priya Sharma | Medium | Moderate |
| swollen lymph nodes | Hematology | Dr. Mohammed Khan | High | Moderate |
| child with unusual lump | Pediatric Oncology | Dr. Arjun Mehta | High | Urgent |
| need blood test | Diagnostics & Pathology | Dr. Amit Joshi | High | Routine |
| pain management | Palliative Care | Dr. Kavitha Iyer | High | Moderate |
| difficulty swallowing | Surgical Oncology | Dr. Ananya Krishnan | Medium | Moderate |
| vision problems | Neuro-Oncology | Dr. Vikram Singh | Medium | Moderate |
| low blood count | Hematology | Dr. Mohammed Khan | High | Moderate |

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Add New Actions to the Agent

Go back to your **Patient Scheduling Agent** in Agent Builder and add these new actions:

#### Action: Find Doctor by Symptoms

1. **Action Name:** `Find_Doctor_By_Symptoms`
2. **Action Type:** Flow (we'll create this flow)
3. **Description:** `Analyze patient symptoms and recommend the most appropriate doctor and department.`
4. **Inputs:**
   - `patient_symptoms` (String) — Description of symptoms from the patient
5. **Outputs:**
   - `recommendation` (String) — Formatted doctor/department recommendation
6. **Instructions for Agent:**
```
Use this action when the patient describes symptoms, health concerns, 
or asks "which doctor should I see?" or "what department handles X?"

Extract the key symptoms from the patient's message and pass them 
as the input. For example, if the patient says "I have headaches and 
blurred vision," the input should be "headache blurred vision."

After receiving the recommendation, present it empathetically and 
ask if they'd like to book an appointment with the recommended doctor.
```

#### Action: List Doctors by Department

1. **Action Name:** `List_Doctors_By_Department`
2. **Action Type:** Flow
3. **Description:** `List all available doctors in a specific department.`
4. **Inputs:**
   - `department_name` (String)
   - `hospital_name` (String, optional)
5. **Outputs:**
   - `doctor_list` (String) — Formatted list of doctors with details

#### Action: Get Doctor Details

1. **Action Name:** `Get_Doctor_Details`
2. **Action Type:** Flow
3. **Description:** `Get detailed information about a specific doctor.`
4. **Inputs:**
   - `doctor_name` (String)
5. **Outputs:**
   - `doctor_info` (String) — Formatted doctor profile

### Step 3.2: Update the "Doctor Discovery" Topic

Go to your **Doctor Discovery** topic and update the instructions:

```
## Doctor & Department Discovery

Help patients find the right medical care through multiple pathways:

### Pathway 1: Symptom-based Search
When the patient describes symptoms:
1. Use the Find_Doctor_By_Symptoms action
2. Present the recommended department and doctor
3. Include: doctor name, specialization, experience, hospital
4. Ask if they'd like to book an appointment

### Pathway 2: Department-based Search
When the patient asks about a specific department:
1. Use the List_Doctors_By_Department action
2. Present available doctors in that department
3. Include: name, specialization, experience, consultation fee
4. Ask which doctor they'd prefer

### Pathway 3: Doctor-specific Search
When the patient asks about a specific doctor:
1. Use the Get_Doctor_Details action
2. Show the doctor's complete profile
3. Mention their availability and consultation fee
4. Offer to book an appointment

### Guidelines
- If symptoms suggest multiple departments, present all options ranked by relevance
- Always mention the doctor's experience and specialization
- If the patient is unsure, ask clarifying questions about their symptoms
- For urgent symptoms, flag the Priority level and suggest earlier appointments
- Never diagnose — always frame as "based on your description, I recommend consulting..."
```

---

## 🔄 4. Automation / Logic

### Flow: Find Doctor By Symptoms

**Flow Name:** `Find_Doctor_By_Symptoms`  
**Type:** Autolaunched Flow (No Trigger)

#### Flow Design:

```
[START]
  ↓
[Input: patient_symptoms (Text)]
  ↓
[STRATEGY 1: Exact Symptom Map Lookup]
[Get Records: Symptom_Department_Map__c]
  - Filter: Symptom__c is in patient_symptoms (text matching)
  - Sort by: Confidence_Level__c DESC
  - Store all matching records
  ↓
[Decision: Any mappings found?]
  ├── YES → [Build recommendation from mapping]
  │          - Get Department details
  │          - Get Provider details
  │          - Format recommendation
  │          → [Output: recommendation]
  │
  └── NO → [STRATEGY 2: Keyword Search on Providers]
           [Get Records: Provider__c]
           - Filter: Symptom_Keywords__c CONTAINS any word from patient_symptoms
           - AND Is_Active__c = TRUE
           - Sort by: Experience_Years__c DESC
           - Store first matching records
             ↓
           [Decision: Any providers found?]
             ├── YES → [Build recommendation from provider match]
             │          → [Output: recommendation]
             │
             └── NO → [Default recommendation]
                      "I wasn't able to match your symptoms to a specific 
                       department. For your safety, I recommend a General 
                       Oncology consultation. Would you like me to help 
                       you book an appointment, or connect you with 
                       our care navigation team?"
                      → [Output: recommendation]
```

#### Detailed Flow Implementation:

**Step 1: Create Input Variable**
- **API Name:** `patient_symptoms`
- **Data Type:** Text
- **Available for Input:** ✅

**Step 2: Create SOQL-like Get Records**

For the `Symptom_Department_Map__c` lookup, you need to break the patient's symptom text into individual words and search. Since Flow doesn't support complex text parsing natively, use this approach:

**Option A (Simple — works for demo):**
- Use a **Get Records** element
- Filter: `Symptom__c` contains `{!patient_symptoms}`
- This does a loose text match

**Option B (Better — use an Apex Action):**
Create an Apex class that does smarter matching:

```apex
public class SymptomMatcher {
    
    @InvocableMethod(label='Match Symptoms to Doctor' 
                     description='Analyzes symptoms and returns doctor recommendations')
    public static List<MatchResult> matchSymptoms(List<MatchRequest> requests) {
        List<MatchResult> results = new List<MatchResult>();
        
        for (MatchRequest req : requests) {
            MatchResult result = new MatchResult();
            String symptoms = req.symptoms.toLowerCase();
            
            // Split symptoms into individual keywords
            List<String> keywords = symptoms.split('[,\\s]+');
            
            // Strategy 1: Check Symptom_Department_Map__c
            List<Symptom_Department_Map__c> mappings = [
                SELECT Symptom__c, Department__c, Department__r.Name,
                       Priority_Provider__c, Priority_Provider__r.Name,
                       Priority_Provider__r.Specialization__c,
                       Priority_Provider__r.Experience_Years__c,
                       Priority_Provider__r.Hospital__r.Name,
                       Priority_Provider__r.Consultation_Fee__c,
                       Priority_Provider__r.Languages_Spoken__c,
                       Confidence_Level__c, Severity_Indicator__c
                FROM Symptom_Department_Map__c
                WHERE Symptom__c IN :keywords
                ORDER BY Confidence_Level__c ASC
                LIMIT 5
            ];
            
            if (!mappings.isEmpty()) {
                Symptom_Department_Map__c bestMatch = mappings[0];
                result.recommendation = buildRecommendation(bestMatch);
                result.departmentName = bestMatch.Department__r.Name;
                result.doctorName = bestMatch.Priority_Provider__r?.Name;
                result.severity = bestMatch.Severity_Indicator__c;
                result.isFound = true;
            } else {
                // Strategy 2: Keyword search on Provider__c.Symptom_Keywords__c
                String searchPattern = '%' + String.join(keywords, '%') + '%';
                List<Provider__c> providers = [
                    SELECT Name, Specialization__c, Experience_Years__c,
                           Department__r.Name, Hospital__r.Name,
                           Consultation_Fee__c, Languages_Spoken__c,
                           Rating__c, Bio__c
                    FROM Provider__c
                    WHERE Is_Active__c = TRUE
                    AND (Symptom_Keywords__c LIKE :searchPattern
                         OR Specialization__c LIKE :searchPattern)
                    ORDER BY Experience_Years__c DESC
                    LIMIT 3
                ];
                
                if (!providers.isEmpty()) {
                    result.recommendation = buildProviderRecommendation(providers);
                    result.departmentName = providers[0].Department__r.Name;
                    result.doctorName = providers[0].Name;
                    result.isFound = true;
                } else {
                    result.recommendation = 'I wasn\'t able to match your symptoms to a specific department. '
                        + 'For your safety, I recommend scheduling a General Oncology consultation. '
                        + 'Would you like me to help you book an appointment, or connect you with our care navigation team?';
                    result.isFound = false;
                }
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    private static String buildRecommendation(Symptom_Department_Map__c mapping) {
        String rec = '🔍 Based on your symptoms, I recommend:\n\n';
        rec += '🏥 Department: ' + mapping.Department__r.Name + '\n';
        
        if (mapping.Priority_Provider__c != null) {
            rec += '👨‍⚕️ Recommended Doctor: ' + mapping.Priority_Provider__r.Name + '\n';
            rec += '📋 Specialization: ' + mapping.Priority_Provider__r.Specialization__c + '\n';
            rec += '⭐ Experience: ' + mapping.Priority_Provider__r.Experience_Years__c + ' years\n';
            rec += '🏥 Hospital: ' + mapping.Priority_Provider__r.Hospital__r.Name + '\n';
            
            if (mapping.Priority_Provider__r.Consultation_Fee__c != null) {
                rec += '💰 Consultation Fee: ₹' + mapping.Priority_Provider__r.Consultation_Fee__c + '\n';
            }
            if (mapping.Priority_Provider__r.Languages_Spoken__c != null) {
                rec += '🗣️ Languages: ' + mapping.Priority_Provider__r.Languages_Spoken__c + '\n';
            }
        }
        
        if (mapping.Severity_Indicator__c == 'Emergency' || mapping.Severity_Indicator__c == 'Urgent') {
            rec += '\n⚠️ Priority: ' + mapping.Severity_Indicator__c;
            rec += '\nI recommend booking the earliest available appointment.';
        }
        
        rec += '\n\nWould you like to book an appointment with this doctor?';
        return rec;
    }
    
    private static String buildProviderRecommendation(List<Provider__c> providers) {
        String rec = '🔍 Based on your description, here are my recommendations:\n\n';
        
        Integer counter = 1;
        for (Provider__c p : providers) {
            rec += counter + '. 👨‍⚕️ ' + p.Name + '\n';
            rec += '   📋 ' + p.Specialization__c + '\n';
            rec += '   🏥 ' + p.Department__r.Name + ' at ' + p.Hospital__r.Name + '\n';
            rec += '   ⭐ ' + p.Experience_Years__c + ' years experience\n';
            if (p.Consultation_Fee__c != null) {
                rec += '   💰 ₹' + p.Consultation_Fee__c + '\n';
            }
            rec += '\n';
            counter++;
        }
        
        rec += 'Which doctor would you like to see? Or would you like more options?';
        return rec;
    }
    
    public class MatchRequest {
        @InvocableVariable(label='Patient Symptoms' required=true)
        public String symptoms;
    }
    
    public class MatchResult {
        @InvocableVariable(label='Recommendation')
        public String recommendation;
        
        @InvocableVariable(label='Department Name')
        public String departmentName;
        
        @InvocableVariable(label='Doctor Name')
        public String doctorName;
        
        @InvocableVariable(label='Severity')
        public String severity;
        
        @InvocableVariable(label='Is Found')
        public Boolean isFound;
    }
}
```

**To deploy this Apex class:**

1. Go to **Setup** → Quick Find → **"Apex Classes"** → **New**
2. Paste the code above
3. Click **Save**

> [!WARNING]
> Apex code must be deployed in a sandbox or developer org first. If you get errors, check:
> - The object API names match exactly (e.g., `Symptom_Department_Map__c`)
> - All referenced fields exist
> - You've created the `Symptom_Department_Map__c` object first

### Flow: List Doctors by Department

**Flow Name:** `List_Doctors_By_Department`

```
[START]
  ↓
[Input: department_name (Text), hospital_name (Text - optional)]
  ↓
[Get Records: Department__c WHERE Name CONTAINS department_name]
  ↓
[Get Records: Provider__c WHERE Department__c = dept.Id AND Is_Active__c = TRUE]
  - Sort by: Experience_Years__c DESC
  ↓
[Loop: for each provider]
  → Build formatted string with:
     - Name, Specialization, Experience, Fee, Languages, Rating
  ↓
[Output: doctor_list (Text)]
```

### Flow: Get Doctor Details

**Flow Name:** `Get_Doctor_Details`

```
[START]
  ↓
[Input: doctor_name (Text)]
  ↓
[Get Records: Provider__c WHERE Name CONTAINS doctor_name]
  ↓
[Decision: Doctor found?]
  ├── YES → Format full profile:
  │          Name, Code, Specialization, Qualification,
  │          Experience, Department, Hospital, Fee,
  │          Languages, Bio, Rating
  │          → [Output: doctor_info]
  │
  └── NO → "I couldn't find a doctor with that name. 
             Could you check the spelling or tell me 
             the department you're interested in?"
             → [Output: doctor_info]
```

---

## 🖥️ 5. UI / Experience Layer

### Suggested Conversation Flow:

```
╔══════════════════════════════════════════════════════════╗
║  🏥 OncoAssist - AI Health Assistant                      ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  👤 Patient: I've been having really bad headaches        ║
║     for the past 2 weeks and sometimes my vision          ║
║     gets blurry                                           ║
║                                                          ║
║  🤖 OncoAssist: I understand your concern. Persistent     ║
║     headaches with vision changes should definitely        ║
║     be evaluated by a specialist.                         ║
║                                                          ║
║     🔍 Based on your symptoms, I recommend:               ║
║                                                          ║
║     🏥 Department: Neuro-Oncology                         ║
║     👨‍⚕️ Dr. Vikram Singh                                  ║
║     📋 Neuro-Oncology Specialist                          ║
║     ⭐ 25 years experience                                ║
║     🏥 Onco Global North, Delhi                           ║
║     💰 ₹3,500 consultation                                ║
║     🗣️ English, Hindi                                     ║
║                                                          ║
║     ⚠️ Given your symptoms, I recommend an early          ║
║     appointment. Would you like to book?                  ║
║                                                          ║
║  👤 Patient: Yes, what's the earliest available?          ║
║                                                          ║
║  🤖 OncoAssist: Let me check Dr. Singh's availability... ║
║     [→ Leads into Feature 4: Appointment Booking]        ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

### Quick-Action Buttons (for the chat widget)

Consider adding clickable suggestion buttons after the agent's initial greeting:

```
🔹 [Find a Doctor]  🔹 [Book Appointment]  🔹 [My Appointments]  🔹 [Hospital Info]
```

In the Embedded Chat widget settings, you can add **Quick Actions** or **Suggested Replies** to offer these as click targets.

---

## 🧪 6. Testing

### Test Scenario 1: Headache Symptoms

**Input:** "I'm having headaches and blurred vision"

**Expected:** Recommends Neuro-Oncology / Dr. Vikram Singh

---

### Test Scenario 2: Breast Concern

**Input:** "I found a lump in my breast"

**Expected:** Recommends Medical Oncology + Surgical Oncology / Dr. Priya Sharma (with urgency flag)

---

### Test Scenario 3: Blood-Related

**Input:** "My blood test shows low platelet count and I'm always tired"

**Expected:** Recommends Hematology / Dr. Mohammed Khan

---

### Test Scenario 4: Child Cancer Concern

**Input:** "My 5-year-old son has a lump on his neck"

**Expected:** Recommends Pediatric Oncology / Dr. Arjun Mehta (with urgency flag)

---

### Test Scenario 5: Need a Lab Test

**Input:** "I need to get my blood work done and a PET scan"

**Expected:** Recommends Diagnostics & Pathology / Dr. Amit Joshi

---

### Test Scenario 6: Department-Specific

**Input:** "Show me doctors in the Radiation Oncology department"

**Expected:** Lists Dr. Rajesh Patel with full details

---

### Test Scenario 7: Doctor-Specific

**Input:** "Tell me about Dr. Meera Nair"

**Expected:** Shows full profile of Dr. Meera Nair (Gynecological Oncology)

---

### Test Scenario 8: Vague Symptoms

**Input:** "I'm not feeling well"

**Expected:** Agent asks clarifying questions:
```
I'd like to help you find the right care. Could you tell me a bit more?
- What symptoms are you experiencing?
- How long have you been feeling this way?
- Is this related to an existing condition or treatment?
```

---

## 🎯 Summary

After completing Feature 3, you have:
- ✅ Symptom-to-Doctor matching system (dual strategy: mapped + keyword search)
- ✅ Symptom_Department_Map__c custom object with 15+ mappings
- ✅ Apex class `SymptomMatcher` for intelligent routing
- ✅ 3 new Agent Actions (Find by Symptoms, List by Department, Doctor Details)
- ✅ Updated Doctor Discovery topic with 3 pathways
- ✅ 3 supporting Flows
- ✅ Tested with 8 scenarios

**Next:** → Feature 4: Appointment Booking System
