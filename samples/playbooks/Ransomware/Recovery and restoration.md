---
dummy: true
id: PB-RAN-005
category: Ransomware
severity: High
attack:
  tactics: [TA0040]
  techniques: [T1486]
owner: Ransomware response lead
last_review: 2026-11-20
---

# Recovery and restoration

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Restores systems after ransomware has been contained and eradicated. This playbook covers recovery only and starts after containment is confirmed.

| Field | Value |
| --- | --- |
| ID | PB-RAN-005 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1486 Data Encrypted for Impact](https://attack.mitre.org/techniques/T1486/) |

## When to use

- Containment is confirmed: no new encryption for at least 24 hours.
- The initial access vector is identified and closed.

## Restore order

1. Identity infrastructure (directory services, identity provider connectors).
2. Network services (DNS, DHCP, internal certificate authority).
3. Business-critical applications, in the order set by the business continuity plan.
4. File shares and user workstations.

## Validation before reconnecting

- Restore from backups taken before the earliest attacker activity, not just before encryption.
- Run a full EDR scan on each restored system.
- Reset all credentials that existed on affected systems, including service accounts.

## Owner

Ransomware response lead, SOC level 2. Last reviewed 2026-11-20.
