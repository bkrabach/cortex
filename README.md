# Cortex

**Personal AI assistant platform** - manages attention, automates tasks, and acts on your behalf across all your devices.

Built on the [Amplifier](https://github.com/microsoft/amplifier) ecosystem.

## Vision

Cortex is a central AI core that:
- **Routes tasks** to specialized Domain Expert services
- **Maintains unified context** across all interactions  
- **Determines when/how** to surface information based on your activity
- **Acts progressively** - learns before taking action, builds trust over time

See [`docs/vision/`](docs/vision/) for the foundational vision documents.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CORTEX HUB (Server)                      │
├─────────────────────────────────────────────────────────────┤
│  Cortex Core - Long-running orchestrator session            │
│       │                                                     │
│       ├── Attention Firewall (notifications) ✓              │
│       ├── Email Manager (future)                            │
│       └── [Additional Domain Experts]                       │
│                                                             │
│  Device Registry - Routes to active device                  │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
    ┌─────────┐      ┌─────────┐      ┌─────────┐
    │ Windows │      │ Android │      │   RPi   │
    │ Client  │      │ (future)│      │(future) │
    └─────────┘      └─────────┘      └─────────┘
```

## Current Status

**Attention Firewall** - First Domain Expert, MVP working:
- Windows notification capture via pywinrt
- AI-powered relevance scoring (suppress / summarize / push)
- Multi-device support with push notifications

See [`ROADMAP.md`](ROADMAP.md) for development phases and next steps.

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

## Repository Structure

```
cortex/
├── README.md                 # This file
├── ROADMAP.md                # Development roadmap
├── AGENTS.md                 # Workspace context for AI assistants
├── docs/vision/              # North star vision documents
├── amplifier-app-server/     # Hub server (submodule)
└── amplifier-bundle-attention-firewall/  # Client + bundle (submodule)
```

## Components

| Component | Repository | Description |
|-----------|------------|-------------|
| **Hub Server** | [amplifier-app-server](https://github.com/bkrabach/amplifier-app-server) | Always-on server hosting Domain Experts |
| **Attention Firewall** | [amplifier-bundle-attention-firewall](https://github.com/bkrabach/amplifier-bundle-attention-firewall) | Notification filtering + Windows client |

## Documentation

- [`ROADMAP.md`](ROADMAP.md) - Development phases, architecture, Amplifier integration
- [`AGENTS.md`](AGENTS.md) - Workspace guide for AI development assistants
- [`docs/vision/`](docs/vision/) - Foundational vision documents (March 2025)

## License

MIT
