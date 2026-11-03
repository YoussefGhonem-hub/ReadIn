# Credential deny-lists

Used by the API, web and mobile to reject weak credentials at sign up (SPEC §9.4).

| File | Content |
|---|---|
| `common-passwords.txt` | Entries from SecLists' `10k-most-common.txt` that would pass the password rules (8–128 characters, a letter and a digit), lower-cased, one per line. Shorter or letter-only entries are already rejected by the rules, so they are left out. |
| `common-pins.txt` | The 100 most common 4-digit PINs, most common first, from SecLists' `four-digit-pin-codes-sorted-by-frequency-withcount.csv`. Only applied when `Recovery:PinLength` is 4. |

Source: [SecLists](https://github.com/danielmiessler/SecLists) (MIT License, © Daniel Miessler), commit `ac8a76c5ddfb31385195448f501d7b915b307e4b`.

Regenerate (Git Bash):

```bash
curl -sSfL https://raw.githubusercontent.com/danielmiessler/SecLists/<commit>/Passwords/Common-Credentials/10k-most-common.txt \
  | tr -d '\r' | tr 'A-Z' 'a-z' | awk 'length($0)>=8 && length($0)<=128 && /[a-z]/ && /[0-9]/' | sort -u > common-passwords.txt
curl -sSfL https://raw.githubusercontent.com/danielmiessler/SecLists/<commit>/Passwords/Common-Credentials/four-digit-pin-codes-sorted-by-frequency-withcount.csv \
  | tr -d '\r' | head -100 | cut -d, -f1 > common-pins.txt
```
