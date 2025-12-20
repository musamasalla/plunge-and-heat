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

### 3. App Groups (Required for Watch & Widgets)
- [ ] iOS Target: Signing & Capabilities → + Capability → App Groups
- [ ] Add: `group.com.plungeheat.app`
- [ ] Watch Target: Repeat the same steps
- [ ] Widget Target: Repeat the same steps

### 4. CloudKit (Optional - for iCloud sync)
To enable iCloud sync:
- [ ] In Xcode: Add iCloud capability
- [ ] Check "CloudKit"
- [ ] Create container: `iCloud.com.plungeheat.app`
- [ ] In CoreDataManager.swift: Change `NSPersistentContainer` to `NSPersistentCloudKitContainer`
- [ ] Uncomment the cloudKitContainerOptions code

### 5. App Store Connect
- [ ] Create app listing at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- [ ] Add app name: "Plunge & Heat"
- [ ] Add app description
- [ ] Upload iPhone screenshots (6.7" and 5.5" sizes)
- [ ] Upload Apple Watch screenshots (if submitting Watch app)
- [ ] Upload 1024x1024 app icon
- [ ] Set pricing (Free with IAP)

### 6. StoreKit Products
Configure in App Store Connect:
- [ ] `com.plungeheat.premium.monthly` - Monthly subscription
- [ ] `com.plungeheat.premium.yearly` - Yearly subscription

### 7. Final Build & Submit
- [ ] Product → Archive in Xcode
- [ ] Upload to App Store Connect
- [ ] Submit for Review

---

## URLs to Update After Publishing
In `SettingsView.swift`, update:
- `rateApp()` - Add real App Store ID
- `shareApp()` - Add real App Store URL

---

## Testing Without Developer Account

### Test iOS App:
1. Select iOS scheme → iPhone simulator → Run (▶)

### Test Watch App:
1. Select "Plunge & Heat Watch App" scheme
2. Select Apple Watch simulator (paired with iPhone)
3. Run (▶) - Both Watch and iPhone simulators will launch

> Note: App Groups won't work in simulator without Developer Account.
> Data sync between iPhone and Watch works only on real devices.
