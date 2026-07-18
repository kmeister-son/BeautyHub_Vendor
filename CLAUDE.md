# BeautyHub Vendor — salon-owner MVP (Flutter)

Vendor-side companion to the BeautyHub customer app (`D:\Mobile_Apps\BeautyHub`).
Salon owners sign in to see their day's schedule and manage their menu, team,
and storefront. Android + iOS, tested on an Android emulator. Backend is
beautyhub-api (`D:\Mobile_Apps\beautyhub-api`) — the `/provider/*` endpoints,
JWT-guarded to the `PROVIDER` role.

## Commands

- `flutter run` — run on the connected emulator/device
- `flutter analyze` — must stay at zero issues
- `flutter test` — unit + widget tests in `test/`

## Dev sign-in

Seeded provider accounts: `owner-<salon>@beautyhub.app` (e.g.
`owner-velvet@beautyhub.app`) with password `provider_dev_password`. There is
no sign-up: registration always creates customers, so this app is login-only.

## Architecture rules

Same dependency rule as the customer app: `features/* (presentation) →
domain ← data`, `domain/` is pure Dart. Key differences from the customer app:

- **No guest identity.** `ApiClient` never mints guests; authenticated calls
  without a token (or with a stale one) throw `UnauthenticatedException` and
  the UI routes to `/login`. Login rejects non-provider accounts client-side.
- All data access via `domain/repositories/` (`VendorAuthRepository`,
  `VendorRepository`); bindings in `lib/core/di/providers.dart` point at the
  API. In-memory mocks in `data/repositories/mock_*.dart` exist for widget
  tests, which override the DI providers.
- `vendorSalonProvider` (features/salon/presentation/providers/) is the single
  source for the salon incl. services & staff — `ref.invalidate` it after any
  mutation. Schedule reads `scheduleProvider` keyed by `scheduleDateProvider`.
- Riverpod without codegen; go_router with a 4-tab `StatefulShellRoute`
  (`/schedule`, `/services`, `/staff`, `/salon`). Editors are full-screen root
  routes: `/services/edit?id=`, `/staff/edit?id=` (no `id` = create),
  `/salon/edit`.
- Theme, formatters, cover gradients, and shared widgets are copies from the
  customer app (`lib/core/`); keep them in sync when the brand changes.
  Currency/date formatting only via `lib/core/utils/formatters.dart`.

## Conventions

- One class per file (private helper widgets may live with their screen),
  feature-first folders: `features/<name>/presentation/` with `providers/`
  and `widgets/` subfolders.
- Tab FABs need explicit `heroTag`s — both tab bodies coexist in the shell's
  IndexedStack.
