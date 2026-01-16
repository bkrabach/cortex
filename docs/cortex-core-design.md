# Cortex Core - Technical Design

**Status:** Design Phase
**Date:** 2026-01-15

---

## Overview

The Cortex Core is the central "brain" of the Cortex platform - a long-running Amplifier session that orchestrates all Domain Experts, manages configurations, and provides a conversational interface for user interaction.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              AMPLIFIER-APP-SERVER (Hub)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           CORTEX CORE SESSION                         │  │
│  │  (Long-running Amplifier session)                     │  │
│  │                                                       │  │
│  │  Orchestrator: loop-streaming (standard)              │  │
│  │  Context: Persistent (conversation history)           │  │
│  │  Tools: filesystem, bash, web, task                   │  │
│  │  Provider: Sonnet (reasoning capability)              │  │
│  │                                                       │  │
│  │  Responsibilities:                                    │  │
│  │  - Chat with user via web UI                         │  │
│  │  - Manage config files (attention-rules.md, etc.)    │  │
│  │  - Monitor Domain Expert events                      │  │
│  │  - Route tasks to appropriate experts                │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           ├─ manages ─┐                     │
│                           │            │                     │
│  ┌────────────────────────▼──────┐  ┌─▼──────────────────┐  │
│  │  NOTIFICATION-SCORER          │  │  CONFIG FILES      │  │
│  │  (Domain Expert)               │  │                    │  │
│  │  - Scores notifications        │  │  attention-rules.md│  │
│  │  - Reads attention-rules.md   │  │  device-prefs.yaml │  │
│  │  - Uses Sonnet                │  │  (future)          │  │
│  └───────────────────────────────┘  └────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Cortex Core Session

**Type:** Long-running Amplifier session
**ID:** `cortex-core`
**Bundle:** Custom bundle with foundation + tools

**Configuration:**
```yaml
session:
  orchestrator: loop-streaming
  context: context-simple  # For now, persistent context later
  
providers:
  - module: provider-anthropic
    config:
      model: claude-sonnet-4-5
      
tools:
  - tool-filesystem
  - tool-bash
  - tool-web
  - tool-task  # For delegating to Domain Experts
  - tool-cortex  # Custom tool for Cortex operations
```

**System Prompt:**
```
You are Cortex, a personal AI assistant managing attention and tasks across devices.

You coordinate Domain Expert services:
- Attention Firewall: Notification filtering (session: notification-scorer)

You manage configuration files:
- config/attention-rules.md: Rules for notification scoring

User can chat with you to:
- Update notification rules ("Only show me urgent stuff until 3pm")
- Check notification history ("What did I miss?")
- Manage VIP lists ("Add Alice to VIPs")
- Query system status ("Is the Windows client connected?")

You have access to filesystem, bash, web, and task delegation tools.
```

### 2. Web UI

**Tech Stack:** Simple HTML + vanilla JavaScript (no framework)
**Location:** `amplifier-app-server/static/`

**Pages:**
- `/` - Chat interface
- `/dashboard` - System status (devices, sessions, notifications)
- `/config` - Configuration editor

**API Endpoints:**
```
GET  /web/chat              → Serve chat UI
WS   /ws/chat/cortex-core   → WebSocket for chat with Core
GET  /web/dashboard         → Serve dashboard UI
GET  /api/status            → System status JSON
```

### 3. Custom Tool: tool-cortex

**Purpose:** Domain-specific operations for Cortex

**Methods:**
```python
# Notification management
get_recent_notifications(hours=1, app_id=None)
get_notification_stats(hours=24)
generate_digest(hours=1)

# Device management  
get_connected_devices()
get_active_device()

# Config management
reload_config(domain_expert="attention-firewall")
```

### 4. Event Aggregation

**Hook:** `hooks-cortex-events`

Listens to Domain Expert events and aggregates for the Core:
- `notification:scored` → Core can see what's being filtered
- `notification:pushed` → Core knows what interrupted the user
- `device:connected` → Core tracks device availability

## Implementation Plan

### Phase 1: Core Session (MVP)
- [ ] Create cortex-core bundle definition
- [ ] Initialize core session at server startup
- [ ] Test chat via CLI: `amplifier-server chat cortex-core`

### Phase 2: Web UI
- [ ] Simple HTML chat interface
- [ ] WebSocket chat endpoint
- [ ] Serve static files from FastAPI

### Phase 3: Domain Expert Integration
- [ ] Core can query notification stats
- [ ] Core can update attention-rules.md
- [ ] Test: User chats "Show me urgent stuff only" → Core updates config

### Phase 4: Dashboard
- [ ] Device status view
- [ ] Notification timeline
- [ ] Domain Expert health

## File Structure

```
amplifier-app-server/
├── src/amplifier_server/
│   ├── server.py                # Add cortex-core session init
│   ├── cortex_core.py          # NEW: Core session management
│   └── api/
│       └── chat.py             # NEW: Chat WebSocket endpoint
├── static/                      # NEW: Web UI
│   ├── index.html              # Chat interface
│   ├── dashboard.html          # System dashboard
│   └── app.js                  # WebSocket client
└── bundles/
    └── cortex-core.md          # NEW: Core bundle definition
```

## User Scenarios

### Scenario 1: Update notification rules via chat

```
User: "I'm in focus mode until 3pm. Only show me urgent stuff or family."

Core: [Uses write_file to update attention-rules.md]
      "Updated! Until 3pm, you'll only see urgent notifications and family messages."
```

### Scenario 2: Check what was missed

```
User: "What did I miss in the last hour?"

Core: [Calls get_recent_notifications, generates summary]
      "In the last hour:
       - 3 Teams messages (suppressed, just chatter)
       - 1 Outlook email from Sam (summarized, FYI only)
       - 2 Phone Link texts (1 from Charlie - I pushed that one to you)
       
       Nothing urgent that you missed."
```

### Scenario 3: Manage VIPs

```
User: "Add Alice Chen to my VIP list"

Core: [Updates attention-rules.md, adds Alice Chen]
      "Added Alice Chen to your VIPs. Her messages will now push through."
```

---

## Next Actions

1. Create `bundles/cortex-core.md` bundle definition
2. Add `cortex_core.py` session management
3. Update `server.py` to initialize Core at startup
4. Add `/ws/chat/cortex-core` WebSocket endpoint
5. Create simple `static/index.html` chat UI

Ready to start implementation?
