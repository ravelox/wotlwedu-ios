# WotlweduClient (iOS + iPadOS, SwiftUI)

A SwiftUI client for the wotlwedu-backend API.

## Highlights
- iOS/iPadOS universal (iOS 16+), SwiftUI, async/await URLSession
- JWT auth (Keychain), Login/Register/Profile
- Elections list/detail, vote, create election, add item, optional image uploads
- **In-app Server Settings** (gear on Login) to set Base URL + Timeout before login
- XcodeGen project and optional OpenAPI codegen scaffolding

## Quick start
```bash
brew install xcodegen
make open
```
Set your `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM`, and update Base URL in **Server Settings** (Login screen).

## Generate a typed client from `docs/openapi.yaml`
```bash
make generate-api
make open
```
This writes Swift sources to `Generated/WotlweduAPI/` using `Tools/openapi-swift-config.yaml`.

## Notes
- ATS is strict by default. Use HTTPS for your API Base URL or add temporary ATS exceptions for local HTTP.
- Image endpoints default to `/elections/{id}/image` and `/elections/{id}/items/{itemId}/image`. Adjust in `Endpoints.swift` to match your backend/spec.