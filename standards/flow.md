# Flow standard

## Start local

Keep communication and state local until a demonstrated requirement justifies a wider boundary. Crossing process, machine, region, service, or external-provider boundaries adds latency, failure modes, serialization, security exposure, and operational cost.

## Measure the constraint

When performance or scale matters, identify:

- arrival/input rate,
- processing rate,
- queue depth or backlog,
- resource pressure,
- latency and error rate,
- the actual bottleneck.

Do not optimize a non-bottleneck merely because it is visible.

## Backpressure and scarcity

A producer must not be able to overwhelm a slower consumer indefinitely. Use bounded queues, rate limits, budgets, load shedding, retry limits, or other controls appropriate to the system.

When resources are scarce, preserve critical work before optional work. Spare capacity may be deliberate resilience rather than waste.

## Cascading failure

Retries, queues, locks, agents, and shared infrastructure can amplify failure. Design retry limits, timeouts, circuit breaking, cancellation, priority, and recovery so degraded components do not make the whole system progressively worse.

## Scale deliberately

Increase distribution, concurrency, replication, or shared infrastructure because evidence shows the current design has reached a limit. Do not introduce them as speculative architecture.
