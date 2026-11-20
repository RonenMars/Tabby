# Tabby — TestFlight Deployment

How to ship a Tabby iOS build to TestFlight.

## Prerequisites (one-time)

- App Store Connect API key on disk at `~/.appstoreconnect/private_keys/AuthKey_G7S8Q6D6Z9.p8`. If missing, restore from 1Password (`MyDevSecrets/AppStoreConnect`, field `auth_key_b64`):
  ```bash
  mkdir -p ~/.appstoreconnect/private_keys
  op item get "AppStoreConnect" --vault "MyDevSecrets" --fields label=auth_key_b64 --reveal | tr -d '"' | base64 -d > ~/.appstoreconnect/private_keys/AuthKey_G7S8Q6D6Z9.p8
  ```
- Flutter **3.41.8**, run as `fvm spawn 3.41.8 <args>` (install once with `fvm install 3.41.8`). Plain `fvm flutter` resolves to the 3.47.2 pinned in `.fvmrc`, which fails to archive and rewrites the iOS project (SwiftPM, `pubspec.lock`); Homebrew's Flutter 3.50 cannot compile `toggle_switch`.
- Xcode 27 builds only iOS 15 and later, so `Podfile` and `Runner.xcodeproj` target 15.0. Builds do not install on iOS 14 or earlier.
- The app needs the UIScene lifecycle (`UIApplicationSceneManifest` in `Info.plist` and `SceneDelegate.swift`). Without it, a build linked against the iOS 27 SDK crashes at launch with `EXC_BREAKPOINT` in `UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`.
- `clang` must be Xcode's. If `which clang` prints `~/.swiftly/bin/clang` and that toolchain is gone, remove `~/.swiftly/bin` from `PATH` for the build commands below.
- `flutter/ios/exportOptions.plist` exists and uses `method: app-store`, `teamID: GUW6BN8X57`.

## Identifiers

| Field | Value |
|---|---|
| Key ID | `G7S8Q6D6Z9` |
| Issuer ID | `e84dd3bd-1e5d-4db4-8b57-46637e2510ff` |
| Team ID | `GUW6BN8X57` |

## Steps

### 1. Bump build number

In `flutter/pubspec.yaml`, increment the part after `+`:
```yaml
version: 1.4.6+72   # was +71
```
TestFlight rejects duplicate build numbers within a `CFBundleShortVersionString`. Bump the build number on every upload, even for the same marketing version.

### 2. Build the Rust library, then the IPA

`flutter build ipa` links `target/aarch64-apple-ios/release/liblibrustdesk.a`, which is not in git.
A fresh checkout or worktree needs it first (about 2.5 minutes, with vcpkg `arm64-ios` already installed):

```bash
git submodule update --init --recursive
ln -s <main checkout>/vcpkg_installed vcpkg_installed   # or run vcpkg install --triplet=arm64-ios
# src/bridge_generated.rs, src/bridge_generated.io.rs and flutter/ios/Runner/bridge_generated.h
# are gitignored; copy them from a checkout that has them, or run scripts/build-ios.sh.
IPHONEOS_DEPLOYMENT_TARGET=13.0 VCPKG_ROOT=$HOME/vcpkg VCPKG_INSTALLED_ROOT=$PWD/vcpkg_installed \
  cargo build --features flutter,hwcodec --release --target aarch64-apple-ios --lib
```

Then, from `flutter/`:

```bash
fvm spawn 3.41.8 pub get
fvm spawn 3.41.8 build ipa --release \
  --export-options-plist=ios/exportOptions.plist \
  --no-pub
```

Gitignored generated files (`flutter/lib/generated_bridge.freezed.dart`) are also needed; copy them from another checkout if `flutter build` reports them missing.
Output: `flutter/build/ios/ipa/<name>.ipa` (~40 MB).

The build log will end with `✓ Built IPA to build/ios/ipa`. Treat the launch-image placeholder warning as known.

### 3. Upload to TestFlight

```bash
xcrun altool --upload-app --type ios \
  -f flutter/build/ios/ipa/*.ipa \
  --apiKey G7S8Q6D6Z9 \
  --apiIssuer e84dd3bd-1e5d-4db4-8b57-46637e2510ff
```
Successful upload prints `No errors uploading <name>.ipa`. Apple processing typically takes 5–15 minutes before the build is testable in TestFlight.

### 4. Verify

- Before uploading, check the packaged app: `unzip -p flutter/build/ios/ipa/Tabby.ipa Payload/Runner.app/Info.plist | plutil -p -` shows the expected `CFBundleVersion` and `UIApplicationSceneManifest`.
- After install, a launch crash shows up as a TestFlight crash report. List them with the App Store Connect API: `GET /v1/apps/6764266996/betaFeedbackCrashSubmissions`, and the log at `/v1/betaFeedbackCrashSubmissions/<id>/crashLog`.

- App Store Connect → TestFlight → look for the new build under the bumped build number.
- Once "Ready to Test", install/update via the TestFlight app on the test device.

## Troubleshooting

- **"No suitable application records were found"** → bundle identifier mismatch; check `flutter/ios/Runner.xcodeproj` matches the App Store Connect record.
- **"Asset validation failed: Invalid Bundle"** → usually a missing entitlement or signing mismatch. Re-check `exportOptions.plist` and active provisioning profile.
- **`altool` hangs > 5 min** → flaky upload server; cancel and retry. Idempotent on the same build number until processing succeeds.
- **Build number already used** → bump `pubspec.yaml` again.
- **`The iOS deployment target ... is set to 11.0, but the range of supported deployment target versions is 15.0 to ...`** → Xcode 27. Set `platform :ios, '15.0'` and the `post_install` `IPHONEOS_DEPLOYMENT_TARGET` in `flutter/ios/Podfile`, and the target in `Runner.xcodeproj`.
- **`clang` / `cc-rs` errors mentioning `swift-5.6.3-RELEASE.xctoolchain`** → the swiftly `clang` shim points at a removed toolchain; take `~/.swiftly/bin` out of `PATH`.
- **App crashes at launch, `EXC_BREAKPOINT`, `NoSceneLifecycleAdoption` in the stack** → the UIScene lifecycle is missing; see Prerequisites.
