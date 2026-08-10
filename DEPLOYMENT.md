# Sajhya Patient App — Play Store deployment

Application ID: `com.manurya.sajhya_patient_app` (permanent once published)

## Status

Fixed in the app; nothing here is outstanding on the client side:

- Application ID moved off `com.example.*` (Play rejects that prefix outright)
- Release builds fail rather than silently falling back to the debug key
- Cleartext HTTP disabled; `INTERNET` declared explicitly
- Cloud backup and device-transfer of the session cookie jar disabled
- Session-cookie logging removed; raw exceptions no longer shown to users
- R8 shrinking + obfuscation enabled, with `Log.*` calls stripped from release
- `FLAG_SECURE` set, so diagnoses/prescriptions cannot be screenshotted
- In-app account deletion added (Dashboard → ⋮ → Delete my account)

Still required before upload. Two of the three are **not** app work:

| # | Item | Where |
|---|------|-------|
| 1 | Upload keystore | Codemagic |
| 2 | `POST /api/delete-account/` endpoint | `sajhya.com` (Django) |
| 3 | Hosted privacy policy + Data Safety form | `sajhya.com` + Play Console |

---

## 1. Upload keystore

Generate once, then **back it up**. Losing it means you can never update the app
under this package name again.

```bash
keytool -genkey -v -keystore sajhya-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias sajhya
```

Upload it to **Codemagic → Team settings → Code signing identities** with the
reference name `sajhya_keystore` (already referenced in `codemagic.yaml`).
Enrol in Play App Signing so Google holds the app signing key and this stays a
replaceable upload key.

Local release builds now fail without a keystore, by design. For a local smoke
test only:

```bash
flutter build apk --release -PallowDebugSigning=true
```

That artifact cannot be uploaded to Play.

## 2. Account deletion endpoint

`lib/services/api_service.dart` → `deleteAccount()` calls:

```
POST /api/delete-account/     (session-authenticated, CSRF-protected)
→ 200 {"success": true}
→ 4xx {"success": false, "error": "..."}
```

This endpoint **does not exist yet** — the app calls it and surfaces a failure
message until it is implemented. It should delete or irreversibly anonymise the
patient profile, exercise history, feedback, cart and orders.

Play also requires a **web** deletion route reachable without installing the app
(e.g. `https://sajhya.com/delete-account/`), and its URL is entered separately
in the Play Console Data Safety form.

Note: exercise/prescription records may be clinical records the physiotherapy
practice is legally required to retain. If so, anonymise rather than hard-delete,
and state the retention period in the privacy policy — Play accepts that, but
only if it is disclosed.

## 3. Privacy policy + Data Safety

The app collects data Play classes as sensitive, so a policy URL is mandatory and
must be live before submission. Declare in the Data Safety form:

| Data | Purpose | Notes |
|------|---------|-------|
| Name, patient code | Account management | Required |
| Health info (diagnosis, prescriptions, exercise feedback) | App functionality | **Sensitive** |
| Delivery address | Order fulfilment | Marketplace orders |
| Camera | QR sign-in and physio pairing | Not stored; not transmitted |

All traffic is HTTPS-only and in transit encrypted — declare that. Also declare
that users can request deletion, and give both the in-app path and the web URL.

Expect health-data apps to draw a slower, stricter review than average.

---

## Build

Kotlin incremental compilation is disabled in `android/gradle.properties`. Without
it, `:mobile_scanner:compileReleaseKotlin` fails on Windows with "Could not close
incremental caches" under this AGP 9 / Kotlin 2.3 / Gradle 9 combination. It costs
build time only.

```bash
flutter build appbundle --release   # AAB is what Play accepts for new apps
```

## Known remaining risk

The session cookie jar (`PersistCookieJar`, `api_service.dart`) is stored
unencrypted in the app documents directory. It is sandboxed and no longer backed
up to the cloud, but is readable on a rooted device. Moving it behind
`flutter_secure_storage` was deliberately **not** done here: it changes how auth
persists for every existing user and could not be verified on a real device in
this pass. Worth doing as a separate, tested change.
