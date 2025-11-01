# 🚀 Complete App Flow: Founder to Investor Journey

## 📋 TABLE OF CONTENTS
1. [Overview](#overview)
2. [Founder Side Flow](#founder-side-flow)
3. [Investor Side Flow](#investor-side-flow)
4. [Firestore Collections Explained](#firestore-collections-explained)
5. [Data Flow Diagram](#data-flow-diagram)
6. [Feature Breakdown](#feature-breakdown)

---

## 🎯 OVERVIEW

This is an **AI-Powered Investment Platform** that connects founders raising capital with investors. The platform uses AI to:
- **Extract and analyze** pitch decks automatically
- **Generate investment memos** (Memo 1 & Memo 2)
- **Run due diligence** using AI
- **Match founders with investors** based on preferences
- **Verify claims** made in pitches
- **Provide explainable AI insights** for investment decisions

---

## 👨‍💼 FOUNDER SIDE FLOW

### Step 1: Upload Pitch Deck
**What Founder Does:**
1. Logs into the app as a **Founder**
2. Navigates to **"Pitch"** tab
3. Uploads a PDF pitch deck (or video/audio pitch)
4. File uploads to **Firebase Storage**

**What Happens Behind the Scenes:**
```
Founder Uploads PDF
    ↓
File stored in Firebase Storage
    ↓
App calls: POST /on_file_upload
    ↓
Backend receives file + founder_email
    ↓
Creates document in 'uploads' collection:
{
  uploadId: "abc123",
  founderEmail: "founder@example.com",
  fileName: "pitch.pdf",
  status: "uploaded",
  uploadedAt: Timestamp
}
```

---

### Step 2: AI Processing (Memo 1 Generation)
**What Happens Automatically:**
1. Cloud Function triggers processing
2. AI extracts text from PDF
3. AI analyzes content and extracts structured data
4. **Memo 1 (Founders Checklist)** is generated

**Data Created in Firestore:**
```
Collection: ingestionResults
Document ID: {uploadId or generated}
{
  memo_1: {
    title: "Company Name",
    founder_name: ["Founder 1", "Founder 2"],
    industry_category: ["FinTech", "SaaS"],
    company_stage: "Seed",
    problem: "...",
    solution: "...",
    traction: "...",
    market_size: "...",
    business_model: "...",
    team: "...",
    summary_analysis: "4-5 paragraph comprehensive summary",
    // ... 100+ fields extracted
  },
  original_filename: "pitch.pdf",
  founder_email: "founder@example.com",
  status: "SUCCESS",
  timestamp: "2025-11-01T06:54:39",
  processing_time_seconds: 71.38
}
```

**What Founder Sees:**
- Upload status changes: "uploaded" → "processing" → "completed"
- Can view Memo 1 analysis
- Can see extracted company information

---

### Step 3: Founder Views Results
**What Founder Can Do:**
1. View **Memo 1** (Founders Checklist)
   - All extracted company data
   - AI-generated summary
   - Initial flags/risks identified

2. Get **AI Feedback**
   - Ask questions about their pitch
   - Get recommendations for improvement

3. **Schedule Interview**
   - Book AI interviewer sessions
   - Get interview preparation tips

---

## 💼 INVESTOR SIDE FLOW

### Step 1: Investor Views Opportunities
**What Investor Sees:**
When investor opens **"AI Diligence Engine"** tab:
- Sees ALL uploaded pitch decks from ALL founders
- Each pitch shows:
  - Company name
  - Founder names
  - Stage (Seed, Series A, etc.)
  - Industry
  - Status: "Pending Diligence" or "Completed"
  - Investment score (if diligence completed)

**Data Source:**
- Queries `ingestionResults` collection
- Shows all documents with `memo_1` field
- No filtering by user (investors see everything)

---

### Step 2: Investor Runs Diligence (Memo 2 Generation)
**What Investor Does:**
1. Clicks on a pitch deck
2. Sees Memo 1 details
3. Clicks **"Run Diligence"** button

**What Happens Behind the Scenes:**
```
Investor clicks "Run Diligence"
    ↓
App calls: POST /trigger_diligence
    ↓
Backend AI Agent analyzes Memo 1:
  - Validates claims
  - Checks market data
  - Analyzes competition
  - Evaluates team
  - Assesses technology
  - Reviews financials
    ↓
Generates Memo 2 (Diligence Analysis)
    ↓
Stores in 'diligenceResults' collection:
{
  memo_1_id: "ingestionResultDocId",
  memo1_diligence: {
    investment_recommendation: "BUY" | "HOLD" | "PASS",
    confidence_score: 0.85,
    
    // Detailed Analysis Sections:
    founder_analysis: {
      background: "...",
      market_fit: "...",
      score: 9
    },
    
    market_analysis: {
      competition: "...",
      opportunity: "...",
      score: 9
    },
    
    traction_analysis: {
      validation: "...",
      growth_potential: "...",
      score: 7
    },
    
    technology_validation: {
      innovation_level: "High",
      technical_feasibility: "..."
    },
    
    problem_validation: {
      market_need: "...",
      severity: "High",
      score: 9
    },
    
    solution_analysis: {
      feasibility: "...",
      uniqueness: "...",
      score: 8
    },
    
    financial_validation: {
      revenue_model: "...",
      unit_economics: "..."
    },
    
    benchmarking_analysis: {
      competitive_advantages: "...",
      differentiation: "...",
      score: 8
    },
    
    strengths: ["Claim 1", "Claim 2", ...],
    weaknesses: ["Risk 1", "Risk 2", ...],
    key_risks: ["Risk 1", "Risk 2", ...],
    due_diligence_next_steps: ["Step 1", "Step 2", ...],
    
    investment_thesis: "Comprehensive thesis...",
    google_analytics_summary: { ... }
  },
  status: "SUCCESS",
  timestamp: "2025-10-24T14:10:53"
}
```

**What Investor Sees:**
- **Investment Recommendation**: BUY / HOLD / PASS
- **Confidence Score**: 0-10 scale
- **Detailed Scores** for each category (founder, market, traction, etc.)
- **Strengths & Weaknesses**
- **Key Risks**
- **Next Steps for Due Diligence**

---

### Step 3: Matchmaking Feature
**What Investor Sees:**
- **Investment Thesis Card**: Their preferences (industries, stages, MRR range, etc.)
- **Matched Founders**: Founders sorted by match score
- Each match shows:
  - Company & founder name
  - Match percentage
  - Stage, industry, location
  - MRR, churn rate (if available)
  - Description

**How Matching Works:**
- Queries `ingestionResults` for all pitches
- Calculates match score based on:
  - Memo 2 confidence score (if available)
  - Industry alignment with investor thesis
  - Stage alignment
  - Simple heuristic if no Memo 2

**Data Sources:**
- `ingestionResults` → Founder/company data
- `diligenceResults` → Match scores (if diligence run)
- `investorProfiles` → Investor preferences (thesis)

---

### Step 4: Ground Truth Engine (Verification)
**What Investor Sees:**
- **Verified Claims**: Claims from pitches that were verified
- **Discrepancies**: Claims that couldn't be verified or contradicted
- **Unverifiable Claims**: Claims that need manual verification

**How It Works:**
- Queries `diligenceResults` collection
- Extracts `strengths` (verified claims) from `memo1_diligence`
- Extracts `weaknesses` (discrepancies) from `memo1_diligence`
- Links back to `ingestionResults` to get founder/company names

**Data Structure:**
```
diligenceResults/{docId}
  memo1_diligence: {
    strengths: [
      "Claim 1 verified",
      "Claim 2 verified"
    ],
    weaknesses: [
      "Discrepancy found in X",
      "Risk identified in Y"
    ],
    verification_status: {
      verified_claims: [...],
      unverified_claims: [...]
    }
  }
```

---

### Step 5: AI Interviewer
**What Investor Can Do:**
1. **Schedule AI Interviews** with founders
2. View **scheduled interviews**
3. View **completed interviews** with transcripts
4. See interview scores

**Data Flow:**
- Investor schedules interview → Creates document in `scheduledInterviews` or `interviews` collection
- Interview conducted → Transcript stored
- Results displayed in app

**Data Structure:**
```
interviews/{docId} or scheduledInterviews/{docId}
{
  founder_email: "...",
  investor_email: "...",
  startup_name: "...",
  scheduled_time: Timestamp,
  status: "scheduled" | "in_progress" | "completed",
  questions: [...],
  transcript: "...",
  score: 85
}
```

---

### Step 6: AI Explainability
**What Investor Sees:**
- **Model Insights**: Type of AI, number of analyses, average scores
- **Performance Metrics**: Accuracy, confidence trends over time
- **Feature Importance**: Which factors matter most (Team, Market, Technology, etc.)
- **Recent Predictions**: Investment recommendations for recent pitches
- **Charts**: Visual representation of AI performance

**Data Source:**
- Queries `diligenceResults` collection (59 documents you have)
- Calculates:
  - Average confidence scores
  - Feature importance from strengths/weaknesses
  - Prediction trends over time
  - Accuracy metrics

**This is why you see "59 analyses"** - there are 59 documents in `diligenceResults`!

---

## 📊 FIRESTORE COLLECTIONS EXPLAINED

### Core Collections:

#### 1. **`uploads`** - File Upload Tracking
**Purpose**: Track file uploads from founders
**Structure:**
```json
{
  uploadId: string,
  founderEmail: string,
  fileName: string,
  fileType: "deck" | "video" | "audio",
  status: "uploaded" | "processing" | "completed" | "failed",
  uploadedAt: Timestamp,
  storageUrl: string
}
```
**Used By**: Founder side to show upload history

---

#### 2. **`ingestionResults`** - Memo 1 Data (Pitch Analysis)
**Purpose**: Store AI-extracted data from pitch decks (Memo 1)
**Structure:**
```json
{
  memo_1: {
    // 100+ extracted fields
    title: string,
    founder_name: array,
    industry_category: array,
    company_stage: string,
    problem: string,
    solution: string,
    traction: string,
    // ... all pitch data
  },
  original_filename: string,
  founder_email: string,
  status: "SUCCESS",
  timestamp: string,
  processing_time_seconds: number
}
```
**Used By**: 
- **Founder side**: View their pitch analysis
- **Investor side**: See all available pitches (Diligence Engine, Matchmaking)

**Your Data**: You have 5 documents here (CASHVISORY and others)

---

#### 3. **`diligenceResults`** - Memo 2 Data (Due Diligence)
**Purpose**: Store AI-generated due diligence analysis (Memo 2)
**Structure:**
```json
{
  memo_1_id: string,  // Links to ingestionResults
  memo1_diligence: {
    investment_recommendation: "BUY" | "HOLD" | "PASS",
    confidence_score: number,
    investment_thesis: string,
    
    // Detailed analysis sections:
    founder_analysis: { background, market_fit, score },
    market_analysis: { competition, opportunity, score },
    traction_analysis: { validation, growth_potential, score },
    technology_validation: { innovation_level, technical_feasibility },
    problem_validation: { market_need, severity, score },
    solution_analysis: { feasibility, uniqueness, score },
    financial_validation: { revenue_model, unit_economics },
    benchmarking_analysis: { competitive_advantages, differentiation, score },
    
    strengths: array,
    weaknesses: array,
    key_risks: array,
    due_diligence_next_steps: array,
    
    google_analytics_summary: { ... }
  },
  status: "SUCCESS",
  timestamp: string
}
```
**Used By**: 
- **Investor side**: 
  - AI Diligence Engine (shows analysis results)
  - Ground Truth Engine (extracts verified/disputed claims)
  - AI Explainability (calculates metrics from all analyses)

**Your Data**: You have **59 documents** here - that's why Explainability shows "59 analyses"!

---

#### 4. **`interviews`** or **`scheduledInterviews`** - Interview Management
**Purpose**: Store scheduled and completed AI interviews
**Structure:**
```json
{
  founder_email: string,
  investor_email: string,
  startup_name: string,
  scheduled_time: Timestamp,
  status: "scheduled" | "in_progress" | "completed",
  questions: array,
  transcript: string,
  score: number
}
```
**Used By**: AI Interviewer feature

---

#### 5. **`founderProfiles`** - Founder Information
**Purpose**: Store founder profile data
**Structure:**
```json
{
  founderEmail: string,
  name: string,
  linkedin: string,
  background: string,
  // ... profile fields
}
```
**Used By**: Matchmaking (if needed)

---

#### 6. **`investorProfiles`** - Investor Preferences
**Purpose**: Store investor investment thesis/preferences
**Structure:**
```json
{
  investorId: string,
  investmentThesis: {
    industries: array,
    stages: array,
    mrrRange: string,
    churnRate: string,
    locations: array
  }
}
```
**Used By**: Matchmaking (to calculate match scores)

---

#### 7. **`investorRecommendations`** - AI-Generated Matches
**Purpose**: Store calculated matches between investors and founders
**Structure:**
```json
{
  investorId: string,
  founderEmail: string,
  memoId: string,
  matchScore: number,
  reasons: array
}
```
**Used By**: Matchmaking (if pre-calculated)

---

### Secondary Collections (You Have):

#### 8. **`adminActivity`** - Admin actions log
**Purpose**: Track admin operations

#### 9. **`adminMemos`** - Admin-generated memos
**Purpose**: Store admin-created memos

#### 10. **`companyVectorData`** - Vector embeddings
**Purpose**: Store vector embeddings for semantic search

#### 11. **`diligenceReports`** - Detailed reports
**Purpose**: May store additional detailed reports

#### 12. **`memo1_validated`** - Validated Memo 1
**Purpose**: Store validated/corrected Memo 1 data

#### 13. **`memo3Results`** - Memo 3 Data
**Purpose**: May be additional analysis layer

#### 14. **`memos`** - General memos
**Purpose**: General memo storage

#### 15. **`platformMetrics`** - Platform analytics
**Purpose**: Track platform usage metrics

#### 16. **`qa_sessions`** - Q&A sessions
**Purpose**: Store AI Q&A interactions

#### 17. **`sentiment_analyses`** - Sentiment analysis
**Purpose**: Store sentiment analysis results

#### 18. **`transcription_sessions`** - Audio transcriptions
**Purpose**: Store transcribed audio/video pitches

#### 19. **`users`** - User accounts
**Purpose**: User authentication/profile data

---

## 🔄 COMPLETE DATA FLOW DIAGRAM

```
FOUNDER SIDE                          BACKEND                           INVESTOR SIDE
─────────────────                    ─────────                          ─────────────

1. Upload PDF       ──────────────>   Cloud Function
                                      /on_file_upload
                                         │
                                         ├─> Firebase Storage
                                         │   (File stored)
                                         │
                                         ├─> uploads/{uploadId}
                                         │   {status: "uploaded"}
                                         │
                                         ├─> AI Processing
                                         │   (Extract text, analyze)
                                         │
                                         └─> ingestionResults/{docId}
                                             {
                                               memo_1: {
                                                 title, founder_name,
                                                 industry, stage, ...
                                               }
                                             }

2. View Memo 1     <───────────────   Query ingestionResults
   (Founder sees                      Read memo_1 field
    analysis)

                                        ════════════════════════════

3. Investor Views   ──────────────>   Query ingestionResults
   Opportunities                       Get all pitches
   (Diligence Tab)                     Display list
                                        
4. Click "Run       ──────────────>   POST /trigger_diligence
   Diligence"                          AI Agent analyzes Memo 1
                                         │
                                         ├─> Validate claims
                                         ├─> Check market data
                                         ├─> Analyze competition
                                         ├─> Evaluate team
                                         └─> Generate Memo 2
                                             │
                                             └─> diligenceResults/{docId}
                                                 {
                                                   memo_1_id: "...",
                                                   memo1_diligence: {
                                                     investment_recommendation,
                                                     confidence_score,
                                                     strengths, weaknesses,
                                                     analysis sections...
                                                   }
                                                 }

5. View Analysis   <───────────────    Query diligenceResults
   Results                             Link to ingestionResults
   (See Memo 2)                        Display comprehensive analysis

6. Matchmaking     ──────────────>    Query ingestionResults
   Feature                             Query diligenceResults (for scores)
                                       Query investorProfiles (for thesis)
                                       Calculate match scores
                                       Display sorted matches

7. Ground Truth    ──────────────>    Query diligenceResults
   Engine                               Extract strengths (verified)
                                       Extract weaknesses (discrepancies)
                                       Display verification results

8. AI Explainability ────────────>    Query diligenceResults (all 59 docs)
                                       Calculate:
                                         - Avg confidence
                                         - Feature importance
                                         - Prediction trends
                                       Display metrics & charts
```

---

## 🎯 FEATURE BREAKDOWN

### **Founder Features:**

1. **Pitch Upload**
   - Upload PDF, video, or audio pitch
   - Real-time upload progress
   - Status tracking

2. **Memo 1 View**
   - See AI-extracted company data
   - Review comprehensive summary
   - Check initial flags/risks

3. **AI Feedback**
   - Ask questions about pitch
   - Get improvement recommendations
   - Receive instant AI responses

4. **Schedule Interview**
   - Book AI interviewer sessions
   - Prepare for investor interviews

---

### **Investor Features:**

1. **AI Diligence Engine**
   - **Purpose**: View all pitches and run due diligence
   - **Shows**: Company list, basic info, diligence status
   - **Action**: Click "Run Diligence" to generate Memo 2
   - **Result**: Comprehensive investment analysis

2. **Matchmaking**
   - **Purpose**: Find founders that match investment thesis
   - **Shows**: Sorted list by match score
   - **Factors**: Industry, stage, MRR, investor preferences

3. **Ground Truth Engine**
   - **Purpose**: Verify claims made in pitches
   - **Shows**: Verified claims, discrepancies, unverifiable claims
   - **Source**: Extracts from Memo 2 strengths/weaknesses

4. **AI Interviewer**
   - **Purpose**: Schedule and conduct AI interviews
   - **Shows**: Scheduled, active, completed interviews
   - **Features**: Transcripts, scores, export options

5. **AI Explainability**
   - **Purpose**: Understand AI decision-making
   - **Shows**: 
     - Model performance metrics
     - Feature importance (what factors matter)
     - Prediction accuracy over time
     - Confidence trends

---

## 🔍 WHY YOU'RE SEEING EMPTY SCREENS

### Current Status:
- ✅ **AI Explainability**: Shows "59 analyses" (working - has data)
- ❌ **AI Diligence Engine**: Empty (should show 5 pitches)
- ❌ **Matchmaking**: Empty (should show 5 founders)
- ❌ **Ground Truth Engine**: Empty (needs Memo 2 data)
- ❌ **AI Interviewer**: Empty (no scheduled interviews)

### The Issue:
Your `ingestionResults` has **5 documents** but they're not showing because:
1. Code might not be handling array fields correctly (FIXED ✅)
2. Timestamp parsing might fail (FIXED ✅)
3. UI might not be rendering (need to check logs)

### Next Steps:
1. Check terminal logs when opening Diligence tab
2. Look for the diagnostic output
3. Verify if data is being loaded but not displayed, or not loaded at all

---

## 📝 SUMMARY

**Founder Journey:**
```
Upload PDF → AI Extracts Data (Memo 1) → Founder Reviews Analysis
```

**Investor Journey:**
```
View All Pitches → Run Diligence (Memo 2) → Get Investment Recommendation
    ↓
Matchmaking: Find Best Fits
    ↓
Ground Truth: Verify Claims
    ↓
AI Explainability: Understand AI Decisions
```

**Data Flow:**
```
uploads → ingestionResults (Memo 1) → diligenceResults (Memo 2)
                                              ↓
                                    All Investor Features
```

This is a complete AI-powered investment platform that automates due diligence and helps investors make data-driven decisions! 🚀

