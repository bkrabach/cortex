# ADR-001: Tool Naming Convention for Behavior Bundles

## Status
**Accepted** - 2026-01-29

## Context

Multiple behavior bundles will provide tools to the Cortex platform. We need a naming convention that:
- Avoids collisions between bundles
- Scales to 10+ behavior bundles
- Provides consistent discoverability for LLMs
- Allows common concepts (like "triage") to exist across domains

### The Problem

"Triage" is a **concept/operation** that spans domains:
- Notification triage = prioritize by attention policy
- Issue triage = prioritize by severity
- Email triage = prioritize by sender importance
- Task triage = decide what to work on next

If we name tools after operations (`triage`, `archive`, `list`), we get collisions.

## Decision

Adopt **domain-centric tool naming** with **operation parameters**.

### The Pattern

```
Tool Name = Domain Noun (the "what")
Operations = Contextual Verbs (the "how")

notifications(operation="triage")  ← Domain provides context
issues(operation="triage")         ← Same verb, different meaning
email(operation="triage")          ← per domain
```

### Naming Rules

**Rule 1: Tool Name = Domain Noun**
- Use the primary domain entity the tool manages
- Plural for collections: `notifications`, `issues`, `tasks`, `events`
- Singular for services/systems: `calendar`, `email` (the system)

**Rule 2: Operations = Contextual Verbs**
- Operations are parameters, not tool names
- Same operation name CAN exist across domains
- The domain provides semantic context

**Rule 3: Qualify Domain When Sources Overlap**
```python
# If multiple bundles handle similar entities:
github_notifications(operation="triage")   # GitHub-specific
slack_messages(operation="triage")         # Slack-specific

# Prefer non-overlapping names when possible:
notifications    # OS/system notifications (attention-firewall)
messages         # Chat messages (chat-manager)
```

**Rule 4: Standard Operation Names**
Encourage reuse where semantically appropriate:

| Operation | Meaning |
|-----------|---------|
| `list` | Return items in the domain |
| `get` | Get single item by ID |
| `triage` | Prioritize/categorize items |
| `update` | Modify item state |
| `archive` | Move to completed/processed state |
| `stats` | Return statistics/metrics |
| `search` | Query with filters |

## Consequences

### Positive
- Consistent pattern across all bundles
- Natural discoverability: "What can I do with notifications?" → check `notifications` tool
- No explosion of tool count (N domains, not N×M tools)
- "triage" concept reused without collision
- Matches REST/resource-centric patterns (proven at scale)

### Negative
- "triage" means different things per domain (mitigated by descriptions)
- Requires discipline to follow convention

## Examples

### Scaling to 10+ Bundles

| Bundle | Tool(s) | Example Operations |
|--------|---------|-------------------|
| attention-firewall | `notifications`, `policies` | triage, list, summary, add_vip |
| issues-manager | `issues` | triage, list, close, assign |
| email-manager | `email` | triage, list, send, archive |
| calendar-manager | `calendar` | list, schedule, conflicts |
| task-manager | `tasks` | triage, list, complete, defer |
| code-reviewer | `reviews` | list, approve, request_changes |

### Tool Signatures

```python
# Attention Firewall
notifications(
    operation: "list" | "get" | "triage" | "update" | "summary" | "stats",
    id: str = None,
    ids: list[str] = None,
    action: str = None,
    feedback: str = None,
    filters: dict = None,
)

policies(
    operation: "list" | "add_vip" | "remove_vip" | "add_keyword" | "mute_app",
    sender: str = None,
    app: str = None,
    keyword: str = None,
)
```

## Key Insight

> "Triage" isn't a tool, it's an operation you perform *on* a domain. 
> The domain is the anchor, the operation is contextual.

## Related Decisions
- ADR-002: Behavior Bundle Structure (pending)
- ADR-003: Agent Delegation Patterns (pending)
