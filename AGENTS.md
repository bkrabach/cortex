# Attention Firewall - Development Workspace

## Project Overview

**Product:** Attention Firewall - AI-powered Windows notification controller

**Repository:** [bkrabach/amplifier-bundle-attention-firewall](https://github.com/bkrabach/amplifier-bundle-attention-firewall)

**Goal:** Build a general-purpose OS notification controller that:
1. Captures ALL Windows toast notifications (Teams, WhatsApp, Outlook, etc.)
2. Uses Amplifier AI agent to score relevance and filter noise
3. Suppresses low-value notifications, surfaces high-signal ones
4. Generates hourly/daily digests of filtered content
5. Supports conversational policy management ("Add Alice to VIP")

## Current Status

**Phase:** Phase 0/1 Complete - Ready for Testing
**Last Updated:** 2025-01-09

## Workspace Structure

```
notification-watcher/                    # This workspace
├── AGENTS.md                            # This file
├── amplifier-bundle-attention-firewall/ # Submodule → GitHub repo
│   ├── bundle.md                        # Amplifier bundle definition
│   ├── src/attention_firewall/          # Python package
│   ├── context/instructions.md          # Agent system prompt
│   ├── config/default-policy.yaml       # Default filtering rules
│   ├── pyproject.toml
│   └── README.md
└── [other submodules as needed]
```

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ATTENTION FIREWALL                              │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐    ┌─────────────────────────────────────────┐ │
│  │  Notification       │    │          Python Service (Daemon)        │ │
│  │  Listener Thread    │    │                                         │ │
│  │                     │    │  ┌─────────────────────────────────┐    │ │
│  │  • pywinrt bindings │───▶│  │        AsyncIO Queue           │    │ │
│  │  • UserNotification │    │  │     (thread-safe bridge)       │    │ │
│  │    Listener API     │    │  └──────────────┬──────────────────┘    │ │
│  │  • Captures ALL     │    │                 │                       │ │
│  │    notifications    │    │                 ▼                       │ │
│  └─────────────────────┘    │  ┌─────────────────────────────────┐    │ │
│                             │  │     Amplifier Session           │    │ │
│  ┌─────────────────────┐    │  │     (persistent, long-lived)    │    │ │
│  │      Scheduler      │───▶│  │                                 │    │ │
│  │    (APScheduler)    │    │  │  Tools:                         │    │ │
│  │                     │    │  │  • ingest_notification          │    │ │
│  │  • Hourly summary   │    │  │  • send_toast                   │    │ │
│  │  • Daily digest     │    │  │  • manage_policy                │    │ │
│  └─────────────────────┘    │  │  • generate_summary             │    │ │
│                             │  └──────────────┬──────────────────┘    │ │
│                             │                 │                       │ │
│                             │                 ▼                       │ │
│                             │  ┌─────────────────────────────────┐    │ │
│                             │  │      State Manager              │    │ │
│                             │  │  • SQLite (persistence)         │    │ │
│                             │  │  • In-memory cache (VIPs, keys) │    │ │
│                             │  └─────────────────────────────────┘    │ │
│                             └─────────────────────────────────────────┘ │
│                                                                         │
│  ┌─────────────────────┐                                                │
│  │   Agent Toasts      │  Branded notifications with rationale         │
│  └─────────────────────┘                                                │
└─────────────────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 0: PoC - COMPLETE ✅
- [x] Research Windows notification APIs
- [x] Research suppression mechanisms  
- [x] Design architecture
- [x] Implement notification listener with pywinrt
- [x] Implement Windows toast sender
- [x] Validate structure (needs Windows testing)

### Phase 1: Core Service - COMPLETE ✅
- [x] Create Amplifier bundle definition
- [x] Implement custom tools (ingest, notify, policy, summary)
- [x] Implement state manager (SQLite + in-memory cache)
- [x] Implement daemon service
- [x] Basic VIP/keyword filtering
- [x] CLI with commands (run, check, summary, policies, add-vip, test)

### Phase 2: Policy & UX - PENDING
- [ ] YAML policy file with hot-reload
- [ ] Full Amplifier session integration for AI scoring
- [ ] Conversational policy updates via agent
- [ ] Hourly/daily digest generation refinement
- [ ] System tray UI (optional)

### Phase 3: Hardening - PENDING
- [ ] Windows service registration
- [ ] Auto-start on boot
- [ ] Crash recovery
- [ ] Setup wizard

## Quick Start (Windows)

```powershell
# Clone the bundle
git clone https://github.com/bkrabach/amplifier-bundle-attention-firewall.git
cd amplifier-bundle-attention-firewall

# Install
uv pip install -e .

# Check system readiness
attention-firewall check

# Run the daemon
attention-firewall run -v
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `amplifier-bundle-attention-firewall/src/attention_firewall/listener.py` | Windows notification capture |
| `amplifier-bundle-attention-firewall/src/attention_firewall/daemon.py` | Main service with filtering pipeline |
| `amplifier-bundle-attention-firewall/src/attention_firewall/state.py` | SQLite state + VIP/keyword cache |
| `amplifier-bundle-attention-firewall/bundle.md` | Amplifier bundle configuration |
| `amplifier-bundle-attention-firewall/context/instructions.md` | Agent system prompt |
| `amplifier-bundle-attention-firewall/config/default-policy.yaml` | Default filtering rules |

## Windows Setup Required

For the system to work, users must configure Windows to suppress banners for target apps:

1. **Settings → System → Notifications**
2. For each app (Teams, WhatsApp, Outlook):
   - Click the app
   - Turn OFF "Show notification banners"
   - Keep ON "Show notifications in notification center"

This allows the listener to capture notifications without the user seeing native popups.

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Notification API | UserNotificationListener via pywinrt | Official Windows 10+ API, full access |
| Suppression model | User disables native banners | No public API for interception |
| Language | Python | Amplifier is Python; pywinrt provides API access |
| State storage | SQLite + in-memory cache | Durable, queryable, fast lookups |
| Event ingestion | Structured prompts to session | Natural conversation context |
| Scheduling | APScheduler | Lightweight, async-compatible |

## Resume Instructions

If resuming this work:

1. Check current phase status above
2. The bundle is in `amplifier-bundle-attention-firewall/` (submodule)
3. Push changes to the bundle repo: `cd amplifier-bundle-attention-firewall && git push`
4. For Phase 2, focus on full Amplifier session integration

## Notes

- This project is Windows-only (uses Windows Notification APIs)
- On non-Windows, runs in "mock mode" for development/testing
- pywinrt may need MSIX packaging for production reliability
