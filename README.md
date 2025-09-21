# 🚀 VERITAS - Founder Investor Platform

A Flutter mobile application that provides a comprehensive platform for founders and investors to connect, manage deals, and streamline the investment process.

## 📱 Features

### 🏢 **The Founder Experience (The 'Co-Pilot')**
- **Unified Data Hub**: Real-time KPIs and performance metrics
- **Pitch Ingestion**: Upload and manage pitch materials (PDFs, videos, audio)
- **Investor Rooms**: Secure spaces for sharing information with investors
- **Dashboard**: Comprehensive overview of your startup's progress

### 💼 **The Investor Experience (The 'AI Analyst')**
- **AI Diligence Engine**: Automated due diligence reports
- **Matchmaking**: AI-powered founder recommendations
- **Ground Truth Engine**: Verification of founder claims
- **AI Interviewer**: Automated interview system
- **AI Explainability**: Insights into AI decision-making

## ⚠️ **Current Status: PROTOTYPE**

This is a **prototype version** with the following characteristics:
- ✅ **Frontend**: Fully functional Flutter UI
- ✅ **Authentication**: Email/password login system
- ⚠️ **Backend**: Hardcoded mock data (no real backend integration)
- ⚠️ **Data**: All data is simulated for demonstration purposes
- ⚠️ **AI Features**: UI mockups (not connected to real AI services)

## 🛠️ **Tech Stack**

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **Authentication**: Firebase Auth
- **Charts**: fl_chart
- **File Handling**: file_picker
- **UI Components**: Material Design 3

## 📋 **Prerequisites**

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Git
- Firebase project (for authentication)

## 🚀 **Installation & Setup**

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/veritas-founder-investor-app.git
cd veritas-founder-investor-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication with Email/Password
3. Download `google-services.json` and place it in `android/app/`
4. Download `GoogleService-Info.plist` and place it in `ios/Runner/`
5. Run `flutterfire configure` to generate `firebase_options.dart`

### 4. Run the App
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## 📱 **Build Instructions**

### Android APK
```bash
flutter build apk --release
```
APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (macOS only)
```bash
flutter build ios --release
```

## 🔧 **Project Structure**

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── founder_model.dart
│   └── investor_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── founder_provider.dart
│   └── investor_provider.dart
├── screens/                  # UI screens
│   ├── auth/                 # Authentication screens
│   ├── founder_dashboard/    # Founder-specific screens
│   └── investor_dashboard/   # Investor-specific screens
├── services/                 # Business logic
│   ├── firebase_auth_services.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── widgets/                  # Reusable UI components
└── theme/                    # App theming
    └── app_theme.dart
```

## 🎨 **UI/UX Features**

- **Responsive Design**: Optimized for mobile devices
- **Material Design 3**: Modern, clean interface
- **Dark/Light Theme**: Consistent theming throughout
- **Custom Components**: Reusable UI elements
- **Smooth Animations**: Enhanced user experience

## 🔐 **Authentication**

Currently supports:
- ✅ Email/Password registration
- ✅ Email/Password login
- ✅ User session management
- ⚠️ Google Sign-In (disabled due to configuration issues)

## 📊 **Mock Data**

The app currently uses hardcoded data for:
- User profiles
- KPI metrics
- Investor information
- Pitch materials
- AI-generated reports

## 🚀 **Deployment**

### Firebase App Distribution
1. Build release APK: `flutter build apk --release`
2. Upload to Firebase App Distribution
3. Add testers via email
4. Share download link

### Google Play Store (Future)
- App is ready for Play Store submission
- Requires backend integration first

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 **Development Roadmap**

### Phase 1: Backend Integration (Next)
- [ ] Real Firebase Firestore integration
- [ ] File upload to Firebase Storage
- [ ] Real user data management
- [ ] API integration for AI services

### Phase 2: AI Features
- [ ] Real AI diligence engine
- [ ] Actual matchmaking algorithms
- [ ] Ground truth verification system
- [ ] AI interviewer implementation

### Phase 3: Advanced Features
- [ ] Real-time notifications
- [ ] Advanced analytics
- [ ] Payment integration (Stripe)
- [ ] Video calling integration

## 🐛 **Known Issues**

- Google Sign-In temporarily disabled
- Firestore service unavailable (using mock data)
- Some UI overflow issues on smaller screens (being fixed)

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 **Team**

- **Developer**: [Your Name]
- **Design**: [Designer Name]
- **Backend**: [Backend Developer Name]

## 📞 **Support**

For support, email [your-email@example.com] or create an issue in this repository.

## 🙏 **Acknowledgments**

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI guidelines
- Open source community for various packages

---

**Note**: This is a prototype version. For production use, backend integration and real AI services are required.