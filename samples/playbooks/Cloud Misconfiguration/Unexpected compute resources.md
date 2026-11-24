---
dummy: true
id: PB-CLD-003
category: Cloud Misconfiguration
severity: High
attack:
  tactics: [TA0040, TA0005]
  techniques: [T1496, T1578.002]
owner: Cloud security lead
last_review: 2026-11-20
---

# Unexpected compute resources

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

New virtual machines or GPU instances appear without a change, often for cryptocurrency mining with stolen credentials.

| Field | Value |
| --- | --- |
| ID | PB-CLD-003 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1496 Resource Hijacking](https://attack.mitre.org/techniques/T1496/) |
| [Defense Evasion](https://attack.mitre.org/tactics/TA0005/) (TA0005) | [T1578.002 Modify Cloud Compute Infrastructure: Create Cloud Instance](https://attack.mitre.org/techniques/T1578/002/) |

## Detection

- Budget alert or sudden cost increase.
- Cloud audit log shows instances created in an unused region.

## Triage

1. Identify the identity that created the resources.
2. Check whether that identity's credential was exposed; see [Leaked access key](Leaked%20access%20key.md).

## Containment

1. Disable the creating identity.
2. Stop and snapshot the instances for evidence, then delete them.

## Eradication

- Remove any additional identities or keys created.

## Recovery

- Restrict allowed regions and instance types through policy.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The creating identity has permissions beyond compute.

## Owner

Cloud security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Leaked access key](Leaked%20access%20key.md)
