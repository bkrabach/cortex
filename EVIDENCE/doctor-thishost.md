# `cortex doctor` — THIS HOST (the demo machine)

Services live, run as the ordinary user on the machine that will host the demo.

```
$ cortex doctor
Cortex doctor  2026-08-09T21:47:33-07:00

Prerequisites
PASS  python3                3.12.3
PASS  uv                     /snap/bin/uv
PASS  git                    /usr/bin/git
PASS  tmux                   /usr/bin/tmux
PASS  curl                   /usr/bin/curl

Components
PASS  gateway                /home/bkrabach/.local/share/cortex/gateway/venv/bin/cortex-gateway
PASS  drumbeat               /home/bkrabach/.local/share/cortex/drumbeat/venv/bin/drumbeat
PASS  hub                    /home/bkrabach/.local/share/cortex/hub/serve.py
PASS  mind                   /home/bkrabach/.local/share/cortex/mind
PASS  pack                   /home/bkrabach/.local/share/cortex/packs/tmux-kit

Configuration
PASS  openai key             /home/bkrabach/.config/cortex/gateway/openai_key (0600)
PASS  gateway config         /home/bkrabach/.config/cortex/gateway
PASS  drumbeat workspace     /home/bkrabach/.local/state/cortex/drumbeat
PASS  drumbeat packs.txt     1 pack(s)

Services
PASS  tmux session           'cortex' (3 windows)
PASS  hub :7080              healthz 200
PASS  gateway :7443          healthz 200, TLS verified against the CA it serves at /api/ca
      that is trust-on-first-use, not independent proof: this check confirms the
      gateway serves a consistent chain, not that the chain is the one you expect.
      The phone does the same thing once, at pairing.
PASS  drumbeat :9102         api/health 200

Distribution
WARN  android apk            not built yet -- hub serves an honest 404, never a placeholder
      remedy: the android lane drops cortex.apk into /home/bkrabach/.local/share/cortex/dist/ (no restart needed)

Neighbours (must be untouched)
PASS  protected ports        live: 8443 9443 9000 9100 8088 -- Cortex binds only 7443/9102/7080

doctor: all checks passed (1 warning(s) -- named above, none fatal)
EXIT=0
```

Gateway healthz, TLS verified against the CA `setup` wrote to disk (no `curl -k`):

```
$ curl -s --cacert ~/.config/cortex/gateway/tls/ca.pem https://127.0.0.1:7443/healthz
{"status":"ok","service":"cortex-gateway","version":"0.1.0","time":"2026-08-10T04:47:33.357796+00:00","port":7443}
```
