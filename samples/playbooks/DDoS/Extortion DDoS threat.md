---
dummy: true
id: PB-DOS-004
category: DDoS
severity: Medium
attack:
  tactics: [TA0040]
  techniques: [T1498, T1657]
owner: Network security lead
last_review: 2026-11-20
---

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An email threatens a DDoS attack unless a payment is made, sometimes followed by a short demonstration attack.

| Field | Value |
| --- | --- |
| ID | PB-DOS-004 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1498 Network Denial of Service](https://attack.mitre.org/techniques/T1498/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1657 Financial Theft](https://attack.mitre.org/techniques/T1657/) |

## Detection

- Threatening email to a public mailbox, often naming a deadline.

## Triage

1. Check whether a demonstration attack happened and its size.
2. Search threat intelligence for the group name; many such threats are not carried out.

## Containment

1. Confirm DDoS protection coverage for all public services before the deadline.

## Eradication

- Not applicable.

## Recovery

- Preserve the email for law enforcement.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always to the incident commander. Payment decisions belong to executive leadership and legal counsel.

## Owner

Network security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Volumetric attack](Volumetric%20attack.md)
- [Ransom note discovered](../Ransomware/Ransom%20note%20discovered.md)
