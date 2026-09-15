# Capability roadmap

Organize this roadmap as a dependency graph, not a chronological wish list.

## Final capability

Describe the externally observable capability defined in `GOAL.md`.

## Dependency graph

Keep leaf capabilities concrete enough to implement and support with independent evidence.

```text
Final capability
├── Capability A
│   ├── A1
│   └── A2
├── Capability B
└── Capability C
```

## Capability quality

Use one current level and one required level when quality matters:

| Level | Meaning |
| --- | --- |
| `absent` | No implementation exists. |
| `works` | Demonstrated on the intended path. |
| `reliable` | Repeatably succeeds within defined conditions. |
| `observable` | Behavior and failures can be diagnosed from evidence. |
| `efficient` | Meets stated resource, cost, latency, or throughput expectations. |
| `resilient` | Handles expected failures and recovery without unacceptable impact. |

Do not promote a capability because more engineering feels desirable. Promote it because the goal or risk requires the next quality level.

## Prioritization

1. Work on the lowest unresolved dependency blocking the current goal.
2. Prefer deleting or simplifying work before expanding architecture.
3. Improve the measured bottleneck, not the most visible subsystem.
4. Choose infrastructure work when it unlocks multiple downstream capabilities or removes recurring toil.
5. Treat migration and maintenance work as roadmap items when postponing them creates material risk.
