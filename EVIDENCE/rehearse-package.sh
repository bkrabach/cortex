#!/usr/bin/env bash
# Fresh-container rehearsal of the SAM PACKAGE.
#
#   ./EVIDENCE/rehearse-package.sh > EVIDENCE/sam-package-raw.log 2>&1
#
# The difference from EVIDENCE/rehearse.sh, and the whole point of this script:
# the container gets NOTHING but the tarball. No workspace mount, no drumbeat
# mount, no repo. If a path outside the package is needed, this fails -- which
# is exactly what it is here to find out, because that is the failure Sam would
# hit and we would not.
#
# Stock ubuntu:24.04, nothing from the install story pre-installed (no uv, no
# cortex, no drumbeat), everything run as an unprivileged user.
#
# Deliberately NO OPENAI_API_KEY: the honest missing-key path is under test.
# doctor must report it as a named warning with its remedy and still pass --
# that is the PASS state for this rehearsal, not a degraded one.
set -uo pipefail

# Namespaced deliberately. The first run of the sibling script picked up an
# ambient IMAGE=nvcr.io/nvidia/vllm from the operator's shell and rehearsed
# against a 20GB CUDA image instead of a stock Ubuntu one. Generic names get
# captured.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
TARBALL="${CORTEX_REHEARSAL_TARBALL:-$(ls -t "${REPO}"/build/cortex-demo-*.tar.gz 2>/dev/null | head -1)}"
IMAGE="${CORTEX_REHEARSAL_IMAGE:-ubuntu:24.04}"
NAME="cortex-pkg-rehearsal-$(date +%H%M%S)"

if [ -z "$TARBALL" ] || [ ! -f "$TARBALL" ]; then
  echo "error: no package tarball found." >&2
  echo "  looked for: ${REPO}/build/cortex-demo-*.tar.gz" >&2
  echo "  remedy: ./scripts/make-package.sh    (or set CORTEX_REHEARSAL_TARBALL)" >&2
  exit 1
fi

echo "=== cortex PACKAGE install rehearsal ==="
echo "host:      $(uname -srm)"
echo "image:     ${IMAGE}"
echo "container: ${NAME}"
echo "package:   ${TARBALL}"
echo "           $(du -h "$TARBALL" | cut -f1)  sha256 $(sha256sum "$TARBALL" | cut -d' ' -f1)"
echo "mounts:    the tarball, read-only, and NOTHING else -- no workspace, no drumbeat"
echo "openai:    deliberately NOT provided -- the missing-key path is under test"
echo "started:   $(date -Is)"
echo

docker run --rm -i --name "$NAME" --entrypoint /bin/bash \
  -v "${TARBALL}:/cortex-demo.tar.gz:ro" \
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
echo "-- and there is genuinely nothing here but the tarball --"
ls -d /workspace 2>&1 | sed 's/^/  /' || true
ls -d /drumbeat  2>&1 | sed 's/^/  /' || true
echo "  tarball: $(ls -l /cortex-demo.tar.gz | awk '{print $5" bytes"}')"

mark "PHASE 1  create the unprivileged user (nothing below runs as root)"
useradd -m -s /bin/bash rehearse && echo "created user: rehearse"

mark "PHASE 2  hand over the tarball, exactly as scp would"
install -o rehearse -g rehearse -m 644 /cortex-demo.tar.gz /home/rehearse/cortex-demo.tar.gz
su rehearse -c 'cd ~ && tar -xzf cortex-demo.tar.gz && ls -d ~/cortex-demo-*'
echo "-- what the extracted package root holds --"
su rehearse -c 'ls -la ~/cortex-demo-*/ | sed "s/^/  /"'
echo "-- the pins that travelled with it --"
su rehearse -c 'sed -n "1,20p" ~/cortex-demo-*/PACKAGE-PINS.md | sed "s/^/  /"'

mark "PHASE 3  prerequisite gate BEFORE prerequisites exist"
su rehearse -c 'cd ~/cortex-demo-*/ && ./install-cortex.sh --no-start'
echo "EXIT=$? (expected 1: prerequisites missing, nothing installed)"

mark "PHASE 4  install prerequisites (the remedies the gate just printed)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /tmp/apt.log 2>&1 && \
apt-get install -y -qq python3 python3-venv git tmux curl ca-certificates >> /tmp/apt.log 2>&1 && \
echo "apt ok: $(python3 -V), $(git --version), $(tmux -V), $(curl --version | head -1 | cut -d' ' -f1-2)" || \
{ echo "apt FAILED"; tail -20 /tmp/apt.log; }

mark "PHASE 5  install uv as the unprivileged user"
su rehearse -c 'curl -LsSf https://astral.sh/uv/install.sh | sh' 2>&1 | tail -3
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH; uv --version'

mark "PHASE 6  THE ONE COMMAND"
echo "-- no CORTEX_*_SRC in the environment, no OPENAI_API_KEY: the package must"
echo "   resolve every one of its own sources or fail saying which it could not --"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH
  cd ~/cortex-demo-*/ && time ./install-cortex.sh'
echo "INSTALL_EXIT=$?"

mark "PHASE 7  cortex doctor"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH; cortex doctor'
echo "DOCTOR_EXIT=$?"

mark "PHASE 8  cortex status"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH; cortex status'

mark "PHASE 9  the distribution page serves, and serves THE PACKAGED APK"
su rehearse -c 'curl -s -o /dev/null -w "GET /          -> %{http_code}\n" http://127.0.0.1:7080/'
su rehearse -c 'curl -s -o /dev/null -w "GET /healthz   -> %{http_code}\n" http://127.0.0.1:7080/healthz'
echo "-- byte-for-byte: what the hub serves must be the apk that travelled in the"
echo "   tarball. A page that serves SOMETHING is not proof; a sha match is. --"
su rehearse -c 'set -e
  PKG=$(ls -d ~/cortex-demo-*/ | head -1)
  code=$(curl -s -o /tmp/served.apk -w "%{http_code}" http://127.0.0.1:7080/cortex.apk)
  echo "  HTTP $code   $(wc -c < /tmp/served.apk) bytes   $(file -b /tmp/served.apk 2>/dev/null || echo binary)"
  a=$(sha256sum "${PKG}cortex/dist/cortex.apk" | cut -d" " -f1)
  b=$(sha256sum /tmp/served.apk | cut -d" " -f1)
  echo "  packaged: $a"
  echo "  served:   $b"
  [ "$a" = "$b" ] && echo "  MATCH: the hub is serving the apk that shipped in this package" \
                  || { echo "  MISMATCH -- the served build is not the packaged build"; exit 1; }'
echo "APK_MATCH_EXIT=$?"
echo "-- the page carries a QR and the gateway URL --"
su rehearse -c 'curl -s http://127.0.0.1:7080/ | grep -o "<svg[^>]*" | head -1'
su rehearse -c 'curl -s http://127.0.0.1:7080/ | grep -o "https://[^<]*:7443/" | head -1'

mark "PHASE 10  one-value pairing hand-off"
su rehearse -c 'curl -s -X POST http://127.0.0.1:7080/pair/new | tee /tmp/mint.json
  python3 - /tmp/mint.json <<PY
import json, sys, urllib.parse
d = json.load(open(sys.argv[1]))
if "pair_uri" not in d:
    print("  no pair_uri:", d.get("detail", d)); raise SystemExit(0)
q = urllib.parse.parse_qs(urllib.parse.urlparse(d["pair_uri"]).query)
print("  gw   ->", q["gw"][0])
print("  code ->", q["code"][0])
print("  halves match the separate fields:", q["gw"][0] == d["gateway_url"] and q["code"][0] == d["code"])
PY'

mark "PHASE 11  gateway healthz -- TLS verified against the CA setup wrote, never curl -k"
su rehearse -c 'CA=$HOME/.config/cortex/gateway/tls/ca.pem
  if [ -f "$CA" ]; then
    echo "using CA: $CA"
    curl -s -o /dev/null -w "https healthz -> %{http_code}\n" --max-time 5 --cacert "$CA" https://127.0.0.1:7443/healthz
    echo "body: $(curl -s --max-time 5 --cacert "$CA" https://127.0.0.1:7443/healthz)"
  else
    echo "no CA on disk at $CA -- gateway setup did not run (see doctor above)"
  fi'

mark "PHASE 12  idempotency -- the same one command again, on an installed box"
su rehearse -c 'export PATH=$HOME/.local/bin:$PATH
  cd ~/cortex-demo-*/ && time ./install-cortex.sh 2>&1 | tail -25'
echo "REINSTALL_EXIT=$?"

mark "PHASE 13  the secret never leaks"
echo "-- no key was provided, so there must be no key file and no key in any response --"
su rehearse -c 'ls -l ~/.config/cortex/gateway/openai_key 2>&1 || echo "no key file: correct, none was given"'
su rehearse -c 'curl -s http://127.0.0.1:7080/ | grep -ci "sk-" || echo "0 occurrences of sk- in the page: correct"'

mark "PHASE 14  the package mount was never written to, and the session is ours alone"
touch /cortex-demo.tar.gz 2>&1 || echo "tarball mount is read-only: confirmed"
su rehearse -c 'tmux ls 2>&1'

mark "DONE"
CONTAINER
rc=$?
echo
echo "=== package rehearsal finished $(date -Is) (docker rc=${rc}) ==="
