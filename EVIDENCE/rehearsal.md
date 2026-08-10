# Fresh-container install rehearsal

**What this proves:** a person who has never touched this project can go from a
stock Ubuntu box to a serving Cortex stack with one command, and that when a
piece of the stack is genuinely missing the installer says so by name instead of
faking it.

Reproduce with `./EVIDENCE/rehearse.sh`. Full unedited transcript:
[`rehearsal-raw.log`](rehearsal-raw.log).

---

## Conditions

| | |
|---|---|
| Host | Linux 6.17.0-1014-nvidia **aarch64** |
| Container | `ubuntu:24.04` (stock), `docker run --rm -i` |
| Pre-installed | **nothing** from the install story — no python3, no uv, no git, no tmux, no curl (Phase 0 proves each ABSENT) |
| Ran as | unprivileged user `rehearse`; only apt and `useradd` ran as root |
| Workspace | `/home/bkrabach/dev/cortex-core` mounted **read-only** at `/workspace` |
| drumbeat | `~/dev/amplifier-attention-manager/drumbeat` mounted **read-only** at `/drumbeat` |
| OpenAI key | **deliberately not provided** — the missing-key path is the thing under test |
| Run date | 2026-08-10 04:48:19 UTC |

---

## Timings

| Phase | Wall clock | Elapsed |
|---|---|---|
| Phase 0 — stock box, nothing installed | 04:48:19 | — |
| Phase 3 — `apt-get install` prerequisites done | 04:48:36 | 17s |
| Phase 4 — `uv` installed as the user | 04:48:37 | 18s |
| Phase 5 — **`./install.sh` finished, all three services up** | 04:48:41 | 22s (**3.76s** for install.sh itself) |
| Phase 6-9 — doctor, status, page, gateway healthz | 04:48:41 | 22s |
| Phase 12 — done | 04:48:42 | **23s total** |
| Phase 10 — idempotent re-run of the same command | — | **1.07s** |

Bare box to a fully serving stack: **23 seconds**, of which 17 were `apt`.

## Results against the DONE gate

| Gate | Result | Evidence |
|---|---|---|
| Install runs as a normal user from a read-only workspace | **PASS** | Phase 5; Phase 12 confirms `/workspace` rejected a write |
| `cortex doctor` all green | **PASS** — `doctor: all checks passed`, `DOCTOR_EXIT=0` | Phase 6 |
| Missing OpenAI key reported honestly, install continues | **PASS** — reported as a named WARN, not hidden, not fatal | Phase 6 |
| `:7080` page serves | **PASS** | Phase 8: `GET / -> 200`, `GET /healthz -> 200` |
| Gateway healthz 200 | **PASS** — TLS verified against the CA on disk, no `curl -k` | Phase 9 |
| Idempotent | **PASS** | Phase 10: same command, 1.07s, no clobbering |

All three services came up on a box that had nothing 22 seconds earlier:

```
up   gateway   :7443
up   drumbeat  :9102
up   hub       :7080

3 up
```

```
Components
PASS  gateway     /home/rehearse/.local/share/cortex/gateway/venv/bin/cortex-gateway
PASS  drumbeat    /home/rehearse/.local/share/cortex/drumbeat/venv/bin/drumbeat
PASS  hub         /home/rehearse/.local/share/cortex/hub/serve.py
PASS  mind        /home/rehearse/.local/share/cortex/mind
PASS  pack        /home/rehearse/.local/share/cortex/packs/tmux-kit

Services
PASS  tmux session   'cortex' (3 windows)
PASS  hub :7080      healthz 200
PASS  gateway :7443  healthz 200, TLS verified against the CA it serves at /api/ca
PASS  drumbeat :9102 api/health 200

doctor: all checks passed (2 warning(s) -- named above, none fatal)
DOCTOR_EXIT=0
```

Phase 9, verified against the CA `cortex-gateway setup` wrote to disk:

```
using CA: /home/rehearse/.config/cortex/gateway/tls/ca.pem
https healthz -> 200
body: {"status":"ok","service":"cortex-gateway","version":"0.1.0","time":"...","port":7443}
```

### The two warnings, both intended

- **`openai key absent`** — no key was supplied to this run on purpose. The stack
  installs and runs; voice minting will 503 naming its remedy. Reported loudly,
  never hidden, and non-fatal.
- **`android apk not built yet`** — the android lane had not published a build at
  run time. The hub serves an honest 404 at `/cortex.apk` rather than a
  placeholder. The moment a build lands in `dist/`, the download goes live with
  no restart; re-run this rehearsal to confirm it.

### An earlier run of this same rehearsal caught a real failure

At 04:39 the gateway lane had published `CONTRACT.md` but no installable
package. The rehearsal recorded that honestly — `INCOMPLETE INSTALL`,
`INSTALL_EXIT=2`, two named FAILs — rather than papering over it. At 04:43 the
package existed but crashed on launch, and the installer reported
`INSTALLED, BUT NOT EVERYTHING CAME UP` with the traceback's last line, exit 3.
Both intermediate states are the system behaving correctly under a
partially-built stack. The 04:48 run above is the same command against a
complete one.

## Behaviours specifically exercised

**The prerequisite gate fires before anything is touched** (Phase 2 — run
deliberately on the bare box, before apt):

```
error: 5 prerequisite(s) missing. Nothing was installed.

  - python3 not found -- remedy: sudo apt install python3 (need >= 3.11)
  - uv not found -- remedy: curl -LsSf https://astral.sh/uv/install.sh | sh
  - git not found -- remedy: sudo apt install git
  - tmux not found -- remedy: sudo apt install tmux
  - curl not found -- remedy: sudo apt install curl
```

All five at once, each with its remedy, exit 1. Phase 3 then applies exactly
those remedies and Phase 5 succeeds — the error message is a working script.

**The APK 404 names the missing build** (Phase 8) rather than serving a
placeholder that would install as a broken app on the stakeholder's phone:

```
GET /cortex.apk-> 404

404 no Android build published
Expected: /home/rehearse/.local/share/cortex/dist/cortex.apk
The APK has not been built yet. This hub deliberately serves a 404
rather than a placeholder file -- a placeholder would install as a
broken app. Drop a real build at the path above and reload; the
download goes live with no restart.
```

**The pairing page carries a real QR** (Phase 8), rendered server-side:

```
<svg xmlns="http://www.w3.org/2000/svg" width="174" height="174" class="segno"
https://127.0.0.1:7443/
```

**No secret leaks** (Phase 11). No key was supplied, so there is no key file, and
`sk-` appears **0** times in the served page.

**The read-only mount was never written** (Phase 12):

```
touch: cannot touch '/workspace/cortex/PROOF-RO': Read-only file system
```

**Only our tmux session exists** (Phase 12): `cortex: 2 windows`. Nothing else was
created, and nothing pre-existing was touched.

---

## Defects this rehearsal found, and their fixes

The rehearsal earned its keep — every one of these was invisible on the dev host
and would have surfaced in front of the stakeholder.

| # | Defect | Fix |
|---|---|---|
| 1 | `cortex start` reported "started 3 service(s)" for a gateway that had exited 200ms later. Launching a tmux window is not a service coming up. | Start now waits for each port to actually accept a connection, prints `up`/`DEAD` per service with the dead one's last log line, and returns non-zero. |
| 2 | `install.sh` printed "Cortex is installed" and exited 0 over a crashed service, because every *component* had installed. | New outcome: `INSTALLED, BUT NOT EVERYTHING CAME UP`, exit 3. Complete install with a dead service is not success. |
| 3 | The gateway was launched with `serve --port 7443`, which its CLI does not accept — it takes the port from the config `setup` wrote. It died instantly on an unrecognised argument. | Start probes `serve --help` and passes `--port` only if advertised. Assumed flags are how you kill a service you just installed. |
| 4 | `[ -r /dev/tty ]` returned true inside `docker run` with no TTY behind it, so the key prompt printed and then errored: `/dev/tty: No such device or address`. | The probe now *opens* the device (`exec 3< /dev/tty`) — the only honest test. Same path protects `curl \| bash`. |
| 5 | `cortex status` showed `STATE=down` beside `HEALTH=200` on a minimal box, because neither `ss` nor `lsof` exists there and state was inferred from pid lookup. A status line that contradicts itself. | State now comes from whether the port actually accepts a connection; pid shows `n/a` when it cannot be resolved. |
| 6 | Remedy text rendered as `printf '%%s' sk-...` — a literal that fails if pasted. | Corrected to `printf '%s'`; grep confirms 0 occurrences in the transcript. |
| 7 | The rehearsal script itself picked up an ambient `IMAGE=nvcr.io/nvidia/vllm` from the operator's shell and rehearsed against a CUDA image instead of Ubuntu. | Namespaced to `CORTEX_REHEARSAL_IMAGE`; the run is invoked with `env -u IMAGE`. |
| 8 | `docker run` without `-i` silently discarded the entire container script — exit 0, no output, a green result that tested nothing. | Added `-i`. A run that executes nothing can no longer look like a pass. |

Two further defects were caught on the dev host before the first container run:
the hub crashed on startup because segno's SVG writer emits bytes into a
`StringIO`, and `http_code` concatenated two codes into `000000` on failure.
Both were visible only because the tmux window is kept open on crash and the log
is written with `tee -a`.

A ninth was self-inflicted and worth recording: a `pkill -f` issued to clean up a
test server matched the very shell that ran it. That is precisely why
`cortex stop` drains by procedure and kills by session name, and why no code in
this lane uses `pkill -f`.

## Re-run

```bash
./EVIDENCE/rehearse.sh > EVIDENCE/rehearsal-raw.log 2>&1
```

Takes ~25 seconds. Re-run this once the gateway lane ships its `pyproject.toml`
to close the one open gate.
