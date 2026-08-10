#!/usr/bin/env bash
# Fresh-container install rehearsal.
#
# Runs install.sh on a stock ubuntu:24.04 box with NOTHING from the install
# story pre-installed (no uv, no cortex, no drumbeat), as an unprivileged user,
# against a READ-ONLY mount of the workspace. Produces a full transcript.
#
#   ./EVIDENCE/rehearse.sh > EVIDENCE/rehearsal-raw.log 2>&1
#
# Deliberately NO OPENAI_API_KEY: the honest missing-key path is what we want
# exercised. doctor must report it and keep going, not hide it and not die.
set -uo pipefail

# Namespaced deliberately. The first run of this script picked up an ambient
# IMAGE=nvcr.io/nvidia/vllm from the operator's shell and rehearsed against a
# 20GB CUDA image instead of a stock Ubuntu one. Generic names get captured.
WORKSPACE="${CORTEX_REHEARSAL_WORKSPACE:-/home/bkrabach/dev/cortex-core}"
DRUMBEAT="${CORTEX_REHEARSAL_DRUMBEAT:-/home/bkrabach/dev/amplifier-attention-manager/drumbeat}"
IMAGE="${CORTEX_REHEARSAL_IMAGE:-ubuntu:24.04}"
NAME="cortex-rehearsal-$(date +%H%M%S)"

echo "=== cortex install rehearsal ==="
echo "host:      $(uname -srm)"
echo "image:     ${IMAGE}"
echo "container: ${NAME}"
echo "workspace: ${WORKSPACE}  (mounted READ-ONLY at /workspace)"
echo "drumbeat:  ${DRUMBEAT}  (mounted READ-ONLY at /drumbeat)"
echo "openai:    deliberately NOT provided -- the missing-key path is under test"
echo "started:   $(date -Is)"
echo

docker run --rm -i --name "$NAME" --entrypoint /bin/bash \
  -v "${WORKSPACE}:/workspace:ro" \
  -v "${DRUMBEAT}:/drumbeat:ro" \
  "$IMAGE" -s <<'CONTAINER'
set -uo pipefail
ts() { date +%H:%M:%S; }
mark() { echo; echo "########## $(ts)  $*"; }

mark "PHASE 0  stock box, before anything"
echo "os:     $(. /etc/os-release && echo "$PRETTY_NAME") $(uname -m)"
echo "python: $(command -v python3 || echo ABSENT)"
echo "uv:     $(command -v uv || echo ABSENT)"
echo "git:    $(command -v git || echo ABSENT)"
echo "tmux:   $(command -v tmux || echo ABSENT)"
echo "curl:   $(command -v curl || echo ABSENT)"

mark "PHASE 1  create the unprivileged user (nothing below runs as root)"
useradd -m -s /bin/bash rehearse && echo "created user: rehearse"

mark "PHASE 2  prerequisite gate BEFORE prerequisites exist"
echo "-- copying install.sh out of the read-only mount so a bare box can run it --"
install -o rehearse -g rehearse -m 755 /workspace/cortex/install.sh /home/rehearse/install.sh
su rehearse -c 'cd /home/rehearse && ./install.sh --no-start'
echo "EXIT=$? (expected 1: prerequisites missing, nothing installed)"

mark "PHASE 3  install prerequisites (the remedies the gate just printed)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /tmp/apt.log 2>&1 && \
apt-get install -y -qq python3 python3-venv git tmux curl ca-certificates >> /tmp/apt.log 2>&1 && \
echo "apt ok: $(python3 -V), $(git --version), $(tmux -V), $(curl --version | head -1 | cut -d' ' -f1-2)" || \
{ echo "apt FAILED"; tail -20 /tmp/apt.log; }

mark "PHASE 4  install uv as the unprivileged user"
su rehearse -c 'curl -LsSf https://astral.sh/uv/install.sh | sh' 2>&1 | tail -3
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH; uv --version'

mark "PHASE 5  THE ONE COMMAND"
echo "-- sources pointed at the read-only mounts; no OPENAI_API_KEY in env --"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH
  export CORTEX_HUB_SRC=/workspace/cortex
  export CORTEX_GATEWAY_SRC=/workspace/cortex-gateway
  export CORTEX_MIND_SRC=/workspace/cortex-mind
  export CORTEX_PACK_SRC=/workspace/cortex-pack-tmux-kit
  export CORTEX_DRUMBEAT_SRC=/drumbeat
  cd /home/rehearse && time ./install.sh'
echo "INSTALL_EXIT=$?"

mark "PHASE 6  cortex doctor"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH; cortex doctor'
echo "DOCTOR_EXIT=$?"

mark "PHASE 7  cortex status"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH; cortex status'

mark "PHASE 8  the distribution page actually serves"
su rehearse -c 'curl -s -o /dev/null -w "GET /          -> %{http_code}\n" http://127.0.0.1:7080/'
su rehearse -c 'curl -s -o /dev/null -w "GET /healthz   -> %{http_code}\n" http://127.0.0.1:7080/healthz'
su rehearse -c 'curl -s -o /dev/null -w "GET /cortex.apk-> %{http_code}\n" http://127.0.0.1:7080/cortex.apk'
echo "-- body of the apk 404, in full: it must NAME the missing build --"
su rehearse -c 'curl -s http://127.0.0.1:7080/cortex.apk'
echo "-- the page carries a QR and the gateway URL --"
su rehearse -c 'curl -s http://127.0.0.1:7080/ | grep -o "<svg[^>]*" | head -1'
su rehearse -c 'curl -s http://127.0.0.1:7080/ | grep -o "https://[^<]*:7443/" | head -1'

mark "PHASE 9  gateway healthz -- TLS verified against the CA setup wrote, never curl -k"
su rehearse -c 'CA=$HOME/.config/cortex/gateway/tls/ca.pem
  if [ -f "$CA" ]; then
    echo "using CA: $CA"
    curl -s -o /dev/null -w "https healthz -> %{http_code}\n" --max-time 5 --cacert "$CA" https://127.0.0.1:7443/healthz
    echo "body: $(curl -s --max-time 5 --cacert "$CA" https://127.0.0.1:7443/healthz)"
  else
    echo "no CA on disk at $CA -- gateway setup did not run (see doctor above)"
  fi'

mark "PHASE 10  idempotency -- run the exact same command again on an installed box"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH
  export CORTEX_HUB_SRC=/workspace/cortex
  export CORTEX_GATEWAY_SRC=/workspace/cortex-gateway
  export CORTEX_MIND_SRC=/workspace/cortex-mind
  export CORTEX_PACK_SRC=/workspace/cortex-pack-tmux-kit
  export CORTEX_DRUMBEAT_SRC=/drumbeat
  cd /home/rehearse && time ./install.sh 2>&1 | tail -30'
echo "REINSTALL_EXIT=$?"

mark "PHASE 11  the secret never leaks"
echo "-- no key was provided, so there must be no key file and no key in any response --"
su rehearse -c 'ls -l ~/.config/cortex/gateway/openai_key 2>&1 || echo "no key file: correct, none was given"'
su rehearse -c 'curl -s http://127.0.0.1:7080/ | grep -ci "sk-" || echo "0 occurrences of sk- in the page: correct"'

mark "PHASE 12  the read-only mount was never written to"
su rehearse -c 'touch /workspace/cortex/PROOF-RO 2>&1 || echo "workspace is read-only: confirmed"'
echo "-- and the tmux session created is ours alone --"
su rehearse -c 'tmux ls 2>&1'

mark "DONE"
CONTAINER
rc=$?
echo
echo "=== rehearsal finished $(date -Is) (docker rc=${rc}) ==="
