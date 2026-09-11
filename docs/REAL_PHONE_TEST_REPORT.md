# Real Phone Test Report — Darazinda Connect

**Status: NOT YET TESTED.** No physical Android phone is reachable
from this development session, so every row below is an unfilled
template — none of it should be read as "passed." Fill it in yourself
(or paste me the results) after running the app on a real device per
`docs/LOCAL_ANDROID_SETUP.md`.

Test device: _______________ (model, Android version)
Date tested: _______________
Tested by: _______________

| # | Test | Steps | Expected | Result (PASS/FAIL/N/A) | Notes |
|---|---|---|---|---|---|
| 1 | App installation | `flutter run` (or install the built APK) | Installs without error | ☐ | |
| 2 | First launch | Open the app | Splash → Onboarding → Login/Guest screen, no crash | ☐ | |
| 3 | Permissions | Start a network test | Location and phone-state permission prompts appear with clear reasoning | ☐ | |
| 4 | GPS | Complete a network test outdoors | Real GPS coordinates + accuracy recorded | ☐ | |
| 5 | Mobile network detection | Check the test result screen | Real operator name and network type (2G/3G/4G/5G) shown | ☐ | |
| 6 | Signal reading | Check the test result screen | Real signal dBm value shown, or "Not available on this device" if the OS doesn't expose it — never a fabricated number | ☐ | |
| 7 | Speed test | Run a full test | Download/upload/ping show real measured numbers; "Cancel Test" button works mid-test | ☐ | |
| 8 | Offline measurement | Enable airplane mode, run a test | Measurement saves locally, marked "Pending Sync"; network-dependent fields show "Not available" | ☐ | |
| 9 | Reconnection | Disable airplane mode | Status flips to "Synced" within a short time (requires a configured Firebase project) | ☐ | |
| 10 | Firebase synchronization | Check Firebase Console → Firestore after a test | The measurement document appears in the `measurements` collection with matching data | ☐ | |
| 11 | Signal map | Open Signal Map | Real pins appear (from this device and/or others); shows "No community measurements yet." if none exist — never fake pins | ☐ | |
| 12 | Report submission | Submit a report with a category and photo | Unique report ID generated; appears in "My Reports"; duplicate-submission dialog appears if repeated within 5 minutes at the same spot | ☐ | |
| 13 | PDF generation | Export a PDF from "My Reports" | PDF opens/shares correctly; shows signal/download/upload/latency and "Map snapshot not available for this export." | ☐ | |
| 14 | Urdu RTL | Settings → Language → Urdu | Layout mirrors correctly; text is legible; navigate a few screens to confirm no broken layout | ☐ | |
| 15 | App restart | Force-close and reopen the app | Previous local data (measurements, reports) still present; no data loss | ☐ | |
| 16 | Battery behavior | Leave the app open/backgrounded for 30+ minutes without starting a test | No continuous GPS/battery drain — the app must not poll location/network in the background | ☐ | |
| 17 | Error handling | Deny a permission, disable GPS, or turn off all connectivity mid-test | Each case shows a specific, actionable message — never a blank screen or silent failure | ☐ | |

## How to report results back

For each row, replace ☐ with ✅ (pass), ❌ (fail — describe what
happened), or `N/A`. If anything fails, include:
- The exact screen/action
- What you expected vs. what happened
- A screenshot if possible

That level of detail lets the failure be fixed precisely instead of
guessed at.
