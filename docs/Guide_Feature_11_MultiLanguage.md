# Feature 11: Multi-language Support (Hinglish/Hindi)

## 📚 1. Concept Explanation

**What we are building:**
Making the agent accessible to a wider demographic by supporting English, Hindi, and Hinglish (a mix of both). Since our hospital network is global but local, this is a "Winning Move" for a hackathon.

**Why it matters:**
- In India (and globally), healthcare is personal. People feel most comfortable speaking in their primary language.
- Shows the power of Generative AI (LLMs) to handle translation and sentiment across languages without hardcoding translations.

---

## 🤖 2. Agentforce Implementation

### Step 2.1: LLM Language Instructions

You don't need a separate agent for each language. You just need to tell the agent to detect and respond.

Update **System Prompt**:
```text
LANGUAGE: Always respond in the language the user uses. 
If the user speaks Hindi, respond in Hindi. 
If they use Hinglish (e.g., "Mera appointment kal shift kar do"), respond in Hinglish.
```

---

## 🏗️ 3. Salesforce Setup Steps

### Step 3.1: Translatable Knowledge

If you have **Knowledge Articles**, you can enable **Multiple Languages** in Knowledge Settings to provide official Hindi translations for FAQs.

---

## 🖥️ 4. UI / Experience Layer (Hinglish Example)

- **User:** *"Doctor change karna hai, possible hai?"* (I want to change the doctor, is it possible?)
- **Agent:** *"Haan, bilkul! Kounsa doctor aap prefer karenge? I can help you reschedule."*

---

## 🧪 5. Testing

- Try phrases like: *"Subah 10 baje ka slot milega?"* (Will I get a 10 AM slot?)
- Verify the agent responds in Hindi/Hinglish and still executes the `Check_Available_Slots` action correctly.
