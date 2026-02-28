# Changelog

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
