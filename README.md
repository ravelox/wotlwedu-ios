# wotlwedu-ios

*wotlwedu* (What'll We Do?) helps groups decide by voting on curated lists (food, places, activities, media, etc.). In the platform, these polls are called **elections**.

This repository contains the SwiftUI iOS client for the wotlwedu ecosystem, mirroring core flows from `wotlwedu-minimal` (auth, notifications, friends, preferences, groups, categories, items, images, lists, elections, voting, roles, users, profile/2FA).

## Structure
- `WotlweduIOSApp.swift` – app entry and environment wiring.
- `Models/` – API DTOs and config models.
- `Services/` – API client, auth, domain services, media upload, config loader, session store.
- `ViewModels/` – app state, paging helpers, voting/notification view models.
- `Views/Flows/` – SwiftUI screens grouped by flow (Auth, Main, Manage, Voting, Profile, Notifications).
- `Resources/` – assets, launch screen, `wotlwedu-config.json` (API settings).
- `project.yml` (repo root) – XcodeGen spec for regenerating `WotlweduIOS.xcodeproj`.

## Prerequisites
- Xcode 15+ (iOS 16 target).
- xcodegen (`brew install xcodegen`) only when regenerating the project.
- Backend API reachable (configure URL below).

## Setup
1. Regenerate the Xcode project (optional, only needed after changing `project.yml`):
   ```bash
   cd wotlwedu-ios
   xcodegen generate
   ```
2. Configure API endpoint and defaults in `WotlweduIOS/Resources/wotlwedu-config.json` (or use the `.template`):
   ```json
   {
     "apiUrl": "https://api.wotlwedu.com:9876/",
     "appVersion": "0.2.2",
     "defaultStartPage": "home",
     "errorCountdown": 30,
     "allowInsecureCertificates": true
   }
   ```
3. Open and build:
   ```bash
   open WotlweduIOS.xcodeproj
   ```
   Select the `WotlweduIOS` scheme and run on a simulator or device.

## Test
Run tests from Xcode or via CLI:
```bash
xcodebuild test -project WotlweduIOS.xcodeproj -scheme WotlweduIOS -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Notes
- If `xcodebuild` complains about simulator plug-ins, run `xcodebuild -runFirstLaunch` or repair Xcode toolchain before building.
- Image upload uses photo library access; the `NSPhotoLibraryUsageDescription` is included in `Info.plist`.
- `allowInsecureCertificates` is intended for local/dev environments and should be `false` for production.

## Parity with wotlwedu-minimal
- CRUD/listing for categories, groups, items, images (with upload), lists (with item linking), elections (with start/stop), roles/capabilities, users, preferences, friends.
- Notifications listing with unread badge; server status on the home dashboard.
- Voting flow for upcoming votes; profile page with 2FA bootstrap/verify and logout.

## Tenant/admin concepts
- Backend now includes tenancy with organizations and organization-scoped workgroups.
- Auth/user payloads may include: `systemAdmin`, `organizationAdmin`, `workgroupAdmin`, `organizationId`, and `adminWorkgroupId`.
- UI/admin flows should enforce these scopes when exposing management actions.
