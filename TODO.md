# TODO

## Supabase Setup
- [x] Create a Supabase project via the dashboard or MCP
- [x] Move secrets to `.env.json` (gitignored) and use `--dart-define-from-file` at build time
- [ ] Regenerate Supabase anon key (old key was exposed in git history)

## Netlify Deployment (Web)
- [ ] Run `npx netlify login` to authenticate
- [ ] Run `npx netlify init` to link to a Netlify site
- [ ] Run `npx netlify deploy --prod` to push the build

## Apple App Store Submission

### Account & Legal
- [ ] Enroll in the Apple Developer Program ($99/year) at https://developer.apple.com
- [ ] Create a **Privacy Policy** and host it at a public URL (required by Apple)
- [ ] Create a **Support URL** (can be a simple webpage, email link, or GitHub repo)

### Xcode & Signing
- [ ] Open `ios/Runner.xcworkspace` in Xcode and set your Development Team
- [ ] Register your **Bundle Identifier** (e.g. `com.yourname.hooks`) on the Apple Developer portal
- [ ] Configure signing & provisioning profiles in Xcode (Signing & Capabilities tab)
- [ ] Create an **App Store distribution provisioning profile** (not just development)

### App Content & Branding
- [ ] Replace default app icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with your branding (1024x1024 required)
- [ ] Customize the launch screen in `ios/Runner/Base.lproj/LaunchScreen.storyboard` (currently default Flutter)
- [ ] Choose an **App Category** (e.g. Social Networking, Lifestyle) for App Store Connect

### Privacy & Compliance
- [ ] Review `ios/Runner/PrivacyInfo.xcprivacy` — add any additional API declarations if you add new dependencies
- [ ] Update `NSPrivacyCollectedDataTypes` in PrivacyInfo.xcprivacy if you collect user data (email, name, photos, etc.)
- [ ] Answer the **Export Compliance** question in App Store Connect — Supabase uses HTTPS/TLS so you must declare "Yes" for encryption, but it qualifies for the encryption exemption (standard HTTPS)
- [ ] Add `ITSAppUsesNonExemptEncryption = NO` to Info.plist if only using standard HTTPS (avoids the question on every upload)
- [ ] Complete the **Age Rating** questionnaire in App Store Connect
- [ ] Fill out the **App Privacy** section in App Store Connect (what data you collect and how)

### App Store Connect Listing
- [ ] Create the app in App Store Connect
- [ ] Prepare screenshots: **6.7" iPhone** (1290x2796) and **5.5" iPhone** (1242x2208) — minimum required sizes
- [ ] Write app description, subtitle (30 chars), keywords (100 chars)
- [ ] Set the Privacy Policy URL and Support URL
- [ ] Add at least one preview/screenshot per required device size

### Build & Submit
- [ ] Test on a **physical iPhone** before submitting (not just simulator)
- [ ] Build archive: `flutter build ipa --release`
- [ ] Upload via Xcode Organizer or `xcrun altool --upload-app`
- [ ] Submit for App Review

## Environment Issues
- [ ] Free up disk space — currently only 300MB free, need several GB for Android/iOS builds
- [ ] Install full Xcode from the App Store (only CLI tools are installed — required for iOS builds)
- [x] Fixed Flutter JDK config (was pointing to missing Android Studio JDK, now uses Corretto 17)

## Notes
- Dart package is named `hooks_app` (not `hooks`) to avoid conflict with an existing pub.dev package
- Project folder remains `Hooks/`
- Netlify CLI is accessible via `npx netlify`
- `android/key.properties` is gitignored — never commit your keystore passwords
- iOS Privacy Manifest (`PrivacyInfo.xcprivacy`) already declares UserDefaults and System Boot Time APIs
- **Secrets workflow**: all keys live in `.env.json` (gitignored). Build with `flutter run --dart-define-from-file=.env.json`. See `.env.json.example` for required keys.
