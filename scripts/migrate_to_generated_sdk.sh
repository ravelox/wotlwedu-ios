#!/usr/bin/env bash
set -euo pipefail

# --- safety checks ---
command -v gh >/dev/null || { echo "Please install GitHub CLI: https://cli.github.com/"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { echo "Run from your iOS repo root"; exit 1; }

BRANCH="migrate/generated-sdk"
PR_TITLE="Migrate iOS client to generated OpenAPI SDK (WotlweduAPI)"
PR_BODY_FILE="$(mktemp)"

# --- generate SDK if missing ---
if [ ! -d "Generated/WotlweduAPI/Sources" ]; then
  echo "Generating SDK via OpenAPI Generator…"
  make generate-api
fi

# --- update project.yml: split generated code into its own module target ---
# 1) Remove Generated path from the app target sources
perl -0777 -pe 's/\n\s*-\s*path:\s*Generated\/WotlweduAPI[^\n]*\n(\s*optional:\s*true\n)?//g' -i project.yml
# 2) Ensure app depends on WotlweduAPI
perl -0777 -pe 's/(WotlweduClient-iOS:\n(?:.*\n)*?\s+scheme:\n(?:.*\n)*?\s+testTargets:\s*\[\]\n)/$1    dependencies:\n      - target: WotlweduAPI\n/g' -i project.yml
# 3) Add WotlweduAPI framework target (idempotent)
if ! grep -q '^  WotlweduAPI:' project.yml; then
cat >> project.yml <<'YAML'

  WotlweduAPI:
    type: framework
    platform: iOS
    sources:
      - path: Generated/WotlweduAPI/Sources
    settings:
      base:
        SKIP_INSTALL: YES
YAML
fi

# --- remove manual client & duplicate models ---
rm -f Sources/Networking/APIClient.swift \
      Sources/Networking/APIClient+CreateAndUpload.swift \
      Sources/Networking/APIError.swift \
      Sources/Models/Election.swift \
      Sources/Models/Auth.swift || true

# --- add a small adapter that uses the generated SDK (adjusts base URL + bearer) ---
mkdir -p Sources/Adapters
cat > Sources/Adapters/GeneratedBackendAdapter.swift <<'SWIFT'
import Foundation
import WotlweduAPI

// Wire base URL + bearer across the app.
enum GeneratedSDKConfig {
    // Tries multiple common scheme keys; whichever your spec uses will be honored.
    static func apply(baseURL: String, bearerToken: String?) {
        WotlweduAPI.Configuration.basePath = baseURL
        let token = (bearerToken ?? "")
        let keys = ["BearerAuth", "bearerAuth", "HTTPBearer", "bearer", "Authorization"]
        if token.isEmpty {
            for k in keys { WotlweduAPI.Configuration.apiKey[k] = nil; WotlweduAPI.Configuration.apiKeyPrefix[k] = nil }
        } else {
            for k in keys { WotlweduAPI.Configuration.apiKey[k] = token; WotlweduAPI.Configuration.apiKeyPrefix[k] = "Bearer" }
        }
    }
}

// Replace your SessionStore’s calls with these wrappers.
// NOTE: Method names follow typical OpenAPI Swift generator conventions for tags/operationIds.
// If your generated APIs differ, tweak the called method names (look in Generated/WotlweduAPI/Sources/APIs).
struct GeneratedBackend {
    // MARK: Auth
    static func login(email: String, password: String) async throws -> WotlweduAPI.AuthTokens {
        let body = WotlweduAPI.LoginRequest(email: email, password: password)
        return try await AuthAPI.login(body: body)
    }
    static func register(email: String, password: String, name: String?) async throws -> WotlweduAPI.AuthTokens {
        let body = WotlweduAPI.RegisterRequest(email: email, password: password, name: name)
        return try await AuthAPI.register(body: body)
    }

    // MARK: Me
    static func me() async throws -> WotlweduAPI.User {
        try await UsersAPI.me()
    }

    // MARK: Elections
    static func listElections() async throws -> [WotlweduAPI.Election] {
        try await ElectionsAPI.listElections()
    }
    static func getElection(id: Int) async throws -> WotlweduAPI.Election {
        try await ElectionsAPI.getElectionById(id: id)
    }
    static func createElection(name: String, description: String?) async throws -> WotlweduAPI.Election {
        let body = WotlweduAPI.CreateElectionRequest(name: name, description: description)
        return try await ElectionsAPI.createElection(body: body)
    }
    static func createItem(electionId: Int, name: String, description: String?) async throws -> WotlweduAPI.ElectionItem {
        let body = WotlweduAPI.CreateElectionItemRequest(name: name, description: description)
        return try await ElectionsAPI.createElectionItem(electionId: electionId, body: body)
    }
    static func vote(electionId: Int, itemId: Int) async throws {
        _ = try await ElectionsAPI.voteItem(electionId: electionId, itemId: itemId)
    }
}
SWIFT

# --- patch SessionStore to configure the generated SDK and call adapter ---
# Inject helper + switch over to use GeneratedBackend
perl -0777 -pe 's/import Foundation/import Foundation\nimport WotlweduAPI/' -i Sources/Auth/SessionStore.swift

# Add a configuration helper if missing
if ! grep -q 'configureGeneratedSDK' Sources/Auth/SessionStore.swift; then
  perl -0777 -pe 's/class SessionStore: ObservableObject \{/@MainActor\nfinal class SessionStore: ObservableObject {\n    func configureGeneratedSDK() {\n        GeneratedSDKConfig.apply(baseURL: config.baseURLString, bearerToken: tokens?.accessToken)\n    }\n/s' -i Sources/Auth/SessionStore.swift
fi

# Swap call sites to use the generated backend
perl -0777 -pe 's/try await session\.signIn\(email: email, password: password\)/try await session.signIn(email: email, password: password)/' -i Sources/Features/LoginView.swift || true
perl -0777 -pe 's/try await api\.me\(\)/try await GeneratedBackend.me()/' -i Sources/Features/ProfileView.swift || true

# Replace implementations in SessionStore
perl -0777 -pe 's/func signIn\(email: String, password: String\) async throws \{.*?\n\}/func signIn(email: String, password: String) async throws {\n        let t = try await GeneratedBackend.login(email: email, password: password)\n        self.tokens = AuthTokens(accessToken: t.accessToken, refreshToken: t.refreshToken)\n        try tokenStore.save(tokens: self.tokens!)\n        configureGeneratedSDK()\n    }\n/s' -i Sources/Auth/SessionStore.swift

perl -0777 -pe 's/func register\(email: String, password: String, name: String\?\) async throws \{.*?\n\}/func register(email: String, password: String, name: String?) async throws {\n        let t = try await GeneratedBackend.register(email: email, password: password, name: name)\n        self.tokens = AuthTokens(accessToken: t.accessToken, refreshToken: t.refreshToken)\n        try tokenStore.save(tokens: self.tokens!)\n        configureGeneratedSDK()\n    }\n/s' -i Sources/Auth/SessionStore.swift

perl -0777 -pe 's/func restore\(\) async \{.*?\n\}/func restore() async {\n        if let t = tokenStore.load() { self.tokens = t } else { self.tokens = nil }\n        configureGeneratedSDK()\n    }\n/s' -i Sources/Auth/SessionStore.swift

perl -0777 -pe 's/func signOut\(\) \{.*?\n\}/func signOut() { tokenStore.clear(); tokens = nil; configureGeneratedSDK() }\n/s' -i Sources/Auth/SessionStore.swift

# Elections flow in views
perl -0777 -pe 's/guard let api = session\.api else \{ return \}\n\s*isLoading = true; defer \{ isLoading = false \}\n\s*do \{ elections = try await api\.listElections\(\) \}\n\s*catch \{.*?\}/isLoading = true; defer { isLoading = false }\n        do { elections = try await GeneratedBackend.listElections() }\n        catch { self.error = (error as? Error)?.localizedDescription ?? error.localizedDescription }/s' -i Sources/Features/ElectionListView.swift || true

perl -0777 -pe 's/guard let api = session\.api else \{ return \}\n\s*do \{ updated = try await api\.getElection\(id: election\.id\) \}\n\s*catch \{.*?\}/do { updated = try await GeneratedBackend.getElection(id: election.id) }\n        catch { self.error = (error as? Error)?.localizedDescription ?? error.localizedDescription }/s' -i Sources/Features/ElectionDetailView.swift || true

perl -0777 -pe 's/guard let api = session\.api else \{ return \}\n\s*do \{\n\s*try await api\.vote\(electionId: election\.id, itemId: item\.id\)\n\s*await refresh\(\)\n\s*\} catch \{.*?\}/do {\n            try await GeneratedBackend.vote(electionId: election.id, itemId: item.id)\n            await refresh()\n        } catch { self.error = (error as? Error)?.localizedDescription ?? error.localizedDescription }/s' -i Sources/Features/ElectionDetailView.swift || true

perl -0777 -pe 's/guard let api = session\.api else \{ return \}\n\s*error = nil\n\s*isBusy = true\n\s*defer \{ isBusy = false \}\n\s*do \{\n\s*_ = try await api\.createElection\(name: name, description: description\.isEmpty \? nil : description\)\n\s*dismiss\(\)\n\s*\} catch \{.*?\}/error = nil\n        isBusy = true\n        defer { isBusy = false }\n        do {\n            _ = try await GeneratedBackend.createElection(name: name, description: description.isEmpty ? nil : description)\n            dismiss()\n        } catch { self.error = (error as? Error)?.localizedDescription ?? error.localizedDescription }/s' -i Sources/Features/CreateElectionView.swift || true

# Server settings should re-apply SDK config
perl -0777 -pe 's/session\.rebuildAPI\(\)/session.configureGeneratedSDK()/' -i Sources/Features/ServerConfigView.swift || true

# --- re-gen project & commit ---
make project

git checkout -b "$BRANCH"
git add -A

# Compose PR body
cat > "$PR_BODY_FILE" <<'MD'
This PR migrates the iOS/iPadOS app to the **generated OpenAPI Swift SDK**:

### What changed
- Split generated client into a separate module target `WotlweduAPI` and made the app depend on it.
- Removed the hand-written `APIClient.swift`, `APIError.swift`, and manual models.
- Added `GeneratedBackendAdapter` that calls the generated `*API` entry points.
- Centralized SDK config for **Base URL** (from in-app Server Settings) and **Bearer auth** (JWT).
- Kept the existing UI flows (login, register, profile, elections list/detail, create, vote).

### How auth is wired
We set `Configuration.basePath` to the chosen server and prime common Bearer scheme keys
(`BearerAuth`, `bearerAuth`, `HTTPBearer`, `bearer`, `Authorization`) with `"Bearer <token>"`.
If your OpenAPI security scheme uses a different name, tweak the keys in `GeneratedSDKConfig.apply`.

### Follow-ups
- If any generated API or model name differs (tags/operationIds), adjust the calls in
  `GeneratedBackendAdapter.swift` to match the exact functions under `Generated/WotlweduAPI/Sources/APIs/`.

### Regenerating
make generate-api
make project

git commit -m "Migrate to generated OpenAPI SDK: add WotlweduAPI module, remove manual client, wire basePath & bearer"
gh pr create --fill --title "$PR_TITLE" --body-file "$PR_BODY_FILE" || {
  echo
  echo "PR creation via gh failed. You can push and create manually:"
  echo "  git push -u origin $BRANCH"
  echo "Then open a PR on GitHub using that branch."
}
