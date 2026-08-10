# Cortex

**Your chief of staff.** One assistant, three ways to reach it:

| Modality | What it is |
|---|---|
| **Calling** | Realtime voice. Talk to it. |
| **Texting** | Native phone notifications you can reply to. |
| **Face-to-face** | Chat. |

Same identity, same memory, same judgment across all three.

---

## Install it

On the machine that will host Cortex (Linux or macOS, Python 3.11+):

```bash
git clone <this repo> && cd cortex
./install.sh
```

That is the whole thing. Then open the address it prints on your phone.

### What that actually does

1. **Checks prerequisites** — `python3` (3.11+), `uv`, `git`, `tmux`, `curl`. If any
   are missing it lists *all* of them with install commands, and stops without
   touching your machine.
2. **Installs three services** into `~/.local/share/cortex/`:

   | Service | Port | Role |
   |---|---|---|
   | `cortex-gateway` | **7443** (https) | the phone talks to this |
   | `drumbeat` | **9102** (http, loopback) | the automation engine |
   | `cortex hub` | **7080** (http) | app download + pairing page |

3. **Asks for your OpenAI key** once (or takes `$OPENAI_API_KEY` from the
   environment) and writes it to `~/.config/cortex/gateway/openai_key`, mode
   `0600`. It is never committed, never logged, and never appears in an HTTP
   response.
4. **Starts everything** in a tmux session called `cortex`, one window per
   service, logs tee'd to `~/.local/state/cortex/logs/`.
5. **Prints the pairing URL.**

Re-running `./install.sh` is safe at any time. It is idempotent: it will not
clobber your key, your config, or a running stack.

---

## Pair your phone

1. Open the pairing page on the phone — `http://<host>:7080/`, the address the
   installer printed. `cortex url` prints it again any time.
2. **Download Cortex for Android** from that page and install it. Android will
   warn you about installing outside the Play Store; allow it for your browser.
   This is a direct build, not a store release.
3. **Scan the QR code** on the same page, or type the gateway address into the
   app. The QR encodes `https://<host>:7443/`.
4. On the host, run `cortex-gateway pair`. It prints a short code
   (`xxxx-xxxx`, good for 15 minutes, single use). Enter it in the app.
5. Say **"what needs me?"** That exercises voice, the gateway, and the engine in
   one shot. On a fresh install the honest answer is "nothing" — that is a
   working system, not a broken one.

The gateway uses its own certificate authority. The app fetches and trusts it
during pairing. Nothing here asks you to disable certificate checking, and you
should be suspicious of anything that does.

---

## Run it

```bash
cortex status     # ports, pids, health — one screen
cortex doctor     # check everything; every failure names its own remedy
cortex logs       # tail all services   (cortex logs gateway -f to follow one)
cortex start      # start the stack
cortex stop       # drain, then stop
cortex restart
cortex url        # the pairing URL
```

**`cortex doctor` is the gate.** If it is green, the stack is good. If it is not,
each red line tells you the exact command that fixes it. Run it first, always.

Two expected non-fatal warnings:

- **No OpenAI key** — the stack runs; voice minting returns `503` with the
  remedy in the response body. Write the key file and it takes effect.
- **No Android build yet** — the hub serves an honest `404` at `/cortex.apk`
  rather than a placeholder file, because a placeholder installs as a broken
  app. Drop a real build into `dist/` and the download goes live with no
  restart.

---

## When something is wrong

| Symptom | First move |
|---|---|
| Anything at all | `cortex doctor` — it names the remedy |
| A service will not stay up | `cortex logs <service>` — the tmux window is kept open on crash, with the traceback intact |
| Phone cannot reach the gateway | Confirm phone and host are on the same network; `cortex url` gives the address to use |
| Voice returns 503 | The key file is missing: `printf '%s' sk-... > ~/.config/cortex/gateway/openai_key && chmod 600 ~/.config/cortex/gateway/openai_key` |

Logs live in `~/.local/state/cortex/logs/`. They are appended, never truncated,
so a restart does not destroy the evidence of why the last run died.

---

## Installing from somewhere else

The installer resolves each component from an environment variable, falling back
to a sibling checkout. Point them anywhere:

```bash
CORTEX_GATEWAY_SRC=/path/to/cortex-gateway \
CORTEX_MIND_SRC=/path/to/cortex-mind \
CORTEX_PACK_SRC=/path/to/cortex-pack-tmux-kit \
CORTEX_DRUMBEAT_SRC=/path/to/drumbeat \
./install.sh
```

These defaults become published URLs once the repos are public; nothing else in
the installer changes when they do.

If a component has not been built yet, the installer says so by name, installs
everything else, and exits non-zero. It never stubs a missing piece — an
install that reports success while quietly missing half the stack is worse than
one that fails.

`drumbeat` is a **dependency**, installed from its own checkout. It is never
vendored into this repo.

---

## The bigger picture

This README covers getting Cortex running. For what it is becoming:

- [`docs/vision/`](docs/vision/) — the foundational vision documents
- [`ROADMAP.md`](ROADMAP.md) — phases and current status
- [`AGENTS.md`](AGENTS.md) — architecture and development guidelines
- `../cortex-gateway/CONTRACT.md` — the device ↔ gateway API, source of truth

Built on the [Amplifier](https://github.com/microsoft/amplifier) ecosystem.
