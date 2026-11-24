---
dummy: true
id: PB-RAN-003
category: Ransomware
severity: High
attack:
  tactics: [TA0040]
  techniques: [T1490, T1485]
owner: Ransomware response lead
last_review: 2026-11-20
---

# Backup deletion attempt

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Someone is deleting shadow copies, backup catalogues or snapshots. This commonly precedes encryption by minutes to hours.

| Field | Value |
| --- | --- |
| ID | PB-RAN-003 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1490 Inhibit System Recovery](https://attack.mitre.org/techniques/T1490/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1485 Data Destruction](https://attack.mitre.org/techniques/T1485/) |

## Detection

- EDR alert for shadow copy deletion or for disabling the system recovery environment.
- Backup platform alert for deleted restore points or a changed retention policy.

## Triage

1. Identify the account and host that issued the deletion.
2. Check whether the account is a backup administrator acting under an approved change.
3. Look for the precursors in [Pre-encryption indicators](Pre-encryption%20indicators.md).

## Containment

1. Disable the account if the action is not covered by an approved change.
2. Isolate the source host.
3. Enable immutability or legal hold on the remaining backups.

## Eradication

- Rotate the credentials of all backup administrators.

## Recovery

- Verify that a clean, restorable backup exists for every critical system.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Backups were deleted and the source is not an approved change.

## Owner

Ransomware response lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Pre-encryption indicators](Pre-encryption%20indicators.md)
- [Initial containment (Contención inicial)](Contenci%C3%B3n%20inicial.md)
