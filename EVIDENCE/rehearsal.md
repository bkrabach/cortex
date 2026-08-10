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
| Run date | 2026-08-10 04:39:30 UTC |

---

## Timings

| Phase | Wall clock | Elapsed |
|---|---|---|
| Phase 0 — stock box, nothing installed | 04:39:30 | — |
| Phase 3 — `apt-get install` prerequisites done | 04:39:47 | 17s |
| Phase 4 — `uv` installed as the user | 04:39:48 | 18s |
| Phase 5 — **`./install.sh` finished** | 04:39:51 | 21s (**3.09s** for install.sh itself) |
| Phase 6-9 — doctor, status, page serving, gateway probe | 04:39:51 | 21s |
| Phase 12 — done | 04:39:52 | **22s total** |
| Phase 10 — idempotent re-run of the same command | — | **0.49s** |

Bare box to serving distribution page: **22 seconds**, of which 17 were `apt`.

---

## Results against the DONE gate

| Gate | Result | Evidence |
|---|---|---|
| Install runs as a normal user from a read-only workspace | **PASS** | Phase 5; Phase 12 confirms `/workspace` rejected a write |
| `cortex doctor` green apart from genuinely-absent pieces | **PASS** with 2 named FAILs, both the gateway lane | Phase 6 |
| Missing OpenAI key reported honestly, install continues | **PASS** | Phase 6: `WARN openai key absent -- voice minting will 503 (by design, naming the remedy)` |
| `:7080` page serves | **PASS** | Phase 8: `GET / -> 200`, `GET /healthz -> 200` |
| Gateway healthz 200 | **NOT REACHED** — gateway not installable at run time | Phase 9: `https healthz -> 000`; see below |
| Idempotent | **PASS** | Phase 10: same command, 0.49s, `already running -- nothing to start`, no clobbering |

### The one gate not met, and why

`cortex-gateway` has published `CONTRACT.md` but no `pyproject.toml` yet, so there
is nothing to install. Both FAILs in Phase 6 trace to that single fact:

```
FAIL  gateway     not installed
      remedy: the gateway lane's checkout must exist, then re-run install.sh
FAIL  gateway :7443   not listening
      remedy: cortex start; then cortex logs gateway
```

This is recorded as an honest miss, not worked around. **Nothing was stubbed.** The
installer named the component, installed everything else, and exited 2 —
`INSTALL_EXIT=2`, an incomplete install refusing to report success. The moment
that lane ships a `pyproject.toml`, re-running the identical command picks it up;
the rehearsal is re-runnable in 22 seconds to confirm.

What *did* come up, unaided, on a box that had nothing 20 seconds earlier:

```
PASS  drumbeat :9102         api/health 200
PASS  hub :7080              healthz 200
PASS  tmux session           'cortex' (2 windows)
PASS  drumbeat packs.txt     1 pack(s)
```

---

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
| 1 | The rehearsal script itself picked up an ambient `IMAGE=nvcr.io/nvidia/vllm` from the operator's shell and rehearsed against a CUDA image instead of Ubuntu. A generic env var name got captured. | Namespaced to `CORTEX_REHEARSAL_IMAGE`, and the run is invoked with `env -u IMAGE`. |
| 2 | `docker run` without `-i` silently discarded the entire container script — exit 0, no output, a green result that tested nothing. | Added `-i`; a run that executes nothing can no longer look like a pass. |
| 3 | `[ -r /dev/tty ]` returned true inside `docker run` with no TTY behind it, so the key prompt printed and then errored: `/dev/tty: No such device or address`. | The probe now *opens* the device (`exec 3< /dev/tty`) — the only honest test. Same path protects `curl \| bash`. |
| 4 | `cortex status` showed `STATE=down` beside `HEALTH=200` on a minimal box, because neither `ss` nor `lsof` exists there and state was inferred from pid lookup. A status line that contradicts itself. | State now comes from whether the port actually accepts a connection; pid shows `n/a` when it cannot be resolved. |
| 5 | Remedy text rendered as `printf '%%s' sk-...` — a literal that would fail if pasted. | Corrected to `printf '%s'`; grep confirms 0 occurrences of `%%s` in the transcript. |

Two further defects were caught on the dev host before this run: the hub crashed
on startup because segno's SVG writer emits bytes into a `StringIO`, and
`http_code` concatenated two codes into `000000` on failure. Both were visible
only because the tmux window is kept open on crash and the log is written with
`tee -a`.

---

## Re-run

```bash
./EVIDENCE/rehearse.sh > EVIDENCE/rehearsal-raw.log 2>&1
```

Takes ~25 seconds. Re-run this once the gateway lane ships its `pyproject.toml`
to close the one open gate.
