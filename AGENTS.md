# Attention Firewall - Development Workspace

## Project Overview

**Product:** Attention Firewall - AI-powered Windows notification controller

**Repositories:**
- [bkrabach/amplifier-bundle-attention-firewall](https://github.com/bkrabach/amplifier-bundle-attention-firewall) - Windows notification capture and filtering
- [bkrabach/amplifier-app-server](https://github.com/bkrabach/amplifier-app-server) - Always-on AI agent runtime

**Goal:** Build a general-purpose OS notification controller that:
1. Captures ALL Windows toast notifications (Teams, WhatsApp, Outlook, etc.)
2. Forwards to an always-on Amplifier server for AI-powered filtering
3. Suppresses low-value notifications, surfaces high-signal ones
4. Generates hourly/daily digests of filtered content
5. Supports conversational policy management ("Add Alice to VIP")
6. Multi-device support - all Windows machines report to one hub

## Current Status

**Phase:** Phase 1.5 - Server Architecture Complete
**Last Updated:** 2025-01-09

### What's Built

- **amplifier-app-server** - Always-on AI agent runtime with HTTP/WebSocket API
- **attention-firewall client mode** - Connects Windows clients to the server
- **Standalone daemon** - Still works for single-machine use

## Workspace Structure

```
notification-watcher/                    # This workspace
├── AGENTS.md                            # This file
├── amplifier-app-server/                # Submodule → GitHub repo
│   ├── src/amplifier_server/
│   │   ├── server.py                    # FastAPI server
│   │   ├── session_manager.py           # Multi-session hosting
│   │   ├── device_manager.py            # Connected device tracking
│   │   ├── hooks/                       # Extension model
│   │   └── api/                         # REST + WebSocket endpoints
│   ├── pyproject.toml
│   └── README.md
├── amplifier-bundle-attention-firewall/ # Submodule → GitHub repo
│   ├── src/attention_firewall/
│   │   ├── client.py                    # NEW: Server client mode
│   │   ├── daemon.py                    # Standalone mode
│   │   ├── listener.py                  # Windows notification capture
│   │   └── ...
│   ├── bundle.md                        # Amplifier bundle definition
│   └── README.md
└── [other submodules as needed]
```

## Architecture - Client/Server Model (Recommended)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DISTRIBUTED ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  WINDOWS DEVICES (Multiple)                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │ attention-firewall  │  │ attention-firewall  │  │ attention-firewall  │ │
│  │ client              │  │ client              │  │ client              │ │
│  │                     │  │                     │  │                     │ │
│  │ • Notification      │  │ • Notification      │  │ • Notification      │ │
│  │   listener          │  │   listener          │  │   listener          │ │
│  │ • Forward to server │  │ • Forward to server │  │ • Forward to server │ │
│  │ • Display pushes    │  │ • Display pushes    │  │ • Display pushes    │ │
│  └──────────┬──────────┘  └──────────┬──────────┘  └──────────┬──────────┘ │
│             │                        │                        │             │
│             │        HTTP POST /notifications/ingest          │             │
│             │        WebSocket /ws/device/{id}                │             │
│             └────────────────────────┼────────────────────────┘             │
│                                      │                                      │
│                                      ▼                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                     AMPLIFIER APP SERVER                              │ │
│  │                     (Always-on Linux/WSL/Mac hub)                     │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Session Manager                              │ │ │
│  │  │                                                                 │ │ │
│  │  │   Session "personal-hub"                                        │ │ │
│  │  │   ├─ Bundle: attention-firewall                                 │ │ │
│  │  │   ├─ Tools: ingest, notify, policy, summary                     │ │ │
│  │  │   └─ Context: VIPs, keywords, conversation history              │ │ │
│  │  └─────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Device Manager                               │ │ │
│  │  │                                                                 │ │ │
│  │  │   Desktop-PC    Laptop       Surface      (WebSocket connected) │ │ │
│  │  └─────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Hook Registry                                │ │ │
│  │  │                                                                 │ │ │
│  │  │   InputHook: NotificationIngest (from devices)                  │ │ │
│  │  │   OutputHook: PushNotification (to devices)                     │ │ │
│  │  └─────────────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ACCESS METHODS                                                             │
│  ├─ CLI: amplifier-server chat SESSION_ID                                  │
│  ├─ WebSocket: /ws/chat/{session_id}                                       │
│  ├─ REST: POST /sessions/{id}/execute                                      │
│  └─ Tailscale: Remote access from anywhere                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 0: PoC - COMPLETE ✅
- [x] Research Windows notification APIs
- [x] Research suppression mechanisms  
- [x] Design architecture
- [x] Implement notification listener with pywinrt
- [x] Implement Windows toast sender

### Phase 1: Core Service - COMPLETE ✅
- [x] Create Amplifier bundle definition
- [x] Implement custom tools (ingest, notify, policy, summary)
- [x] Implement state manager (SQLite + in-memory cache)
- [x] Implement standalone daemon service
- [x] Basic VIP/keyword filtering
- [x] CLI with commands (run, check, summary, policies, add-vip, test)

### Phase 1.5: Server Architecture - COMPLETE ✅
- [x] Create amplifier-app-server with multi-session support
- [x] HTTP/WebSocket API for sessions, devices, notifications
- [x] Device manager for tracking connected clients
- [x] Hook-based extension model for bundles
- [x] Client mode for attention-firewall (connects to server)

### Phase 2: AI Integration - PENDING
- [ ] Full Amplifier session integration in server
- [ ] AI-powered relevance scoring
- [ ] Conversational policy updates via agent
- [ ] Hourly/daily digest generation refinement
- [ ] Web UI for chat interface

### Phase 3: Hardening - PENDING
- [ ] Server as systemd service
- [ ] Windows client as Windows service
- [ ] Auto-start on boot
- [ ] Crash recovery
- [ ] Setup wizard

## Quick Start

### Option A: Client/Server Mode (Recommended)

```bash
# On your always-on server (Linux/WSL/Mac)
cd amplifier-app-server
uv pip install -e .
amplifier-server run --port 8420

# On your Windows machine(s)
cd amplifier-bundle-attention-firewall
uv pip install -e .
attention-firewall client --server http://your-server:8420
```

### Option B: Standalone Mode (Single Machine)

```powershell
# On Windows only
cd amplifier-bundle-attention-firewall
uv pip install -e .
attention-firewall run -v
```

## Key Files Reference

### amplifier-app-server

| File | Purpose |
|------|---------|
| `src/amplifier_server/server.py` | Main FastAPI server |
| `src/amplifier_server/session_manager.py` | Multi-session hosting |
| `src/amplifier_server/device_manager.py` | WebSocket device tracking |
| `src/amplifier_server/hooks/base.py` | Extension model for bundles |
| `src/amplifier_server/api/` | REST and WebSocket endpoints |

### amplifier-bundle-attention-firewall

| File | Purpose |
|------|---------|
| `src/attention_firewall/client.py` | Server client mode |
| `src/attention_firewall/daemon.py` | Standalone mode |
| `src/attention_firewall/listener.py` | Windows notification capture |
| `src/attention_firewall/state.py` | SQLite state + VIP/keyword cache |
| `bundle.md` | Amplifier bundle configuration |

## API Reference (amplifier-app-server)

### Sessions

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/sessions` | Create session with bundle |
| GET | `/sessions` | List all sessions |
| GET | `/sessions/{id}` | Get session info |
| POST | `/sessions/{id}/execute` | Execute prompt |
| POST | `/sessions/{id}/inject` | Inject context |
| DELETE | `/sessions/{id}` | Stop session |

### Devices

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/devices` | List connected devices |
| GET | `/devices/{id}` | Get device info |

### Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/notifications/ingest` | Receive from device |
| POST | `/notifications/push` | Send to device(s) |

### WebSocket

| Endpoint | Description |
|----------|-------------|
| `/ws/device/{device_id}` | Device connection |
| `/ws/chat/{session_id}` | Interactive chat |
| `/ws/events` | Event stream |

## Windows Setup Required

For the system to work, users must configure Windows to suppress banners for target apps:

1. **Settings → System → Notifications**
2. For each app (Teams, WhatsApp, Outlook):
   - Click the app
   - Turn OFF "Show notification banners"
   - Keep ON "Show notifications in notification center"

This allows the listener to capture notifications without the user seeing native popups.

## Resume Instructions

If resuming this work:

1. Check current phase status above
2. Submodules:
   - `amplifier-app-server/` - Server runtime
   - `amplifier-bundle-attention-firewall/` - Windows client/bundle
3. To test:
   - Start server: `cd amplifier-app-server && amplifier-server run`
   - Connect client: `cd amplifier-bundle-attention-firewall && attention-firewall client`
4. For Phase 2, focus on full Amplifier session integration in the server

## Future Vision

This architecture enables building a **personal AI assistant** that:
- Runs 24/7 on an always-on server
- Receives notifications from all your devices
- Builds up context over time about your work and priorities
- Can be chatted with from anywhere (web, CLI, mobile)
- Proactively notifies you of important things
- Eventually: calendar integration, email, task management

## Notes

- attention-firewall is Windows-only (uses Windows Notification APIs)
- amplifier-app-server runs on any platform (Linux, WSL, Mac)
- On non-Windows, attention-firewall runs in "mock mode" for development
- Use Tailscale for secure remote access to the server
