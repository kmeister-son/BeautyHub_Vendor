# BeautyHub Vendor

Salon/barbershop owner companion app to the BeautyHub customer app. Flutter,
Android-first. Lets a salon owner manage their storefront, services, staff,
and incoming bookings from their phone.

## Documentation

Full engineering docs for the whole BeautyHub system (this app, the
customer app, the admin tool, and the shared backend) live in the backend
repo: **[beautyhub-api/docs](https://github.com/kmeister-son/BeautyHub_API/tree/main/docs)**.

Start there — in particular
[03 — Vendor app](https://github.com/kmeister-son/BeautyHub_API/blob/main/docs/03-vendor-app.md)
for this repo specifically, and
[06 — Local dev setup](https://github.com/kmeister-son/BeautyHub_API/blob/main/docs/06-local-dev-setup.md)
to get it running end-to-end.

## Quick start

```sh
flutter pub get
flutter run              # needs beautyhub-api running locally, see the docs above
flutter analyze          # must stay at zero issues
flutter test
```

No self-registration — log in with a seeded `owner-*@beautyhub.app` account
(see the docs for the list and password).

See also `CLAUDE.md` in this repo for architecture rules and conventions.
