#!/usr/bin/env bash
# Cortex demo package -- the one command.
#
#   ./install-cortex.sh [--no-start] [--force-config] [--help]
#
# This is a thin redirect, not a second installer. Everything real happens in
# cortex/install.sh; this only points it at the copies that travel in this
# package.
#
# It sets exactly one source override: drumbeat. The installer already resolves
# cortex-gateway, cortex-mind and cortex-pack-tmux-kit as siblings of the hub,
# which is why this package is laid out as siblings -- that seam needs no help.
# drumbeat is different: its default is a path on the author's machine, because
# the engine has no public home yet.
#
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Fail loud if this is not a complete extracted package. A half-copied tarball
# that starts installing and dies three minutes in is worse than one that
# refuses in the first second.
MISSING=()
[ -f "${HERE}/cortex/install.sh" ]            || MISSING+=("cortex/install.sh")
[ -f "${HERE}/cortex/hub/serve.py" ]          || MISSING+=("cortex/hub/serve.py")
[ -d "${HERE}/cortex-gateway" ]               || MISSING+=("cortex-gateway/")
[ -d "${HERE}/cortex-mind" ]                  || MISSING+=("cortex-mind/")
[ -d "${HERE}/cortex-pack-tmux-kit" ]         || MISSING+=("cortex-pack-tmux-kit/")
[ -f "${HERE}/drumbeat/pyproject.toml" ]      || MISSING+=("drumbeat/pyproject.toml")

if [ ${#MISSING[@]} -gt 0 ]; then
  printf '\nerror: this does not look like a complete Cortex package.\n\n' >&2
  printf 'Missing, relative to %s:\n' "$HERE" >&2
  for m in "${MISSING[@]}"; do printf '  - %s\n' "$m" >&2; done
  printf '\nremedy: re-extract the tarball and run this script from inside the\n' >&2
  printf '        extracted directory:  tar -xzf cortex-demo-*.tar.gz\n' >&2
  printf '                              cd cortex-demo-* && ./install-cortex.sh\n\n' >&2
  exit 1
fi

# The one redirect. Respects an override if the operator already set one.
export CORTEX_DRUMBEAT_SRC="${CORTEX_DRUMBEAT_SRC:-${HERE}/drumbeat}"

exec "${HERE}/cortex/install.sh" "$@"
