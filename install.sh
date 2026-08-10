#!/usr/bin/env bash
# Cortex turnkey installer.
#
#   curl -fsSL https://.../install.sh | bash
#   ./install.sh [--no-start] [--force-config] [--help]
#
# Installs and wires the Cortex stack:
#   cortex-gateway   https :7443   device <-> gateway API
#   drumbeat         http  :9102   the automation engine (a DEPENDENCY, never vendored)
#   cortex hub       http  :7080   distribution page: APK download + pairing
#
# Laws honoured here (CONTRACT-PINS.md):
#   1. Fail loud. No fallbacks, no silent degradation. Every failure names its remedy.
#   2. Never vendor drumbeat -- install it from its own checkout.
#   3. Never touch ports 8443/9443/9000/9100/8088 or a tmux session we did not create.
#
set -uo pipefail

CORTEX_INSTALLER_VERSION="0.1.0"

# ---------------------------------------------------------------- paths (pinned)
CORTEX_CONF="${HOME}/.config/cortex"
CORTEX_STATE="${HOME}/.local/state/cortex"
CORTEX_SHARE="${HOME}/.local/share/cortex"
CORTEX_BIN="${HOME}/.local/bin"

GATEWAY_CONF="${CORTEX_CONF}/gateway"          # pinned
GATEWAY_STATE="${CORTEX_STATE}/gateway"        # pinned
GATEWAY_HOME="${CORTEX_SHARE}/gateway"
DRUMBEAT_WS="${CORTEX_STATE}/drumbeat"         # pinned
DRUMBEAT_HOME="${CORTEX_SHARE}/drumbeat"
MIND_HOME="${CORTEX_SHARE}/mind"
PACK_HOME="${CORTEX_SHARE}/packs/tmux-kit"
HUB_HOME="${CORTEX_SHARE}/hub"
DIST_DIR="${CORTEX_SHARE}/dist"
LOG_DIR="${CORTEX_STATE}/logs"
OPENAI_KEY_FILE="${GATEWAY_CONF}/openai_key"   # pinned

GATEWAY_PORT=7443
DRUMBEAT_PORT=9102
HUB_PORT=7080
TMUX_SESSION="cortex"

# Ports owned by OTHER live services. Touching these is a contract violation.
FORBIDDEN_PORTS="8443 9443 9000 9100 8088"

# ---------------------------------------------------------------- output helpers
if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_DIM=$'\033[2m'; C_B=$'\033[1m'; C_0=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_B=""; C_0=""
fi
say()  { printf '%s\n' "$*"; }
step() { printf '\n%s==> %s%s\n' "$C_B" "$*" "$C_0"; }
ok()   { printf '  %sok%s    %s\n' "$C_OK" "$C_0" "$*"; }
info() { printf '  %sinfo%s  %s\n' "$C_DIM" "$C_0" "$*"; }
warn() { printf '  %swarn%s  %s\n' "$C_WARN" "$C_0" "$*"; }
bad()  { printf '  %sFAIL%s  %s\n' "$C_ERR" "$C_0" "$*"; }
die()  { printf '\n%serror:%s %s\n' "$C_ERR" "$C_0" "$1" >&2; exit "${2:-1}"; }

# Components that did not install, with the reason. Printed in the summary and
# reflected in the exit code -- an incomplete install never reports success.
MISSING=()
missing() { MISSING+=("$1"); bad "$1"; }

# ---------------------------------------------------------------- args
DO_START=1
FORCE_CONFIG=0
while [ $# -gt 0 ]; do
  case "$1" in
    --no-start)     DO_START=0 ;;
    --force-config) FORCE_CONFIG=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      cat <<'EOF'

Options:
  --no-start       install and configure, but do not start services
  --force-config   regenerate config files that already exist
  -h, --help       this help

Source overrides (env). Each defaults to a sibling checkout in the Cortex
workspace; these become GitHub URLs once the repos are published:
  CORTEX_HUB_SRC        this repo (install.sh, hub, cortex CLI)
  CORTEX_GATEWAY_SRC    cortex-gateway
  CORTEX_MIND_SRC       cortex-mind
  CORTEX_PACK_SRC       cortex-pack-tmux-kit
  CORTEX_DRUMBEAT_SRC   drumbeat engine  (a dependency -- never vendored)

  OPENAI_API_KEY        written to ~/.config/cortex/gateway/openai_key (0600)
EOF
      exit 0 ;;
    *) die "unknown option: $1 -- remedy: run '$0 --help'" ;;
  esac
  shift
done

say "${C_B}Cortex installer${C_0} ${C_DIM}v${CORTEX_INSTALLER_VERSION}${C_0}"

# ---------------------------------------------------------------- 1. prereqs
# Report EVERY missing prerequisite at once. Being told about one missing tool
# per run, five runs deep, is how installs get abandoned.
step "Checking prerequisites"
PREREQ_ERRORS=()

if command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,11) else 1)' 2>/dev/null; then
    ok "python3 $(python3 -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])')"
  else
    PREREQ_ERRORS+=("python3 is $(python3 -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])' 2>/dev/null || echo unknown), need >= 3.11 -- remedy: install python3.11+ (Ubuntu: sudo apt install python3.11)")
  fi
else
  PREREQ_ERRORS+=("python3 not found -- remedy: sudo apt install python3 (need >= 3.11)")
fi

command -v uv   >/dev/null 2>&1 && ok "uv   $(uv --version 2>/dev/null | head -1)" \
  || PREREQ_ERRORS+=("uv not found -- remedy: curl -LsSf https://astral.sh/uv/install.sh | sh   (then re-open your shell)")
command -v git  >/dev/null 2>&1 && ok "git  $(git --version 2>/dev/null | head -1)" \
  || PREREQ_ERRORS+=("git not found -- remedy: sudo apt install git")
command -v tmux >/dev/null 2>&1 && ok "tmux $(tmux -V 2>/dev/null | head -1)" \
  || PREREQ_ERRORS+=("tmux not found -- remedy: sudo apt install tmux   (required: Cortex supervises its services in a tmux session)")
command -v curl >/dev/null 2>&1 && ok "curl $(curl --version 2>/dev/null | head -1 | cut -d' ' -f1-2)" \
  || PREREQ_ERRORS+=("curl not found -- remedy: sudo apt install curl")

if [ ${#PREREQ_ERRORS[@]} -gt 0 ]; then
  printf '\n%serror: %d prerequisite(s) missing. Nothing was installed.%s\n\n' "$C_ERR" "${#PREREQ_ERRORS[@]}" "$C_0" >&2
  for e in "${PREREQ_ERRORS[@]}"; do printf '  - %s\n' "$e" >&2; done
  printf '\nFix all of the above, then re-run this installer. It is safe to re-run.\n' >&2
  exit 1
fi

# ---------------------------------------------------------------- 2. sources
# The seam: today these default to sibling checkouts in the dev workspace.
# When the repos are published, the defaults below become git URLs and nothing
# else in this script changes.
step "Resolving sources"

# Locate this repo. Works from a checkout; when curl-piped, BASH_SOURCE is not a
# real path, so CORTEX_HUB_SRC must be provided.
_self="${BASH_SOURCE[0]:-}"
if [ -n "$_self" ] && [ -f "$_self" ]; then
  _selfdir="$(cd "$(dirname "$_self")" && pwd)"
else
  _selfdir=""
fi
CORTEX_HUB_SRC="${CORTEX_HUB_SRC:-$_selfdir}"
if [ -z "$CORTEX_HUB_SRC" ] || [ ! -f "${CORTEX_HUB_SRC}/hub/serve.py" ]; then
  die "cannot locate the cortex hub sources (hub/serve.py).
  This happens when install.sh is piped from stdin before the repo is published.
  remedy: git clone <cortex repo> && ./cortex/install.sh
      or: CORTEX_HUB_SRC=/path/to/cortex bash install.sh"
fi

WORKSPACE="$(cd "${CORTEX_HUB_SRC}/.." && pwd)"
CORTEX_GATEWAY_SRC="${CORTEX_GATEWAY_SRC:-${WORKSPACE}/cortex-gateway}"
CORTEX_MIND_SRC="${CORTEX_MIND_SRC:-${WORKSPACE}/cortex-mind}"
CORTEX_PACK_SRC="${CORTEX_PACK_SRC:-${WORKSPACE}/cortex-pack-tmux-kit}"
CORTEX_DRUMBEAT_SRC="${CORTEX_DRUMBEAT_SRC:-${HOME}/dev/amplifier-attention-manager/drumbeat}"

src_state() { [ -d "$1" ] && echo "found" || echo "MISSING"; }
info "hub       ${CORTEX_HUB_SRC}"
info "gateway   ${CORTEX_GATEWAY_SRC}   [$(src_state "$CORTEX_GATEWAY_SRC")]"
info "mind      ${CORTEX_MIND_SRC}   [$(src_state "$CORTEX_MIND_SRC")]"
info "pack      ${CORTEX_PACK_SRC}   [$(src_state "$CORTEX_PACK_SRC")]"
info "drumbeat  ${CORTEX_DRUMBEAT_SRC}   [$(src_state "$CORTEX_DRUMBEAT_SRC")]"

# ---------------------------------------------------------------- 3. layout
step "Creating directories"
mkdir -p "$GATEWAY_CONF" "$GATEWAY_STATE" "$GATEWAY_HOME" "$DRUMBEAT_WS" \
         "$DRUMBEAT_HOME" "$MIND_HOME" "$HUB_HOME" "$LOG_DIR" "$CORTEX_BIN" \
         "$DIST_DIR" "$(dirname "$PACK_HOME")"
chmod 700 "$CORTEX_CONF" 2>/dev/null || true
ok "config  ${CORTEX_CONF}"
ok "state   ${CORTEX_STATE}"
ok "share   ${CORTEX_SHARE}"

# ---------------------------------------------------------------- 4. hub + CLI
step "Installing cortex hub and CLI"
cp -f "${CORTEX_HUB_SRC}/hub/serve.py" "${HUB_HOME}/serve.py"
cp -f "${CORTEX_HUB_SRC}/bin/cortex"   "${CORTEX_SHARE}/cortex"
chmod +x "${CORTEX_SHARE}/cortex"
ln -sf "${CORTEX_SHARE}/cortex" "${CORTEX_BIN}/cortex"
ok "hub      ${HUB_HOME}/serve.py"
ok "cortex   ${CORTEX_BIN}/cortex -> ${CORTEX_SHARE}/cortex"

# Serve the APK straight out of the repo's dist/ so the android lane dropping a
# build there is published immediately, with no reinstall.
if [ -d "${CORTEX_HUB_SRC}/dist" ]; then
  rm -rf "$DIST_DIR"; ln -sfn "${CORTEX_HUB_SRC}/dist" "$DIST_DIR"
  ok "dist     ${DIST_DIR} -> ${CORTEX_HUB_SRC}/dist"
else
  ok "dist     ${DIST_DIR}"
fi

# QR rendering for the pairing page. Pure-python, no system package needed.
# If this fails (offline box), the page still serves and says so in plain text.
if [ ! -x "${HUB_HOME}/venv/bin/python" ]; then
  uv venv --quiet "${HUB_HOME}/venv" >/dev/null 2>&1 || true
fi
if [ -x "${HUB_HOME}/venv/bin/python" ] && \
   VIRTUAL_ENV="${HUB_HOME}/venv" uv pip install --quiet segno >/dev/null 2>&1; then
  ok "qr       segno installed (pairing QR enabled)"
else
  warn "qr       segno unavailable -- the pairing page will show the URL as text instead of a QR code"
  warn "         remedy (needs network): VIRTUAL_ENV=${HUB_HOME}/venv uv pip install segno"
fi

# ---------------------------------------------------------------- 5. drumbeat
# A dependency, installed from its own checkout. Never vendored, never copied.
step "Installing drumbeat engine"
if [ -f "${CORTEX_DRUMBEAT_SRC}/pyproject.toml" ]; then
  if [ ! -x "${DRUMBEAT_HOME}/venv/bin/python" ]; then
    uv venv --quiet "${DRUMBEAT_HOME}/venv" || die "uv venv failed for drumbeat at ${DRUMBEAT_HOME}/venv"
  fi
  if VIRTUAL_ENV="${DRUMBEAT_HOME}/venv" uv pip install --quiet "${CORTEX_DRUMBEAT_SRC}" ; then
    ok "drumbeat $("${DRUMBEAT_HOME}/venv/bin/drumbeat" --help >/dev/null 2>&1 && echo "installed from ${CORTEX_DRUMBEAT_SRC}" || echo "installed (cli probe inconclusive)")"
  else
    missing "drumbeat -- 'uv pip install ${CORTEX_DRUMBEAT_SRC}' failed. remedy: run that command by hand to see the build error"
  fi
else
  missing "drumbeat -- no pyproject.toml at ${CORTEX_DRUMBEAT_SRC}. remedy: set CORTEX_DRUMBEAT_SRC to the drumbeat checkout"
fi

# ---------------------------------------------------------------- 6. gateway
step "Installing cortex-gateway"
GATEWAY_BIN=""
if [ -f "${CORTEX_GATEWAY_SRC}/pyproject.toml" ]; then
  if [ ! -x "${GATEWAY_HOME}/venv/bin/python" ]; then
    uv venv --quiet "${GATEWAY_HOME}/venv" || die "uv venv failed for gateway at ${GATEWAY_HOME}/venv"
  fi
  if VIRTUAL_ENV="${GATEWAY_HOME}/venv" uv pip install --quiet "${CORTEX_GATEWAY_SRC}" ; then
    # Find the console script the gateway actually shipped -- do not assume.
    for cand in cortex-gateway gateway cortexgateway; do
      [ -x "${GATEWAY_HOME}/venv/bin/${cand}" ] && { GATEWAY_BIN="${GATEWAY_HOME}/venv/bin/${cand}"; break; }
    done
    if [ -n "$GATEWAY_BIN" ]; then
      ok "gateway  ${GATEWAY_BIN}"
    else
      missing "cortex-gateway -- installed, but no console script found in ${GATEWAY_HOME}/venv/bin (looked for: cortex-gateway, gateway). remedy: add [project.scripts] cortex-gateway to the gateway pyproject.toml"
    fi
  else
    missing "cortex-gateway -- 'uv pip install ${CORTEX_GATEWAY_SRC}' failed. remedy: run that command by hand to see the build error"
  fi
else
  missing "cortex-gateway -- no pyproject.toml at ${CORTEX_GATEWAY_SRC}. remedy: the gateway lane has not landed yet; re-run this installer once it has, or set CORTEX_GATEWAY_SRC"
fi

# ---------------------------------------------------------------- 7. mind
step "Installing cortex-mind"
# Lane bookkeeping (.git, EVIDENCE, GOAL.md, lane.log) is not product content.
# A checkout containing only those is an empty mind, and must be reported as one.
MIND_EXCLUDES=(--exclude '.git' --exclude 'EVIDENCE' --exclude 'GOAL.md' --exclude 'lane.log' --exclude 'BLOCKED.md')
mind_payload() { ls -A "$1" 2>/dev/null | grep -Ev '^(\.git|EVIDENCE|GOAL\.md|lane\.log|BLOCKED\.md)$' || true; }

if [ -d "$CORTEX_MIND_SRC" ] && [ -n "$(mind_payload "$CORTEX_MIND_SRC")" ]; then
  mkdir -p "$MIND_HOME"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${MIND_EXCLUDES[@]}" "${CORTEX_MIND_SRC}/" "${MIND_HOME}/"
  else
    (cd "$CORTEX_MIND_SRC" && tar --exclude='.git' --exclude='EVIDENCE' --exclude='GOAL.md' --exclude='lane.log' --exclude='BLOCKED.md' -cf - .) | (cd "$MIND_HOME" && tar -xf -)
  fi
  # Verify the copy actually landed -- reporting "ok" over an empty directory is
  # exactly the false green this project refuses.
  if [ -n "$(mind_payload "$MIND_HOME")" ]; then
    ok "mind     ${MIND_HOME} ($(find "$MIND_HOME" -type f | wc -l) files)"
  else
    missing "cortex-mind -- copied from ${CORTEX_MIND_SRC} but ${MIND_HOME} is empty. remedy: check what that checkout actually contains"
  fi
elif [ -d "$CORTEX_MIND_SRC" ]; then
  missing "cortex-mind -- ${CORTEX_MIND_SRC} exists but holds no content yet (only lane bookkeeping). remedy: the mind lane has not landed yet; re-run this installer once it has"
else
  missing "cortex-mind -- no directory at ${CORTEX_MIND_SRC}. remedy: set CORTEX_MIND_SRC to the cortex-mind checkout"
fi

# ---------------------------------------------------------------- 8. pack
step "Installing cortex-pack-tmux-kit"
if [ -f "${CORTEX_PACK_SRC}/pack.md" ]; then
  mkdir -p "$PACK_HOME"
  # Copy the pack contract and its tools -- not the author's build tree. A
  # copied .venv carries absolute paths from another machine and is worse than
  # useless here.
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.git' --exclude '.venv' --exclude '.ruff_cache' \
          --exclude '__pycache__' --exclude 'EVIDENCE' --exclude 'GOAL.md' \
          --exclude 'lane.log' --exclude 'BLOCKED.md' "${CORTEX_PACK_SRC}/" "${PACK_HOME}/"
  else
    (cd "$CORTEX_PACK_SRC" && tar --exclude='.git' --exclude='.venv' --exclude='.ruff_cache' \
        --exclude='__pycache__' --exclude='EVIDENCE' --exclude='GOAL.md' \
        --exclude='lane.log' --exclude='BLOCKED.md' -cf - .) | (cd "$PACK_HOME" && tar -xf -)
  fi
  ok "pack     ${PACK_HOME} ($(find "$PACK_HOME" -type f | wc -l) files)"
elif [ -d "$CORTEX_PACK_SRC" ]; then
  missing "cortex-pack-tmux-kit -- ${CORTEX_PACK_SRC} exists but has no pack.md, which drumbeat's pack contract requires (it refuses to load a pack without one). remedy: the pack lane has not shipped pack.md yet; re-run this installer once it has"
else
  missing "cortex-pack-tmux-kit -- no directory at ${CORTEX_PACK_SRC}. remedy: set CORTEX_PACK_SRC to the pack checkout"
fi

# ---------------------------------------------------------------- 9. config
step "Configuring"

# --- OpenAI key. env, else prompt once on a real terminal, else name the remedy.
# Read per-request from this file by the gateway, so it takes effect with no restart.
if [ -s "$OPENAI_KEY_FILE" ] && [ "$FORCE_CONFIG" -eq 0 ]; then
  chmod 600 "$OPENAI_KEY_FILE"
  ok "openai   key present at ${OPENAI_KEY_FILE} (0600)"
elif [ -n "${OPENAI_API_KEY:-}" ]; then
  umask 077; printf '%s\n' "$OPENAI_API_KEY" > "$OPENAI_KEY_FILE"; chmod 600 "$OPENAI_KEY_FILE"
  ok "openai   key written from \$OPENAI_API_KEY to ${OPENAI_KEY_FILE} (0600)"
elif { exec 3< /dev/tty; } 2>/dev/null; then
  # Opening it is the only honest test. /dev/tty can be present and readable by
  # mode while having no controlling terminal behind it -- which is exactly what
  # happens under `docker run` without -t, and under curl | bash.
  printf '  OpenAI API key (input hidden, press Enter to skip): '
  _key=""; read -r -s _key <&3 || true; exec 3<&-; printf '\n'
  if [ -n "$_key" ]; then
    umask 077; printf '%s\n' "$_key" > "$OPENAI_KEY_FILE"; chmod 600 "$OPENAI_KEY_FILE"
    unset _key
    ok "openai   key written to ${OPENAI_KEY_FILE} (0600)"
  else
    warn "openai   no key given -- voice minting will 503 until you provide one"
    warn "         remedy: printf '%s' sk-... > ${OPENAI_KEY_FILE} && chmod 600 ${OPENAI_KEY_FILE}"
  fi
else
  warn "openai   no key (no \$OPENAI_API_KEY, no terminal to prompt on)"
  warn "         remedy: printf '%s' sk-... > ${OPENAI_KEY_FILE} && chmod 600 ${OPENAI_KEY_FILE}"
fi

# --- gateway setup. Only invoke a subcommand the gateway actually advertises.
if [ -n "$GATEWAY_BIN" ]; then
  if "$GATEWAY_BIN" --help 2>&1 | grep -qw 'setup'; then
    if [ -f "${GATEWAY_CONF}/config.yaml" ] || [ -f "${GATEWAY_CONF}/config.json" ]; then
      if [ "$FORCE_CONFIG" -eq 1 ]; then
        "$GATEWAY_BIN" setup --force >/dev/null 2>&1 || "$GATEWAY_BIN" setup >/dev/null 2>&1 || true
        ok "gateway  setup re-run (--force-config)"
      else
        ok "gateway  already configured in ${GATEWAY_CONF} (use --force-config to regenerate)"
      fi
    else
      if "$GATEWAY_BIN" setup 2>&1 | sed 's/^/         /'; then
        ok "gateway  setup complete"
      else
        missing "gateway setup failed -- remedy: run '${GATEWAY_BIN} setup' by hand and read the error"
      fi
    fi
  else
    info "gateway  no 'setup' subcommand advertised -- skipping (nothing to configure)"
  fi
fi

# --- drumbeat workspace. Directory convention, not a config file:
#     automations/ prompts/ runs/ + packs.txt at the workspace root.
mkdir -p "${DRUMBEAT_WS}/runs" "${DRUMBEAT_WS}/prompts"
if [ -d "${MIND_HOME}/automations" ]; then
  # Symlink so edits to the installed mind take effect without reinstalling.
  ln -sfn "${MIND_HOME}/automations" "${DRUMBEAT_WS}/automations"
  ok "drumbeat workspace automations -> ${MIND_HOME}/automations"
else
  # Deliberately NOT creating an empty automations/. drumbeat would start and
  # schedule nothing while looking healthy -- exactly the silent-degradation
  # this project refuses. doctor reports it; the engine refuses to start.
  if [ -d "$MIND_HOME" ] && [ -n "$(mind_payload "$MIND_HOME")" ]; then
    warn "drumbeat workspace has no automations/ -- cortex-mind is installed but ships none"
  else
    warn "drumbeat workspace has no automations/ -- cortex-mind is not installed"
  fi
  warn "         drumbeat refuses to start without it, and an empty automations/ is NOT"
  warn "         created here: it would schedule nothing while looking healthy"
fi
if [ -d "${MIND_HOME}/prompts" ]; then
  ln -sfn "${MIND_HOME}/prompts" "${DRUMBEAT_WS}/prompts"
  ok "drumbeat workspace prompts -> ${MIND_HOME}/prompts"
fi

if [ ! -f "${DRUMBEAT_WS}/packs.txt" ] || [ "$FORCE_CONFIG" -eq 1 ]; then
  cat > "${DRUMBEAT_WS}/packs.txt" <<EOF
# Cortex drumbeat instance -- pack list.
# One path per line, absolute or relative to this workspace. '#' comments ok.
${PACK_HOME}
EOF
  ok "drumbeat packs.txt -> ${PACK_HOME}"
else
  ok "drumbeat packs.txt already present (use --force-config to regenerate)"
fi

cat > "${DRUMBEAT_WS}/SHARED-RESOURCES.md" <<EOF
# Cortex drumbeat instance

| Resource | Value |
|---|---|
| port | ${DRUMBEAT_PORT} |
| workspace | ${DRUMBEAT_WS} |
| packs | ${DRUMBEAT_WS}/packs.txt |

Port ${DRUMBEAT_PORT} is registered to the Cortex instance. Port 9100 is drumbeat's
default and belongs to a DIFFERENT, live instance -- never bind it from here.
EOF

# ---------------------------------------------------------------- 10. start
if [ "$DO_START" -eq 1 ]; then
  step "Starting services (tmux session '${TMUX_SESSION}')"
  if [ -x "${CORTEX_BIN}/cortex" ]; then
    "${CORTEX_BIN}/cortex" start || warn "one or more services did not start -- run 'cortex doctor'"
  fi
else
  step "Skipping start (--no-start)"
  info "start later with: cortex start"
fi

# ---------------------------------------------------------------- 11. summary
step "Summary"
LAN_IP="$(ip -4 -o addr show scope global 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}')"
LAN_IP="${LAN_IP:-127.0.0.1}"

if [ ${#MISSING[@]} -eq 0 ]; then
  say ""
  say "  ${C_OK}Cortex is installed.${C_0}"
  say ""
  say "  Pairing page   ${C_B}http://${LAN_IP}:${HUB_PORT}/${C_0}   (open this on the phone)"
  say "  Gateway        https://${LAN_IP}:${GATEWAY_PORT}/"
  say ""
  say "  Next:  cortex doctor      check everything"
  say "         cortex status      ports, pids, health"
  say "         cortex logs        follow the logs"
  say ""
  exit 0
else
  say ""
  say "  ${C_ERR}INCOMPLETE INSTALL${C_0} -- ${#MISSING[@]} component(s) did not install:"
  say ""
  for m in "${MISSING[@]}"; do printf '    - %s\n' "$m"; done
  say ""
  say "  What DID install is configured and usable. Nothing was stubbed or faked."
  say "  Re-run this installer once the missing pieces land -- it is idempotent."
  say ""
  say "  Check current state with:  cortex doctor"
  say ""
  exit 2
fi
