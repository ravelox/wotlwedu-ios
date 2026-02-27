# AGENTS.md (wotlwedu-ios)

Local instructions for Codex-style agents working in this repository.

## Repo Summary
- App: iOS client for the wotlwedu platform
- Language/tooling: Swift + Xcode project structure

## Key Areas
- App source: `WotlweduIOS/`
- Unit tests: `WotlweduIOSTests/`
- Integration tests: `WotlweduIOSIntegrationTests/`
- Xcode project: `WotlweduIOS.xcodeproj`
- Project metadata/template: `project.yml`

## Backend Contract Notes
- Backend APIs are organization/workgroup aware.
- Category assignment is user-scoped.
- Auth is JWT-based with optional 2FA flows.

## Repo Hygiene
- Do not commit derived data, secrets, provisioning profiles, or local machine files.
- Keep API route/field assumptions aligned with `wotlwedu-backend`.
