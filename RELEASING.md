# Releasing Gauss

Gauss releases are built, signed, notarized, and published by GitHub Actions.
There is no manual upload step and no Supabase storage — binaries are hosted on
GitHub Releases and the Sparkle appcast is served from the `gh-pages` branch via
GitHub Pages.

## Prerequisites (one-time setup)

These GitHub repository secrets must be configured in
**Settings → Secrets and variables → Actions**:

| Secret | Value |
|--------|-------|
| `BUILD_CERTIFICATE_BASE64` | base64 of your exported Developer ID Application `.p12` (see below) |
| `P12_PASSWORD` | the password you set when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | any string; used as the temp-keychain password in CI |
| `APPLE_ID` | your Apple ID email |
| `APPLE_TEAM_ID` | 10-char Team ID (e.g. `T247WTJV77`) |
| `NOTARIZE_PASSWORD` | app-specific password from appleid.apple.com |
| `SPARKLE_PRIVATE_KEY` | EdDSA private key for Sparkle update signing (can be shared with Capso) |

The EdDSA **public** key is committed in `Gauss/Info.plist` → `SUPublicEDKey`
(this is safe to commit; only the private half is a secret).

### Exporting the Developer ID certificate

```bash
# In Keychain Access: export "Developer ID Application: <name>" as a .p12
base64 -i DeveloperID.p12 -o DeveloperID.p12.b64
# Copy the contents of DeveloperID.p12.b64 into the BUILD_CERTIFICATE_BASE64 secret
```

### gh-pages branch

A `gh-pages` branch must exist (GitHub Pages serves `appcast.xml` from it).
Create it once:

```bash
git checkout --orphan gh-pages
git rm -rf .
echo "Gauss appcast" > README.md
git add README.md
git commit -m "Initialize gh-pages"
git push origin gh-pages
# Then enable Pages in repo Settings → Pages → Source: gh-pages branch
```

## Release a New Version

1. Bump the version in `project.yml`:
   - `MARKETING_VERSION` (e.g. `"1.1.0"`) — user-facing version
   - `CURRENT_PROJECT_VERSION` (e.g. `3`) — build number, must increment every release
2. Commit and push:
   ```bash
   git add project.yml
   git commit -m "chore: bump version to 1.1.0"
   git push
   ```
3. Tag and push the tag:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
4. The **Build & Release** workflow runs automatically. It:
   - builds a universal (arm64 + x86_64) app
   - re-signs the Sparkle framework with Developer ID
   - notarizes the app and DMG with Apple
   - creates a **draft** GitHub Release with the DMG + ZIP attached
   - signs the DMG with the Sparkle EdDSA key and pushes `appcast.xml` to `gh-pages`
5. Review the draft release at `https://github.com/lzhgus/Gauss/releases` and **publish** it.

## How Users Get Updates

- Sparkle checks `https://lzhgus.github.io/Gauss/appcast.xml` periodically (default: every 24 hours)
- Users can also manually check via **Settings → "Check for Updates…"**
- The DMG is downloaded from GitHub Releases

## Infrastructure

| Component | Location |
|-----------|----------|
| Appcast URL | `https://lzhgus.github.io/Gauss/appcast.xml` (gh-pages branch) |
| Release binaries | `https://github.com/lzhgus/Gauss/releases` |
| EdDSA public key | `Gauss/Info.plist` → `SUPublicEDKey` |
| EdDSA private key | GitHub Secret `SPARKLE_PRIVATE_KEY` |
| Signing certificate | GitHub Secret `BUILD_CERTIFICATE_BASE64` |
| Sparkle CLI tools | resolved from Xcode DerivedData in CI |

## Version Numbering

- `MARKETING_VERSION` (e.g. `1.1.0`) — user-facing version, maps to `CFBundleShortVersionString`
- `CURRENT_PROJECT_VERSION` (e.g. `3`) — build number, maps to `CFBundleVersion`, must increment with every release
- Sparkle compares `CFBundleVersion` (build number) to determine if an update is available

## Troubleshooting

**Notarization failed** — Open the failed workflow run, the job logs the notarization log from `xcrun notarytool log`. Common causes: unsigned Sparkle nested binaries (handled by the re-sign step), hardened-runtime/entitlement issues, or an expired app-specific password.

**EdDSA key lost / rotated** — Run `generate_keys` (from Sparkle) to create a new keypair. Update `SUPublicEDKey` in `Gauss/Info.plist` and the `SPARKLE_PRIVATE_KEY` secret. Users on the old key will need to re-download manually (one-time).

**Appcast not updating** — Confirm the `gh-pages` branch exists and GitHub Pages is enabled (Settings → Pages → Source: `gh-pages`). The workflow pushes `appcast.xml` to that branch on every tag.

## Local fallback release (optional)

`scripts/release.sh` is a local-only fallback for building/signing/notarizing from your own machine (it is gitignored and not part of the public repo). CI is the primary path.
