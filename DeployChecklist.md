# BeautyHub Vendor — Deployment Readiness Checklist

Drafted 2026-07-22, based on the same review approach used for the customer
app (`D:\Mobile_Apps\BeautyHub\DeployChecklist.md`). This app is Flutter,
Android + iOS, same architecture pattern as the customer app, backed by the
same `beautyhub-api`.

## Open decision — RESOLVED 2026-07-29: full public Play Store listing

Owner confirmed the app goes out as a **full public listing**, not a closed
track. That pulls in the complete public-facing compliance set (see "Store
compliance" below). Note for review: because the app is login-only with no
sign-up, Google Play's app review requires **demo credentials** to be supplied
in the Play Console ("App access" declaration) — plan to provide a dedicated
demo provider account on the production backend, not a real salon's login.

Note: this doesn't need a *second* Apple Developer Program membership or Play
Console developer account — both are account-level, not per-app. Once
enrolled for the customer app, this app is just a second app entry under the
same accounts.

## Found during this review (bugs, not just deployment gaps)

- [x] **Fixed 2026-07-22:** `android/app/src/main/AndroidManifest.xml` was
      missing the `INTERNET` permission entirely (only present in the
      debug-variant manifest). Added `<uses-permission
      android:name="android.permission.INTERNET"/>` to the main manifest,
      matching the customer app.
- [ ] No `usesCleartextTraffic` flag and no network security config. Same
      situation the customer app started in — fine for now since the backend
      is dev-only HTTP, but combine with the item above: even after adding
      `INTERNET`, a release build talking to `http://10.0.2.2:3000` needs
      cleartext explicitly allowed the same way the customer app's manifest
      does, until the backend is HTTPS.

## Backend

- [ ] **Still the #1 blocker (confirmed 2026-07-29: hosting planned, not
      started).** Shares `beautyhub-api` with the customer app — no separate
      backend work needed here. Once that's hosted on Railway (see customer
      app's checklist), build with
      `flutter build appbundle --dart-define=API_BASE_URL=https://<prod-url>`.
      Without the define, release builds point at emulator-only localhost
      over cleartext HTTP and cannot work.
- [x] **Done 2026-07-29:** "Forgot password?" flow added — login screen
      links to `/forgot-password` (ported from the customer app), wired to
      the API's `/auth/forgot-password` + `/auth/reset-password` endpoints
      via `VendorAuthRepository`. Covered by a widget test on the mock.

## Release signing & builds

- [x] **Fixed 2026-07-29:** own upload keystore generated at
      `android/app/upload-keystore.jks` (alias `upload`, credentials in
      `android/key.properties` — both git-ignored), release signing wired in
      `android/app/build.gradle.kts` mirroring the customer app's setup.
      **Back up the keystore + key.properties somewhere safe (password
      manager / secure storage) — they are not in git, and losing them
      before first upload means regenerating; after first upload, enroll in
      Play App Signing so Google holds the app signing key.**
- [x] **Done 2026-07-29:** version scheme set (`0.1.0+1` in pubspec —
      bump the `+N` build number for every Play upload). Display name set
      to "BeautyHub Vendor" (Android manifest + iOS Info.plist).
      `flutter_launcher_icons` wired; drop the real 1024×1024 icon at
      `assets/icon/app_icon.png` and run `dart run flutter_launcher_icons`
      (see `assets/icon/README.md`) — until then it's still the Flutter
      default icon, which Play review may flag.
- [ ] iOS: same "no Mac" situation as the customer app — Codemagic (or
      similar) needed once Apple Developer enrollment clears.
- [x] **Done 2026-07-29:** repo pushed to GitHub
      (`kmeister-son/BeautyHub_Vendor`), unblocking Actions CI (now live —
      see Quality gates) and a future Codemagic connection for iOS.

## Store compliance (public listing — full set applies)

- [ ] Public privacy policy page at a stable URL (required field in Play
      Console; must cover the account/booking data this app handles).
- [ ] Data Safety form (collects: email, name, booking/schedule data;
      transmitted to beautyhub-api; declare encryption-in-transit once the
      backend is HTTPS).
- [ ] Store listing assets: phone screenshots (min 2), feature graphic
      1024×500, app icon 512×512, short + full description.
- [ ] Content rating questionnaire (should come out "Everyone").
- [ ] "App access" declaration with working demo provider credentials for
      Google's reviewers (login-only app).
- [ ] Final launcher icon + launch screen replaced (icon plumbing is in;
      asset still pending — see Release signing section).

## Quality gates

- [x] **Done 2026-07-29:** CI live and green
      (`.github/workflows/ci.yml`, mirror of the customer app's) — `flutter
      analyze` + `flutter test` on every push/PR, then a signed release
      `.aab` built from repo secrets and uploaded as an artifact on pushes
      to `main`. First run passed end-to-end. Repo pushed to
      https://github.com/kmeister-son/BeautyHub_Vendor with signing secrets
      (`ANDROID_KEYSTORE_*`, `ANDROID_KEY_*`) set via `gh secret set`.
- [ ] No crash reporting/analytics wired in, same as the customer app.

## Not applicable / lower priority for this app

- **Payments** — no in-app payment flow expected here (this is the
  salon-owner ops app, not the customer booking flow); confirm this
  assumption if a payout/earnings view is ever planned.
- **Push notifications** — same "defer post-MVP" call as the customer app
  is a reasonable default, but worth asking specifically: schedule/booking
  alerts arguably matter more to a salon owner than to a customer.
