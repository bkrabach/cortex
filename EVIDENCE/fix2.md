# FIX LANE round 2 — one-value pairing hand-off + config defaults

Round 1 made pairing *possible*. The owner then paired successfully and reported the
hand-off was clunky: two values to carry from a webpage to a phone, by eye, by hand.
This round makes it **one value**, offers three copy affordances in descending order,
and — critically — **says which one is actually active** rather than claiming a copy
that did not happen.

Host: `Linux 6.17.0-1014-nvidia aarch64` · gateway `:7443` · hub `:7080` · drumbeat `:9102`
Run: 2026-08-10 04:18–04:28 PDT

---

## 1 · One combined value, minted by the server

`POST /pair/new` now returns the combined value alongside the halves. It is built
**server-side**, because the hub is the only party that knows which address the phone
actually reached it on; a value assembled in the browser is one more place for the two
halves to drift apart.

```
$ curl -s -X POST http://192.168.1.5:7080/pair/new
{
 "code": "aa3d-feb0",
 "expires_at": "2026-08-10T11:42:54.762020+00:00",
 "gateway_url": "https://192.168.1.5:7443",
 "pair_uri": "cortex://pair?gw=https://192.168.1.5:7443&code=aa3d-feb0",
 "single_use": true
}

$ # does the combined value parse into its two halves?
  scheme=cortex  action=pair
  gw   = https://192.168.1.5:7443
  code = aa3d-feb0
  halves match the separately-returned fields: True
```

The URI is deliberately **not** percent-encoded: `https://host:7443` is legal unencoded
in a query value (RFC 3986 — `pchar` admits `:`, query admits `/`), and this is the
literal shape the app lane is parsing.

## 2 · Three copy affordances, feature-detected, honestly reported

All three are present in the served page. Line numbers from `curl -s http://192.168.1.5:7080/`:

```
  72:    <button id="mintbtn" class="btn" type="button">Get pairing link</button>
 135:    return !!(window.isSecureContext && navigator.clipboard && navigator.clipboard.writeText);
 189:      '<button id="copybtn" class="btn sec" type="button">Copy</button>' +
 162:      copied = !!document.execCommand('copy');
 188:      '<div class="pairv" id="pairvalue" title="tap to select all">' + esc(uri) + '</div>' +
 190:      '<p class="status warn" id="pairstatus">Checking what this browser allows...</p>' +
 229:      setStatus('warn', 'Auto-copy is off: the clipboard API needs a secure (https) page and ' +
```

| Tier | Mechanism | On the phone (plain http) |
|---|---|---|
| a | `navigator.clipboard.writeText` | **Expected unavailable.** Gated on `window.isSecureContext`; the page is http, so this is detected as off and *said so*, never assumed to have worked. |
| b | `document.execCommand('copy')` | Works on http in most mobile browsers. The button reports the **actual** boolean the browser returned — a refused copy says nothing was copied. |
| c | tap-to-select-all container | The floor. Monospace, `user-select:all`, one tap selects the whole value. Cannot fail. |

Law 1 detail: every failure path in the status line contains the words *"nothing was
copied"*. There is no path where the page claims a copy it did not make. Tier (a) is
attempted first and reported truthfully either way; the status element starts as
`Checking what this browser allows...` and is only ever replaced by a statement of what
actually happened.

## 3 · Installer config defaults — merged, never templated over

Live host, before/after the first `./install.sh` re-run (`drumbeat_api_key_file` redacted):

```diff
--- config.before.json
+++ config.after.json
@@ -13,5 +13,6 @@
   ],
   "drumbeat_url": "http://127.0.0.1:9102",
   "drumbeat_api_key_file": "<redacted>",
-  "reply_default_automation_slug": "chat"
+  "reply_default_automation_slug": "chat",
+  "fleet_bin": "/home/bkrabach/.local/share/cortex/packs/tmux-kit/bin/tmux-fleet"
 }

pre-existing keys: 9
pre-existing keys whose value changed: none
keys added: ['fleet_bin']
```

Installer transcript for the same run:

```
==> Configuring
  ok    gateway  already configured in /home/bkrabach/.config/cortex/gateway
         added: fleet_bin='/home/bkrabach/.local/share/cortex/packs/tmux-kit/bin/tmux-fleet'
         kept existing: reply_default_automation_slug='chat'
  ok    gateway  config defaults merged into /home/bkrabach/.config/cortex/gateway/config.json
```

Second re-run on the same box — idempotent, no churn:

```
         added: nothing (all keys already present)
         kept existing: reply_default_automation_slug='chat', fleet_bin='/home/.../tmux-kit/bin/tmux-fleet'
```

### Two merge rules the container found, not the author

**`null` is not a set value.** The gateway's own `setup` writes
`reply_default_automation_slug: null`. The first implementation used `if key in cfg`,
so it "kept" the null — leaving a fresh install with the key *present*, the value
*empty*, and replies matching no automation. Present-but-null looked exactly like
configured. Only real values are now preserved (`False` and `0` are real and are kept):

```
BEFORE: {"version":1,"reply_default_automation_slug":null,"fleet_bin":"  "}
        added: reply_default_automation_slug='chat' (was null), fleet_bin='/bin/true' (was blank)
AFTER:  {"version": 1, "reply_default_automation_slug": "chat", "fleet_bin": "/bin/true"}

# a genuinely user-set value survives untouched
        added: nothing (all keys already present)
        kept existing: reply_default_automation_slug='my-own-slug', fleet_bin='/bin/true'
```

**A `fleet_bin` that does not resolve is a dangling pointer, not a preference.** The
gateway's `setup` writes `~/dev/cortex-core/cortex-pack-tmux-kit/bin/tmux-fleet` — a path
that exists on this workstation and on nobody else's box. The fresh container proved it:

```
REPAIRED: fleet_bin='/home/rehearse/.local/share/cortex/packs/tmux-kit/bin/tmux-fleet'
          (was '~/dev/cortex-core/cortex-pack-tmux-kit/bin/tmux-fleet', which does not resolve here)
kept existing: reply_default_automation_slug='chat'
```

A `fleet_bin` that **does** resolve is never touched:

```
        added: nothing (all keys already present)
        kept existing: reply_default_automation_slug='mine', fleet_bin='/bin/true'
```

## 4 · Doctor — four new checks, and they are not checks that cannot fail

Final run on this host, `cortex doctor` → **exit 0, all checks passed, zero warnings**:

```
Configuration
PASS  reply slug             reply_default_automation_slug=chat
PASS  fleet_bin              ~/dev/cortex-core/cortex-pack-tmux-kit/bin/tmux-fleet -> /home/bkrabach/dev/cortex-core/cortex-pack-tmux-kit/bin/tmux-fleet (executable)

Rails
PASS  GET /v1/notifications  rail present, 401 unauthenticated (device auth enforced, as contracted)
PASS  delivery cursor        cursor 40891, lag 0, updated 2026-08-10T11:27:37.228218+00:00

doctor: all checks passed
```

**These four were observed failing before they were observed passing** — which is the only
way to know a check is real:

| Check | Seen failing | Seen passing |
|---|---|---|
| `reply slug` | `FAIL … not set in …/config.json` (fresh container, before the null fix) | `PASS reply_default_automation_slug=chat` |
| `fleet_bin` | `FAIL fleet_bin not set` (host, pre-merge); `FAIL ~/dev/…/tmux-fleet does not exist` (container) | `PASS … (executable)` |
| `GET /v1/notifications` | `WARN not served by the running gateway yet (404)` | `PASS rail present, 401 unauthenticated` |
| `delivery cursor` | `WARN no cursor published: …/.delivery-worker-cursor.json does not exist …` | `PASS cursor 40891, lag 0` |

The `/v1/notifications` check flipped from WARN to PASS **with no code change**, when the
gateway lane landed the endpoint mid-run. Per the coordination note, a check that lands
before its endpoint does exists says so — `404` is reported as *"not served by the running
gateway yet … this check is not a pass and does not pretend to be"*, as a WARN that keeps
doctor honest without inventing a green. It also distinguishes `401/403` (present,
enforcing), `200` (present, **not** enforcing — flagged), `000` (gateway down, FAIL) and
`NOCA` (unverifiable).

The `fleet_bin` check expands a leading `~` before judging the path and shows both forms
(`configured -> resolved`); judging the unexpanded string failed a path that actually works.

## 5 · Rehearsal — fresh ubuntu:24.04 container, exit 0

```
REHEARSE_EXIT=0
137:INSTALL_EXIT=0
187:DOCTOR_EXIT=0
270:REINSTALL_EXIT=0
287:=== rehearsal finished 2026-08-10T04:26:08-07:00 (docker rc=0) ===
```

Full transcript: `EVIDENCE/rehearsal-raw.log`. New `PHASE 8b` exercises the hand-off inside
the container:

```
########## PHASE 8b  one-value pairing hand-off
-- the three copy affordances are present in the served page --
  tier A auto-copy (secure-context gated): 1
  tier B Copy button (legacy execCommand): 4
  tier C tap-to-select container:          2
  status line naming the active tier:      1
-- POST /pair/new returns ONE combined value, and it parses --
{ "code": "6045-640c", …
  "pair_uri": "cortex://pair?gw=https://172.17.0.4:7443&code=6045-640c", … }
  gw   -> https://172.17.0.4:7443
  code -> 6045-640c
  halves match the separate fields: True
```

`PHASE 8` also stopped dumping the APK into the transcript. Now that a real 14 MB build
exists, `curl … /cortex.apk` was writing 14 MB of binary into the evidence log (521 KB of
it survived as mojibake, and `grep` refused to read the file as text). The 404 body is
still printed in full — that is the honest-failure text under test — but a real build is
reported by type and size. Log is back to 12 KB of ASCII.

---

## Cross-lane notes for the gateway lane

Both found by this round's rehearsal, both outside this lane to fix:

1. **`setup` writes a dev-workspace `fleet_bin`.** `~/dev/cortex-core/cortex-pack-tmux-kit/bin/tmux-fleet`
   resolves on this workstation and nowhere else. A fresh install gets a config that looks
   complete and fails at the first `fleet_status` call. This installer now repairs a
   non-resolving `fleet_bin` (and says so loudly), but the template should point at the
   installed pack.

2. **A new required key with no migration path.** Mid-run, `serve` began refusing to start:

   ```
   FATAL: config at /home/bkrabach/.config/cortex/gateway/config.json is missing required
   key 'drumbeat_runs_dir' -- re-run `cortex-gateway setup --force` or edit the file directly
   [cortex] gateway exited rc=2
   ```

   Every existing install was bricked by that until the key was added by hand. The
   suggested remedy — `setup --force` — regenerates the CA, which would unpair the phone
   that was paired an hour earlier, so it was **not** used. The value applied here was read
   from a throwaway `cortex-gateway setup` into a temp config dir (the gateway's own
   generator, not a guess by this lane): `drumbeat_runs_dir = "~/.local/state/cortex/drumbeat/runs"`.
   By the time it was written the key was already present — the lane appears to have
   patched the host in parallel. Recommend `setup` backfill missing keys into an existing
   config, the way this installer's merge does, rather than making `serve` fatal on an
   install that worked an hour ago.

## What a stakeholder does now

1. Open `http://192.168.1.5:7080/` on the phone.
2. Install the APK (step 1), open Cortex, tap Settings (step 2).
3. Tap **Get pairing link** (step 3). One value appears, with a Copy button and a
   tap-to-select box, and a line telling you which of those actually worked.
4. Paste it into the pairing field, tap **Pair** (step 4).

If the build still has two fields, the same card prints the gateway URL and the code
separately underneath the combined value.
