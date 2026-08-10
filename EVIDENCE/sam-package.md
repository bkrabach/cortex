# EVIDENCE — the Sam package

**Claim under test:** a stakeholder who has never seen this workspace can install
the whole Cortex stack on his own machine from one file, with one command.

**How it was tested:** a fresh `ubuntu:24.04` container that is given the
tarball and **nothing else** — no workspace mount, no drumbeat mount, no repo,
no `CORTEX_*_SRC` in the environment, no `OPENAI_API_KEY`. Everything after user
creation runs as an unprivileged user.

Artifacts:

| File | What |
|---|---|
| `scripts/make-package.sh` | builds the tarball; refuses to ship an incomplete one |
| `scripts/install-cortex.sh` | the package's front door (copied to package root) |
| `SAM-README.md` | the instructions that travel with it |
| `EVIDENCE/rehearse-package.sh` | the fresh-container rehearsal, tarball-only |
| `EVIDENCE/sam-package-build.log` | full build transcript |
| `EVIDENCE/sam-package-raw.log` | full rehearsal transcript (317 lines) |

The tarball itself is **not** committed: it is a 9 MB build artifact,
reproducible from `scripts/make-package.sh` at any time, and `build/` is
gitignored.

---

## Gate 1 — the tarball exists, and what is in it

`./scripts/make-package.sh` → **exit 0**. Verbatim tail of
`EVIDENCE/sam-package-build.log`:

```
==> Staging cortex-demo-20260810
  ok    cortex                 190 files, 20M
  ok    cortex-gateway         38 files, 524K
  ok    cortex-mind            11 files, 80K
  ok    cortex-pack-tmux-kit   17 files, 136K
  ok    drumbeat               41 files, 764K
  ok    android apk            sha256 f3bdc01921fd5c4f...

==> Writing the front door
  ok    install-cortex.sh
  ok    SAM-README.md
  ok    PACKAGE-PINS.md

==> Verifying the staged package
  ok    all required files present, no excluded paths leaked

==> Writing the tarball
  ok    /home/bkrabach/dev/cortex-core/cortex/build/cortex-demo-20260810.tar.gz  (9.0M)
  ok    sha256 7ef4aa3017634e7bca276ea6e038af67b3b3b8b472d4c54e4a26ed428737e927

==> Confirming the sources were not touched
  ok    cortex                 unchanged
  ok    cortex-gateway         unchanged
  ok    cortex-mind            unchanged
  ok    cortex-pack-tmux-kit   unchanged
  ok    drumbeat               unchanged

==> Contents (top 2 levels)
  cortex-demo-20260810/
  cortex-demo-20260810/cortex/
  cortex-demo-20260810/cortex-gateway/
  cortex-demo-20260810/cortex-mind/
  cortex-demo-20260810/cortex-pack-tmux-kit/
  cortex-demo-20260810/drumbeat/
  cortex-demo-20260810/install-cortex.sh
  cortex-demo-20260810/PACKAGE-PINS.md
  cortex-demo-20260810/SAM-README.md
```

**Size:** 9.0M (9,373,153 bytes). **sha256:**
`7ef4aa3017634e7bca276ea6e038af67b3b3b8b472d4c54e4a26ed428737e927`

### The drumbeat SHA pin

Quoted from `PACKAGE-PINS.md` **as extracted from the tarball**
(`tar -xzOf ... cortex-demo-20260810/PACKAGE-PINS.md`):

```
| Component | Source path on the build host | Commit | Worktree |
|---|---|---|---|
| `cortex` | `/home/bkrabach/dev/cortex-core/cortex` | `7073e5167b5685a37c8cc995ecc4b1da4279c4cd` | dirty |
| `cortex-gateway` | `/home/bkrabach/dev/cortex-core/cortex-gateway` | `2c6c4f7642a79902e69eab9fa1c16cc8c8504335` | dirty |
| `cortex-mind` | `/home/bkrabach/dev/cortex-core/cortex-mind` | `04f7edfafbe0bc7b660103f061c9e1d3d176b1d1` | clean |
| `cortex-pack-tmux-kit` | `/home/bkrabach/dev/cortex-core/cortex-pack-tmux-kit` | `859ba3a455e57c850ded51bf5e39111dbc259fcb` | clean |
| `drumbeat` | `/home/bkrabach/dev/amplifier-attention-manager/drumbeat` | `86d8a06423d4f6deb5882c4ea0e0dda8c748ae93` | clean |

## The drumbeat dependency

`drumbeat/` is the automation engine Cortex DEPENDS on. It has no GitHub home
yet, which is the only reason a copy travels in this package instead of being
installed from a URL. It is pinned at:

    86d8a06423d4f6deb5882c4ea0e0dda8c748ae93
```

drumbeat travels as a **pinned dependency, not a fork**: the copy is taken from
a clean worktree at `86d8a06`, `.git` is stripped so it cannot be committed
into by mistake, and the pins file says in plain words to replace it with a real
checkout once the engine is published. The two `dirty` rows are honest: those
two repos have uncommitted work at build time and the pins say so rather than
implying a clean provenance.

---

## Gate 2 — fresh-container rehearsal from the extracted tarball

`./EVIDENCE/rehearse-package.sh` → **docker rc=0**, full transcript in
`EVIDENCE/sam-package-raw.log`.

### The container really does only have the tarball

```
########## 13:40:19  PHASE 0  stock box, before anything
os:     Ubuntu 24.04.4 LTS aarch64
python: ABSENT
uv:     ABSENT
git:    ABSENT
tmux:   ABSENT
curl:   ABSENT
-- and there is genuinely nothing here but the tarball --
  ls: cannot access '/workspace': No such file or directory
  ls: cannot access '/drumbeat': No such file or directory
  tarball: 9373153 bytes
```

The header of the same run records which artifact was under test — it is the
byte-identical tarball from Gate 1:

```
package:   /home/bkrabach/dev/cortex-core/cortex/build/cortex-demo-20260810.tar.gz
           9.0M  sha256 7ef4aa3017634e7bca276ea6e038af67b3b3b8b472d4c54e4a26ed428737e927
mounts:    the tarball, read-only, and NOTHING else -- no workspace, no drumbeat
openai:    deliberately NOT provided -- the missing-key path is under test
```

### Extract

```
########## 13:40:19  PHASE 2  hand over the tarball, exactly as scp would
/home/rehearse/cortex-demo-20260810
-- what the extracted package root holds --
  -rw-rw-r--  1 rehearse rehearse 2105 Aug 10 13:40 PACKAGE-PINS.md
  -rw-rw-r--  1 rehearse rehearse 7253 Aug 10 13:40 SAM-README.md
  drwxrwxr-x 18 rehearse rehearse 4096 Aug 10 13:34 cortex
  drwxrwxr-x  5 rehearse rehearse 4096 Aug 10 11:11 cortex-gateway
  drwxrwxr-x  7 rehearse rehearse 4096 Aug 10 05:35 cortex-mind
  drwxrwxr-x  6 rehearse rehearse 4096 Aug 10 04:34 cortex-pack-tmux-kit
  drwxrwxr-x  5 rehearse rehearse 4096 Aug  9 22:35 drumbeat
  -rwxr-xr-x  1 rehearse rehearse 2085 Aug 10 13:40 install-cortex.sh
```

### The prerequisite gate fires before anything is installed

```
########## 13:40:19  PHASE 3  prerequisite gate BEFORE prerequisites exist
error: 5 prerequisite(s) missing. Nothing was installed.

  - python3 not found -- remedy: sudo apt install python3 (need >= 3.11)
  - uv not found -- remedy: curl -LsSf https://astral.sh/uv/install.sh | sh   (then re-open your shell)
  - git not found -- remedy: sudo apt install git
  - tmux not found -- remedy: sudo apt install tmux   (required: Cortex supervises its services in a tmux session)
  - curl not found -- remedy: sudo apt install curl

Fix all of the above, then re-run this installer. It is safe to re-run.
EXIT=1 (expected 1: prerequisites missing, nothing installed)
```

All five at once, each with its remedy — matching what `SAM-README.md` promises.

### Install — the one command, no environment help

```
########## 13:40:40  PHASE 6  THE ONE COMMAND
-- no CORTEX_*_SRC in the environment, no OPENAI_API_KEY: the package must
   resolve every one of its own sources or fail saying which it could not --

==> Resolving sources
  info  hub       /home/rehearse/cortex-demo-20260810/cortex
  info  gateway   /home/rehearse/cortex-demo-20260810/cortex-gateway   [found]
  info  mind      /home/rehearse/cortex-demo-20260810/cortex-mind   [found]
  info  pack      /home/rehearse/cortex-demo-20260810/cortex-pack-tmux-kit   [found]
  info  drumbeat  /home/rehearse/cortex-demo-20260810/drumbeat   [found]
...
==> Starting services (tmux session 'cortex')
up   gateway   :7443
up   drumbeat  :9102
up   hub       :7080

3 up

==> Summary

  Cortex is installed.

real	0m3.696s
INSTALL_EXIT=0
```

Every source resolved from inside the package. The sibling-directory seam did
the work; the wrapper supplied exactly one override (`CORTEX_DRUMBEAT_SRC`).

### doctor

```
########## 13:40:44  PHASE 7  cortex doctor

Components
PASS  gateway                /home/rehearse/.local/share/cortex/gateway/venv/bin/cortex-gateway
PASS  drumbeat               /home/rehearse/.local/share/cortex/drumbeat/venv/bin/drumbeat
PASS  hub                    /home/rehearse/.local/share/cortex/hub/serve.py
PASS  mind                   /home/rehearse/.local/share/cortex/mind
PASS  pack                   /home/rehearse/.local/share/cortex/packs/tmux-kit

Configuration
WARN  openai key             absent -- voice minting will 503 (by design, naming the remedy)
      remedy: printf '%s' sk-... > /home/rehearse/.config/cortex/gateway/openai_key && chmod 600 ...
              read per-request: no restart needed once the file exists
PASS  gateway config         /home/rehearse/.config/cortex/gateway
PASS  reply slug             reply_default_automation_slug=chat
PASS  fleet_bin              /home/rehearse/.local/share/cortex/packs/tmux-kit/bin/tmux-fleet (executable)
PASS  mind_dir               /home/rehearse/.local/share/cortex/mind
PASS  drumbeat workspace     /home/rehearse/.local/state/cortex/drumbeat

Services
PASS  tmux session           'cortex' (3 windows)
PASS  hub :7080              healthz 200
PASS  gateway :7443          healthz 200, TLS verified against the CA it serves at /api/ca
PASS  drumbeat :9102         api/health 200

Distribution
PASS  android apk            15M at /home/rehearse/.local/share/cortex/dist/cortex.apk

Neighbours (must be untouched)
PASS  protected ports        live: none -- Cortex binds only 7443/9102/7080

doctor: all checks passed (2 warning(s) -- named above, none fatal)
DOCTOR_EXIT=0
```

This is the declared PASS state: exit 0 with the missing OpenAI key reported as
a **named warning carrying its own remedy**, not hidden and not fatal. (The
second warning is the delivery cursor, which no consumer has published in a
one-shot container.)

### The page serves the APK, and it is the packaged APK

```
########## 13:40:44  PHASE 9  the distribution page serves, and serves THE PACKAGED APK
GET /          -> 200
GET /healthz   -> 200
-- byte-for-byte: what the hub serves must be the apk that travelled in the
   tarball. A page that serves SOMETHING is not proof; a sha match is. --
  HTTP 200   14701322 bytes   binary
  packaged: f3bdc01921fd5c4fe79deb8fda845fbc5790c95235d5bb68c66f5edc42ace1a2
  served:   f3bdc01921fd5c4fe79deb8fda845fbc5790c95235d5bb68c66f5edc42ace1a2
  MATCH: the hub is serving the apk that shipped in this package
APK_MATCH_EXIT=0
```

### Gateway healthz over real TLS

```
########## 13:40:45  PHASE 11  gateway healthz -- TLS verified against the CA setup wrote, never curl -k
using CA: /home/rehearse/.config/cortex/gateway/tls/ca.pem
https healthz -> 200
body: {"status":"ok","service":"cortex-gateway","version":"0.1.0","time":"2026-08-10T13:40:45.154315+00:00","port":7443}
```

### Pairing, idempotency, and the secret

```
########## 13:40:44  PHASE 10  one-value pairing hand-off
  gw   -> https://172.17.0.4:7443
  code -> 9105-135f
  halves match the separate fields: True

########## 13:40:45  PHASE 12  idempotency -- the same one command again, on an installed box
  ok    gateway  already configured in /home/rehearse/.config/cortex/gateway (use --force-config to regenerate)
         kept existing: reply_default_automation_slug='chat', fleet_bin='/home/rehearse/.local/share/cortex/packs/tmux-kit/bin/tmux-fleet', mind_dir='/home/rehearse/.local/share/cortex/mind'
REINSTALL_EXIT=0

########## 13:40:46  PHASE 13  the secret never leaks
no key file: correct, none was given
0 occurrences of sk- in the page: correct

########## 13:40:46  PHASE 14  the package mount was never written to
touch: cannot touch '/cortex-demo.tar.gz': Read-only file system
tarball mount is read-only: confirmed
```

---

## What the rehearsal found, and the root-cause fix

The rehearsal earned its keep: it exposed a defect that **cannot** be seen on
this host, because on this host the broken path happens to exist.

**Defect.** `cortex-gateway setup` writes `mind_dir` from its own
`DEFAULT_MIND_DIR = "~/dev/cortex-core/cortex-mind"` — a path in the *author's*
dev workspace. On Sam's machine that directory does not exist, so
`cortex_gateway/mind.py` falls back to its builtin persona:

```
builtin-fallback (no cortex-mind checkout at ~/dev/cortex-core/cortex-mind)
```

The cortex-mind we ship would have been installed correctly to
`~/.local/share/cortex/mind` and then never read. The gateway's own doctor
reports `mind_dir` as a **non-required** check, so this passed quietly. Cortex
would have run on Sam's box with a different character than the one we built,
and nothing would have said so.

**Fix, at the root cause, in two places:**

1. `install.sh` — the existing "a path that does not resolve here is a dangling
   pointer, not a preference" repair rule was written for `fleet_bin` alone.
   It is now a general rule over path-valued keys (`PATH_KEYS`), with a
   per-key resolution test, and `mind_dir` joins it. A value that *does*
   resolve is still never touched.
2. `bin/cortex` — `cortex doctor` now checks `mind_dir` and treats a
   non-resolving one as **FAIL**, not a warning: a silent downgrade of the
   product's whole character is not a warning-level event.

Proof it now repairs, from the same transcript:

```
REPAIRED: fleet_bin='/home/rehearse/.local/share/cortex/packs/tmux-kit/bin/tmux-fleet' (was '~/dev/cortex-core/cortex-pack-tmux-kit/bin/tmux-fleet', which does not resolve here),
          mind_dir='/home/rehearse/.local/share/cortex/mind' (was '~/dev/cortex-core/cortex-mind', which does not resolve here)
```

and that the repair is respected on re-install rather than re-applied blindly:

```
kept existing: reply_default_automation_slug='chat', fleet_bin='...tmux-fleet', mind_dir='.../share/cortex/mind'
```

No wrapper hack was used to paper over this. The wrapper still sets exactly one
variable.

---

## Gate 3 — the live stack was not touched

`cd /home/bkrabach/dev/cortex-core/cortex && ./bin/cortex doctor` **after** the
build and both rehearsals — exit 0:

```
Services
PASS  tmux session           'cortex' (3 windows)
PASS  hub :7080              healthz 200
PASS  gateway :7443          healthz 200, TLS verified against the CA it serves at /api/ca
PASS  drumbeat :9102         api/health 200

Rails
PASS  GET /v1/notifications  rail present, 401 unauthenticated (device auth enforced, as contracted)
PASS  delivery cursor        cursor 68267, lag 0, updated 2026-08-10T13:34:34.741464+00:00

Distribution
PASS  android apk            15M at /home/bkrabach/.local/share/cortex/dist/cortex.apk

Neighbours (must be untouched)
PASS  protected ports        live: 8443 9443 9000 9100 8088 -- Cortex binds only 7443/9102/7080

doctor: all checks passed
```

Note the live host also shows `PASS mind_dir ~/dev/cortex-core/cortex-mind ->
/home/bkrabach/dev/cortex-core/cortex-mind` — the new check passes here because
the path genuinely resolves here, which is exactly why the bug was invisible
without a foreign box to test on.

### Sources were read, never written

The build fingerprints every source before and after (git SHA + porcelain
status + a size/mtime manifest) and **fails the build** if any changed. It
passed for all five, quoted in Gate 1. Independently, after everything:

```
../cortex-gateway                 2c6c4f7  1 changed     <- pre-existing: ?? FIX2-GOAL.md (the gateway lane's own)
../cortex-mind                    04f7edf  0 changed
../cortex-pack-tmux-kit           859ba3a  0 changed
~/dev/amplifier-attention-manager/drumbeat  86d8a06  0 changed
```

The guard is not decorative — it fired for real, twice, during this work:

- first when the default output directory (`build/`) sat inside the source tree.
  Fixed by pruning **the resolved output path**, by exact path rather than by
  name, so a directory that merely happens to be called `build` inside a source
  is still watched;
- then when the build's own transcript was redirected into `EVIDENCE/` while the
  build ran. The build writes its log to `build/` and it is copied into
  `EVIDENCE/` afterwards. A check that cannot fail proves nothing; this one can,
  and did.

---

## Honest limits

- **Rehearsed on `ubuntu:24.04/aarch64`, in a container.** Sam's box is not
  this box. What is proven: the package is self-contained, the seam resolves,
  the services come up, the page serves the right APK. What is not proven:
  his distro, his firewall, his phone.
- **Voice was not exercised.** No OpenAI key was provided by design, so minting
  returns 503 with its remedy. The key path itself is proven on the live host,
  not here.
- **No phone was paired in the container.** Pairing is proven only as far as
  the mint (`pair_uri` parses, halves match). The end-to-end phone pairing is
  covered by `EVIDENCE/fix-pairing.md` on the live stack.
- **The extracted directory must stay.** `install.sh` symlinks the served
  `dist/` at the package's `cortex/dist/`, so deleting the extracted folder
  takes the APK download with it. This is called out in `SAM-README.md` §2.
  It is a deliberate property (a rebuilt APK republishes with no reinstall),
  not an oversight.
