# Changelog

## [0.2.22] - 2026-03-28
- Add backend poll-tutorial payload models and service methods for `/tutorial/poll` and `/tutorial/poll/start`.
- Surface tutorial progress on the home dashboard and inside the list, audience-group, and poll management flows.
- Pre-fill tutorial names and bound list/group selections so the iOS app walks a new user through creating a genuine poll and viewing its stats.
- Add skip, resume, and restart controls for the signed-in user, plus an admin tutorial re-enable/restart action in the profile flow.

## [0.2.11] - 2026-03-24
- Refine the profile sign-in and audit sections with reusable support-style rows and outcome badges.
- Add a compact organization audit snapshot in the SwiftUI profile flow for admin users.
- Keep the iOS profile support presentation aligned with the backend auth/invite/audit slice without introducing a separate console.

## [0.2.8] - 2026-03-24
- Add Google Sign-In to the iOS auth flow using the official `GoogleSignIn-iOS` Swift Package Manager packages.
- Add invite-aware onboarding with backend `GET /login/invite/:token` lookup and `POST /login/google` completion.
- Add organization-admin invite management in the profile flow with create, list, resend, revoke, and status filtering.
- Add Google OAuth build settings and URL-scheme wiring in `project.yml` and `Info.plist`.

## [0.2.7] - 2026-03-09
- Harden auth/session token restoration and API client handling for malformed persisted values.
- Align registration and password-reset client behavior with backend token validation hardening.
- Bump bundled app/config metadata references to `0.2.7`.

## [0.2.6] - 2026-03-01
- Group item, image, list, election, group, and workgroup management views into collapsible category sections.
- Preserve category label casing in list rendering by displaying category names exactly as returned by the backend.
- Align bundled config metadata and README examples to app version `0.2.6`.

## [0.2.5] - 2026-02-28
- Add richer notification handling with optimistic unread-count updates, per-type primary actions, and preview/accept flows for shared items, images, and lists.
- Update the iOS notification client to use paged inbox fetches and numeric notification status IDs compatible with the backend notification API.
- Improve notification-related model decoding so numeric status ids and notification object references round-trip safely.

## [0.2.4] - 2026-02-28
- Add category selection to iOS list and image create/edit flows.
- Persist image and list `categoryId` values through the iOS domain/media services.
- Include category details in iOS list/item fetches so edit forms preload existing category assignments.

## [0.2.3] - 2026-02-28
- Add a login-screen `Settings` tab to override `apiUrl`, `defaultStartPage`, `errorCountdown`, and `allowInsecureCertificates`.
- Persist login settings overrides locally and rebuild services immediately after saving.
- Apply `defaultStartPage` on entry to the main shell and use `errorCountdown` to auto-dismiss the global error alert.

## [0.2.2] - 2026-02-14
- Bump app/config version metadata to `0.2.2`.
- Add organization/workgroup management UI and workgroup-scoped management flows for items/images/lists/elections.

## [0.2.1] - 2026-02-13
- Bump app/config version metadata to `0.2.1`.
- Document backend tenancy/admin concepts for client compatibility (`organization`, `workgroup`, `systemAdmin`, `organizationAdmin`, `workgroupAdmin`).

## [0.2.0] - 2026-02-12
- Added `/ai/*` endpoint support in `WotlweduDomainService` for recommendations, summaries, suggestions, moderation, categorization, digest/defaults, image description, and assistant query.
- Added typed AI response models and integrated AI tools into the Home dashboard for interactive usage.

## [0.1.0] - 2025-11-23
- Initial SwiftUI app scaffolding mirroring wotlwedu-minimal flows (auth, dashboard, CRUD for categories/groups/items/images/lists/elections/roles/users/preferences/friends, voting, notifications, profile/2FA).
- Added unit tests for API client, session store, and config loader; integration tests for app bootstrap and domain service.
