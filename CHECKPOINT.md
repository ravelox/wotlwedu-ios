# Checkpoint

Last updated: 2026-03-24
Repo: `wotlwedu-ios`
Current version: `0.2.11`

## Current Focus

This repo has been updated to expose sign-in method visibility and audit/activity data in the SwiftUI client, matching the backend hardening slice.

## Implemented State

- Google sign-in and invite-aware onboarding already existed.
- Deferred Google-link confirmation now shows a clearer expired-token message in the view model.
- The profile flow now includes:
  - linked sign-in method visibility
  - unlink actions for removable providers
  - recent account activity
  - organization audit activity for users with access
  - richer invite metadata display
  - refined support/admin audit presentation with outcome badges and summary metrics

## Key Files For This Baseline

- [WotlweduIOS/Models/WotlweduModels.swift](/Users/dkelly/Projects/wotlwedu/wotlwedu-ios/WotlweduIOS/Models/WotlweduModels.swift)
- [WotlweduIOS/Services/WotlweduDomainService.swift](/Users/dkelly/Projects/wotlwedu/wotlwedu-ios/WotlweduIOS/Services/WotlweduDomainService.swift)
- [WotlweduIOS/ViewModels/AppViewModel.swift](/Users/dkelly/Projects/wotlwedu/wotlwedu-ios/WotlweduIOS/ViewModels/AppViewModel.swift)
- [WotlweduIOS/Views/Flows/Profile/ProfileView.swift](/Users/dkelly/Projects/wotlwedu/wotlwedu-ios/WotlweduIOS/Views/Flows/Profile/ProfileView.swift)
- [README.md](/Users/dkelly/Projects/wotlwedu/wotlwedu-ios/README.md)

## Verification Already Run

Passed:

```bash
xcodebuild build -project WotlweduIOS.xcodeproj -scheme WotlweduIOS -sdk iphonesimulator -destination 'platform=iOS Simulator,id=11422201-BA7E-4AC2-9311-EAC93D6C29BD'
```

## Notes

- Apple sign-in remains intentionally out of scope unless explicitly requested.
- Real Google login still depends on the configured iOS Google client settings and URL scheme.

## Likely Next Actions

1. Keep parity with backend auth/invite/audit behavior.
2. Expand beyond the profile-based support snapshot only if the iOS client needs a dedicated operational console.
