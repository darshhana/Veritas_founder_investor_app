# 🚀 VERITAS - AI-Powered Investment Platform

**Version 2.0** - Complete Backend Integration | Production Ready

A comprehensive Flutter mobile application that revolutionizes the fundraising and investment process by leveraging AI to automate due diligence, match founders with investors, and provide intelligent investment insights.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Tech Stack](#tech-stack)
5. [Installation & Setup](#installation--setup)
6. [Backend Integration](#backend-integration)
7. [Firestore Collections](#firestore-collections)
8. [API Endpoints](#api-endpoints)
9. [Data Models](#data-models)
10. [Project Structure](#project-structure)
11. [User Flows](#user-flows)
12. [Build & Deployment](#build--deployment)
13. [Configuration](#configuration)
14. [Contributing](#contributing)

---

## 🎯 Overview

VERITAS is an AI-powered investment platform that connects founders raising capital with investors seeking opportunities. The platform automates the entire investment analysis workflow using advanced AI agents, providing:

- **For Founders**: AI co-pilot to build compelling pitches, get feedback, and connect with investors
- **For Investors**: AI analyst to automate due diligence, verify claims, and make data-driven investment decisions

### Key Capabilities

- **Automated Pitch Analysis**: AI extracts and analyzes pitch decks (PDF, video, audio)
- **Intelligent Due Diligence**: AI-powered validation and risk assessment
- **Smart Matchmaking**: AI matches founders with investors based on preferences
- **Ground Truth Verification**: Automated claim verification and discrepancy detection
- **Explainable AI**: Transparent AI decision-making with detailed insights
- **Interview Automation**: AI-powered interview scheduling and transcript analysis

---

## ✨ Features

### 👨‍💼 Founder Experience (AI Co-Pilot)

#### 1. **Unified Data Hub**
- Real-time KPIs and performance metrics
- Pitch analytics dashboard
- Quick access to AI Feedback and Interview Scheduling
- Visual insights into pitch performance

#### 2. **Pitch Ingestion**
- Upload pitch decks (PDF, video, audio formats)
- Real-time upload progress tracking
- Automatic status updates (uploaded → processing → completed)
- Memo generation tracking (Memo 1 - Founders Checklist)
- View analysis results directly in-app

#### 3. **AI Feedback**
- **Get Recommendations**: AI-powered feedback on pitch improvements
- **Ask Questions**: Interactive Q&A with AI about your pitch
- Clean, formatted responses without markdown artifacts
- Real-time chat interface

#### 4. **Interview Scheduling**
- Schedule AI interviewer sessions with investors
- Calendar integration
- Interview preparation tools
- View scheduled and completed interviews

#### 5. **Investor Rooms**
- Secure spaces for sharing information
- Document management
- Investor collaboration tools

#### 6. **Memo Display**
- View Memo 1 (Founders Checklist) - Extracted pitch data
- Comprehensive company information display
- AI-generated summary analysis

---

### 💼 Investor Experience (AI Analyst)

#### 1. **AI Diligence Engine**
- View all pitch decks from all founders
- Run AI-powered due diligence analysis
- Generate Memo 2 (Diligence Analysis)
- Investment recommendations (BUY/HOLD/PASS)
- Confidence scoring (0-100%)
- Detailed analysis sections:
  - Founder Analysis
  - Market Analysis
  - Traction Analysis
  - Problem Validation
  - Solution Analysis
  - Financial Validation
  - Technology Validation
  - Benchmarking Analysis

#### 2. **Matchmaking**
- AI-powered founder recommendations
- Investment thesis management (editable preferences)
- Match scoring based on:
  - Industry alignment
  - Stage preference
  - MRR/churn criteria
  - Geographic location
- Connect/Pass functionality
- Real-time match updates

#### 3. **Ground Truth Engine**
- Claim verification system
- Discrepancy detection
- Verified claims vs. unverified claims
- Unique concerns tracking across all pitches
- Company name extraction and linking

#### 4. **AI Interviewer**
- Schedule interviews with founders
- View all interviews (scheduled, active, completed)
- Interview transcript viewing
- Transcript export (saves as .txt file)
- Interview scoring and analytics

#### 5. **AI Explainability**
- Model performance metrics
- Feature importance analysis
- Prediction accuracy trends
- Confidence level tracking
- Recent predictions with recommendations
- Sector analysis
- Bias detection
- Decision logic visualization

---

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                       │
│  ┌──────────────┐              ┌──────────────┐            │
│  │   Founder    │              │   Investor   │            │
│  │  Dashboard   │              │  Dashboard   │            │
│  └──────────────┘              └──────────────┘            │
│         │                              │                    │
│         └──────────────┬───────────────┘                    │
│                        │                                     │
│            ┌───────────▼──────────┐                         │
│            │   Service Layer     │                         │
│            │  - API Service      │                         │
│            │  - Firestore Service│                         │
│            │  - Storage Service  │                         │
│            └───────────┬──────────┘                         │
└────────────────────────┼───────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
    │ Firebase │    │ Firebase │    │  Cloud  │
    │  Auth    │    │ Firestore │   │Functions│
    └──────────┘    └──────────┘    └─────────┘
                            │               │
                            │               │
                    ┌───────▼───────────────▼───────┐
                    │      AI Backend Agents         │
                    │  - Intake Curation Agent       │
                    │  - Diligence Agent            │
                    │  - Feedback Agent             │
                    │  - Matchmaking Agent          │
                    │  - Interview Coordinator      │
                    └───────────────────────────────┘
```

### Data Flow

```
1. FILE UPLOAD
   Founder uploads PDF
        ↓
   Firebase Storage (file stored)
        ↓
   POST /on_file_upload (Cloud Function)
        ↓
   uploads/{uploadId} collection (status tracking)
        ↓
   AI Processing (Intake Curation Agent)
        ↓
   ingestionResults/{docId} (Memo 1 generated)

2. DILIGENCE ANALYSIS
   Investor clicks "Run Diligence"
        ↓
   POST /trigger_diligence
        ↓
   AI Analysis (Diligence Agent)
        ↓
   diligenceResults/{docId} (Memo 2 generated)
   OR
   diligenceReports/{docId} (Enhanced format)

3. MATCHMAKING
   Investor views matches
        ↓
   Query ingestionResults + diligenceResults
        ↓
   Calculate match scores
        ↓
   Display sorted recommendations

4. AI FEEDBACK
   Founder requests feedback
        ↓
   POST /ai_feedback
        ↓
   AI Analysis (Feedback Agent)
        ↓
   Return recommendations/questions
```

---

## 💻 Tech Stack

### Frontend
- **Framework**: Flutter 3.8.1+
- **Language**: Dart 3.8.1+
- **State Management**: Provider 6.1.2
- **UI**: Material Design 3
- **Charts**: fl_chart 0.65.0
- **File Handling**: file_picker 8.0.0+
- **HTTP Client**: Dio 5.4.0, http 1.2.0

### Backend Services
- **Authentication**: Firebase Auth 5.3.0+
- **Database**: Cloud Firestore 5.4.0+
- **Storage**: Firebase Storage 12.3.0+
- **Cloud Functions**: Google Cloud Functions
- **API Base URL**: `https://asia-south1-veritas-472301.cloudfunctions.net`

### AI & Processing
- **AI Agents**: 7 specialized agents
  - Intake Curation Agent (Memo 1 generation)
  - Diligence Agent (Memo 2 generation)
  - Feedback Agent (Recommendations & Q&A)
  - Matchmaking Agent (Investor-founder matching)
  - Interview Coordinator Agent
  - Ground Truth Agent (Claim verification)
  - Explainability Agent (Model insights)

### Development Tools
- **Linting**: flutter_lints 5.0.0
- **Icons**: flutter_launcher_icons 0.13.1
- **Notifications**: fluttertoast 8.2.6

---

## 🚀 Installation & Setup

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code with Flutter extensions
- Git
- Firebase project with:
  - Authentication (Email/Password enabled)
  - Firestore Database
  - Cloud Storage
  - Cloud Functions deployed

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/veritas-founder-investor-app.git
cd veritas-founder-investor-app
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Firebase Configuration

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create new project or use existing
   - Enable Authentication with Email/Password
   - Create Firestore Database (start in production mode)
   - Enable Cloud Storage

2. **Android Configuration**
   ```bash
   # Download google-services.json from Firebase Console
   # Place it in: android/app/google-services.json
   ```

3. **iOS Configuration** (if deploying to iOS)
   ```bash
   # Download GoogleService-Info.plist from Firebase Console
   # Place it in: ios/Runner/GoogleService-Info.plist
   ```

4. **Generate Firebase Options**
   ```bash
   # Install FlutterFire CLI if not installed
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart`

### Step 4: Configure App Logo

1. Place your logo at: `assets/logos/app_logo.png`
   - Size: 512x512 or 1024x1024 pixels
   - Format: PNG with transparent background
   - Name exactly: `app_logo.png`

2. Generate app icons:
   ```bash
   dart run flutter_launcher_icons
   ```

### Step 5: Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

---

## 🔌 Backend Integration

### Cloud Functions Base URL

```dart
static const String baseUrl = 'https://asia-south1-veritas-472301.cloudfunctions.net';
```

### Authentication

The app uses Firebase Authentication:
- Email/Password registration and login
- User sessions managed by Firebase Auth
- User type (Founder/Investor) stored in user profile

### API Integration

All backend communication is handled through `ApiService` (`lib/services/api_service.dart`):

- **Timeout Configuration**: 
  - Standard requests: 30 seconds
  - AI requests (recommendations, questions): 60s connect, 90s receive
- **Error Handling**: Comprehensive error messages with retry options
- **Logging**: Request/response logging for debugging

---

## 📊 Firestore Collections

### Primary Collections

#### 1. **`uploads`**
**Purpose**: Track file uploads from founders
```json
{
  "id": "uploadId",
  "founderEmail": "founder@example.com",
  "fileName": "pitch.pdf",
  "originalName": "My Pitch Deck.pdf",
  "fileType": "deck",
  "status": "uploaded" | "processing" | "completed" | "error",
  "uploadedAt": Timestamp,
  "processedAt": Timestamp?,
  "downloadUrl": "https://...",
  "memoId": "memoId?"
}
```

#### 2. **`ingestionResults`**
**Purpose**: Store Memo 1 (AI-extracted pitch data)
```json
{
  "id": "docId",
  "memo_1": {
    "title": "Company Name",
    "founder_name": ["Founder 1", "Founder 2"],
    "industry_category": ["FinTech", "SaaS"],
    "company_stage": "Seed",
    "problem": "...",
    "solution": "...",
    "traction": "...",
    "market_size": "...",
    "business_model": "...",
    "team": "...",
    "summary_analysis": "4-5 paragraph comprehensive summary"
  },
  "original_filename": "pitch.pdf",
  "founder_email": "founder@example.com",
  "upload_id": "uploadId?",
  "status": "SUCCESS",
  "timestamp": "2025-11-01T06:54:39",
  "processing_time_seconds": 71.38
}
```

#### 3. **`diligenceResults`** (Legacy Format)
**Purpose**: Store Memo 2 (Due Diligence Analysis) - Older format
```json
{
  "id": "docId",
  "memo_1_id": "ingestionResultDocId",
  "memo1_diligence": {
    "investment_recommendation": "BUY" | "HOLD" | "PASS",
    "confidence_score": 8,
    "founder_analysis": {...},
    "market_analysis": {...},
    "investment_thesis": "..."
  },
  "status": "SUCCESS",
  "timestamp": "2025-10-24T14:10:53"
}
```

#### 4. **`diligenceReports`** (Preferred Format)
**Purpose**: Store Memo 2 (Due Diligence Analysis) - Enhanced format
```json
{
  "id": "docId",
  "memo_1_id": "ingestionResultDocId",
  "memo1_diligence": {
    "executive_summary": {
      "overall_dd_score": 5,
      "recommendation": "CONDITIONAL",
      "key_findings": "...",
      "red_flags_count": 5
    },
    "founder_credibility_assessment": {
      "credibility_rating": "Fair",
      "overall_score": 5,
      "dimensions": {...}
    },
    "investment_recommendation": "HOLD",
    "investment_thesis": "...",
    "key_risks": [...],
    "overall_dd_score_recommendation": {...}
  },
  "status": "SUCCESS",
  "timestamp": "2025-11-01T04:51:03"
}
```

**Note**: The app prioritizes `diligenceReports` over `diligenceResults` when both exist.

#### 5. **`interviews`** / **`scheduledInterviews`**
**Purpose**: Store AI interview sessions
```json
{
  "id": "interviewId",
  "founder_email": "founder@example.com",
  "founderName": "John Doe",
  "investor_email": "investor@example.com",
  "investorEmail": "investor@example.com",
  "startup_name": "Startup Name",
  "startupName": "Startup Name",
  "scheduled_time": Timestamp,
  "scheduledAt": Timestamp,
  "status": "scheduled" | "in_progress" | "completed",
  "questions": [...],
  "responses": [...],
  "transcript": "...",
  "summary": {
    "confidenceScore": 85
  },
  "score": 85
}
```

#### 6. **`founderProfiles`**
**Purpose**: Store founder profile information
```json
{
  "founderEmail": "founder@example.com",
  "name": "Founder Name",
  "linkedin": "https://...",
  "background": "..."
}
```

#### 7. **`investorProfiles`**
**Purpose**: Store investor preferences/thesis
```json
{
  "investorId": "investorId",
  "investmentThesis": {
    "industries": ["FinTech", "HealthTech"],
    "stages": ["Seed", "Series A"],
    "mrrRange": "$10K-$100K",
    "churnRate": "<5%",
    "locations": ["USA", "India"]
  }
}
```

#### 8. **`investorRecommendations`**
**Purpose**: Store pre-calculated matches
```json
{
  "investorId": "investorId",
  "founderEmail": "founder@example.com",
  "memoId": "memoId",
  "matchScore": 85,
  "reasons": [...]
}
```

### Secondary Collections

- `adminActivity` - Admin operations log
- `adminMemos` - Admin-generated memos
- `companyVectorData` - Vector embeddings for semantic search
- `memo1_validated` - Validated/corrected Memo 1
- `memo3Results` - Additional analysis layer
- `memos` - General memo storage
- `platformMetrics` - Platform usage analytics
- `qa_sessions` - Q&A interaction logs
- `sentiment_analyses` - Sentiment analysis results
- `transcription_sessions` - Audio/video transcriptions
- `users` - User account data

---

## 🌐 API Endpoints

### Base URL
```
https://asia-south1-veritas-472301.cloudfunctions.net
```

### File Upload & Processing

#### 1. Upload File
```http
POST /on_file_upload
Content-Type: multipart/form-data

Body:
- file: (File) - Pitch deck (PDF, MP4, MP3)
- file_type: "deck" | "video" | "audio"
- founder_email: "founder@example.com"
- original_name: "my-pitch.pdf"

Response:
{
  "success": true,
  "data": {
    "uploadId": "...",
    "message": "File uploaded successfully"
  }
}
```

#### 2. Check Memo Status
```http
GET /check_memo?fileName=my-pitch.pdf

Response:
{
  "success": true,
  "data": {
    "exists": true,
    "memoId": "..."
  }
}
```

### AI Analysis & Feedback

#### 3. Get AI Recommendations
```http
POST /ai_feedback
Content-Type: application/json

Body:
{
  "founder_email": "founder@example.com",
  "action": "recommendations"
}

Response:
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "category": "Investor Appeal",
        "priority": "High",
        "title": "...",
        "description": "...",
        "action_items": [...]
      }
    ]
  }
}
```

#### 4. Ask AI Question
```http
POST /ai_feedback
Content-Type: application/json

Body:
{
  "founder_email": "founder@example.com",
  "action": "question",
  "question": "How can I improve my market analysis?"
}

Response:
{
  "success": true,
  "data": {
    "answer": "Based on your pitch..."
  }
}
```

### Due Diligence

#### 5. Trigger Diligence
```http
POST /trigger_diligence
Content-Type: application/json

Body:
{
  "memo_1_id": "ingestionResultDocId",
  "ga_property_id": "optional",
  "linkedin_url": "optional"
}

Response:
{
  "success": true,
  "data": {
    "diligenceId": "...",
    "status": "processing"
  }
}
```

#### 6. Run Diligence (RAG-based)
```http
POST /run_diligence
Content-Type: application/json

Body:
{
  "company_id": "companyId",
  "investor_email": "investor@example.com"
}
```

#### 7. Query Diligence
```http
POST /query_diligence
Content-Type: application/json

Body:
{
  "company_id": "companyId",
  "question": "What are the key risks?"
}
```

### Interview Scheduling

#### 8. Schedule Interview
```http
POST /schedule_ai_interview
Content-Type: application/json

Body:
{
  "founder_email": "founder@example.com",
  "investor_email": "investor@example.com",
  "startup_name": "Startup Name",
  "company_id": "companyId",
  "calendar_id": "optional"
}

Response:
{
  "success": true,
  "data": {
    "interviewId": "...",
    "scheduledEventLink": "https://calendar.google.com/..."
  }
}
```

---

## 📦 Data Models

### UploadModel
```dart
class UploadModel {
  final String id;
  final String fileName;
  final String originalName;
  final String fileType;
  final String founderEmail;
  final String status;
  final String? downloadUrl;
  final String? memoId;
  final DateTime uploadedAt;
  final DateTime? processedAt;
}
```

### Memo1Model
```dart
class Memo1Model {
  final String id;
  final String? title;
  final List<String> founderName;
  final List<String> industryCategory;
  final String? companyStage;
  final String? problem;
  final String? solution;
  final String? traction;
  final String? marketSize;
  final String? businessModel;
  final String? team;
  final String? summaryAnalysis;
  // ... 100+ additional fields
}
```

### Memo2Model
```dart
class Memo2Model {
  final String id;
  final String? memo1Id;
  final String? investmentRecommendation;
  final double? confidenceScore;
  final AnalysisSection? founderAnalysis;
  final AnalysisSection? marketAnalysis;
  final AnalysisSection? tractionAnalysis;
  final AnalysisSection? problemValidation;
  final AnalysisSection? solutionAnalysis;
  final List<String>? keyRisks;
  final String? investmentThesis;
  // ... additional analysis sections
}

class AnalysisSection {
  final String? background;
  final String? marketFit;
  final double? score;
  // ... section-specific fields
}
```

---

## 📁 Project Structure

```
founder_investor_app/
├── lib/
│   ├── main.dart                    # App entry point, routing
│   ├── firebase_options.dart        # Generated Firebase config
│   │
│   ├── models/                      # Data models
│   │   ├── user_model.dart
│   │   ├── founder_model.dart
│   │   ├── investor_model.dart
│   │   ├── memo1_model.dart         # Memo 1 (Founders Checklist)
│   │   ├── memo2_model.dart         # Memo 2 (Diligence Analysis)
│   │   └── upload_model.dart        # File upload tracking
│   │
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── founder_provider.dart    # Founder data
│   │   └── investor_provider.dart   # Investor data
│   │
│   ├── screens/
│   │   ├── auth/                    # Authentication
│   │   │   ├── dual_login_screen.dart    # Main login (Founder/Investor)
│   │   │   ├── founder_login_screen.dart
│   │   │   └── investor_login_screen.dart
│   │   │
│   │   ├── founder_dashboard/       # Founder features
│   │   │   ├── founder_dashboard_screen.dart
│   │   │   ├── unified_data_hub.dart         # Main dashboard
│   │   │   ├── pitch_ingestion.dart           # Upload pitches
│   │   │   ├── memo_display_screen.dart      # View Memo 1
│   │   │   ├── ai_feedback_screen.dart       # AI feedback & Q&A
│   │   │   ├── interview_scheduling_screen.dart
│   │   │   └── investor_rooms.dart
│   │   │
│   │   └── investor_dashboard/       # Investor features
│   │       ├── investor_dashboard_screen.dart
│   │       ├── ai_diligence_engine.dart      # Run diligence
│   │       ├── matchmaking.dart              # Find matches
│   │       ├── ground_truth_engine.dart      # Verify claims
│   │       ├── ai_interviewer.dart           # Schedule interviews
│   │       └── ai_explainability.dart        # AI insights
│   │
│   ├── services/                    # Business logic
│   │   ├── api_service.dart         # Cloud Functions API calls
│   │   ├── firestore_service.dart   # Firestore operations
│   │   ├── storage_service.dart     # Firebase Storage
│   │   └── firebase_auth_services.dart
│   │
│   ├── widgets/                     # Reusable components
│   │   ├── custom_button.dart
│   │   ├── custom_card.dart
│   │   └── custom_text_field.dart
│   │
│   └── theme/
│       └── app_theme.dart           # App theming
│
├── assets/
│   ├── logos/
│   │   └── app_logo.png             # App logo (512x512 or larger)
│   └── images/                      # Other images
│
├── android/                         # Android configuration
│   ├── app/
│   │   ├── build.gradle
│   │   ├── google-services.json     # Firebase config (not in repo)
│   │   └── src/main/res/            # App icons (auto-generated)
│   └── gradle.properties
│
├── ios/                             # iOS configuration
│   └── Runner/
│       ├── GoogleService-Info.plist # Firebase config (not in repo)
│       └── Assets.xcassets/        # App icons
│
├── pubspec.yaml                     # Dependencies & config
└── README.md                        # This file
```

---

## 🔄 User Flows

### Founder Journey

```
1. REGISTRATION/LOGIN
   └─> Email/Password auth
       └─> Founder Dashboard

2. UPLOAD PITCH
   └─> Pitch Ingestion Screen
       └─> Select PDF/video/audio
           └─> Upload to Firebase Storage
               └─> POST /on_file_upload
                   └─> Status: "processing"
                       └─> AI Processing (Intake Curation Agent)
                           └─> Memo 1 generated in ingestionResults
                               └─> Status: "completed"

3. VIEW ANALYSIS
   └─> View Memo 1
       └─> See extracted company data
           └─> Review AI summary
               └─> Check initial flags

4. GET FEEDBACK
   └─> AI Feedback Screen
       └─> Get Recommendations
           └─> OR Ask Questions
               └─> Receive AI-powered insights

5. SCHEDULE INTERVIEW
   └─> Interview Scheduling Screen
       └─> Enter investor email, startup name
           └─> POST /schedule_ai_interview
               └─> Calendar event created
                   └─> Interview link received
```

### Investor Journey

```
1. LOGIN
   └─> Email/Password auth (Investor type)
       └─> Investor Dashboard

2. VIEW OPPORTUNITIES
   └─> AI Diligence Engine
       └─> See all pitches from all founders
           └─> View Memo 1 for each pitch
               └─> Click "Run Diligence"
                   └─> POST /trigger_diligence
                       └─> Memo 2 generated in diligenceResults/diligenceReports
                           └─> View comprehensive analysis
                               └─> See investment recommendation
                                   └─> Review detailed scores

3. FIND MATCHES
   └─> Matchmaking Screen
       └─> View investment thesis
           └─> Edit preferences
               └─> See matched founders (sorted by score)
                   └─> Connect or Pass on opportunities

4. VERIFY CLAIMS
   └─> Ground Truth Engine
       └─> View verified claims
           └─> Check discrepancies
               └─> See unique concerns

5. SCHEDULE INTERVIEWS
   └─> AI Interviewer
       └─> Schedule interview
           └─> View all interviews
               └─> View transcripts
                   └─> Export transcripts

6. UNDERSTAND AI DECISIONS
   └─> AI Explainability
       └─> View model performance
           └─> See feature importance
               └─> Review prediction trends
```

---

## 🏗️ Build & Deployment

### Development Build

```bash
# Debug build
flutter run

# Release build
flutter run --release
```

### Android Build

#### APK (for direct installation)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Build (macOS only)

```bash
flutter build ios --release
# Then open Xcode to archive and upload to App Store
```

### App Icon Generation

```bash
# After adding logo to assets/logos/app_logo.png
dart run flutter_launcher_icons
```

This automatically generates all required icon sizes for:
- Android (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (all required sizes)
- Adaptive icons

---

## ⚙️ Configuration

### Firebase Setup

1. **Authentication**
   - Enable Email/Password provider
   - Configure authorized domains

2. **Firestore**
   - Create database
   - Set up security rules (production rules recommended)
   - Create composite indexes if needed:
     ```javascript
     // Example index for uploads
     collectionGroup: 'uploads'
     fields: [founderEmail (ASC), uploadedAt (DESC)]
     ```

3. **Storage**
   - Create storage bucket
   - Set up security rules for file uploads
   - Configure CORS if needed

4. **Cloud Functions**
   - Deploy all required functions
   - Ensure functions are in region: `asia-south1`
   - Verify API endpoints are accessible

### Environment Variables

Currently, API base URL is hardcoded in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://asia-south1-veritas-472301.cloudfunctions.net';
```

For different environments, consider using:
- `flutter_dotenv` package
- Or environment-specific configuration files

### Gradle Configuration

**File**: `android/gradle.properties`
```properties
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m
android.useAndroidX=true
android.enableJetifier=true
kotlin.incremental=false
org.gradle.caching=false
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. **"No memo found" after upload**
- **Solution**: Wait for AI processing (30-120 seconds)
- Check `ingestionResults` collection in Firestore
- Verify file upload was successful
- Check backend logs for processing errors

#### 2. **Diligence status stuck at "Pending"**
- **Solution**: Check if `diligenceResults` or `diligenceReports` collection has the memo
- App checks both collections automatically
- Verify `memo_1_id` links correctly to `ingestionResults` document

#### 3. **RenderFlex overflow errors**
- **Fixed**: All overflow issues resolved with:
  - `Expanded` and `Flexible` widgets
  - `maxLines` and `TextOverflow.ellipsis`
  - Proper constraints

#### 4. **API timeout errors**
- **Solution**: Timeouts increased for AI requests (60s connect, 90s receive)
- Check network connectivity
- Verify backend Cloud Functions are running

#### 5. **Logo not showing**
- **Solution**: 
  - Ensure file is at `assets/logos/app_logo.png`
  - Run `flutter pub get`
  - Hot restart (not hot reload)

---

## 🔒 Security Considerations

### Firebase Security Rules

**Firestore Rules** (Example - adjust for your needs):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Uploads - founders can only see their own
    match /uploads/{uploadId} {
      allow read, write: if request.auth != null && 
        resource.data.founderEmail == request.auth.token.email;
    }
    
    // Ingestion Results - founders see their own, investors see all
    match /ingestionResults/{docId} {
      allow read: if request.auth != null;
      allow write: if false; // Only backend can write
    }
    
    // Diligence Results - investors can read all
    match /diligenceResults/{docId} {
      allow read: if request.auth != null;
      allow write: if false; // Only backend can write
    }
  }
}
```

**Storage Rules** (Example):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /uploads/{userId}/{fileName} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

### API Security

- Currently using Firebase Auth (email/password)
- Consider implementing API key authentication for Cloud Functions
- Add rate limiting on backend
- Validate all inputs on both client and server

---

## 📊 Performance Optimization

### Implemented Optimizations

1. **In-Memory Sorting**: Avoids composite index requirements
2. **Stream Builders**: Real-time updates without polling
3. **Lazy Loading**: Data loaded on demand
4. **Image Optimization**: Proper image sizing and caching
5. **Periodic Memo Checks**: 30-second intervals for processing uploads

### Recommendations

1. **Pagination**: Implement pagination for large lists
2. **Caching**: Cache frequently accessed data
3. **Image Compression**: Compress uploaded images
4. **Offline Support**: Consider offline-first architecture
5. **Background Sync**: Sync data in background

---

## 🧪 Testing

### Manual Testing Checklist

- [x] Founder registration and login
- [x] Investor registration and login
- [x] File upload (PDF, video, audio)
- [x] Memo 1 generation and display
- [x] Memo 2 (diligence) generation
- [x] AI feedback (recommendations)
- [x] AI Q&A functionality
- [x] Interview scheduling
- [x] Matchmaking display and editing
- [x] Ground truth verification
- [x] AI explainability metrics
- [x] Transcript viewing and export

### Test Data

See `TEST_PITCH_DECK.md` for a comprehensive test pitch deck.

---

## 📈 Version History

### Version 2.0 (Current)
- ✅ Complete backend integration
- ✅ Real-time Firestore synchronization
- ✅ All AI features functional
- ✅ Logo and app icon support
- ✅ Enhanced UI with overflow fixes
- ✅ Improved error handling
- ✅ Periodic memo checking
- ✅ Transcript export functionality

### Version 1.0
- Initial prototype
- Basic UI implementation
- Mock data

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Style

- Follow Dart/Flutter style guide
- Use `flutter_lints` for linting
- Write meaningful commit messages
- Add comments for complex logic

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Developer, Design, Backend**: Darshana Ojha

---

## 📞 Support

For support, email [ojhadarshana30@gmail.com] or create an issue in this repository.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI guidelines
- Open source community for various packages

---

## 📚 Additional Documentation

- **Complete App Flow**: See `COMPLETE_APP_FLOW_EXPLANATION.md` for detailed user journey documentation

---

**Built with ❤️ using Flutter and Firebase**

**Status**: ✅ Production Ready - Version 2.0
