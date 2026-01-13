# Cortex Platform - Roadmap & Design

**Status**: Planning / Early Development
**Last Updated**: 2026-01-13

---

## Overview

Cortex is a personal AI assistant platform that manages attention, automates tasks, and acts on behalf of the user across all their devices. Built on the [Amplifier](https://github.com/microsoft/amplifier) ecosystem.

### Vision Documents

The foundational vision for Cortex is captured in these documents (written March 2025):

- **[Vision and Values](docs/vision/cortex-platform_vision-and-values.md)** - High-level vision, core values, modular architecture
- **[Technical Architecture](docs/vision/cortex-platform_technical-architecture.md)** - Detailed component specifications
- **[A Day in the Life](docs/vision/cortex-platform_a-day-in-the-life.md)** - User scenarios showing seamless integration
- **[Central AI Core](docs/vision/central-ai-core-with-adaptive-ecosystem.md)** - Core routing and adaptive ecosystem concept
- **[Domain Expert Entities](docs/vision/domain-expert-entities.md)** - Autonomous specialized modules

These documents serve as the **north star** for the project. The implementation leverages the Amplifier ecosystem (developed after the vision docs) as the foundation.

---

## Core Concepts (from Vision)

### The Cortex Core

> "The core is a router. It keeps track of the available inputs/outputs, connections to apps/services, etc. and intelligently invokes the right parts to serve the task at hand."

The Cortex Core is the central orchestrator - implemented as a long-running Amplifier session that:
- Maintains unified context/memory across all interactions
- Routes tasks to appropriate Domain Expert services
- Determines when/how to surface information to the user
- Manages configuration for all connected services

### Domain Expert Entities

> "Domain expert entities are autonomous, specialized modules that bring deep expertise in a specific field... like a highly skilled specialist that can understand a high-level request, figure out the best approach within its field, and execute the task efficiently and independently."

Each Domain Expert is a specialized service (Amplifier session) that:
- Operates autonomously with minimal oversight from the core
- Has its own planning/execution/evaluation cycle
- Reports back to the core with results and recommendations
- Can request user input when needed via the core

### Multi-Modal I/O

> "Inputs/outputs are lightweight and independent... You can input on whatever is convenient for your situation - scenario/device/location/environment, and it can output on whatever is most appropriate."

Devices are I/O endpoints that:
- Declare their capabilities (screen, voice, keyboard, etc.)
- Connect to the hub and register presence
- Route notifications/interactions based on user activity
- The core decides optimal routing based on context

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CORTEX HUB (Server)                            │
│                     (Ubuntu on Spark box)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    CORTEX CORE                               │   │
│  │            (Long-running Amplifier Session)                  │   │
│  │  - Web UI for chat/administration                            │   │
│  │  - Manages AGENTS.md-like config files for services          │   │
│  │  - Aggregates events from all Domain Experts                 │   │
│  │  - Routes tasks and surfaces information to user             │   │
│  │  - Unified memory (JAKE concept via Amplifier context)       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│         ┌────────────────────┼────────────────────┐                │
│         ▼                    ▼                    ▼                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐          │
│  │ Attention   │     │   Email     │     │  Future     │          │
│  │ Firewall    │     │  Manager    │     │  Experts    │          │
│  │ (notifs)    │     │  (future)   │     │             │          │
│  └─────────────┘     └─────────────┘     └─────────────┘          │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    DEVICE REGISTRY                           │   │
│  │  - Tracks connected devices and capabilities                 │   │
│  │  - Knows which device(s) user is currently active on         │   │
│  │  - Routes communications to appropriate device               │   │
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
   │             │     │  (future)   │     │  (future)   │
   └─────────────┘     └─────────────┘     └─────────────┘
```

---

## Amplifier Integration Strategy

The Cortex vision predates Amplifier by ~6 months. We leverage Amplifier as the implementation foundation:

### Amplifier Primitives → Cortex Concepts

| Cortex Concept | Amplifier Implementation |
|----------------|-------------------------|
| **Cortex Core** | Long-running Amplifier session with custom orchestrator |
| **Domain Expert Entity** | Amplifier agent (bundle + session) |
| **Unified Memory (JAKE)** | Amplifier context module + persistent storage |
| **Configuration** | AGENTS.md-style files managed by the core |
| **Integration Layer** | MCP tools, custom tools, hooks |

### What We'll Build

| Component | Type | Description |
|-----------|------|-------------|
| `cortex-hub` | Amplifier App | Server application hosting the core |
| `cortex-core` | Custom Orchestrator | Main routing/coordination logic |
| `cortex-context` | Context Module | Persistent memory system |
| `cortex-client` | Python Package | Cross-platform client library |
| `attention-firewall` | Domain Expert (Bundle) | Notification filtering service |
| `email-manager` | Domain Expert (Bundle) | Email handling service (future) |

---

## Client Architecture

### Design Principle: DRY Core + OS-Specific Extensions

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENT (per device)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              CROSS-PLATFORM CORE (Python)                 │ │
│  │  - Server communication (WebSocket, REST)                 │ │
│  │  - Local Amplifier instance for on-device intelligence    │ │
│  │  - Event routing and buffering                            │ │
│  │  - Capability negotiation                                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│              ┌───────────────┼───────────────┐                 │
│              ▼               ▼               ▼                  │
│       ┌───────────┐   ┌───────────┐   ┌───────────┐           │
│       │ Notif     │   │ Display   │   │ Activity  │           │
│       │ Listener  │   │ Manager   │   │ Monitor   │           │
│       │ (OS ext)  │   │ (OS ext)  │   │ (OS ext)  │           │
│       └───────────┘   └───────────┘   └───────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Device Capabilities

Each device registers with the hub declaring its capabilities:

```yaml
device:
  id: "ALIENWARE-R13"
  name: "Brian's Desktop"
  platform: windows
  capabilities:
    - notifications:listen
    - notifications:display
    - screen:display
    - input:keyboard
    - input:mouse
    - audio:output
    - audio:input
    - files:access
    - amplifier:local
```

### Active Device Routing

> "The core is responsible for determining when things should be surfaced to the user - are we actively working on something and it should be now, are we after the user's work hours and this should wait until tomorrow..."

```
When notification needs to be pushed:
  1. Check active devices (last activity < 5 min)
  2. If desktop active → show toast
  3. If no desktop, check mobile → push notification
  4. If voice-capable device in location → announce
  5. Fallback → queue for next active device
```

---

## Domain Expert: Attention Firewall

**Status**: MVP working (notifications flowing, LLM scoring)

### Current State
- Windows client captures notifications via pywinrt
- Server receives and stores notifications
- Amplifier session scores relevance (0-1)
- Decisions: suppress / summarize / push
- Push notifications sent back to active devices

### Configuration Design

The Attention Firewall will have an AGENTS.md-style config managed by the Cortex Core:

```yaml
# attention-firewall-config.yaml

user:
  name: Brian Krabach
  aliases: [Brian, bkrabach, brkrabac]

vip_senders:
  - Kevin Scott
  - Sam Schillace
  - Charlie Krabach  # family

apps:
  WhatsApp:
    ingest: true
    default_action: summarize
    vip_override: push
    
  Teams:
    ingest: true
    default_action: allow
    
  Outlook:
    ingest: true
    default_action: summarize
    vip_override: push
    keywords_push: [urgent, deadline, blocking]

schedule:
  focus_hours:
    - time: "09:00-12:00"
      action: suppress_unless_vip
    - time: "13:00-16:00"
      action: suppress_unless_vip
      
  digest_times: ["09:00", "12:00", "16:00"]

# Dynamic instructions from Cortex Core
current_instructions: |
  I'm heads down until noon working on the Cortex platform.
  Only interrupt me for:
  - Messages from Charlie (family)
  - Anything mentioning "production" or "outage"
  At noon, send me a summary and remind me to take a break.
```

---

## Domain Expert: Email Manager (Future)

**Status**: Planned

### Autonomy Progression

| Level | Description |
|-------|-------------|
| **1. Observer** | Read emails, provide summaries, learn patterns |
| **2. Suggester** | Propose actions (archive, respond, flag) |
| **3. Assistant** | Draft responses for review |
| **4. Actor** | Take approved action types automatically |
| **5. Autonomous** | Full authority for routine email management |

---

## Cortex Core Design

### Main Orchestrator

The "brain" of the system - a long-running Amplifier session with:

**Custom Orchestrator** that:
- Maintains conversation history as working memory
- Processes events from all Domain Experts
- Routes tasks to appropriate experts
- Decides when/how to surface information to user

**Web UI** providing:
- Chat interface for conversational interaction
- Dashboard showing service status and device connectivity
- Event feed / timeline across all services
- Configuration management with AI assistance

**Configuration Management**:
- Manages AGENTS.md-like files for each Domain Expert
- User says: "I'm heads down until noon, only family or emergencies"
- Core updates attention-firewall-config.yaml with current_instructions
- Sets focus mode across devices
- Schedules noon reminder

---

## Project Structure

```
cortex/
├── README.md
├── ROADMAP.md                    # This file
├── AGENTS.md                     # Workspace guidance
├── docs/
│   └── vision/                   # North star documents
│       ├── cortex-platform_vision-and-values.md
│       ├── cortex-platform_technical-architecture.md
│       ├── cortex-platform_a-day-in-the-life.md
│       ├── central-ai-core-with-adaptive-ecosystem.md
│       └── domain-expert-entities.md
│
├── amplifier-app-server/         # Hub server (submodule)
│   └── (FastAPI server, notification processing)
│
├── amplifier-bundle-attention-firewall/  # Client bundle (submodule)
│   └── (Windows notification listener, client CLI)
│
└── [future components]
    ├── cortex-core/              # Custom orchestrator module
    ├── cortex-context/           # Persistent memory module  
    ├── cortex-web/               # Web UI for admin
    └── cortex-client/            # Cross-platform client library
```

---

## Development Phases

### Phase 0: Foundation (Current)
- [x] Windows notification capture
- [x] Server ingestion and storage
- [x] LLM-based scoring
- [x] Push notifications back to devices
- [ ] Sender extraction from content
- [ ] VIP/policy configuration
- [ ] Reduce token usage (stateless scoring)

### Phase 1: Attention Firewall Polish
- [ ] AGENTS.md-style config file
- [ ] Digest generation (hourly, daily, on-demand)
- [ ] Focus mode with time-based rules
- [ ] User feedback loop on decisions

### Phase 2: Cortex Core
- [ ] Long-running session architecture
- [ ] Web UI for chat/administration
- [ ] Configuration management via chat
- [ ] Event aggregation from services

### Phase 3: Multi-Device
- [ ] Device capability registry
- [ ] Active device detection
- [ ] Smart routing based on activity
- [ ] macOS client (if needed)
- [ ] Android client (future)

### Phase 4: Additional Domain Experts
- [ ] Email Manager (personal email)
- [ ] Calendar awareness
- [ ] Additional integrations

---

## Development Principles

1. **Vision as north star** - Cortex vision docs guide direction
2. **Amplifier-native** - Use Amplifier primitives (sessions, bundles, modules)
3. **Progressive autonomy** - Learn before acting
4. **Cross-platform DRY** - Minimize OS-specific code
5. **Event-driven** - Services emit events, core aggregates
6. **User makes the calls** - AI proposes, user decides

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-13 | Adopt "Cortex" as project name | Aligns with prior vision docs |
| 2026-01-13 | Use pywinrt for Windows notifications | Best Windows API coverage |
| 2026-01-13 | Central hub architecture | User has always-on Ubuntu server |
| 2026-01-13 | Amplifier as implementation foundation | Provides sessions, agents, orchestration |
