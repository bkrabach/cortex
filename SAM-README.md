# Cortex — install it on your machine

Cortex is a personal AI chief of staff. It reaches you three ways, all one identity:

- **Calling** — realtime voice. You talk, it answers, it can act.
- **Texting** — native phone notifications you can reply to inline.
- **Face-to-face** — chat.

This package installs the whole stack on **your** machine and pairs **your** phone
to it. Nothing here phones home to anyone else's box.

---

## 1. What you need first

Four things. The installer checks all four **before touching anything**, and if
any are missing it prints every one of them with the exact command to fix it,
installs nothing, and exits 1. You will not discover them one at a time.

| Need | Why | Ubuntu/Debian |
|---|---|---|
| `python3` **3.11+** | the gateway and engine are Python | `sudo apt install python3` |
| `uv` | installs the Python components into isolated venvs | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `git` | one dependency is fetched from a git tag | `sudo apt install git` |
| `tmux` | Cortex supervises its three services in a tmux session | `sudo apt install tmux` |
| `curl` | health checks | `sudo apt install curl` |

After installing `uv`, **open a new shell** (it adds `~/.local/bin` to your PATH).

Linux or macOS. Not Windows — WSL is fine.

---

## 2. The one command

```bash
tar -xzf cortex-demo-*.tar.gz
cd cortex-demo-*
./install-cortex.sh
```

Usually under two minutes. It is **safe to re-run** — it is idempotent, and
re-running is the correct response to almost any problem you hit.

**Keep the extracted folder.** The installer serves the Android build straight
out of `cortex/dist/` in this directory, so deleting it after installing takes
the phone download with it.

### It will ask for one thing

```
OpenAI API key (input hidden, press Enter to skip):
```

Paste an OpenAI API key. It is written to `~/.config/cortex/gateway/openai_key`
with mode 0600, is never committed anywhere, and never appears in any HTTP
response.

You can press Enter and skip it. Everything installs and runs; **voice** will
return a 503 that names this exact remedy until you add one. The key is read
per request, so adding it later takes effect immediately:

```bash
printf '%s' sk-... > ~/.config/cortex/gateway/openai_key
chmod 600 ~/.config/cortex/gateway/openai_key
```

You can also set `OPENAI_API_KEY` in your environment before running the
installer and it will not prompt.

---

## 3. What comes up

Three services, in a tmux session named `cortex`:

| Service | Port | What it is |
|---|---|---|
| gateway | **7443** (https) | the front door your phone talks to — pairing, voice, replies |
| drumbeat | **9102** (http) | the automation engine that decides what deserves your attention |
| hub | **7080** (http) | this install's own web page: app download + pairing |

Check it at any time:

```bash
cortex doctor     # every component, config value and service, with reasons
cortex status     # ports, health, one line each
cortex logs       # follow all three
cortex stop       # stop everything
cortex start      # start it again
```

`cortex doctor` is the one to run when anything looks wrong. It **names** what
is broken and the remedy. Warnings are not failures — a missing OpenAI key, for
example, is reported as a warning with its remedy and the install is still good.

---

## 4. Pair your phone

Open the hub page on **the phone**, on the same network:

```bash
cortex url        # prints the URL — e.g. http://192.168.1.50:7080/
```

The page shows a QR code you can scan from another machine, and walks four steps:

1. **Install the app** — tap *Download Cortex for Android*, then open the
   downloaded APK. Android will ask you to allow installs from your browser;
   this is a direct build, not a Play Store listing.
2. **Open Cortex, tap Settings → Pair with gateway.**
3. **Back on the hub page, tap *Get pairing link*.** One value appears. The page
   copies it automatically where the browser allows it; if not, there is a Copy
   button, and failing that you can tap the value to select it.
4. **Paste the whole link into the app and tap Pair.**

That single link carries both the gateway address and the code — there is no
second field to get wrong. Codes are short-lived; if one expires, tap
*Get pairing link* again.

If the phone cannot reach the gateway, it is almost always a firewall on this
machine: ports **7080** and **7443** need to be reachable from your LAN.

---

## 5. Five minutes with it

Try these three, in this order. They exercise all three modalities.

**1 · Ask it what matters (voice, ~1 min)**

In the app, start a call and say:

> "What needs me?"

It answers out loud with what it thinks is actually worth your attention right
now, not a list of everything.

**2 · Reply to a notification (texting, ~2 min)**

Wait for a Cortex notification, then reply to it **inline from the notification
shade** — the same way you would reply to a text, without opening the app. The
reply is routed back through the gateway to the engine and acted on. This is the
bit that usually surprises people: it is a real two-way channel, not an alert.

**3 · Tell it something for us (~1 min)**

By voice or chat:

> "Log that for the developers: <whatever you just noticed>"

It captures the feedback with the surrounding context. This is how you report
anything in this list that did not do what it says.

---

## 6. What is in the box

```
cortex-demo-<date>/
  install-cortex.sh      the one command (a thin redirect into cortex/install.sh)
  SAM-README.md          this file
  PACKAGE-PINS.md        exact commit of every component, including drumbeat
  cortex/                the hub page, the `cortex` CLI, the installer, the APK
  cortex-gateway/        device <-> gateway API: pairing, TLS, voice, replies
  cortex-mind/           the automations and guidance — what Cortex actually does
  cortex-pack-tmux-kit/  the connector that lets it observe real work sessions
  drumbeat/              the automation engine — a DEPENDENCY, not our code
```

Everything travels in the tarball because the engine has no public home yet and
the rest is private. `PACKAGE-PINS.md` records the exact commit each directory
was copied from, so any of them can be swapped for a real checkout later without
changing anything else.

Installed files live in three places, all under your home directory:

| Path | What |
|---|---|
| `~/.config/cortex/` | config, TLS CA, the OpenAI key (mode 0600) |
| `~/.local/state/cortex/` | logs, the engine's workspace and run history |
| `~/.local/share/cortex/` | the installed components and their venvs |

To remove it: `cortex stop`, then delete those three directories and
`~/.local/bin/cortex`.

---

## 7. If something is wrong

Run this first, and read what it says:

```bash
cortex doctor
```

It is built to name the failing thing and its remedy rather than print a colour.
If it reports a component missing, re-running `./install-cortex.sh` from the
extracted package is the right fix and cannot hurt — it never overwrites config
you have set.

If a service came up and then died, `cortex logs <gateway|drumbeat|hub>` has its
last words; the tmux window is deliberately kept open so the trace survives.
