# VERITAS - Release Guide

## 🔒 Security Notes

**NEVER commit these files to Git:**
- `android/veritas-release-key.keystore`
- `android/key.properties`
- Any files containing passwords

## 📱 APK Release Process

### 1. Build Release APK
```bash
flutter build apk --release
```

### 2. APK Location
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 47.6MB
- **Status**: ✅ Signed and ready for distribution

### 3. Free Hosting Options

#### Option A: GitHub Releases
1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Upload `app-release.apk`
4. Get direct download link

#### Option B: Firebase Hosting
1. Upload APK to Firebase Hosting
2. Get direct download URL
3. Embed in your website

#### Option C: Netlify
1. Upload APK to Netlify
2. Get direct download URL
3. Embed in your website

## 🌐 Website Integration

### HTML Download Button
```html
<a href="YOUR_APK_DOWNLOAD_LINK" download="VERITAS.apk">
    <button>Download VERITAS App</button>
</a>
```

### Mobile-Friendly Download
- Works on all Android devices
- Direct APK download
- No app store required

## 🔄 Future Updates

### Building New Versions
1. Update version in `pubspec.yaml`
2. Run `flutter build apk --release`
3. Upload new APK to your hosting
4. Update download link

### Keystore Security
- **Keep keystore file safe** - you'll need it for all updates
- **Store passwords securely**
- **Never share keystore files**

## 📋 Release Checklist

- [ ] APK built and signed
- [ ] Keystore files secured (not in Git)
- [ ] APK uploaded to hosting
- [ ] Download link created
- [ ] Website integration complete
- [ ] Test download on mobile device

## 🎯 Next Steps

1. **Choose hosting method** (GitHub Releases recommended)
2. **Upload APK** to chosen platform
3. **Get download link**
4. **Embed in your website**
5. **Test on mobile device**

Your app is ready for distribution! 🚀
