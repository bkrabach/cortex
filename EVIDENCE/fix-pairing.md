# EVIDENCE — the pairing flow, fixed for a real human

Round 1 fix. The owner's report, verbatim:

> "it did not have the scan option that the original webpage instructed me to use.
> It wants a pair code, but there is no pair code anywhere. If I scan the QR code,
> it's just the address to the server. That is as far as I can get since it can't
> do anything until paired."

Both halves were true, and both were the page's fault, not the app's:

1. **No human could get a code.** The gateway had `POST /v1/pair` and
   `cortex-gateway pair`, but nothing a person could reach — the CLI lives inside
   a venv under `~/.local/share/cortex/gateway/`, unreferenced by the page.
2. **The page promised a scanner that does not exist.** It said
   *"Open Cortex → Pair → scan"*. `PairingActivity` has exactly two text fields
   (`Gateway URL`, `Pairing code`) and a `Pair` button. There is no scanner in the
   APK. The QR also encoded the *gateway* address, so scanning it with a generic
   camera app produced a URL with nowhere to put it.

Minting was **not** reimplemented. The hub shells the gateway's own
`cortex-gateway pair`; the gateway remains the only thing that writes the pairing
rail. If that CLI is missing or fails, the hub answers 503 naming the remedy and
mints nothing — a hub-invented code would not be redeemable by the gateway that
has to honour it.

Captured against the live stack: hub `:7080`, gateway `:7443`.
Run: `bash /tmp/evidence-run.sh` → `/tmp/evidence-raw.log`. All output below is
verbatim.

---

## A. The page now says what actually happens

```
$ curl -s http://127.0.0.1:7080/ | grep -oE 'Step [0-9] &middot; [^<]*'
Step 1 &middot; Install the app
Step 2 &middot; Open Cortex, tap Settings
Step 3 &middot; Type this into &ldquo;Gateway URL&rdquo;
Step 4 &middot; Get a pairing code
Step 5 &middot; Enter the code, tap Pair
```

Each step names what the human sees in the APK — `Settings` (the button in
`activity_main.xml`), `Gateway URL` and `Pairing code` (the two hints in
`activity_pairing.xml`), `Pair` (the button). The exact address to type is
rendered, not described:

```
$ curl -s http://127.0.0.1:7080/ | grep -o 'https://[0-9.]*:7443'
https://192.168.1.5:7443
```

The code surface exists on the page:

```
$ curl -s http://127.0.0.1:7080/ | grep -o '<button id="mintbtn"[^>]*>[^<]*</button>'
<button id="mintbtn" class="btn" type="button">Get pairing code</button>
```

**The scanner claim is gone.** Every remaining mention of "scan" on the page,
in full:

```
$ curl -s http://127.0.0.1:7080/ | grep -in 'scan'
88:    <p class="meta">Scan this to open <em>this page</em> on the phone &mdash; that
89:      is all this QR does. Cortex has no QR scanner of its own; pairing is done

$ curl -s http://127.0.0.1:7080/ | grep -ci 'scan to pair\|Pair &rarr; scan\|scan the QR to pair'
0
```

The QR now encodes the hub page, not the gateway — the one thing a phone camera
can usefully do with it.

## B. The mint action returns a code

```
$ curl -s -X POST http://127.0.0.1:7080/pair/new
{
 "code": "896d-eae7",
 "expires_at": "2026-08-10T10:52:35.489155+00:00",
 "single_use": true
}
```

## C. That code succeeds against the live gateway

```
$ curl -s -i --cacert ~/.config/cortex/gateway/tls/ca.pem \
    -X POST https://127.0.0.1:7443/v1/pair \
    -H 'Content-Type: application/json' \
    -d '{"code":"896d-eae7","label":"evidence-phone"}'
content-type: application/json

{"device_id":"d-8903561f","device_key":"yqrwKxb_PtALpPXZ78bJcd_-AzSFG931kNXE_YGn0W0","label":"evidence-phone","paired_at":"2026-08-10T10:37:35.535504+00:00"}
```

200 with a `device_key`. This is the exact request `PairingActivity` makes.

## D. Reusing the same code is refused

```
$ curl -s -i --cacert ... -d '{"code":"896d-eae7","label":"evidence-phone"}'
HTTP/1.1 401 Unauthorized
{"detail":"pairing code already redeemed -- codes are single-use; mint a new one with `cortex-gateway pair`"}
```

## E. A wrong code is refused

```
$ curl -s -i --cacert ... -d '{"code":"dead-beef","label":"evidence-phone"}'
HTTP/1.1 401 Unauthorized
{"detail":"unknown pairing code -- mint one with `cortex-gateway pair`"}
```

D and E are the checks that make B and C mean anything: the endpoint distinguishes
a spent code from an unknown one, and rejects both.

## F. GET does not mint

```
$ curl -s -i http://127.0.0.1:7080/pair/new
HTTP/1.0 405 Method Not Allowed
{"detail":"POST /pair/new to mint a pairing code -- GET does not mint, so a code is never handed out by a link preview or a crawler."}
```

## G. `cortex pair` — the terminal path

```
$ cortex pair evidence-cli

  pairing code   33dc-385e
  expires        2026-08-10T10:52:35.744215+00:00
  single use     redeeming it once spends it

On the phone: open Cortex -> Settings, then
  Gateway URL    https://192.168.1.5:7443
  Pairing code   33dc-385e
and tap Pair. (Full walkthrough: http://192.168.1.5:7080/)
```

Redeeming the code it just printed:

```
$ curl -s -i --cacert ... -d '{"code":"33dc-385e","label":"evidence-cli"}'
content-type: application/json

{"device_id":"d-7bab095c","device_key":"wPliUezcGo2a65ck8CWMz3hLZ22gsKyZLoAW3xoYlS0","label":"evidence-cli","paired_at":"2026-08-10T10:37:35.803930+00:00"}
```

**Both codes shown in this document are spent.** `896d-eae7` was redeemed in C and
refused in D; `33dc-385e` was redeemed above and is refused now:

```
$ curl -s --cacert ... -d '{"code":"33dc-385e","label":"evidence-cli"}'
{"detail":"pairing code already redeemed -- codes are single-use; mint a new one with `cortex-gateway pair`"}
```

`cortex --help` lists it:

```
  cortex pair [tag]  mint a single-use pairing code for the phone
```

(`usage()` previously printed a fixed line range, `sed -n '2,20p'`. Adding a
command pushed `set -uo pipefail` and the first lines of source into the help
output. It now prints the comment header however long it is.)

## H. Every mint is loud in the hub log

```
$ tail -6 ~/.local/state/cortex/logs/hub.log
10/Aug/2026 03:37:35  PAIR-MINT OK  peer=127.0.0.1  label='hub-page 127.0.0.1'  expires_at=2026-08-10T10:52:35.489155+00:00  (code withheld from log by design; single use)
10/Aug/2026 03:37:35  "POST /pair/new HTTP/1.1" 200 -
10/Aug/2026 03:37:35  "GET /pair/new HTTP/1.1" 405 -
```

The peer, label and expiry are logged; **the code itself is not**. It is a live
credential with a 900 s TTL, and the log is world-readable on this host. A refused
mint logs `PAIR-MINT REFUSED` with its reason and remedy.

## I. Nothing else regressed

```
$ cortex doctor ; echo "exit=$?"
...
PASS  protected ports        live: 8443 9443 9000 9100 8088 -- Cortex binds only 7443/9102/7080

doctor: all checks passed
exit=0

$ ./EVIDENCE/rehearse.sh ; echo "exit=$?"
...
########## 10:38:22  PHASE 12  the read-only mount was never written to
touch: cannot touch '/workspace/cortex/PROOF-RO': Read-only file system
workspace is read-only: confirmed

########## 10:38:22  DONE

=== rehearsal finished 2026-08-10T03:38:22-07:00 (docker rc=0) ===
exit=0
```

Both exit codes were read directly from the command, not through a pipe — an
earlier draft of this run read `$?` after `| tail`, which reports `tail`'s status
and can never fail.

---

## Security posture — stated, not hidden

`POST /pair/new` is **unauthenticated**, like the page that hosts it. That is
deliberate and inside tonight's trust boundary: the same LAN/tailnet surface
already serves the APK itself and the by-design-unauthenticated `POST /v1/pair`.
What bounds it is the credential, not the caller — 900 s TTL, single use, and
every mint logged.

It is not the right posture past tonight. Anyone who can reach `:7080` can mint a
code, and a code is a device key waiting to happen. The hardening — gating the
page-side mint — is written down as a follow-up in `README.md`, **not built
tonight**, and this paragraph exists so nobody discovers that by reading the
source.

## What was deliberately not done

- **Minting was not reimplemented in the hub.** The gateway owns the pairing rail.
  The hub shells its CLI and parses what it prints; if the output format changes,
  the hub says so and mints nothing rather than guessing.
- **No QR scanner was added to the page's story.** The APK has none. Copy was
  changed to match the app, not the other way around — the app is another lane's
  repo, and a page that describes software that exists beats a page that describes
  software someone might build.
- **The code is not written to the hub log.** Auditing a mint does not require
  retaining the credential.
