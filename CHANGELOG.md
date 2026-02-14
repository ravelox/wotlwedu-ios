# Changelog

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
