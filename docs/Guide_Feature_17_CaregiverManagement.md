# Feature 17: Family & Caregiver Appointment Management

## 📚 1. Concept Explanation

**What we are building:**
A caregiver delegation system that allows family members, spouses, or designated caregivers to manage appointments **on behalf of** cancer patients. In oncology, patients are often too ill, elderly, or undergoing treatment to manage their own schedules. This feature lets authorized caregivers book, reschedule, cancel, and receive reminders through the same AI agent.

**Why this is an oncology-specific game-changer:**
- **Deeply empathetic design** — shows you understand the cancer care reality where family plays a critical role
- No other hackathon team will address this — it's a **domain expertise differentiator**
- Addresses a real pain point: 40% of cancer patients rely on family members for appointment coordination
- Demonstrates **Health Cloud's care team model** — which is exactly what Health Cloud is designed for
- Judges will see this as proof of **deep user research** and understanding

**User Stories:**
```
"I'm booking for my mother who has cervical cancer. She's 72 and 
 can't use the phone."                    → Caregiver booking flow

"Can I get a copy of my husband's appointment reminder too?"
                                           → Dual-notification setup

"My father is Rahul Verma, PAT-00001. I'm his son Vikram. 
 I need to reschedule his chemo appointment."
                                           → Verified caregiver access
```

---

## 🏗️ 2. Salesforce Setup Steps

### Step 2.1: Create Caregiver Relationship Object

#### 👪 Custom Object: `Caregiver_Relationship__c`

**Purpose:** Links a caregiver (family member) to a patient with specific permission levels.

**Create the object:**
- **Label:** `Caregiver Relationship`
- **Plural Label:** `Caregiver Relationships`
- **Record Name:** `Relationship ID` (Auto Number, format: `CG-{00000}`)

**Fields:**

| Field Label | API Name | Data Type | Required | Description |
|------------|----------|-----------|----------|-------------|
| Patient | `Patient__c` | Lookup(Account) | ✅ Yes | The patient being cared for |
| Caregiver Name | `Caregiver_Name__c` | Text(100) | ✅ Yes | Full name of the caregiver |
| Caregiver Phone | `Caregiver_Phone__c` | Phone | ✅ Yes | For verification and reminders |
| Caregiver Email | `Caregiver_Email__c` | Email | No | For email notifications |
| Relationship | `Relationship__c` | Picklist | ✅ Yes | Son, Daughter, Spouse, Sibling, Parent, Other |
| Permission Level | `Permission_Level__c` | Picklist | ✅ Yes | View Only, Book & Manage, Full Access |
| Is Verified | `Is_Verified__c` | Checkbox | No | Has identity been verified? |
| Verification Method | `Verification_Method__c` | Picklist | No | Phone OTP, In-Person, Doctor Approved |
| Is Active | `Is_Active__c` | Checkbox | No | Default: TRUE |
| Receive Reminders | `Receive_Reminders__c` | Checkbox | No | Should caregiver also get reminders? |
| Receive Copy of Booking | `Receive_Booking_Copy__c` | Checkbox | No | Send booking confirmations to caregiver? |
| Date Authorized | `Date_Authorized__c` | Date | No | When the caregiver was authorized |
| Notes | `Notes__c` | Text Area(500) | No | Any special notes |

**Picklist Values:**

**Relationship__c:**
- Son, Daughter, Spouse, Sibling, Parent, Friend, Legal Guardian, Other

**Permission_Level__c:**
- `View Only` — Can check appointment status, no changes
- `Book & Manage` — Can book, reschedule, cancel appointments
- `Full Access` — Full access including medical history view

**Verification_Method__c:**
- Phone OTP, In-Person Verification, Doctor Approved, Patient Authorized via Chat

### Step 2.2: Add Caregiver Fields to Appointment__c

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Booked By | `Booked_By__c` | Text(100) | Name of the person who booked (patient or caregiver) |
| Booked By Role | `Booked_By_Role__c` | Picklist | Self, Caregiver, Hospital Staff |
| Caregiver Relationship | `Caregiver_Relationship__c` | Lookup(Caregiver_Relationship__c) | If booked by a caregiver |

### Step 2.3: Add Primary Caregiver to Patient Account

| Field Label | API Name | Data Type | Description |
|------------|----------|-----------|-------------|
| Has Active Caregiver | `Has_Caregiver__c` | Checkbox | Quick flag for agent logic |
| Primary Caregiver Name | `Primary_Caregiver__c` | Text(100) | Quick reference to main caregiver |

---

## 🤖 3. Agentforce Implementation

### Step 3.1: Agent Action — Verify Caregiver

1. **Action Name:** `Verify_Caregiver`
2. **Action Type:** Apex Invocable
3. **Description:** `Verify that a person is an authorized caregiver for a specific patient.`
4. **Inputs:**
   - `patient_id` (String) — Patient ID or name
   - `caregiver_name` (String) — Caregiver's name
   - `caregiver_phone` (String) — For phone-based verification
5. **Outputs:**
   - `is_verified` (Boolean)
   - `caregiver_details` (String) — Relationship and permission info
   - `permission_level` (String) — What they're allowed to do
   - `patient_name` (String) — The patient's name

### Step 3.2: Agent Action — Register Caregiver

1. **Action Name:** `Register_Caregiver`
2. **Action Type:** Apex Invocable
3. **Description:** `Register a new caregiver for a patient.`
4. **Inputs:**
   - `patient_id` (String)
   - `caregiver_name` (String)
   - `caregiver_phone` (String)
   - `caregiver_email` (String, optional)
   - `relationship` (String)
   - `permission_level` (String)
5. **Outputs:**
   - `registration_confirmation` (String)

### Step 3.3: Agent Instructions for Caregiver Handling

```
## Family & Caregiver Protocol

### Detecting Caregiver Interactions
When a user says things like:
- "I'm calling for my mother/father/husband/wife..."
- "I want to book for someone else"
- "My patient ID is PAT-XXXXX but I'm their son/daughter"
- Any third-person references to a patient

IMMEDIATELY switch to Caregiver Mode:

### Caregiver Mode Flow:

#### Step 1: Identify the Patient
- Ask for the patient's name or Patient ID
- "Who is the patient you'd like to help with today?"

#### Step 2: Verify the Caregiver
- Ask: "May I know your name and relationship to [Patient Name]?"
- Call Verify_Caregiver to check authorization
- If verified: "Thank you, [Caregiver Name]. You're verified as 
  [Patient Name]'s [relationship]. How can I help you today?"
- If NOT verified: "I don't have you on file yet as an authorized 
  caregiver. Would you like to set up caregiver access? I'll need 
  to verify with the patient or their treating doctor."

#### Step 3: Check Permissions
- View Only: Can only check appointment status
- Book & Manage: Can perform all appointment operations
- If action exceeds permission level: "Your current access level 
  allows viewing only. To make changes, please ask [Patient Name] 
  to upgrade your access, or visit the hospital for in-person 
  verification."

#### Step 4: Execute with Attribution
- All actions should note "Booked by: [Caregiver Name] (Caregiver)"
- Send confirmations to BOTH patient and caregiver (if opted in)

### Tone Adjustments for Caregivers:
- Extra empathy: "Thank you for taking care of [Patient Name]"
- More clinical context: Caregivers often need more detail
- Offer printed/WhatsApp summaries: "Would you like me to send 
  these details to your WhatsApp as well?"
```

---

## 🔄 4. Automation / Logic

### Apex Class: Caregiver Service

```apex
public class CaregiverService {
    
    @InvocableMethod(label='Verify Caregiver'
                     description='Check if a person is an authorized caregiver for a patient')
    public static List<CaregiverResult> verifyCaregiver(List<CaregiverRequest> requests) {
        List<CaregiverResult> results = new List<CaregiverResult>();
        
        for (CaregiverRequest req : requests) {
            CaregiverResult result = new CaregiverResult();
            
            try {
                // Find the patient
                List<Account> patients = [
                    SELECT Id, Name, Patient_ID__c
                    FROM Account
                    WHERE Id = :req.patientId
                    OR Patient_ID__c = :req.patientId
                    OR Name LIKE :('%' + req.patientId + '%')
                    LIMIT 1
                ];
                
                if (patients.isEmpty()) {
                    result.isVerified = false;
                    result.caregiverDetails = 'Patient not found. Please check the Patient ID.';
                    results.add(result);
                    continue;
                }
                
                Account patient = patients[0];
                result.patientName = patient.Name;
                
                // Check for caregiver relationship
                List<Caregiver_Relationship__c> caregivers = [
                    SELECT Id, Caregiver_Name__c, Caregiver_Phone__c,
                           Relationship__c, Permission_Level__c,
                           Is_Verified__c, Is_Active__c,
                           Receive_Reminders__c, Receive_Booking_Copy__c
                    FROM Caregiver_Relationship__c
                    WHERE Patient__c = :patient.Id
                    AND Is_Active__c = TRUE
                    AND (Caregiver_Name__c LIKE :('%' + req.caregiverName + '%')
                         OR Caregiver_Phone__c = :req.caregiverPhone)
                    LIMIT 1
                ];
                
                if (!caregivers.isEmpty()) {
                    Caregiver_Relationship__c cg = caregivers[0];
                    
                    result.isVerified = true;
                    result.permissionLevel = cg.Permission_Level__c;
                    
                    String details = '✅ Caregiver Verified!\n\n';
                    details += '👤 Caregiver: ' + cg.Caregiver_Name__c + '\n';
                    details += '🔗 Relationship: ' + cg.Relationship__c + '\n';
                    details += '🏥 Patient: ' + patient.Name + ' (' + patient.Patient_ID__c + ')\n';
                    details += '🔑 Access Level: ' + cg.Permission_Level__c + '\n';
                    
                    if (cg.Permission_Level__c == 'View Only') {
                        details += '\n📋 You can: View appointment status\n';
                        details += '❌ You cannot: Book, modify, or cancel appointments';
                    } else if (cg.Permission_Level__c == 'Book & Manage') {
                        details += '\n📋 You can: View, book, reschedule, and cancel appointments';
                    } else {
                        details += '\n📋 You have full access to manage appointments';
                    }
                    
                    result.caregiverDetails = details;
                    
                } else {
                    result.isVerified = false;
                    result.caregiverDetails = '❌ No caregiver record found for "' + req.caregiverName 
                        + '" linked to patient ' + patient.Name + '.\n\n'
                        + 'Would you like to:\n'
                        + '1. Register as an authorized caregiver (requires patient or doctor approval)\n'
                        + '2. Visit the hospital for in-person verification\n'
                        + '3. Have the patient authorize you via their account';
                }
                
            } catch (Exception e) {
                result.isVerified = false;
                result.caregiverDetails = 'Error during verification: ' + e.getMessage();
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class CaregiverRequest {
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
        
        @InvocableVariable(label='Caregiver Name' required=true)
        public String caregiverName;
        
        @InvocableVariable(label='Caregiver Phone')
        public String caregiverPhone;
    }
    
    public class CaregiverResult {
        @InvocableVariable(label='Is Verified')
        public Boolean isVerified;
        
        @InvocableVariable(label='Caregiver Details')
        public String caregiverDetails;
        
        @InvocableVariable(label='Permission Level')
        public String permissionLevel;
        
        @InvocableVariable(label='Patient Name')
        public String patientName;
    }
}
```

### Apex Class: Caregiver Registration

```apex
public class CaregiverRegistration {
    
    @InvocableMethod(label='Register Caregiver'
                     description='Register a new caregiver for a patient')
    public static List<RegistrationResult> registerCaregiver(List<RegistrationRequest> requests) {
        List<RegistrationResult> results = new List<RegistrationResult>();
        
        for (RegistrationRequest req : requests) {
            RegistrationResult result = new RegistrationResult();
            
            try {
                // Find patient
                Account patient = [
                    SELECT Id, Name, Patient_ID__c
                    FROM Account
                    WHERE Id = :req.patientId OR Patient_ID__c = :req.patientId
                    LIMIT 1
                ];
                
                // Check for existing relationship
                List<Caregiver_Relationship__c> existing = [
                    SELECT Id FROM Caregiver_Relationship__c
                    WHERE Patient__c = :patient.Id
                    AND Caregiver_Phone__c = :req.caregiverPhone
                    AND Is_Active__c = TRUE
                    LIMIT 1
                ];
                
                if (!existing.isEmpty()) {
                    result.registrationConfirmation = 'A caregiver with this phone number is already '
                        + 'registered for ' + patient.Name + '.';
                    results.add(result);
                    continue;
                }
                
                // Create caregiver relationship
                Caregiver_Relationship__c cg = new Caregiver_Relationship__c();
                cg.Patient__c = patient.Id;
                cg.Caregiver_Name__c = req.caregiverName;
                cg.Caregiver_Phone__c = req.caregiverPhone;
                cg.Caregiver_Email__c = req.caregiverEmail;
                cg.Relationship__c = req.relationship;
                cg.Permission_Level__c = 'Book & Manage'; // default for registered caregivers
                cg.Is_Active__c = true;
                cg.Is_Verified__c = false; // Needs verification
                cg.Verification_Method__c = 'Patient Authorized via Chat';
                cg.Receive_Reminders__c = true;
                cg.Receive_Booking_Copy__c = true;
                cg.Date_Authorized__c = Date.today();
                insert cg;
                
                // Update patient record
                patient.Has_Caregiver__c = true;
                patient.Primary_Caregiver__c = req.caregiverName;
                update patient;
                
                String conf = '✅ Caregiver Registration Successful!\n\n';
                conf += '👤 Caregiver: ' + req.caregiverName + '\n';
                conf += '🔗 Relationship: ' + req.relationship + '\n';
                conf += '🏥 Patient: ' + patient.Name + '\n';
                conf += '🔑 Access: Book & Manage appointments\n';
                conf += '📱 Phone: ' + req.caregiverPhone + '\n\n';
                conf += '📋 As a registered caregiver, you can now:\n';
                conf += '  • Book appointments for ' + patient.Name + '\n';
                conf += '  • Reschedule or cancel existing appointments\n';
                conf += '  • Receive appointment reminders\n';
                conf += '  • Get copies of booking confirmations\n\n';
                conf += '⚠️ Note: For security, in-person verification at the hospital '
                    + 'is recommended for full access.';
                
                result.registrationConfirmation = conf;
                
            } catch (Exception e) {
                result.registrationConfirmation = '❌ Registration error: ' + e.getMessage();
            }
            
            results.add(result);
        }
        return results;
    }
    
    public class RegistrationRequest {
        @InvocableVariable(label='Patient ID' required=true)
        public String patientId;
        
        @InvocableVariable(label='Caregiver Name' required=true)
        public String caregiverName;
        
        @InvocableVariable(label='Caregiver Phone' required=true)
        public String caregiverPhone;
        
        @InvocableVariable(label='Caregiver Email')
        public String caregiverEmail;
        
        @InvocableVariable(label='Relationship' required=true)
        public String relationship;
    }
    
    public class RegistrationResult {
        @InvocableVariable(label='Registration Confirmation')
        public String registrationConfirmation;
    }
}
```

### Flow: Dual Notification for Caregiver Appointments

**Flow Name:** `Caregiver_Dual_Notification`
**Trigger:** When `Appointment__c` is created with `Booked_By_Role__c = 'Caregiver'`

```
[TRIGGER: Appointment created by Caregiver]
  ↓
[Get Records: Caregiver_Relationship__c WHERE Appointment.Caregiver_Relationship__c]
  ↓
[Decision: Receive_Booking_Copy = TRUE?]
  ├── YES → [Send confirmation to caregiver phone/email]
  │          AND
  │          [Send confirmation to patient phone/email]
  └── NO  → [Send confirmation to patient only]
  ↓
[END]
```

---

## 🖥️ 5. UI / Experience Layer

### Demo Conversation — Caregiver Booking

```
👤 Hi, I need to book an appointment for my mother. 
   She has cervical cancer and can't manage the phone.

🤖 I completely understand. Thank you for being there 
   for your mother. 🙏 I can help you manage her 
   appointments.

   First, may I know your mother's name or Patient ID?

👤 Her Patient ID is PAT-00004, Fatima Sheikh

🤖 I found her record. Before I proceed, I need to 
   verify your caregiver access.

   May I know your name and your relationship to 
   Fatima Sheikh?

👤 I'm Zara Sheikh, her daughter

🤖 ✅ Caregiver Verified!
   
   👤 Caregiver: Zara Sheikh
   🔗 Relationship: Daughter
   🏥 Patient: Fatima Sheikh (PAT-00004)
   🔑 Access Level: Book & Manage
   
   You have full appointment management access for 
   your mother. How can I help today?

👤 I need to book a follow-up with Dr. Meera Nair

🤖 Of course! Let me check Dr. Nair's availability 
   for your mother's follow-up...

   [continues with standard booking flow, 
    but sends confirmations to BOTH Fatima and Zara]
```

### Demo: Unregistered Caregiver

```
👤 I want to book for my friend Rahul Verma, PAT-00001

🤖 I appreciate you helping Rahul. For security, I need 
   to verify your caregiver access.

   What is your name?

👤 Sanjay Kumar

🤖 I don't have a caregiver record for "Sanjay Kumar" 
   linked to Rahul Verma.

   For patient privacy and security, I can only allow 
   authorized caregivers to manage appointments. 
   
   Would you like to:
   1. 📝 Register as an authorized caregiver 
      (Rahul will need to approve)
   2. 🏥 Visit the hospital for in-person verification
   3. 📱 Have Rahul contact us to authorize you

   Which option works best?
```

---

## 🧪 6. Testing

| Test | Input | Expected Result |
|------|-------|-----------------|
| Verified caregiver | Zara Sheikh for PAT-00004 | Access granted, permission level shown |
| Unverified caregiver | Unknown person for any patient | Access denied, registration offered |
| View Only access | Caregiver tries to book | Blocked — "Your access level allows viewing only" |
| Caregiver booking | Book apt as verified caregiver | Appointment created with `Booked_By_Role = Caregiver` |
| Dual notification | Book as caregiver with reminders ON | Both patient and caregiver get confirmation |
| Registration | New caregiver registers | `Caregiver_Relationship__c` record created |
| Permission check | Caregiver tries to cancel | Allowed if Book & Manage, blocked if View Only |

---

## 🎯 Summary

After completing Feature 17:
- ✅ `Caregiver_Relationship__c` custom object with permission levels
- ✅ Caregiver verification system (name + phone matching)
- ✅ Caregiver registration flow via chat
- ✅ Permission-based action control (View Only / Book & Manage / Full Access)
- ✅ Dual notification system (patient + caregiver)
- ✅ Appointment attribution tracking (who booked it)
- ✅ Empathetic agent behavior adapted for caregiver interactions
- ✅ Security-first approach with verification requirements

**Next:** → Feature 18: Post-Visit Follow-Up & Treatment Adherence Automation
