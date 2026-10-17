# Security policy

Gize Rider is an educational prototype and is not suitable for real trips or real personal data.

## Reporting a vulnerability

Do not post credentials, private account details, phone numbers, trip records, precise location data, or an exploitable report in a public issue. If GitHub's private vulnerability reporting is enabled for this repository, use it. Otherwise, use the maintainer's GitHub profile to request a private reporting channel without including sensitive details.

## Security boundaries

- No production Firebase project, service-account key, Firebase rules, or trusted notification backend is included.
- Firebase client configuration is not a secret boundary; enforce authorization and validation in server-side rules.
- Never embed FCM server credentials, API secrets, signing identities, or real user data in this client.
- Treat location, contact data, device tokens, and trip history as sensitive.
- Before any real deployment, perform a threat model, rules review, abuse/rate-limit review, dependency audit, and end-to-end security test.
