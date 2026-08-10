# Changelog

All notable, user-visible changes to the Cortex hub lane.

## [Unreleased]

### Fixed

- **You can now get a pairing code without reading the source.** The gateway
  always had one (`cortex-gateway pair`), but it lives inside a venv under
  `~/.local/share/cortex/gateway/` that the page never mentioned — so the phone
  asked for a code that existed nowhere a person could reach. The distribution
  page has a **Get pairing code** button, and there is a **`cortex pair`** command
  for the terminal. Both print the code, its expiry, and that it is single use.
- **The page no longer promises a QR scanner the app does not have.** It said
  *"Open Cortex → Pair → scan"*. The Android app has two text fields and a Pair
  button; there is no scanner in it. The instructions are now the five steps the
  app actually puts in front of you — install, Settings, type the gateway URL
  (shown exactly), get a code, type it and tap Pair.
- **The QR code now points at this page, not the gateway.** Scanning the old one
  produced the gateway address in a camera app, with nothing able to accept it.
  It is labelled for what it does: open this page on the phone.

### Added

- **`install.sh`** — one-command, curl-pipeable, idempotent installer for the whole
  stack. Reports every missing prerequisite at once before touching the machine.
  Installs gateway, drumbeat and the hub; configures the drumbeat workspace and
  the OpenAI key file; starts everything in a tmux session.
- **`cortex` CLI** — `status`, `doctor`, `logs`, `start`, `stop`, `restart`, `url`.
  `doctor` checks prerequisites, components, config, live services and the
  protected neighbouring ports; every failure names the command that fixes it.
- **Distribution page on :7080** — pairing instructions, gateway URL, and a QR
  code of it. Serves `cortex.apk` out of `dist/` the moment a build lands, with
  no restart.
- **`README.md`** — the stakeholder path: one command, what it does, how to pair
  a phone, and what to do when something is wrong.

### Deliberately not done

- **No placeholder APK.** With no build published, `/cortex.apk` returns a 404
  that says the build is missing. A placeholder file would install as a broken
  app on the stakeholder's phone.
- **No empty `automations/`.** If cortex-mind supplies none, the directory is
  not created. drumbeat then refuses to start — which is correct. An empty
  automations directory makes the engine boot happily and schedule nothing.
- **No stubs for lanes that have not landed.** Missing components are named
  individually, the rest still install, and the installer exits non-zero. An
  install that reports success while half the stack is absent is worse than one
  that fails.
- **No `curl -k`, anywhere.** The gateway's TLS is verified against a CA from
  disk when one exists, otherwise against the CA the gateway itself publishes at
  `/api/ca` — and that case is labelled trust-on-first-use, not proof.

### Notes for operators

- Logs are written with `tee -a`, never plain `tee`: a restart appends rather
  than truncating, so the record of why the last run died survives.
- A crashed service keeps its tmux window open with the traceback on screen
  instead of vanishing.
- `cortex stop` drains drumbeat by its own documented procedure and kills only
  the tmux session named `cortex`. It never uses `pkill -f`, which matches far
  more than intended — including, as this lane found out first-hand, the shell
  that ran it.
- Cortex binds only 7443, 9102 and 7080. Ports 8443, 9443, 9000, 9100 and 8088
  belong to other live services on the demo host; `cortex doctor` reports them
  as untouched neighbours. Note that 9100 is drumbeat's *default* port and
  belongs to a different instance — the Cortex instance is always started with
  an explicit `--port 9102`.

### Verified

- **Fresh-container install rehearsal** on stock `ubuntu:24.04` as an
  unprivileged user against a read-only workspace, with nothing pre-installed:
  bare box to all three services live in **23 seconds** (3.76s of that is
  `install.sh`), `cortex doctor` **all checks passed**, gateway `/healthz` 200
  with TLS verified against the CA on disk, idempotent re-run in 1.07s.
  Transcript and analysis in [`EVIDENCE/rehearsal.md`](EVIDENCE/rehearsal.md).
- **`cortex doctor` on the demo host**: all checks passed, gateway + drumbeat +
  hub live. See [`EVIDENCE/doctor-thishost.md`](EVIDENCE/doctor-thishost.md).
- The rehearsal found eight defects invisible on the dev host — among them a
  `start` that reported success for a service which had already exited, an
  installer that printed "Cortex is installed" over a crashed gateway, and a
  `--port` flag passed to a CLI that does not accept it. All fixed; full table
  in the evidence.
