# Cortex Platform - Development Workspace

## Overview

**Cortex** is a personal AI assistant platform that manages attention, automates tasks, and acts on behalf of the user across all their devices. Built on [Amplifier](https://github.com/microsoft/amplifier).

**Vision Documents:** See `docs/vision/` for the foundational vision (written March 2025).

**Roadmap:** See `ROADMAP.md` for current status and development phases.

## Core Concepts

### Cortex Core
The central orchestrator - a long-running Amplifier session that routes tasks, maintains unified context, and determines when/how to surface information to the user.

### Domain Expert Entities
Autonomous specialized services (each an Amplifier session) that handle specific domains:
- **Attention Firewall** - Notification filtering and prioritization
- **Email Manager** (future) - Email handling and drafting
- More to come...

### Multi-Device I/O
Devices are lightweight I/O endpoints that register capabilities. The core routes to the optimal device based on user activity.

## Repositories

| Repository | Purpose |
|------------|---------|
| [bkrabach/amplifier-app-server](https://github.com/bkrabach/amplifier-app-server) | Cortex Hub - Always-on server |
| [bkrabach/amplifier-bundle-attention-firewall](https://github.com/bkrabach/amplifier-bundle-attention-firewall) | Attention Firewall Domain Expert + Windows client |

## Current Status

**Phase:** MVP - Attention Firewall working
**Last Updated:** 2026-01-13

### What Works
- Windows notification capture via pywinrt
- Server ingestion and storage
- LLM-powered relevance scoring (0-1)
- Decisions: suppress / summarize / push
- Push notifications back to devices
- Multi-device support

### Next Steps
- AGENTS.md-style config for notification rules
- Sender extraction from notification content
- VIP/policy configuration
- Reduce token usage (stateless scoring)
- Cortex Core orchestrator design
- Web UI for administration

## Workspace Structure

```
cortex/                              # This workspace
├── AGENTS.md                        # This file
├── ROADMAP.md                       # Development roadmap
├── docs/
│   └── vision/                      # North star documents
│       ├── cortex-platform_vision-and-values.md
│       ├── cortex-platform_technical-architecture.md
│       ├── cortex-platform_a-day-in-the-life.md
│       ├── central-ai-core-with-adaptive-ecosystem.md
│       └── domain-expert-entities.md
├── amplifier-app-server/            # Submodule → GitHub repo
│   └── src/amplifier_server/
│       ├── server.py                # FastAPI server
│       ├── notifications.py         # Notification processing
│       ├── notification_processor.py # Amplifier session for scoring
│       └── api/                     # REST + WebSocket endpoints
├── amplifier-bundle-attention-firewall/  # Submodule → GitHub repo
│   └── src/attention_firewall/
│       ├── client.py                # Server client mode
│       ├── listener.py              # Windows notification capture
│       └── toast.py                 # Windows toast display
└── [Amplifier reference submodules]
    ├── amplifier/
    ├── amplifier-core/
    └── amplifier-foundation/
```

## Quick Start

### Server (Linux/WSL/Mac)

```bash
cd amplifier-app-server
uv venv && source .venv/bin/activate
uv pip install -e .
amplifier-server run --port 8420
```

### Client (Windows)

```powershell
cd amplifier-bundle-attention-firewall
uv venv && .venv\Scripts\activate
uv pip install -e .
attention-firewall client --server http://your-server:8420
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CORTEX HUB (Server)                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              CORTEX CORE (Future)                            │   │
│  │  Long-running Amplifier session for orchestration            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│         ┌────────────────────┼────────────────────┐                │
│         ▼                    ▼                    ▼                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐          │
│  │ Attention   │     │   Email     │     │  Future     │          │
│  │ Firewall    │     │  Manager    │     │  Experts    │          │
│  │ ✓ Working   │     │  (planned)  │     │             │          │
│  └─────────────┘     └─────────────┘     └─────────────┘          │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    DEVICE REGISTRY                           │   │
│  │  Tracks connected devices, routes to active device           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │   Windows   │     │   Android   │     │ Raspberry   │
   │   Client    │     │   Client    │     │ Pi Client   │
   │  ✓ Working  │     │  (future)   │     │  (future)   │
   └─────────────┘     └─────────────┘     └─────────────┘
```

## API Reference

### Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/notifications/ingest` | Receive notification from device |
| GET | `/notifications` | List stored notifications |
| GET | `/notifications/{id}` | Get notification details |

### Devices

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/devices` | List connected devices |
| WS | `/ws/device/{device_id}` | Device WebSocket connection |

## Windows Setup

For Attention Firewall to work, configure Windows to suppress native banners:

1. **Settings → System → Notifications**
2. For each app (Teams, WhatsApp, Outlook):
   - Turn OFF "Show notification banners"
   - Keep ON "Show notifications in notification center"

This allows capture without native popups, letting the AI decide what to surface.

## Development Guidelines

1. **Vision as north star** - Reference `docs/vision/` for direction
2. **Amplifier-native** - Use Amplifier primitives (sessions, bundles, modules)
3. **Progressive autonomy** - Learn before acting
4. **Cross-platform DRY** - Minimize OS-specific code
5. **User makes the calls** - AI proposes, user decides

## Resume Instructions

1. Check `ROADMAP.md` for current phase and next steps
2. Server: `amplifier-app-server/` 
3. Client: `amplifier-bundle-attention-firewall/`
4. Vision docs: `docs/vision/`
5. To test: Start server, connect Windows client, trigger notifications
