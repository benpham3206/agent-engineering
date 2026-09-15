# Threat model

Keep this document focused on realistic assets, boundaries, abuse paths, and controls. Update it when authority or trust changes materially.

## Assets

List data, credentials, systems, identities, user capabilities, deployment authority, and other resources that require protection.

## Actors and identities

List humans, services, agents, workers, CI jobs, and external providers that can request or perform actions. Record how each actor is authenticated and which capabilities it receives.

## Trust boundaries

Identify where untrusted input crosses into privileged behavior, especially model-generated tool arguments, commands, paths, URLs, code, external content, and cross-agent messages.

## Privileged actions

List actions that require explicit policy, independent verification, or human approval: destructive writes, permission changes, deployment, publishing, money movement, sensitive communications, credential access, or comparable project-specific operations.

## Abuse and failure cases

Document realistic scenarios, including injection, privilege escalation, secret leakage, hostile dependencies/tool output, destructive actions, runaway resource use, and cross-agent trust abuse when relevant.

## Controls

For each material risk, record prevention, containment, detection, recovery, and audit controls. Prefer structural controls over reminders.

## Verification

Link each important control to a test, adversarial eval, scan, policy check, review requirement, or operational evidence that demonstrates it remains effective.
