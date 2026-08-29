# Cortex — Context Transfer for New Sessions

This document provides everything needed to continue work on the Cortex project with zero prior context. Read this ENTIRELY before taking any action.

---

## 1. What Is Cortex?

Cortex is a **personal AI attention management system** that intercepts OS notifications from Windows (Teams, WhatsApp, Outlook, etc.), scores them with an LLM for relevance, and decides whether to push them through, suppress them, or batch them into summaries. It consists of:

- **A Linux server** (`amplifier-app-server`) running as a systemd service on `spark-1`
- **A Windows client** (`amplifier-bundle-attention-firewall`) running as a Windows Task Scheduler task
- **A macOS client** (`cortex-client-macos`) running as a native Swift menu bar app
- **A web UI** at `http://spark-1:19420` for chat, triage, and admin
- **Mobile push** via ntfy.sh to Android/iOS
- **A2A (Agent-to-Agent)** mesh integration on port 8214

The system is built on the **Amplifier framework** (microsoft/amplifier ecosystem).

---

## 2. Repository Structure

The parent repo is `bkrabach/cortex` (a monorepo with submodules):

```
/home/bkrabach/repos/notification-watcher/     ← This is the working directory
├── amplifier/                                  ← microsoft/amplifier (docs, governance)
├── amplifier-core/                             ← microsoft/amplifier-core (kernel)
├── amplifier-foundation/                       ← microsoft/amplifier-foundation (bundles, utils)
├── amplifier-app-server/                       ← bkrabach/amplifier-app-server ★ MAIN SERVER
│   ├── bundles/
│   │   └── cortex-core.md                      ← Web chat bundle
│   │       (cortex-a2a.md removed -- cortex-x12e/SCOPING-a2a.md: stale agent
│   │        card advertising capabilities the shipped product never had, at
│   │        an unconditional tier:trusted with no human in the loop)
│   ├── config/
│   │   └── attention-rules.md                  ← Notification scoring rules (LLM reads this)
│   ├── context/
│   │   └── a2a-network.md                      ← A2A mesh topology and routing rules
│   ├── src/amplifier_server/
│   │   ├── server.py                           ← FastAPI server, lifespan, session init
│   │   ├── session_manager.py                  ← Amplifier session creation and management
│   │   ├── notification_processor.py           ← Scoring pipeline, push decisions, A2A broadcast
│   │   ├── notification_store.py               ← SQLite notification storage + conversation history
│   │   ├── llm_scorer.py                       ← LLM scoring with conversation context
│   │   ├── ntfy_notifier.py                    ← ntfy.sh mobile push integration
│   │   ├── device_manager.py                   ← WebSocket device connections
│   │   ├── chat_store.py                       ← Chat history persistence
│   │   ├── startup.py                          ← systemd service management
│   │   ├── main.py                             ← CLI entry point (run, service, status, etc.)
│   │   └── api/                                ← FastAPI routers (notifications, triage, chat, auth, etc.)
│   ├── static/                                 ← Web UI (index.html, admin.html, JS, CSS)
│   └── .env                                    ← CORTEX_API_KEY, NTFY_TOPIC
├── amplifier-bundle-attention-firewall/        ← bkrabach/amplifier-bundle-attention-firewall ★ WIN CLIENT
│   └── src/attention_firewall/
│       ├── client.py                           ← WebSocket client connecting to server
│       ├── listener.py                         ← Windows notification capture via pywinrt
│       ├── toast.py                            ← Windows toast notifications (PowerShell, CREATE_NO_WINDOW)
│       ├── startup.py                          ← Windows Task Scheduler management (VBScript launcher)
│       ├── main.py                             ← CLI entry point
│       └── __main__.py                         ← Enables python -m attention_firewall
├── cortex-client-macos/                        ← bkrabach/cortex-client-macos ★ MAC CLIENT
│   └── (Swift/SwiftUI native app)
└── docs/, assets/, etc.
```

**All 4 project repos are PUBLIC:**
- `bkrabach/cortex` — parent monorepo
- `bkrabach/amplifier-app-server` — server
- `bkrabach/amplifier-bundle-attention-firewall` — Windows client + Amplifier bundle
- `bkrabach/cortex-client-macos` — macOS native client

---

## 3. How It All Runs

### Server (Linux — spark-1)

```
Location:  /home/bkrabach/repos/notification-watcher/amplifier-app-server
Service:   systemd user service "cortex-server" (enabled, auto-start on boot)
Port:      19420 (main HTTP/WebSocket API + web UI)
Port:      8214 (A2A agent-to-agent protocol)
Python:    3.11.14 (in .venv)
Data dir:  ~/.amplifier-server/ (notifications.db, chat.db)
Config:    ~/.cortex/server.env (ANTHROPIC_API_KEY)
           .env in repo root (CORTEX_API_KEY, NTFY_TOPIC)
```

**Managing the server:**
```bash
cd ~/repos/notification-watcher/amplifier-app-server
source .venv/bin/activate
amplifier-server service status    # Check if running
amplifier-server service restart   # Restart after code changes
amplifier-server service logs -f   # Follow logs
amplifier-server service stop      # Stop
amplifier-server service start     # Start
```

**The server creates 2 Amplifier sessions on startup** (a 3rd, `cortex-a2a`, the
autonomous A2A responder session, was removed -- see cortex-x12e/SCOPING-a2a.md):
1. `notification-scorer` — Minimal session (Haiku) for fast notification scoring
2. `cortex-core-{user_id}` — Per-user web chat session (Sonnet 4.5 with extended thinking)

### Windows Client (ALIENWARE-R13)

```
Location:  C:\Users\brkrabac\repos\amplifier-bundle-attention-firewall
Service:   Windows Task Scheduler "CortexAttentionFirewall" (runs at logon)
Launcher:  %USERPROFILE%\.cortex\cortex-client.vbs (VBScript, runs pythonw.exe hidden)
Config:    %USERPROFILE%\.cortex\client.yaml (server URL, device_id, API key)
Python:    3.14 (in .venv)
```

**Managing Windows client:**
```powershell
attention-firewall startup status     # Check
attention-firewall startup restart    # Restart
attention-firewall startup stop       # Stop
# For debugging with console output:
attention-firewall client --config %USERPROFILE%\.cortex\client.yaml --verbose
```

**Critical: `startup install` requires Administrator prompt.**

### macOS Client

Native Swift menu bar app. Connects via WebSocket to the server. Has its own repo with amplifier submodules.

### Mobile Push (ntfy.sh)

Topic: `cortex-bkrabach-474ujd` — when server pushes a notification, it also sends to ntfy.sh, which delivers to the ntfy app on Android/watch.

---

## 4. Notification Flow

```
Windows notifications → Client captures via pywinrt UserNotificationListener
    ↓
Client sends to server via POST /notifications/ingest
    ↓
Server stores in SQLite (notification_store.py)
    ↓
notification_processor.py picks it up from queue
    ↓
HARD FILTER: Skip if title/sender contains "ntfy" (loop prevention)
    ↓
LLM Scorer (llm_scorer.py):
  - Loads attention-rules.md from disk (hot-reload)
  - Fetches conversation history (last 10 msgs from same thread, 24h)
  - Sends to Anthropic with rules + history + notification
  - Returns: {score, decision, rationale, tags}
    ↓
Decision: push (>= 0.6) | summarize (0.3-0.6) | suppress (< 0.3)
    ↓
If push:
  - Send to all connected WebSocket devices (device_manager)
  - Send via ntfy.sh (ntfy_notifier.py)
  - If score >= 0.9: trigger A2A broadcast to ai-os (fire-and-forget asyncio task)
  - Create triage item with status "surfaced"
If summarize:
  - Create triage item with status "pending"
If suppress:
  - Store but don't surface
```

---

## 5. Key Configuration Files

### `config/attention-rules.md`
The LLM reads this file on EVERY scoring call. Contains:
- VIP senders, keyword triggers, app-specific rules
- Time-based rules (before 8am: family only, etc.)
- Current context (e.g., travel mode, focus periods)
- The user can ask Cortex to update this file via the web chat

**Runtime copy:** `~/.amplifier-server/config/attention-rules.md`

### `bundles/cortex-core.md`
Powers the web chat. Has:
- Anthropic provider (claude-sonnet-4-5)
- tool-filesystem, tool-bash, tool-web, tool-delegate, tool-a2a
- Notification/policies tools (mounted programmatically)
- Time context instructions (user is Pacific Time, DB stores UTC)
- Instructions to delegate complex notification ops to triage-manager agent

### `bundles/cortex-a2a.md` (REMOVED)
Used to power an autonomous A2A responder (hooks-a2a-server on port 8214 +
tool-a2a, proactive trigger rules notifying ai-os). Deleted per
cortex-x12e/SCOPING-a2a.md: the card advertised an "attention management
platform" with notification-scoring/focus-mode skills the shipped product
never had, to four hardcoded `localhost` peers at an unconditional
`tier: trusted`, with its own body instruction stating "there is no human in
the loop" -- the exact inverse of the product's governing principle. Left in
this historical section for context; do not resurrect without a real trust/
consent model for peer agents (SCOPING-a2a.md's "Security / consent
boundaries" section).

### `context/a2a-network.md`
Was shared by `cortex-a2a.md` above (now removed) and `cortex-core.md`'s
`tool-a2a` reference. Describes the 5-agent mesh:
- ai-os (port 8210), lifeline (8211), lifeline-demo (8212), hive-slack (8213), cortex (8214)
- Routing rules: when to ask which peer
- Proactive triggers: only ai-os gets automatic notifications (customizable)

---

## 6. Critical Gotchas — DO NOT Break These

### Environment / API Keys
- `ANTHROPIC_API_KEY` is in `~/.cortex/server.env` (NOT in .env or shell profile)
- The server loads env files in this order: `.env` → `~/.amplifier/keys.env` → `~/.cortex/server.env`
- If API key is missing, the Anthropic provider silently fails to mount → "No providers mounted" error

### systemd Service
- The service file is at `~/.config/systemd/user/cortex-server.service`
- It sets PATH, HOME, USER, XDG_*, UV_CACHE_DIR, VIRTUAL_ENV explicitly (systemd has minimal env)
- `loginctl enable-linger` is set so it runs even when user is not logged in
- After code changes: `amplifier-server service restart` (NOT just `git pull`)

### Bundle Cache
- Amplifier caches bundles in `~/.amplifier/cache/`
- If bundles behave strangely after updates: `rm -rf ~/.amplifier/cache/*` then restart
- This was the fix for "No providers mounted" after updating dependencies

### Session Manager Prepared Bundle Cache
- `session_manager.py` caches prepared bundles by `bundle_uri` (NOT by bundle name)
- This was a critical bug fix (commit `0e587e2`) — previously cortex-core and cortex-a2a collided because both composed bundles had name "config-override:1.0.0"
- DO NOT change the cache key back to `bundle.name:bundle.version`

### Notification/Policies Tools
- These are from the `attention-firewall` package but DON'T follow the `amplifier_module_*` naming convention
- They're mounted PROGRAMMATICALLY in `session_manager.py` via `_mount_attention_firewall_tools()`
- This runs for ALL sessions created via `_create_amplifier_session()`

### A2A Modules
- `amplifier-module-tool-a2a` and `amplifier-module-hooks-a2a-server` are pip-installed as editable from `/home/bkrabach/repos/amplifier-bundle-a2a/modules/`
- The tool-a2a module had a Python 3.11 syntax fix (nested f-string on line 831) — fixed in both source and cache
- The A2A agent card currently shows `"skills": []` — this is a known issue where the skills from bundle config aren't being passed through to the card builder

### ntfy Feedback Loop
- Hard filter in `notification_processor.py` skips notifications where title/sender contains "ntfy" or body starts with 🚨/🔔
- This prevents: Cortex pushes via ntfy → Phone Link reflects it → Windows client sends it back → infinite loop

### Windows Client
- Uses `pythonw.exe` (no console window) via VBScript launcher
- All winrt-* packages are in pyproject.toml with `sys_platform == "win32"` markers
- `startup install` REQUIRES Administrator prompt (Task Scheduler limitation)
- PowerShell toast notifications use `CREATE_NO_WINDOW` flag to prevent console flash

### Chat History Injection
- When cortex-core session is created (e.g., after server restart), chat history from ChatStore is injected into the session's context via `context.set_messages()`
- Without this, the LLM says "I don't have context from our previous conversation"
- This is in `api/chat.py` — the `session_just_created` flag triggers injection

---

## 7. A2A Integration (Latest Work) — cortex-a2a bundle REMOVED, see cortex-x12e/SCOPING-a2a.md

**This whole section describes a bundle that no longer exists.** Kept for
historical record only; do not use it as a guide to the current system, and
do not resurrect `bundles/cortex-a2a.md` from it without first reading
SCOPING-a2a.md's "Security / consent boundaries" section (unconditional
`tier: trusted` for hardcoded peers, no consent representation, no human in
the loop).

### Former State (historical, pre-removal)
- A2A server running on port 8214 ✅
- Agent card at `http://localhost:8214/.well-known/agent.json` ✅ (skills list is empty — known issue)
- cortex-a2a session handles incoming A2A messages autonomously ✅
- tool-a2a available in web chat (cortex-core bundle) ✅
- Proactive broadcast to ai-os on score >= 0.9 ✅

### The 5-Agent Mesh
| Agent | Port | Domain |
|-------|------|--------|
| ai-os | 8210 | Email, calendar, tasks, files |
| lifeline | 8211 | Relationship intelligence, people knowledge |
| lifeline-demo | 8212 | Calendar, email, files via Microsoft Graph |
| hive-slack | 8213 | Coding, dev tasks, Slack channels |
| **cortex** | **8214** | **Notification scoring, focus modes, attention** |

### Design Documents
- Design: `docs/plans/2026-02-26-cortex-a2a-integration-design.md`
- Implementation plan: `docs/plans/2026-02-26-cortex-a2a-implementation.md`
- A2A handoff doc: `/home/bkrabach/dev/all-a2a/docs/handoffs/cortex-a2a-handoff.md`

### Known Issues to Fix
1. **Agent card skills list is empty** — the skills from cortex-a2a.md config aren't being passed through to the card builder
2. **A2A modules need to stay pip-installed** — if the server venv is recreated, reinstall: `uv pip install -e /home/bkrabach/repos/amplifier-bundle-a2a/modules/tool-a2a` and `uv pip install -e /home/bkrabach/repos/amplifier-bundle-a2a/modules/hooks-a2a-server`

---

## 8. Web UI

- **Chat** (`http://spark-1:19420`) — Multiline textarea input, "Cortex is thinking..." indicator, markdown rendering, WebSocket-based
- **Triage** — Notification triage with cards, bulk actions, expandable AI reasoning
- **Admin** — User management, API key generation
- **Auth** — JWT tokens (7-day access, 90-day refresh), auto-refresh on 401, stored in localStorage

---

## 9. Common Tasks

### After Pulling Code Changes
```bash
cd ~/repos/notification-watcher/amplifier-app-server
git pull
amplifier-server service restart
```

### If "No providers mounted" Error
```bash
rm -rf ~/.amplifier/cache/*
amplifier-server service restart
```

### Updating Attention Rules
Edit `config/attention-rules.md` directly, OR tell Cortex via web chat to update its rules. The LLM scorer reloads this file on every scoring call.

### Adding a Feature to the Server
1. Edit files in `src/amplifier_server/`
2. Commit with conventional commits (`feat:`, `fix:`, `docs:`)
3. Push to main: `git push`
4. Restart: `amplifier-server service restart`

### Updating Amplifier Dependencies
```bash
cd ~/repos/notification-watcher
cd amplifier-core && git pull && cd ..
cd amplifier-foundation && git pull && cd ..
cd amplifier-app-server && source .venv/bin/activate
uv pip install -e ../amplifier-core
uv pip install -e ../amplifier-foundation --no-deps
amplifier-server service restart
```

---

## 10. What NOT to Do

- **DO NOT** edit `amplifier-core` or `amplifier-foundation` source code — those are upstream Microsoft repos
- **DO NOT** remove the ntfy feedback loop filter from notification_processor.py
- **DO NOT** change the prepared bundle cache key in session_manager.py back to name:version
- **DO NOT** add `PrivateTmp=true` or `NoNewPrivileges=true` to the systemd service — it breaks subprocess calls
- **DO NOT** create files in the parent `notification-watcher/` repo when you mean the `amplifier-app-server/` submodule — this was a bug in a previous session
- **DO NOT** use `%USERPROFILE%` in PowerShell — use `$env:USERPROFILE` instead
- **DO NOT** assume the API key is in the shell environment — under systemd it's ONLY in `~/.cortex/server.env`

---

## 11. Prioritized Next Steps

### P0 — Fix Before Demo

1. ~~**A2A agent card skills list is empty**~~ — MOOT: `bundles/cortex-a2a.md` (the card this bug lived in) was removed per cortex-x12e/SCOPING-a2a.md. Left here only so a reader of this historical P0 list doesn't go looking for a bundle that no longer exists.

2. **Test A2A end-to-end with a peer agent** — Start one of the other agents (ai-os is the most important peer) and verify:
   - Cortex can send a message to ai-os via `a2a(operation="send", agent="ai-os", message="...")`
   - ai-os can send a message to Cortex and get an autonomous response
   - The Morning Briefing scenario works: ai-os asks "What notifications came through overnight?" and Cortex responds with ranked results

3. **Verify proactive A2A broadcast** — Trigger a notification with score >= 0.9 and confirm the cortex-a2a session fires off a message to ai-os via tool-a2a.

### P1 — Important Improvements

4. **Attention rules are stale** — The `config/attention-rules.md` still has Palo Alto trip context from early February. The runtime copy at `~/.amplifier-server/config/attention-rules.md` may also be stale. Update both to reflect current priorities. Ask the user what their current context/travel/focus should be.

5. **LLM conversation context for scoring** — We recently added conversation history injection (the scorer now sees the last 10 messages in the same thread). Monitor the logs to verify this is working well and the context isn't getting too large (body truncated to 200 chars per history message).

6. **Web UI polish** — The chat UI now has multiline input and thinking indicator. Consider adding:
   - Streaming responses (currently waits for full response)
   - Better error display when LLM fails
   - Notification count in browser tab title

### P2 — Nice to Have

7. **macOS client reconnection** — The macOS client sometimes drops and doesn't reconnect. May need keep-alive or reconnection logic.

8. **Notification deduplication** — The Windows client sometimes sends duplicate notifications. The store has dedup logic but it may need tuning.

9. **Focus mode integration** — The attention-rules.md has focus mode concepts but there's no actual focus mode toggle in the web UI or API yet. When implemented, it should trigger an A2A notification to ai-os per the routing rules.

10. **Update CONTEXT_TRANSFER.md** — This document should be updated at the end of each major session to keep it current for the next handoff.
