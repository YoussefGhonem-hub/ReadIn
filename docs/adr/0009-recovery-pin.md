# 0009 — Recovery PIN instead of SMS for forgotten passwords

- **Status:** Accepted
- **Date:** 2026-11-03
- **Related:** [0007](0007-phone-password-authentication.md)

## Context

Without SMS or email (ADR 0007) there is no out-of-band channel to prove who is resetting a password. Users still forget
passwords, and support-only resets don't scale.

## Decision

- Every account sets a **recovery PIN** at sign up (4 digits by default, `Recovery:PinLength`). Forgot password is
  `POST /auth/recovery/verify-pin` (phone + PIN), which returns a **reset token** (random 256-bit, 10 minutes, single use,
  bound to the user and the creating IP, stored hashed), then `POST /auth/recovery/reset-password`. The reset revokes
  every session.
- **Hashing:** `PasswordHasher(HMACSHA256(pepper, userId + ":" + pin))`. The pepper (`Security:RecoveryPinPepper`, at least
  32 characters) lives only in secrets. A leaked database alone can't be used to try the 10,000 PINs offline, and the
  user id binds a hash to its account.
- **Any digits are accepted** (changed 2026-11-07, see the update below): every client and the API check only that the
  PIN is digits and of the configured length.
- **Limits:** 5 wrong PINs lock recovery for an hour; the third lockout within 7 days disables recovery until an Admin
  reset. Per number, 5 attempts an hour; per IP, 10 an hour. Every attempt is recorded in `RecoveryAttempts` with a keyed
  hash of the number, never the number itself.
- **"Forgot the PIN too":** support → an Admin with `users.reset_password` resets the account: temporary password +
  `MustChangePassword`, PIN cleared + `MustSetRecoveryPin`, recovery re-enabled, sessions revoked, audit log entry. An Admin
  can't reset an Admin or SuperAdmin; only a SuperAdmin can.
- Accounts without a PIN (seeded before it existed, admin resets, the production SuperAdmin) see a mandatory "set
  recovery PIN" screen; `POST /me/recovery-pin` sets the first one, `PUT /me/recovery-pin` (with the password) changes it.

## Consequences

- A 4-digit PIN is a small secret; the per-account lockouts, per-number limits and the pepper are what make it safe.
  Changing the pepper invalidates every PIN (every user must set a new one).
- Anyone who knows a user's number and PIN can reset the password. Owner notifications for password and PIN changes
  (F17) are the user's signal that this happened.

## Update (2026-11-07): any PIN is accepted

The user decided that people pick the PIN they will remember, so 1111, 1234, a year, the end of the phone number or
digits from the password are all accepted. The weak-PIN checks (repeated digits, runs, the 100 most common PINs from
SecLists, years 1950–2030, phone and password digits) were removed from the API, the web and the app, together with
`shared/security/common-pins.txt` and the `pin.weak` error. A PIN is now only digits of `Recovery:PinLength`.
The lockouts, rate limits and the pepper above still protect it.
