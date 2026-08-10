# Changelog

All notable, user-visible changes to the Cortex hub lane.

## [Unreleased]

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
  unprivileged user against a read-only workspace: bare box to serving
  distribution page in **22 seconds** (3.1s of that is `install.sh`), idempotent
  re-run in 0.49s. Transcript and analysis in
  [`EVIDENCE/rehearsal.md`](EVIDENCE/rehearsal.md), raw log alongside it.
- The rehearsal found five defects invisible on the dev host — including a
  status line that read `down` next to `200`, and a `/dev/tty` probe that passed
  where no terminal existed. All fixed; see the defect table in the evidence.
