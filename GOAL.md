FIRST: read /home/bkrabach/dev/cortex-core/CONTRACT-PINS.md and honor every pin and law in it.

# LANE: cortex (hub) — turnkey install, supervision, distribution

You own this repo (/home/bkrabach/dev/cortex-core/cortex, git initialized). This is the piece every
predecessor deferred and the reason tomorrow's demo exists: **a stakeholder must be able to install
the whole Cortex stack with one command and pair his phone.** Donors: the install-rehearsal +
runbook patterns named in the pins file; drumbeat serve/systemd notes in its README.

## Deliverables

1. **install.sh** (curl-pipeable, idempotent, fail-loud with named remedies):
   - prereq checks: python3.11+, uv, git, tmux (report ALL missing at once, then stop)
   - source resolution: env overrides CORTEX_GATEWAY_SRC / CORTEX_MIND_SRC /
     CORTEX_DRUMBEAT_SRC (default the sibling checkouts in this workspace tonight; GitHub URLs
     become the default once published — leave the seam obvious)
   - installs: gateway (uv venv), drumbeat (uv pip install from CORTEX_DRUMBEAT_SRC =
     ~/dev/amplifier-attention-manager/drumbeat — a DEPENDENCY, never vendored), cortex-mind →
     ~/.local/share/cortex/mind
   - config: runs gateway setup, generates drumbeat instance config (port 9102, workspace
     ~/.local/state/cortex/drumbeat, packs.txt pointing at cortex-pack-tmux-kit), accepts
     OPENAI_API_KEY from env or prompts once → ~/.config/cortex/gateway/openai_key (0600)
   - starts services in a tmux session `cortex` (windows: gateway :7443, drumbeat :9102,
     hub :7080) — logs with `tee -a` (a predecessor lost a night of logs to plain tee)
2. **Distribution page** on :7080 (stdlib http server is fine): downloads cortex.apk (from
   ./dist/, placed there by the android lane — serve a clear "not built yet" 404 until it exists,
   never a placeholder file), shows pairing instructions + gateway URL + QR.
3. **`cortex` CLI** (bash is fine): `cortex status` (ports/pids/health), `cortex doctor`
   (checks every prereq + service + key presence; names each failure + remedy), `cortex logs`.
4. **README.md**: the stakeholder path — one command, what happens, how to pair the phone.

## DONE gates (artifacts in EVIDENCE/, real output only)

- **Fresh-container rehearsal**: docker or incus ubuntu container, workspace mounted read-only,
  run install.sh as a normal user → `cortex doctor` all green (missing OPENAI key must be
  reported honestly by doctor and mint must 503-name-remedy — that is a PASS state for the
  rehearsal) → :7080 page serves → gateway healthz 200. Full transcript in
  EVIDENCE/rehearsal.md with timings.
- `cortex doctor` on THIS host: all green with services live.
- All work committed. CHANGELOG.md current.

Coordination: gateway/drumbeat/mind lanes are building in sibling dirs right now. Install from
their checkouts as they land; if a piece isn't ready, stub NOTHING — doctor names it missing and
the rehearsal records the honest state. Re-run the rehearsal once they land.

Blocked? Write BLOCKED.md per pins law 7 and stop.
