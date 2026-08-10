# cortex doctor -- THIS HOST (the demo machine)

Command: `cortex doctor` run on the demo host with services live.

```
2026-08-09T21:40:08-07:00
Cortex doctor  2026-08-09T21:40:08-07:00

Prerequisites
PASS  python3                3.12.3
PASS  uv                     /snap/bin/uv
PASS  git                    /usr/bin/git
PASS  tmux                   /usr/bin/tmux
PASS  curl                   /usr/bin/curl

Components
FAIL  gateway                not installed
      remedy: the gateway lane's checkout must exist, then re-run install.sh
              (CORTEX_GATEWAY_SRC=/path/to/cortex-gateway ./install.sh)
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
PASS  tmux session           'cortex' (2 windows)
PASS  hub :7080              healthz 200
FAIL  gateway :7443          not listening
      remedy: cortex start; then cortex logs gateway
PASS  drumbeat :9102         api/health 200

Distribution
WARN  android apk            not built yet -- hub serves an honest 404, never a placeholder
      remedy: the android lane drops cortex.apk into /home/bkrabach/.local/share/cortex/dist/ (no restart needed)

Neighbours (must be untouched)
PASS  protected ports        live: 8443 9443 9000 9100 8088 -- Cortex binds only 7443/9102/7080

doctor: 2 check(s) FAILED -- fix the named remedies and re-run
EXIT=1
```
