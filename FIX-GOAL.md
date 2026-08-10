FIRST: read /home/bkrabach/dev/cortex-core/CONTRACT-PINS.md and honor every pin and law in it.

# FIX LANE: cortex (hub) — the pairing flow is incoherent for a real human (round 1)

You own this repo. The owner tried to pair his phone tonight and reported, verbatim:
"it did not have the scan option that the original webpage instructed me to use. It wants a
pair code, but there is no pair code anywhere. If I scan the QR code, it's just the address
to the server. That is as far as I can get since it can't do anything until paired."

Ground truth: the gateway ALREADY has the mechanism — `POST /v1/pair` (unauthenticated by
design; the short-lived single-use code IS the credential) and an operator mint surface
(`cortex-gateway pair` CLI / `mint_pairing_code` in cortex-gateway/src/cortex_gateway/auth.py).
What's missing is the turnkey SURFACE: no human can get a code, and the page copy promises a
scanner the app does not have. Fix the surface; do NOT reimplement minting.

## Fix

1. **Distribution page (:7080)**: add a "Get pairing code" action → hub mints via the
   gateway's own mint surface (shell the co-located `cortex-gateway pair` CLI with the right
   config dir, or the cleanest official path you find) → page shows the code + its expiry +
   "single use". Log every mint loudly in the hub log.
2. **Fix the page copy** to match reality, step by step: install APK → open Cortex →
   Settings → enter gateway URL (show the exact value) → get pairing code here → enter it →
   Pair. The QR stays but labeled honestly ("scan to open this page on your phone") — no
   scanner exists in the app; remove every "scan to pair" implication.
3. **`cortex pair`** subcommand: prints a fresh code + expiry for terminal users. Update the
   CLI help text.
4. Security posture: minting from an unauthenticated LAN/tailnet page is within tonight's
   trust boundary (same boundary that serves the APK and the by-design-unauthenticated
   /v1/pair), given short TTL + single-use. Note it in the CHANGELOG and add a hardening
   follow-up line to README (page-side mint gating) — do not build the hardening tonight.

## DONE gates (EVIDENCE/fix-pairing.md, real output only)

- curl transcript: page contains the new instructions + code surface; mint action returns a
  code; that code succeeds against the live gateway `POST /v1/pair` for a test device
  (200 + device_key); REUSING the same code is refused; a wrong code is refused. Quote all
  four responses.
- `cortex pair` prints a working code (shown once in the transcript, then note it was redeemed).
- `cortex doctor` still all green; ./EVIDENCE/rehearse.sh still exit 0 (re-run it).
- Committed + CHANGELOG lines written for the owner to read.

Blocked? BLOCKED.md per pins law 7 and stop.
