# BeautyHub Vendor — Deployment Readiness Checklist

Drafted 2026-07-22, based on the same review approach used for the customer
app (`D:\Mobile_Apps\BeautyHub\DeployChecklist.md`). This app is Flutter,
Android + iOS, same architecture pattern as the customer app, backed by the
same `beautyhub-api`.

## Open decision (affects scope below)

This app is login-only for seeded/invited salon owners (`owner-*@beautyhub.app`
accounts) — there's no public sign-up. **Recommendation: distribute via Play
Console's Closed Testing track and TestFlight's internal testing, not a
public store listing.** That skips public-facing requirements (privacy policy
page discoverable by the public, public screenshots, full Data Safety
disclosure detail) since access is invite-only. Confirm this is actually the
plan before treating the "store compliance" section below as scoped correctly
— a public listing would need to add those items back.

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

- [ ] Shares `beautyhub-api` with the customer app — no separate backend
      work needed here. Once that's hosted on Railway (see customer app's
      checklist), point this app's `ApiConfig.baseUrl` at the same URL via
      `--dart-define=API_BASE_URL=...`.
- [ ] No mailer/password-reset concern here — this app has no sign-up and
      presumably no self-service password reset (confirm: how do salon
      owners recover a forgotten password today?).

## Release signing & builds

- [ ] **Needs its own upload keystore — cannot reuse the customer app's.**
      Currently signs release with the debug keystore
      (`android/app/build.gradle.kts`, same unfixed TODO as the customer app
      had). Bundle ID is `com.beautyhub.beautyhub_vendor` (Android) /
      `com.beautyhub.beautyhubVendor` (iOS) — distinct from the customer
      app, so a distinct signing identity either way.
- [ ] iOS: same "no Mac" situation as the customer app — Codemagic (or
      similar) needed once Apple Developer enrollment clears.
- [ ] No git remote configured yet (`git remote -v` is empty) — this repo
      isn't pushed to GitHub at all. That's a prerequisite for GitHub Actions
      CI and for Codemagic's GitHub-OAuth repo connection.

## Store compliance

- [ ] If going the closed/internal-testing route (recommended above): still
      need a minimal Play Console app entry and App Store Connect app
      record, but can skip the public privacy policy page and full public
      store listing assets.
- [ ] If a public listing is wanted instead: same full list as the customer
      app (Data Safety form, App Privacy label, screenshots, age rating,
      etc.) — ask before assuming which applies.
- [ ] Confirm final app icon/launch screen aren't still Flutter defaults.

## Quality gates

- [ ] No CI at all yet (`.github/` doesn't exist). Existing test coverage is
      actually reasonable already: `test/unit/api_client_test.dart`,
      `test/unit/mock_vendor_repository_test.dart`,
      `test/widget/vendor_flow_test.dart`. A `ci.yml` mirroring the customer
      app's (`analyze` + `test`, then a `build-android` job once a keystore
      exists) would close this gap quickly.
- [ ] No crash reporting/analytics wired in, same as the customer app.

## Not applicable / lower priority for this app

- **Payments** — no in-app payment flow expected here (this is the
  salon-owner ops app, not the customer booking flow); confirm this
  assumption if a payout/earnings view is ever planned.
- **Push notifications** — same "defer post-MVP" call as the customer app
  is a reasonable default, but worth asking specifically: schedule/booking
  alerts arguably matter more to a salon owner than to a customer.
