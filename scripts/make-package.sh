#!/usr/bin/env bash
# Build the self-contained Cortex demo package.
#
#   ./scripts/make-package.sh [--out DIR] [--name NAME] [--help]
#
# Produces  <out>/cortex-demo-<date>.tar.gz  containing everything needed to
# install Cortex on a machine that has never seen this workspace:
#
#   cortex-demo-<date>/
#     install-cortex.sh      the one command
#     SAM-README.md          what to do, in order
#     PACKAGE-PINS.md        exact source SHAs, including the drumbeat dependency
#     cortex/                hub, CLI, installer, dist/cortex.apk
#     cortex-gateway/  cortex-mind/  cortex-pack-tmux-kit/
#     drumbeat/              a transported DEPENDENCY, pinned by SHA -- not a fork
#
# Why a tarball and not a curl|bash from GitHub: the drumbeat engine has no
# GitHub home yet and our repos are private. Everything therefore travels
# together, and the SHA of each source is recorded in PACKAGE-PINS.md so a
# packaged copy can always be traced back to -- and replaced by -- its origin.
#
# The sibling layout is deliberate: install.sh already resolves gateway, mind
# and pack as siblings of the hub, so the package needs no new resolution
# logic. Only drumbeat -- whose default is a path on the author's box -- is
# redirected, by the wrapper.
#
# Laws honoured here (CONTRACT-PINS.md):
#   1. Fail loud. Every missing source is named, all of them, before anything
#      is built. A package that is missing a component is never written.
#   2. drumbeat is a dependency, transported and pinned, never forked.
#   6. The build verifies it changed none of its sources, and says so.
#
set -uo pipefail

MAKE_PACKAGE_VERSION="0.1.0"

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
die()  { printf '\n%serror:%s %s\n' "$C_ERR" "$C_0" "$1" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------- locate self
_self="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$_self")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE="$(cd "${REPO}/.." && pwd)"

# ---------------------------------------------------------------- args
OUT_DIR="${CORTEX_PACKAGE_OUT:-${REPO}/build}"
PKG_NAME="cortex-demo-$(date +%Y%m%d)"
while [ $# -gt 0 ]; do
  case "$1" in
    --out)  shift; [ $# -gt 0 ] || die "--out needs a directory"; OUT_DIR="$1" ;;
    --name) shift; [ $# -gt 0 ] || die "--name needs a value";    PKG_NAME="$1" ;;
    -h|--help) sed -n '2,30p' "$_self" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 -- remedy: run '$0 --help'" ;;
  esac
  shift
done

# Resolved now rather than at write time: the read-only check below has to know
# which single directory this build is allowed to write into.
mkdir -p "$OUT_DIR" || die "cannot create output directory ${OUT_DIR}"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

# ---------------------------------------------------------------- sources
# Same env var names as install.sh, same sibling defaults. drumbeat defaults to
# the checkout it lives in today; it has no GitHub home yet.
CORTEX_HUB_SRC="${CORTEX_HUB_SRC:-$REPO}"
CORTEX_GATEWAY_SRC="${CORTEX_GATEWAY_SRC:-${WORKSPACE}/cortex-gateway}"
CORTEX_MIND_SRC="${CORTEX_MIND_SRC:-${WORKSPACE}/cortex-mind}"
CORTEX_PACK_SRC="${CORTEX_PACK_SRC:-${WORKSPACE}/cortex-pack-tmux-kit}"
CORTEX_DRUMBEAT_SRC="${CORTEX_DRUMBEAT_SRC:-${HOME}/dev/amplifier-attention-manager/drumbeat}"

# name | source dir | marker file that proves it is the real thing | env override
COMPONENTS=(
  "cortex|${CORTEX_HUB_SRC}|hub/serve.py|CORTEX_HUB_SRC"
  "cortex-gateway|${CORTEX_GATEWAY_SRC}|pyproject.toml|CORTEX_GATEWAY_SRC"
  "cortex-mind|${CORTEX_MIND_SRC}|automations|CORTEX_MIND_SRC"
  "cortex-pack-tmux-kit|${CORTEX_PACK_SRC}|pack.md|CORTEX_PACK_SRC"
  "drumbeat|${CORTEX_DRUMBEAT_SRC}|pyproject.toml|CORTEX_DRUMBEAT_SRC"
)

APK_SRC="${CORTEX_HUB_SRC}/dist/cortex.apk"

# Lane bookkeeping, build trees and caches. None of it is product, all of it
# either bloats the package or -- in the case of a .venv -- carries absolute
# paths from this machine and is actively harmful on Sam's.
EXCLUDES=(
  --exclude=.git
  --exclude=.venv
  --exclude=venv
  --exclude=__pycache__
  --exclude='*.pyc'
  --exclude=.ruff_cache
  --exclude=.pytest_cache
  --exclude=.mypy_cache
  --exclude=node_modules
  --exclude=.DS_Store
  --exclude=build
  --exclude=runs
  --exclude=lane.log
  --exclude=BLOCKED.md
  --exclude='*GOAL.md'
)

say "${C_B}Cortex package builder${C_0} ${C_DIM}v${MAKE_PACKAGE_VERSION}${C_0}"

# ---------------------------------------------------------------- 1. verify sources
# Every missing source at once. Being told about one per run is how builds get
# abandoned at 3am.
step "Checking sources"
SRC_ERRORS=()
for entry in "${COMPONENTS[@]}"; do
  IFS='|' read -r name dir marker envvar <<<"$entry"
  if [ ! -d "$dir" ]; then
    SRC_ERRORS+=("${name}: no directory at ${dir} -- remedy: set ${envvar} to its checkout")
  elif [ ! -e "${dir}/${marker}" ]; then
    SRC_ERRORS+=("${name}: ${dir} exists but has no ${marker}, so it is not a usable ${name} checkout")
  else
    ok "$(printf '%-22s %s' "$name" "$dir")"
  fi
done

if [ ! -f "$APK_SRC" ]; then
  SRC_ERRORS+=("android apk: nothing at ${APK_SRC} -- remedy: drop the built cortex.apk there (the package exists to hand Sam an installable phone build; shipping without one is not a demo)")
else
  ok "$(printf '%-22s %s (%s)' "android apk" "$APK_SRC" "$(du -h "$APK_SRC" | cut -f1)")"
fi

if [ ${#SRC_ERRORS[@]} -gt 0 ]; then
  printf '\n%serror: %d source(s) unusable. Nothing was built.%s\n\n' "$C_ERR" "${#SRC_ERRORS[@]}" "$C_0" >&2
  for e in "${SRC_ERRORS[@]}"; do printf '  - %s\n' "$e" >&2; done
  printf '\n' >&2
  exit 1
fi

# ---------------------------------------------------------------- 2. fingerprint sources
# Law 4 of this script: the build reads its sources and writes none of them.
# A claim like that is worth nothing unless it is checked, so fingerprint every
# source now and again at the end.
src_fingerprint() {
  local d="$1"
  {
    git -C "$d" rev-parse HEAD 2>/dev/null || echo "no-git"
    git -C "$d" status --porcelain 2>/dev/null || true
    # Two kinds of path are pruned, and only these two:
    #   - volatile by design: .git internals churn on read, and lane.log is
    #     being appended by the harness that is running this build;
    #   - the declared output directory, which is the one thing this build is
    #     supposed to write. It is pruned by exact path, not by name, so a
    #     directory that merely happens to be called "build" inside a source
    #     is still watched.
    find "$d" \( -path "$OUT_DIR" -o -name .git -o -name .venv \
                 -o -name '__pycache__' -o -name '.*_cache' \
                 -o -name lane.log -o -name runs \) -prune \
         -o -type f -printf '%P %s %T@\n' 2>/dev/null | LC_ALL=C sort
  } | sha256sum | cut -d' ' -f1
}
src_sha()   { git -C "$1" rev-parse HEAD 2>/dev/null || echo "(not a git checkout)"; }
src_dirty() { [ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ] && echo "dirty" || echo "clean"; }

step "Fingerprinting sources (they must be unchanged when this finishes)"
FP_BEFORE=()
for entry in "${COMPONENTS[@]}"; do
  IFS='|' read -r name dir marker envvar <<<"$entry"
  FP_BEFORE+=("$(src_fingerprint "$dir")")
  info "$(printf '%-22s %s  %s' "$name" "$(src_sha "$dir" | cut -c1-12)" "$(src_dirty "$dir")")"
done

# ---------------------------------------------------------------- 3. stage
step "Staging ${PKG_NAME}"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/cortex-package.XXXXXX")" || die "cannot create a staging directory"
trap 'rm -rf "$STAGE"' EXIT
PKG_ROOT="${STAGE}/${PKG_NAME}"
mkdir -p "$PKG_ROOT"

copy_tree() {  # src dst
  local src="$1" dst="$2"
  mkdir -p "$dst" || return 1
  ( cd "$src" && tar "${EXCLUDES[@]}" -cf - . ) | ( cd "$dst" && tar -xf - )
}

for entry in "${COMPONENTS[@]}"; do
  IFS='|' read -r name dir marker envvar <<<"$entry"
  copy_tree "$dir" "${PKG_ROOT}/${name}" \
    || die "copying ${name} from ${dir} failed -- nothing usable was produced"
  ok "$(printf '%-22s %s files, %s' "$name" \
        "$(find "${PKG_ROOT}/${name}" -type f | wc -l)" \
        "$(du -sh "${PKG_ROOT}/${name}" | cut -f1)")"
done

# The APK is gitignored (a build artifact, never committed) so it is copied
# explicitly rather than riding along with the tree.
mkdir -p "${PKG_ROOT}/cortex/dist"
cp -f "$APK_SRC" "${PKG_ROOT}/cortex/dist/cortex.apk"
APK_SHA="$(sha256sum "${PKG_ROOT}/cortex/dist/cortex.apk" | cut -d' ' -f1)"
ok "$(printf '%-22s %s' "android apk" "sha256 ${APK_SHA:0:16}...")"

# ---------------------------------------------------------------- 4. package front door
step "Writing the front door"
cp -f "${SCRIPT_DIR}/install-cortex.sh" "${PKG_ROOT}/install-cortex.sh" \
  || die "missing ${SCRIPT_DIR}/install-cortex.sh -- the package has no entry point without it"
chmod 755 "${PKG_ROOT}/install-cortex.sh"
ok "install-cortex.sh"

cp -f "${REPO}/SAM-README.md" "${PKG_ROOT}/SAM-README.md" \
  || die "missing ${REPO}/SAM-README.md -- the package has no instructions without it"
ok "SAM-README.md"

{
  echo "# Cortex demo package -- pins"
  echo
  echo "Built $(date -Is) on $(uname -srm) by \`scripts/make-package.sh\` v${MAKE_PACKAGE_VERSION}."
  echo
  echo "Every directory in this package is a COPY of a source checkout, taken at the"
  echo "commit below. None of them is a fork. To move a component back to its origin,"
  echo "replace the directory with a clone at the recorded SHA and nothing else changes"
  echo "-- the installer resolves sources by path, and each path is overridable."
  echo
  echo "| Component | Source path on the build host | Commit | Worktree |"
  echo "|---|---|---|---|"
  for entry in "${COMPONENTS[@]}"; do
    IFS='|' read -r name dir marker envvar <<<"$entry"
    printf '| `%s` | `%s` | `%s` | %s |\n' "$name" "$dir" "$(src_sha "$dir")" "$(src_dirty "$dir")"
  done
  echo
  echo "## The drumbeat dependency"
  echo
  echo "\`drumbeat/\` is the automation engine Cortex DEPENDS on. It has no GitHub home"
  echo "yet, which is the only reason a copy travels in this package instead of being"
  echo "installed from a URL. It is pinned at:"
  echo
  printf '    %s\n' "$(src_sha "$CORTEX_DRUMBEAT_SRC")"
  echo
  echo "Do not develop against this copy. When drumbeat is published, delete the"
  echo "directory and point \`CORTEX_DRUMBEAT_SRC\` at a real checkout."
  echo
  echo "## Artifacts"
  echo
  printf '| Artifact | Value |\n|---|---|\n'
  printf '| `cortex/dist/cortex.apk` | sha256 `%s` |\n' "$APK_SHA"
  printf '| apk size | %s bytes |\n' "$(wc -c < "${PKG_ROOT}/cortex/dist/cortex.apk" | tr -d ' ')"
  echo
  echo "## Excluded from every directory"
  echo
  echo "Lane bookkeeping and build trees are not product and are left behind:"
  echo "\`.git\`, \`.venv\`, \`__pycache__\`, \`*.pyc\`, \`.ruff_cache\`, \`.pytest_cache\`,"
  echo "\`.mypy_cache\`, \`node_modules\`, \`build\`, \`runs\`, \`lane.log\`, \`BLOCKED.md\`,"
  echo "\`*GOAL.md\`. A copied \`.venv\` in particular carries absolute paths from the"
  echo "build host and is worse than useless on yours."
} > "${PKG_ROOT}/PACKAGE-PINS.md"
ok "PACKAGE-PINS.md"

# ---------------------------------------------------------------- 5. verify the package
# A tarball that is missing a piece is discovered by the person you handed it
# to. Check here instead.
step "Verifying the staged package"
PKG_ERRORS=()
for required in \
  install-cortex.sh SAM-README.md PACKAGE-PINS.md \
  cortex/install.sh cortex/hub/serve.py cortex/bin/cortex cortex/dist/cortex.apk \
  cortex-gateway/pyproject.toml cortex-mind/automations \
  cortex-pack-tmux-kit/pack.md drumbeat/pyproject.toml
do
  [ -e "${PKG_ROOT}/${required}" ] || PKG_ERRORS+=("missing from package: ${required}")
done
[ -x "${PKG_ROOT}/install-cortex.sh" ] || PKG_ERRORS+=("install-cortex.sh is not executable")
[ -x "${PKG_ROOT}/cortex/install.sh" ] || PKG_ERRORS+=("cortex/install.sh is not executable")

LEAKED="$(find "$PKG_ROOT" \( -name .git -o -name .venv -o -name lane.log \
          -o -name '__pycache__' -o -name '*GOAL.md' -o -name '.*_cache' \) -print 2>/dev/null)"
if [ -n "$LEAKED" ]; then
  while IFS= read -r l; do PKG_ERRORS+=("excluded path leaked into the package: ${l#$PKG_ROOT/}"); done <<<"$LEAKED"
fi

if [ ${#PKG_ERRORS[@]} -gt 0 ]; then
  printf '\n%serror: the staged package is not shippable (%d problem(s)). No tarball written.%s\n\n' \
    "$C_ERR" "${#PKG_ERRORS[@]}" "$C_0" >&2
  for e in "${PKG_ERRORS[@]}"; do printf '  - %s\n' "$e" >&2; done
  exit 1
fi
ok "all required files present, no excluded paths leaked"

# ---------------------------------------------------------------- 6. tar it
step "Writing the tarball"
TARBALL="${OUT_DIR}/${PKG_NAME}.tar.gz"
rm -f "$TARBALL"
( cd "$STAGE" && tar -czf "$TARBALL" "$PKG_NAME" ) || die "tar failed writing ${TARBALL}"
TAR_SHA="$(sha256sum "$TARBALL" | cut -d' ' -f1)"
ok "$(printf '%s  (%s)' "$TARBALL" "$(du -h "$TARBALL" | cut -f1)")"
ok "sha256 ${TAR_SHA}"

# ---------------------------------------------------------------- 7. sources unchanged
step "Confirming the sources were not touched"
CHANGED=()
i=0
for entry in "${COMPONENTS[@]}"; do
  IFS='|' read -r name dir marker envvar <<<"$entry"
  after="$(src_fingerprint "$dir")"
  if [ "$after" != "${FP_BEFORE[$i]}" ]; then
    CHANGED+=("${name} at ${dir}")
  else
    ok "$(printf '%-22s unchanged' "$name")"
  fi
  i=$((i+1))
done
if [ ${#CHANGED[@]} -gt 0 ]; then
  printf '\n%serror: the build modified %d source(s). The tarball is suspect and was left at %s for inspection.%s\n\n' \
    "$C_ERR" "${#CHANGED[@]}" "$TARBALL" "$C_0" >&2
  for c in "${CHANGED[@]}"; do printf '  - %s\n' "$c" >&2; done
  printf '\nThis build is supposed to be read-only over its sources. Investigate before shipping.\n' >&2
  exit 1
fi

# ---------------------------------------------------------------- 8. summary
step "Contents (top 2 levels)"
tar -tzf "$TARBALL" | awk -F/ 'NF==2 || (NF==3 && $3=="")' | sort | sed 's/^/  /'

say ""
say "  ${C_OK}Package ready.${C_0}"
say ""
say "  ${C_B}${TARBALL}${C_0}"
say "  $(du -h "$TARBALL" | cut -f1)   sha256 ${TAR_SHA}"
say ""
say "  Hand it over with:"
say "    scp ${TARBALL} sam@his-box:~/"
say "    ssh sam@his-box"
say "    tar -xzf ${PKG_NAME}.tar.gz && cd ${PKG_NAME} && ./install-cortex.sh"
say ""
exit 0
