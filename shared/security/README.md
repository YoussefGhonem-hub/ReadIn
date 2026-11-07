# Password deny-list

Used by the API, web and mobile to reject weak passwords (SPEC §9.4). Recovery PINs have no deny-list: any digits of
the configured length are accepted (user decision, 2026-11-07, ADR 0009).

| File | Content |
|---|---|
| `common-passwords.txt` | Entries from SecLists' `10k-most-common.txt` that would pass the password rules (8–128 characters, a letter and a digit), lower-cased, one per line. Shorter or letter-only entries are already rejected by the rules, so they are left out. |

Source: [SecLists](https://github.com/danielmiessler/SecLists) (MIT License, © Daniel Miessler), commit `ac8a76c5ddfb31385195448f501d7b915b307e4b`.

Regenerate (Git Bash):

```bash
curl -sSfL https://raw.githubusercontent.com/danielmiessler/SecLists/<commit>/Passwords/Common-Credentials/10k-most-common.txt \
  | tr -d '\r' | tr 'A-Z' 'a-z' | awk 'length($0)>=8 && length($0)<=128 && /[a-z]/ && /[0-9]/' | sort -u > common-passwords.txt
```
