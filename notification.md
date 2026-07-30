# Push notifications — implementation plan

Drafted 2026-07-30. Spans all three repos: `beautyhub-api`, this app, and
the customer app (`D:\Mobile_Apps\BeautyHub`). Nothing is wired yet —
no Firebase dependency, no notification code, no device-token table.

The immediate reason this matters: the booking approval flow shipped
2026-07-30 (see `DeployChecklist.md` and the API's booking-approval
commit) leaves a salon owner unaware of a pending request until they
happen to open the app, while the customer waits up to 24 hours for it to
silently expire. Push is what makes that feature actually work.

## Choice: FCM

Firebase Cloud Messaging — free, covers Android and iOS through one
server API, official Flutter plugin. The alternative (OneSignal) buys
faster setup at the cost of another vendor holding user data, which isn't
worth it when there's already a NestJS backend to send from.

**iOS is blocked by Apple Developer enrolment** (still pending — see
"Release signing & builds" in `DeployChecklist.md`). APNs needs a key
generated in that account and there is no way around it. Ship Android
first; adding iOS later needs Firebase configuration only, no backend
changes.

## Pieces

### 1. Firebase project

One project, three app registrations (vendor Android, customer Android,
the iOS pair later). `flutterfire configure` generates
`firebase_options.dart` and drops `google-services.json` into each app.

- `google-services.json` is client config — normally committed.
- The **service-account JSON the server uses is a real secret**: env var
  (base64 is easiest for Railway), never in git, never in the apps.

### 2. Database (`beautyhub-api`)

A `DeviceToken` model: `token` (unique), `userId`, `platform`,
`lastSeenAt`. Cascade-delete on user. Delete the row on logout so a
shared phone doesn't leak one salon's requests to the next person.

### 3. Both Flutter apps

Add `firebase_core` + `firebase_messaging`. Request permission — Android
13+ requires the runtime `POST_NOTIFICATIONS` permission and both apps
target API 35, so this is mandatory, not optional. Register the token
with the API on sign-in and on every token refresh. Handle three
delivery states separately: foreground, background tap, and terminated
(notification as launch reason).

### 4. API endpoints + send path

`POST /devices` and `DELETE /devices/:token`, plus a
`NotificationsService` wrapping `firebase-admin`. Two rules matter more
than the rest:

- **A push failure must never fail the request that triggered it.** An
  FCM outage must not break a booking.
- **Prune tokens on `messaging/registration-token-not-registered`**, or
  the token table rots and every send gets slower.

## Triggers (they fall out of the approval flow)

| Event | Notify | Route in payload |
|---|---|---|
| Booking created at a salon with `autoConfirmBookings = false` | Salon owner | `/schedule` |
| Owner accepts / declines | Customer | `/bookings` |
| Pending request lapses to `EXPIRED` | Customer | `/bookings` |

The first is the one that makes the whole feature work — it's what gets
the owner to open the app before the 24-hour expiry.

The expiry notification is more interesting. The lazy sweep in
`bookings.service.ts` / `provider.service.ts` deliberately avoids a
scheduler, and it still can: when the sweep flips a request to `EXPIRED`
it knows exactly which customer to tell, so the send happens there
without introducing `@nestjs/schedule`. Trade-off: the customer isn't
told at the 24-hour mark but whenever someone next reads that data.
Acceptable now; revisit when appointment reminders land, since those do
need a real scheduler.

## Gotchas specific to this project

- **Guest identity in the customer app.** Guests are real user rows so
  tokens attach fine — but when a guest signs in, that device's token is
  still pointed at the abandoned guest user and the push goes nowhere.
  Re-register on every auth state change and upsert on the unique token
  so the row re-points instead of duplicating. The vendor app is
  login-only, so it doesn't have this problem.
- **Play Store Data Safety declaration needs updating** — push tokens are
  a collected data type. Already an open item in `DeployChecklist.md`.
- FCM sending is outbound only, so it works from a localhost backend in
  dev; production sending needs the backend hosted (Railway, still open).

## Effort

Firebase setup ~1h · API ~half a day · each app ~half a day · iOS parked
until Apple Developer enrolment clears.

## Prerequisite before implementation starts

The Firebase project must be created under the owner's Google account,
and the service-account JSON handed over — that step can't be automated
from here.
