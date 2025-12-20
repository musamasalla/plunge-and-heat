# Plunge & Heat - App Store Submission Checklist

## Before Submission

### 1. Apple Developer Program
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Wait for approval (usually 24-48 hours)

### 2. Xcode Signing
- [ ] Open Xcode → Signing & Capabilities
- [ ] Select your Team (should show your developer account)
- [ ] Click "Try Again" to resolve provisioning
- [ ] Ensure "Automatically manage signing" is checked

### 3. App Store Connect
- [ ] Create app listing at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- [ ] Add app name: "Plunge & Heat"
- [ ] Add app description
- [ ] Upload screenshots (6.7" and 5.5" sizes)
- [ ] Upload 1024x1024 app icon
- [ ] Set pricing (Free with IAP or Paid)
- [ ] Configure In-App Purchases for premium subscription

### 4. CloudKit (Optional)
To enable iCloud sync:
- [ ] In Xcode: Add iCloud capability
- [ ] Check "CloudKit"
- [ ] Create container: `iCloud.com.plungeheat.app`
- [ ] In CoreDataManager.swift: Change back to `NSPersistentCloudKitContainer`

### 5. StoreKit Products
Configure in App Store Connect:
- [ ] `com.plungeheat.premium.monthly` - Monthly subscription
- [ ] `com.plungeheat.premium.yearly` - Yearly subscription

### 6. Final Build
- [ ] Product → Archive in Xcode
- [ ] Upload to App Store Connect
- [ ] Submit for Review

---

## URLs to Update After Publishing
In `SettingsView.swift`, update:
- `rateApp()` - Add real App Store ID
- `shareApp()` - Add real App Store URL
