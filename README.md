# wotlwedu-ios

SwiftUI client for the wotlwedu platform, mirroring the flows in the `wotlwedu-minimal` Angular app (auth, notifications, friends, preferences, groups, categories, items, images, lists, elections, voting, roles, users, profile/2FA).

## Structure
- `WotlweduIOSApp.swift` – app entry and environment wiring.
- `Models/` – API DTOs and config models.
- `Services/` – API client, auth, domain services, media upload, config loader, session store.
- `ViewModels/` – app state, paging helpers, voting/notification view models.
- `Views/Flows/` – SwiftUI screens grouped by flow (Auth, Main, Manage, Voting, Profile, Notifications).
- `Resources/` – assets, launch screen, `wotlwedu-config.json` (API settings), `project.yml` for xcodegen.

## Prerequisites
- Xcode 15+ (iOS 16 target).
- xcodegen (`brew install xcodegen`).
- Backend API reachable (configure URL below).

## Setup
1. Generate the Xcode project:
   ```bash
   cd wotlwedu-ios
   xcodegen generate
   ```
2. Configure API endpoint and defaults in `WotlweduIOS/Resources/wotlwedu-config.json` (or use the `.template`):
   ```json
   {
     "apiUrl": "https://api.wotlwedu.com:9876/",
     "appVersion": "0.2.0",
     "defaultStartPage": "home",
     "errorCountdown": 30
   }
   ```
3. Open and build:
   ```bash
   open WotlweduIOS.xcodeproj
   ```
   Select the `WotlweduIOS` scheme and run on a simulator or device.

## Notes
- If `xcodebuild` complains about simulator plug-ins, run `xcodebuild -runFirstLaunch` or repair Xcode toolchain before building.
- Image upload uses photo library access; the `NSPhotoLibraryUsageDescription` is included in `Info.plist`.

## Parity with wotlwedu-minimal
- CRUD/listing for categories, groups, items, images (with upload), lists (with item linking), elections (with start/stop), roles/capabilities, users, preferences, friends.
- Notifications listing with unread badge; server status on the home dashboard.
- Voting flow for upcoming votes; profile page with 2FA bootstrap/verify and logout.

## AI-assisted features
- Home dashboard includes AI actions backed by authenticated `/ai/*` API routes.
- Supports notification digest, smart defaults, prompt-based list suggestions, text categorization/moderation, assistant query, election summary/recommendations, participant suggestions, and image metadata description.
