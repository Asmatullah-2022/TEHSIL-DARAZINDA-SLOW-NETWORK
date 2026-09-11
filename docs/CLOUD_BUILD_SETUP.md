# Cloud Build Setup — Darazinda Connect

**You need nothing installed.** This project now builds a debug APK
entirely on GitHub's own cloud servers (GitHub Actions), triggered
either automatically on push or manually with one tap from your
phone's browser. You only need the GitHub app or a mobile browser.

## Can this be built in Claude's own sandbox environment?

**No.** That environment has Flutter installed but no Android SDK, and
this session's network policy blocks downloading one from Google's
servers (`dl.google.com` returns 403). This was verified directly —
`flutter build apk --debug` was run there and failed immediately with
`No Android SDK found`. Nothing about a successful local build is
claimed. Full detail in `docs/QA_CHECKLIST.md`.

Since that path is closed, this document sets up the realistic
alternative: **GitHub Actions**, a free cloud build service already
connected to this repository, whose runners come with Java, Flutter
(installed by the workflow), and a full Android SDK pre-installed by
GitHub — nothing to configure on your end.

## What was prepared in this repo

- `.github/workflows/build-debug-apk.yml` — the cloud build recipe:
  checks out the code, installs Flutter 3.24.5 (the version already
  verified against this codebase — see `docs/QA_CHECKLIST.md`), runs
  `flutter pub get`, generates the database code
  (`build_runner`), runs `flutter analyze` and `flutter test`, then
  `flutter build apk --debug`. If any of those steps fail, the whole
  run fails and no APK is produced — so a green checkmark on GitHub
  genuinely means a working build, not a partial one.
- `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/*`
  — the Gradle wrapper. **This did not exist before** and would have
  made even a correctly-configured cloud build fail; it's now
  generated and committed (a completely standard, non-secret file —
  every Flutter/Android project ships one).
- `android/app/proguard-rules.pro` — referenced by the release build
  config but didn't exist; created so a future `--release` build won't
  fail at Gradle configuration time. (Not needed for today's debug
  build, but this is the moment it would otherwise be discovered.)
- The APK produced is published two ways on every successful run:
  1. As a workflow **artifact** (zipped, attached to that specific
     run).
  2. As an asset on a GitHub **Release** tagged `debug-latest` — this
     one is the phone-friendly option: a single, permanent link that
     always points at the newest successful build, no zip involved.

Nothing about Firebase, signing, or the app's own architecture changed
in this pass — only what was needed to make a cloud build possible.

## Step-by-step: get the APK on your phone

### Option A — it may already be building
Every push to this branch triggers the workflow automatically. If a
commit was just pushed, a build may already be running or finished.
Skip to "Download the APK" below and check.

### Option B — trigger it yourself (1 tap, from your phone)
1. Open the repository in your phone's browser or the GitHub app:
   `github.com/Asmatullah-2022/TEHSIL-DARAZINDA-SLOW-NETWORK`
2. Tap the **Actions** tab.
3. Tap **Build Debug APK** in the left list (may need "see more" on
   mobile).
4. Tap **Run workflow** → choose the `claude/darazinda-connect-app-8e727o`
   branch → **Run workflow**.
5. Wait — a Flutter Android build typically takes **5-10 minutes** on
   GitHub's runners. Refresh the Actions page to watch progress; a
   green check means success, red means it failed (tap into it to see
   which step and why — tell me the exact error text and I'll fix it).

### Download the APK
Once the run shows a green check, either:

- **Easiest:** go to the repository's **Releases** page (or
  `.../releases/tag/debug-latest`) and tap `app-debug.apk` under
  **Assets**. This downloads the file directly — no extraction needed.
- **Alternative:** open the finished workflow run → scroll to
  **Artifacts** → tap `darazinda-connect-debug-apk` → this downloads a
  `.zip`; use your phone's Files app to extract the `.apk` from it.

### Install it
1. Tap the downloaded `app-debug.apk` file (from your Downloads
   folder, or the notification).
2. Android will likely ask to allow installs from this source (Chrome,
   Files, or whichever app you used) — allow it once.
3. Tap **Install**. This is a debug build — Android will warn it's
   from an unknown source; that's expected and normal for
   pre-release testing, not a sign of a fake or malicious app.

## After installing

Follow `docs/REAL_PHONE_TEST_REPORT.md` to actually test it — GPS,
signal reading, speed test, offline sync, map, reports, PDF, Urdu.
Note: without a configured Firebase project (see
`docs/PLAY_STORE_PREP.md`'s Firebase section, or ask me to walk
through it), the app runs in local-only/guest mode — measurements and
reports still work and save on-device, they just won't sync to a
shared community map yet.

## If a build fails

Open the failed run on the Actions tab, tap the red ✗ step to expand
its log, and send me the exact error text — don't guess at a fix
yourself first; the log usually names the exact line/package at
fault, and guessing risks masking the real cause.
