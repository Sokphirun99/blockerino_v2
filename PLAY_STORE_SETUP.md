# Play Store Publishing Checklist

## 🔐 CRITICAL: Release Signing (REQUIRED)

### Step 1: Create Release Keystore
```bash
keytool -genkey -v -keystore ~/blockerino-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias blockerino-key
```

**Important:** Save the passwords securely! You'll need:
- Keystore password
- Key alias: `blockerino-key`
- Key password

### Step 2: Create key.properties
Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=blockerino-key
storeFile=/Users/phirun/blockerino-release-key.jks
```

⚠️ **NEVER commit key.properties to git!**

### Step 3: Update android/app/build.gradle.kts

Replace the buildTypes section:

```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

## 📱 App Metadata Updates

### 1. Update App Name (AndroidManifest.xml)
Current: `blockerino_v2` → Change to: `Blockerino`

```xml
<application
    android:label="Blockerino"
```

### 2. Update Version Numbers (pubspec.yaml)
```yaml
version: 1.0.0+1
# Format: major.minor.patch+buildNumber
```

### 3. Update Application ID
Current: `com.blockerinov2`
Recommended: `com.blockerino.game` or `com.yourcompany.blockerino`

## 🎨 Store Listing Requirements

### Required Assets:
- [ ] App Icon (512x512 PNG)
- [ ] Feature Graphic (1024x500 PNG)
- [ ] Screenshots (at least 2, max 8):
  - Phone: 320px - 3840px
  - Tablet (optional): 320px - 3840px
- [ ] Privacy Policy URL
- [ ] App Description (short & full)

### App Description Template:

**Short Description (80 chars):**
"Block-breaking puzzle game with multiple modes, daily challenges & story mode"

**Full Description:**
```
🎮 Blockerino - Master the Art of Block Puzzle!

Drop colorful pieces on the 8×8 board and clear lines to score big! 
Challenge yourself across multiple game modes:

🌟 FEATURES:
• Story Mode - 30 levels with increasing difficulty
• Daily Challenges - New puzzle every day
• Classic Mode - Endless puzzle fun
• Chaos Mode - Fast-paced action
• Power-ups - Hammer, Random Clear, Color Bomb & more
• Leaderboards - Compete globally
• Offline Play - No internet required

🎯 GAMEPLAY:
• Drag & drop pieces onto the board
• Clear lines horizontally or vertically
• Build combos for bonus points
• Use power-ups strategically
• Unlock new levels and earn coins

Perfect for quick breaks or long sessions!
Download now and start your block-clearing adventure!
```

## 🔒 Privacy & Compliance

### Privacy Policy (REQUIRED)
You're using Firebase, so you MUST have a privacy policy covering:
- [ ] Data collection (Analytics, Crashlytics)
- [ ] Firebase Authentication (anonymous & Google Sign-In)
- [ ] Cloud Firestore (scores, progress)
- [ ] User rights (data deletion)

### Permissions Review
Check `AndroidManifest.xml` for unnecessary permissions.

## 🏗️ Build Commands

### Test Release Build:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (RECOMMENDED for Play Store):
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Test on Device:
```bash
flutter install --release
```

## ✅ Pre-Submission Testing

- [ ] Test on multiple screen sizes (phone & tablet)
- [ ] Test all game modes
- [ ] Test in-app purchases (if applicable)
- [ ] Test Firebase features (sign-in, leaderboards)
- [ ] Test offline functionality
- [ ] Check memory usage
- [ ] Verify no debug logs in release
- [ ] Test back button behavior
- [ ] Test app icon & splash screen

## 📋 Play Console Setup

1. Create app in Play Console
2. Upload app bundle (AAB)
3. Fill in store listing
4. Upload screenshots & graphics
5. Set content rating (PEGI/ESRB)
6. Add privacy policy URL
7. Select countries for distribution
8. Set pricing (Free/Paid)
9. Review & publish to internal testing first
10. After testing → Production

## 🐛 Known Issues to Monitor:

- Java 11 vs 17 issue (fixed in gradle.properties)
- Firebase anonymous auth on iOS (handled with try-catch)
- UI overflows (all fixed)

## 🚀 Post-Launch

- Monitor Crashlytics for crashes
- Check Analytics for user behavior
- Respond to user reviews
- Plan updates based on feedback
