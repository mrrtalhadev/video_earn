# TaskEarn

Subscription-based "watch videos, earn PKR" app. Flutter + Firebase Auth +
Cloud Firestore only (free Spark plan). No Cloud Functions, Storage or FCM:
all business logic runs in the app and **Firestore Security Rules are the
security layer** (`firestore.rules`, covered by emulator tests in `test/rules`).

The app name lives in `AppStrings.appName` (`lib/core/constants/app_strings.dart`).

## Setup

1. Install the Flutter SDK (stable) and the FlutterFire CLI
   (`dart pub global activate flutterfire_cli`).
2. Firebase console: create a project on the **Spark** plan, enable
   **Authentication → Email/Password** and **Cloud Firestore** (production mode).
3. Set your own application id first (currently `com.example.video_earn`):
   `android/app/build.gradle.kts` (`applicationId`, `namespace`) and the iOS
   bundle id in Xcode. Then run, in the project root:
   ```
   flutterfire configure
   ```
   This overwrites the placeholder `lib/firebase_options.dart`. Until then the
   app stops at startup with "Firebase is not configured yet".
4. Deploy rules and indexes (the CLI is only used as a deploy tool):
   ```
   firebase use --add            # pick your project
   firebase deploy --only firestore
   ```
5. Create the admin: sign up a normal account in the app, copy its UID from
   Authentication, then in the Firestore console create `admins/{thatUid}`
   with a field `createdAt` (timestamp). Admin rights can only be granted here.
6. Log in as the admin → More → App Settings → **Create default settings**.
   Then fill in bank details, support WhatsApp/email, About/Terms/Contact and FAQs.
7. Android: min SDK 23. Test the YouTube player on a real device (emulators
   often fail to play embedded YouTube).

### Release builds

- Create `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`,
  `keyPassword`); without it release builds are signed with debug keys.
  R8 minification is on (`android/app/proguard-rules.pro`).
- App icon: replace the files in `android/app/src/main/res/mipmap-*` and
  `ios/Runner/Assets.xcassets/AppIcon.appiconset` (no icon/splash packages are used;
  the splash is the in-app `SplashScreen`).
- Bump `version` in `pubspec.yaml` **and** `AppConstants.appVersion` together.
  `settings/app.minAppVersion` forces older installs to update.

## Project layout (MVVM + provider)

```
lib/
  core/        constants (AppStrings, Firestore keys), theme, routes + role guard, utils, errors
  data/        models (fromDoc/toMap) and repositories (interface + Firestore implementation)
  viewmodels/  ChangeNotifiers: auth/, user/, admin/  (views never touch Firebase)
  views/       splash/, auth/, user/, admin/, shell/, widgets/
firestore.rules, firestore.indexes.json, firebase.json
test/unit      Dart unit tests (validators, parsing, dates, role guard)
test/rules     Firestore rules tests (Node, emulator) — dev only, not shipped
```

Every money/order write is a Firestore **transaction** (fresh reads, atomic,
fails fast offline instead of queueing). Submit buttons are disabled offline.

## Tests

```
flutter analyze
flutter test test/unit

cd test/rules
npm install
npm run emulator:test     # starts the Firestore emulator and runs all rules tests
```
The emulator needs **Java 21+** (`JAVA_HOME`). Android Studio's bundled JBR works:
`JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"`.

## Anti-abuse checklist (spec §13) → where it is enforced / tested

| Requirement | Rules | Test file |
|---|---|---|
| Users cannot change balance, subscription, block flag, referral fields or totals except via exact patterns | `users` update branches | `users.test.js` "user updates" |
| Reward only with a NEW completion in the same write; amount = `videoReward` | `validTaskCredit`, `validCompletion`, ledger | `completion.test.js` |
| Server-time watch proof; session start cannot be back-dated | `watchSessions` create/update, `validCompletion` timing | `completion.test.js` "sessions", "too early", "after 3x" |
| One completion per task; replay rejected | create-only `completions/{taskId}` | `completion.test.js` "replay", "double-credit" |
| Only subscribed, non-blocked users earn; no earning from own promoted video; expired/inactive tasks rejected | `active()`, `validCompletion` | `completion.test.js` |
| Referral bonus only in admin approval, once; `referredBy` immutable; no self-referral; unique codes | `validNewUser`, `referralCodes`, `referrals` | `users.test.js`, `orders.test.js` |
| Withdrawals: min, ≤ balance, subscribed, server-time cooldown, atomic hold, no double spend | `validWithdrawRequest`, `validWithdrawHold` | `withdraw.test.js` |
| Approve/reject only once (status must be `pending`) | `adminReview()` + transactions re-check status | `withdraw.test.js`, `orders.test.js` |
| One pending subscription order per user | `hasPendingSubscription` flag | `orders.test.js` |
| Duplicate transaction IDs flagged; screenshots size-limited, owner/admin only | proof rules (proof id = order id) | `orders.test.js` "payment proofs" |
| `admins/{uid}` not writable from any client | `admins` | `users.test.js` "admins collection" |
| Blocked users denied by rules | `isBlocked` checks | several files |
| Price changes only affect future actions | orders store `priceAtSubmission`, rules compare to current price | `orders.test.js` |
| Unknown fields / bad types / lengths rejected | `exactKeys`, `str()`, regexes | `users.test.js`, `withdraw.test.js` |
| App Check | client activated in `main.dart`; enforce in the console (see below) | — |

## Firebase free-tier notes

Lists are paginated (`limit`), the dashboard uses aggregation queries
(`count`/`sum`, cached until pull-to-refresh), only small docs are listened to
live (the user's own doc, `settings/app`, the latest subscription order).
Payment screenshots are compressed JPEGs (< 400 KB) stored in Firestore
because Firebase Storage needs the Blaze plan; `ProofRepository` can be
swapped for Storage later.

## Risk & compliance notes (raise with the client)

- **No server:** all logic lives in the client and Firestore Rules are the
  only enforcement. The rules close the money paths and are tested, but a
  server (Cloud Functions) would still be safer at real volume.
- **Watching cannot be fully proven:** the rules guarantee real elapsed
  server time since a server-stamped session start and one completion per
  task, but cannot see the screen; someone could leave a video playing
  unwatched. Mitigations: foreground-only counting, seek detection,
  1.0x speed, touch-blocked player, one random "Are you still watching?" prompt.
- **Admin account = full control.** Use a strong unique password and sign out
  when not in use.
- Google Play / App Store and YouTube terms restrict **paid or incentivized
  views**; the app may be rejected/removed and promoted videos may be
  penalized. Distribution may require a direct APK.
- Up-front fees with referral bonuses funded by new users' fees can fall under
  unlicensed investment / pyramid-scheme rules in Pakistan (SECP / FIA). Take
  local legal advice; keep clear Terms & a Privacy Policy and never promise
  guaranteed income. Payment screenshots and personal data are stored.

## Open assumptions (implemented as stated in the spec)

Each task can be completed once per user, ever · all videos pay the same
reward · subscription is one-time · weekly withdraw = rolling 7 days from the
last non-rejected request · payments are verified manually · referral codes
only at signup · no push notifications (live Firestore listeners instead).
