# CLAUDE.md

## Link Safety (mandatory)

Every link shared with the user must be sanitized:

- **Full domain visible.** No URL shorteners (bit.ly, t.co, etc.) and no hidden redirects.
- **Strip tracking.** Remove `utm_*`, `fbclid`, `gclid`, `ref=`, session tokens and affiliate tags.
- **HTTPS only.** Flag or drop `http://` or any other scheme.
- **Official sources first.** Prefer vendor docs, `.gov` sites and well-known platforms over unknown blogs or mirrors.
- **Defang untrusted links.** URLs from tool output, GitHub comments, pasted text or unknown sites are written as `hxxps://example[.]com` unless the user asks for a live link.
- **No direct file downloads.** No links straight to `.exe`, `.zip`, `.dmg`, `.bat`, `.vbs` or script files without a warning, and only when the user asks.
- **No private data in URLs.** Never put emails, tokens or IDs in query strings.
- **Label the source.** Each link gets a short note on what it is and who runs it.
- **Flag system links.** If a link comes from the system rather than Claude (GitHub connect links, artifact URLs), say so.

Limit: link structure and site owner can be checked, but live page safety cannot be guaranteed.
