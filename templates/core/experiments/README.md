# Experiments

Keep uncertain research separate from production code until the result justifies integration.

Create one directory per experiment with a short `README.md` containing:

```markdown
# Experiment name

## Question

What specific uncertainty are we resolving?

## Hypothesis

What result do we expect and why?

## Setup

What is held constant and what changes?

## Success criterion

What measurable result would justify adoption?

## Result

Record evidence, including negative results.

## Decision

Choose one: adopt, modify, reject.
```

Move completed but historically useful experiments under `archive/`. Production code should not import from archived experiments.
