---
dummy: true
id: PB-INS-004
category: Insider Threat
severity: Critical
attack:
  tactics: [TA0040]
  techniques: [T1485, T1489, T1531]
owner: Insider risk lead
last_review: 2026-11-20
---

# Sabotage by privileged user

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An administrator deliberately deletes data, stops services or locks out other administrators.

| Field | Value |
| --- | --- |
| ID | PB-INS-004 |
| Severity | Critical ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1485 Data Destruction](https://attack.mitre.org/techniques/T1485/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1489 Service Stop](https://attack.mitre.org/techniques/T1489/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1531 Account Access Removal](https://attack.mitre.org/techniques/T1531/) |

## Detection

- Mass deletion of virtual machines, databases or backups by one administrator.
- Other administrators removed from privileged groups.

## Triage

1. Confirm the actions are not part of an approved change.
2. Identify all systems the administrator can still reach.

## Containment

1. Disable the account immediately using break-glass credentials if necessary.
2. Revoke all sessions and rotate shared administrative secrets.

## Eradication

- Audit for scheduled jobs or logic bombs left behind.

## Recovery

- Restore deleted resources from backup and restore other administrators' access.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always.

## Owner

Insider risk lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Privileged account misuse](../Account%20Compromise/Privileged%20account%20misuse.md)
- [Backup deletion attempt](../Ransomware/Backup%20deletion%20attempt.md)
