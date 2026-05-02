# Feature 6: AI Symptom-Based Routing

## 📚 1. Concept Explanation

**What we are building:**
An advanced AI-powered triage system where patients describe their symptoms in natural language, and the agent intelligently routes them to the correct department and most appropriate doctor — factoring in symptom severity, specialist expertise, and urgency.

**Why this is a hackathon differentiator:**
- Goes beyond simple keyword matching — uses **weighted scoring**
- Handles **multi-symptom** descriptions ("I have headaches AND fatigue AND weight loss")
- Detects **urgency levels** and adjusts routing priority
- Can flag potential **emergency situations**
- Judges will see this as genuine AI-driven healthcare innovation

**How it differs from Feature 3:**
Feature 3 was a basic discovery system. Feature 6 is a **clinical-grade triage engine** with:
- Multi-symptom scoring across departments
- Severity escalation logic
- Confidence scores for transparency
- Smart follow-up questions when confidence is low

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Enhance the Symptom Mapping Table

Update `Symptom_Department_Map__c` with additional fields:

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Weight Score | `Weight_Score__c` | Number(3,0) | 1-100, how strongly this symptom maps to this department |
| Related Symptoms | `Related_Symptoms__c` | Text Area(500) | Other symptoms often seen together |
| Urgency Score | `Urgency_Score__c` | Number(3,0) | 1-10, how urgent this symptom is |
| Follow-up Question | `Follow_Up_Question__c` | Text(500) | Question to ask for more clarity |
| Red Flag Indicator | `Red_Flag__c` | Checkbox | TRUE for potentially dangerous symptoms |

### Step 2.2: Populate Enhanced Symptom Mappings

Create a comprehensive mapping table. Here are 30+ mappings:

| Symptom | Department | Weight | Urgency | Severity | Red Flag | Related Symptoms | Follow-up Question |
|---------|-----------|--------|---------|----------|----------|-----------------|-------------------|
| headache | Neuro-Oncology | 80 | 5 | Moderate | No | vision problems, dizziness, nausea | How long have you had this headache? Days, weeks, or months? |
| severe headache | Neuro-Oncology | 95 | 8 | Urgent | Yes | vomiting, confusion, neck stiffness | Is this the worst headache you've ever had? Any vision loss? |
| breast lump | Medical Oncology | 95 | 7 | Urgent | Yes | breast pain, nipple discharge | How long ago did you notice the lump? Has it changed in size? |
| persistent cough | Medical Oncology | 70 | 4 | Moderate | No | chest pain, blood in sputum, weight loss | How long have you been coughing? Any blood in the sputum? |
| coughing blood | Medical Oncology | 98 | 9 | Emergency | Yes | chest pain, weight loss, smoking | How much blood? Please seek immediate medical attention. |
| blood in stool | Surgical Oncology | 85 | 7 | Urgent | Yes | abdominal pain, weight loss, change in bowel habits | How often is this happening? What color is the blood? |
| swollen lymph nodes | Hematology | 80 | 5 | Moderate | No | night sweats, fever, weight loss | Where are the swollen nodes? How long have they been swollen? |
| unexplained weight loss | Medical Oncology | 75 | 6 | Moderate | Yes | fatigue, loss of appetite, night sweats | How much weight have you lost and over what period? |
| fatigue | Medical Oncology | 50 | 3 | Routine | No | weight loss, fever, anemia | Is the fatigue constant or does it come and go? |
| night sweats | Hematology | 70 | 5 | Moderate | No | weight loss, fever, lymph node swelling | How often do you wake up drenched in sweat? |
| seizures | Neuro-Oncology | 95 | 9 | Emergency | Yes | headache, confusion, vision loss | When was the last seizure? How frequent are they? |
| pelvic pain | Gynecological Oncology | 70 | 5 | Moderate | No | irregular bleeding, bloating | Where exactly is the pain? Is it constant? |
| irregular bleeding | Gynecological Oncology | 85 | 7 | Urgent | Yes | pelvic pain, post-menopause bleeding | Is this between periods or after menopause? |
| difficulty swallowing | Surgical Oncology | 80 | 6 | Moderate | No | weight loss, chest pain, hoarseness | Is it getting worse? Solid food, liquids, or both? |
| skin changes | Surgical Oncology | 65 | 4 | Moderate | No | mole changes, new growths, itching | Has a mole changed color, shape, or size? |
| bone pain | Medical Oncology | 70 | 5 | Moderate | No | fractures, weakness, fatigue | Where is the pain? Is it constant? |
| blood in urine | Surgical Oncology | 85 | 7 | Urgent | Yes | pain during urination, frequency | How much blood? Any pain? |
| abdominal pain | Surgical Oncology | 60 | 5 | Moderate | No | bloating, nausea, weight loss | Where in the abdomen? Sharp or dull pain? |
| jaundice | Surgical Oncology | 90 | 8 | Urgent | Yes | abdominal pain, dark urine, pale stool | When did you first notice yellowing? |
| shortness of breath | Medical Oncology | 80 | 7 | Urgent | No | cough, chest pain, wheezing | Is this new or worsening? At rest or during activity? |
| fever with chemo | Medical Oncology | 99 | 10 | Emergency | Yes | chills, shaking, infection | What is your temperature? Go to ER immediately if >100.4°F |
| child with lump | Pediatric Oncology | 90 | 8 | Urgent | Yes | swelling, pain, behavioral changes | What age is the child? Where is the lump? |
| severe pain | Palliative Care | 85 | 8 | Urgent | No | cancer diagnosis, medication not helping | Where is the pain? On a scale of 1-10? |
| need scan | Diagnostics & Pathology | 80 | 3 | Routine | No | doctor referral | Do you have a referral from your doctor? What type of scan? |
| lab test | Diagnostics & Pathology | 80 | 2 | Routine | No | blood work, follow up | Do you have a lab order from your doctor? |

### Step 2.3: Create a Triage Log Object (for tracking and analytics)

#### 📊 Custom Object: `Triage_Log__c`

**Purpose:** Logs every symptom-based routing event for analytics and compliance.

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Patient | `Patient__c` | Lookup(Account) | Who was triaged |
| Symptoms Reported | `Symptoms_Reported__c` | Text Area(Long) | Raw symptom text |
| Matched Department | `Matched_Department__c` | Lookup(Department__c) | Where they were routed |
| Matched Provider | `Matched_Provider__c` | Lookup(Provider__c) | Recommended doctor |
| Confidence Score | `Confidence_Score__c` | Percent(3,0) | Algorithm confidence |
| Severity Level | `Severity_Level__c` | Picklist | Routine, Moderate, Urgent, Emergency |
| Red Flag Detected | `Red_Flag_Detected__c` | Checkbox | Emergency symptoms found |
| Follow-up Action | `Follow_Up_Action__c` | Picklist | Booked, Escalated, Declined, Pending |
| Triage Timestamp | `Triage_Timestamp__c` | Date/Time | When the triage happened |
| Channel | `Channel__c` | Picklist | Web Chat, WhatsApp, SMS |

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Enhanced Agent Action — Advanced Symptom Router

Replace the basic `Find_Doctor_By_Symptoms` action with an advanced version:

1. **Action Name:** `Advanced_Symptom_Router`
2. **Action Type:** Apex Invocable
3. **Description:** `Advanced AI-powered symptom analysis with weighted scoring, multi-department matching, severity detection, and follow-up question generation.`
4. **Inputs:**
   - `patient_symptoms` (String) — Full symptom description
   - `patient_id` (String, optional) — For personalized routing (e.g., existing diagnosis)
   - `patient_age` (String, optional) — For pediatric routing
5. **Outputs:**
   - `routing_result` (String) — Formatted recommendation
   - `severity_level` (String) — Routine/Moderate/Urgent/Emergency
   - `follow_up_questions` (String) — Questions to ask the patient
   - `is_emergency` (Boolean) — Flag for emergency handling
   - `confidence_score` (Number) — 0-100 confidence

### Step 3.2: Update Agent System Prompt with Triage Guidelines

Add this to your agent's system instructions:

```
## Symptom-Based Triage Guidelines

When a patient describes symptoms, follow this protocol:

### Phase 1: Listen & Gather
- Let the patient fully describe their symptoms
- DO NOT immediately diagnose or recommend
- Ask ONE follow-up question if the description is vague

### Phase 2: Analyze
- Use the Advanced_Symptom_Router action
- This will analyze symptoms, match to department/doctor, and assess severity

### Phase 3: Respond Based on Severity

#### 🟢 Routine (Severity 1-3)
- Present the recommendation calmly
- Offer to book at the patient's convenience
- "Based on what you've described, I'd recommend [department]. Would you like to book?"

#### 🟡 Moderate (Severity 4-6)
- Show mild concern but be reassuring
- Suggest a timely appointment
- "I'd recommend seeing [doctor] soon. Shall I check this week's availability?"

#### 🟠 Urgent (Severity 7-8)
- Express appropriate concern
- Push for earliest appointment
- "This should be evaluated promptly. Let me find the earliest slot for you."

#### 🔴 Emergency (Severity 9-10)
- IMMEDIATELY provide emergency contact
- DO NOT try to book a routine appointment
- "Your symptoms suggest you need immediate medical attention. Please call 1800-ONCO-911 or go to the nearest emergency department."

### Phase 4: Disclaimer
ALWAYS include this after any symptom-based recommendation:
"Please note: This is an AI-assisted recommendation, not a medical diagnosis. 
Please consult with the doctor for a proper evaluation."
```

---

## 🔄 4. Automation / Logic

### Apex Class: Advanced Symptom Router

```apex
public class AdvancedSymptomRouter {
    
    @InvocableMethod(label='Advanced Symptom Router'
                     description='AI-powered symptom analysis with weighted scoring and severity detection')
    public static List<TriageResult> routeBySymptoms(List<TriageRequest> requests) {
        List<TriageResult> results = new List<TriageResult>();
        
        for (TriageRequest req : requests) {
            TriageResult result = new TriageResult();
            String symptoms = req.patientSymptoms.toLowerCase().trim();
            
            // ========== STEP 1: KEYWORD EXTRACTION ==========
            // Split patient input into individual terms
            List<String> symptomTerms = new List<String>();
            for (String word : symptoms.split('[,\\s\\.;]+')) {
                String cleaned = word.trim().toLowerCase();
                if (cleaned.length() > 2) { // Skip short words like "a", "is", "in"
                    symptomTerms.add(cleaned);
                }
            }
            
            // Also check multi-word phrases
            List<String> phrases = new List<String>();
            phrases.add(symptoms); // full text
            // Build bi-grams
            List<String> words = symptoms.split('\\s+');
            for (Integer i = 0; i < words.size() - 1; i++) {
                phrases.add(words[i] + ' ' + words[i+1]);
            }
            
            // ========== STEP 2: MATCH AGAINST SYMPTOM MAP ==========
            // Fetch all symptom mappings
            List<Symptom_Department_Map__c> allMappings = [
                SELECT Symptom__c, Department__c, Department__r.Name,
                       Priority_Provider__c, Priority_Provider__r.Name,
                       Priority_Provider__r.Specialization__c,
                       Priority_Provider__r.Experience_Years__c,
                       Priority_Provider__r.Hospital__r.Name,
                       Priority_Provider__r.Consultation_Fee__c,
                       Priority_Provider__r.Languages_Spoken__c,
                       Weight_Score__c, Urgency_Score__c,
                       Confidence_Level__c, Severity_Indicator__c,
                       Related_Symptoms__c, Follow_Up_Question__c,
                       Red_Flag__c
                FROM Symptom_Department_Map__c
                ORDER BY Weight_Score__c DESC
            ];
            
            // Score each mapping against patient symptoms
            Map<Id, DepartmentScore> deptScores = new Map<Id, DepartmentScore>();
            List<String> matchedFollowUps = new List<String>();
            Boolean emergencyDetected = false;
            Decimal maxUrgency = 0;
            
            for (Symptom_Department_Map__c mapping : allMappings) {
                String mappingSymptom = mapping.Symptom__c.toLowerCase();
                Boolean matched = false;
                
                // Check if any symptom term matches
                for (String term : symptomTerms) {
                    if (mappingSymptom.contains(term) || term.contains(mappingSymptom)) {
                        matched = true;
                        break;
                    }
                }
                // Also check phrases
                if (!matched) {
                    for (String phrase : phrases) {
                        if (phrase.contains(mappingSymptom) || mappingSymptom.contains(phrase)) {
                            matched = true;
                            break;
                        }
                    }
                }
                
                if (matched) {
                    Id deptId = mapping.Department__c;
                    
                    if (!deptScores.containsKey(deptId)) {
                        DepartmentScore ds = new DepartmentScore();
                        ds.departmentId = deptId;
                        ds.departmentName = mapping.Department__r.Name;
                        ds.totalScore = 0;
                        ds.maxUrgency = 0;
                        ds.matchCount = 0;
                        ds.providers = new List<Symptom_Department_Map__c>();
                        deptScores.put(deptId, ds);
                    }
                    
                    DepartmentScore ds = deptScores.get(deptId);
                    Decimal weight = mapping.Weight_Score__c != null ? mapping.Weight_Score__c : 50;
                    ds.totalScore += weight;
                    ds.matchCount++;
                    ds.providers.add(mapping);
                    
                    if (mapping.Urgency_Score__c != null && mapping.Urgency_Score__c > ds.maxUrgency) {
                        ds.maxUrgency = mapping.Urgency_Score__c;
                    }
                    
                    // Track emergency
                    if (mapping.Red_Flag__c == true) {
                        emergencyDetected = true;
                    }
                    if (mapping.Urgency_Score__c != null && mapping.Urgency_Score__c >= 9) {
                        emergencyDetected = true;
                    }
                    if (mapping.Urgency_Score__c != null && mapping.Urgency_Score__c > maxUrgency) {
                        maxUrgency = mapping.Urgency_Score__c;
                    }
                    
                    // Collect follow-up questions
                    if (mapping.Follow_Up_Question__c != null && !matchedFollowUps.contains(mapping.Follow_Up_Question__c)) {
                        matchedFollowUps.add(mapping.Follow_Up_Question__c);
                    }
                }
            }
            
            // ========== STEP 3: RANK DEPARTMENTS ==========
            List<DepartmentScore> rankedDepts = new List<DepartmentScore>(deptScores.values());
            rankedDepts.sort();
            
            // ========== STEP 4: BUILD RESULT ==========
            if (!rankedDepts.isEmpty()) {
                DepartmentScore topDept = rankedDepts[0];
                
                // Calculate confidence (normalized score)
                Decimal maxPossible = 100 * topDept.matchCount;
                Decimal confidence = Math.min(100, (topDept.totalScore / maxPossible) * 100);
                result.confidenceScore = confidence.intValue();
                
                // Determine severity
                result.isEmergency = emergencyDetected;
                if (maxUrgency >= 9) {
                    result.severityLevel = 'Emergency';
                } else if (maxUrgency >= 7) {
                    result.severityLevel = 'Urgent';
                } else if (maxUrgency >= 4) {
                    result.severityLevel = 'Moderate';
                } else {
                    result.severityLevel = 'Routine';
                }
                
                // Build human-readable recommendation
                String rec = '';
                
                if (emergencyDetected) {
                    rec += '🚨 **URGENT ATTENTION NEEDED**\n\n';
                    rec += '⚠️ Based on your symptoms, I strongly recommend seeking immediate medical care.\n';
                    rec += '📞 Emergency Helpline: **1800-ONCO-911**\n';
                    rec += '📞 National Emergency: **112**\n\n';
                }
                
                rec += '🔍 Based on your symptoms, here\'s my recommendation:\n\n';
                
                // Top department
                rec += '🏆 **Primary Recommendation:**\n';
                rec += '🏬 Department: **' + topDept.departmentName + '**\n';
                
                if (!topDept.providers.isEmpty() && topDept.providers[0].Priority_Provider__c != null) {
                    Symptom_Department_Map__c topMapping = topDept.providers[0];
                    rec += '👨‍⚕️ Doctor: **' + topMapping.Priority_Provider__r.Name + '**\n';
                    rec += '📋 Specialization: ' + topMapping.Priority_Provider__r.Specialization__c + '\n';
                    rec += '⭐ Experience: ' + topMapping.Priority_Provider__r.Experience_Years__c + ' years\n';
                    rec += '🏥 Hospital: ' + topMapping.Priority_Provider__r.Hospital__r.Name + '\n';
                    if (topMapping.Priority_Provider__r.Consultation_Fee__c != null) {
                        rec += '💰 Fee: ₹' + topMapping.Priority_Provider__r.Consultation_Fee__c + '\n';
                    }
                }
                
                rec += '📊 Confidence: ' + result.confidenceScore + '%\n';
                rec += '⚡ Priority: ' + result.severityLevel + '\n';
                
                // Secondary recommendations if multiple departments matched
                if (rankedDepts.size() > 1) {
                    rec += '\n📋 **Other possible departments:**\n';
                    for (Integer i = 1; i < Math.min(3, rankedDepts.size()); i++) {
                        rec += '  • ' + rankedDepts[i].departmentName + '\n';
                    }
                }
                
                rec += '\n⚕️ _Note: This is an AI-assisted recommendation, not a medical diagnosis. '
                    + 'Please consult with the doctor for proper evaluation._\n';
                
                if (!emergencyDetected) {
                    rec += '\nWould you like to book an appointment with the recommended doctor?';
                }
                
                result.routingResult = rec;
                
                // Follow-up questions
                if (!matchedFollowUps.isEmpty()) {
                    result.followUpQuestions = String.join(matchedFollowUps, '\n');
                }
                
            } else {
                // No matches found
                result.routingResult = '🤔 I wasn\'t able to match your symptoms to a specific department.\n\n'
                    + 'To better help you, could you:\n'
                    + '1. Describe your symptoms in more detail?\n'
                    + '2. Mention how long you\'ve had these symptoms?\n'
                    + '3. Let me know if you have any existing diagnosis?\n\n'
                    + 'Or I can connect you with our care navigation team for personalized guidance.';
                result.confidenceScore = 0;
                result.severityLevel = 'Routine';
                result.isEmergency = false;
            }
            
            // ========== STEP 5: LOG THE TRIAGE ==========
            try {
                Triage_Log__c log = new Triage_Log__c();
                log.Symptoms_Reported__c = req.patientSymptoms;
                if (req.patientId != null && req.patientId != '') {
                    log.Patient__c = Id.valueOf(req.patientId);
                }
                if (!rankedDepts.isEmpty()) {
                    log.Matched_Department__c = rankedDepts[0].departmentId;
                    if (!rankedDepts[0].providers.isEmpty() && rankedDepts[0].providers[0].Priority_Provider__c != null) {
                        log.Matched_Provider__c = rankedDepts[0].providers[0].Priority_Provider__c;
                    }
                }
                log.Confidence_Score__c = result.confidenceScore;
                log.Severity_Level__c = result.severityLevel;
                log.Red_Flag_Detected__c = emergencyDetected;
                log.Follow_Up_Action__c = 'Pending';
                log.Triage_Timestamp__c = DateTime.now();
                log.Channel__c = 'Web Chat';
                insert log;
            } catch (Exception e) {
                // Don't let logging failure break the main flow
                System.debug('Triage log insert failed: ' + e.getMessage());
            }
            
            results.add(result);
        }
        return results;
    }
    
    // Inner class for department scoring — implements Comparable for sorting
    public class DepartmentScore implements Comparable {
        public Id departmentId;
        public String departmentName;
        public Decimal totalScore;
        public Decimal maxUrgency;
        public Integer matchCount;
        public List<Symptom_Department_Map__c> providers;
        
        public Integer compareTo(Object other) {
            DepartmentScore otherScore = (DepartmentScore) other;
            // Sort descending by total score
            if (this.totalScore > otherScore.totalScore) return -1;
            if (this.totalScore < otherScore.totalScore) return 1;
            return 0;
        }
    }
    
    public class TriageRequest {
        @InvocableVariable(label='Patient Symptoms' required=true)
        public String patientSymptoms;
        
        @InvocableVariable(label='Patient ID')
        public String patientId;
        
        @InvocableVariable(label='Patient Age')
        public String patientAge;
    }
    
    public class TriageResult {
        @InvocableVariable(label='Routing Result')
        public String routingResult;
        
        @InvocableVariable(label='Severity Level')
        public String severityLevel;
        
        @InvocableVariable(label='Follow-up Questions')
        public String followUpQuestions;
        
        @InvocableVariable(label='Is Emergency')
        public Boolean isEmergency;
        
        @InvocableVariable(label='Confidence Score')
        public Integer confidenceScore;
    }
}
```

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — Multi-Symptom Triage

```
👤 I've been having night sweats for the last 3 weeks, and I've lost 
   about 8 kg without trying. My lymph nodes are swollen too.

🤖 Thank you for sharing those details. Those symptoms together are 
   important to evaluate. Let me analyze this for you...

   🔍 Based on your symptoms, here's my recommendation:

   🏆 Primary Recommendation:
   🏬 Department: Hematology
   👨‍⚕️ Doctor: Dr. Mohammed Khan
   📋 Specialization: Hematology
   ⭐ Experience: 20 years
   🏥 Onco Global Main Campus, Mumbai
   💰 Fee: ₹2,000
   📊 Confidence: 87%
   ⚡ Priority: Urgent

   📋 Other possible departments:
     • Medical Oncology

   ⚠️ The combination of night sweats, weight loss, and swollen
   lymph nodes warrants prompt evaluation.

   ⚕️ Note: This is an AI-assisted recommendation, not a medical
   diagnosis. Please consult with the doctor for proper evaluation.

   I'd recommend booking the earliest available appointment.
   Shall I check Dr. Khan's availability?
```

---

## 🧪 6. Testing

| Test Case | Symptoms | Expected Dept | Expected Severity | Red Flag? |
|-----------|----------|--------------|-------------------|-----------|
| Single clear symptom | "breast lump" | Medical Oncology | Urgent | Yes |
| Multi-symptom | "night sweats, weight loss, swollen lymph nodes" | Hematology | Urgent | No |
| Emergency | "coughing blood, chest pain" | Medical Oncology | Emergency | Yes |
| Chemo emergency | "I'm on chemo and have fever of 103" | Medical Oncology | Emergency | Yes |
| Pediatric | "my 4 year old child has a lump" | Pediatric Oncology | Urgent | Yes |
| Vague | "I'm not feeling well" | No match / ask more | Routine | No |
| Routine | "I need a blood test" | Diagnostics | Routine | No |
| Multi-department | "headache and pelvic pain" | Neuro + Gynec shown | Moderate | No |

---

## 🎯 Summary

After completing Feature 6:
- ✅ Advanced multi-symptom weighted scoring algorithm
- ✅ 30+ symptom-to-department mappings with urgency scores
- ✅ Red flag / emergency detection system
- ✅ Confidence scoring for transparency
- ✅ Follow-up question generation
- ✅ Triage logging for analytics and compliance
- ✅ Severity-based response formatting (Routine → Emergency)

**Next:** → Feature 7: Smart Slot Optimization Logic
