---
dummy: true
id: PB-RAN-006
category: Ransomware
severity: High
attack:
  tactics: [TA0005, TA0006, TA0008]
  techniques: [T1562.001, T1003.001, T1021.001]
owner: Ransomware response lead
last_review: 2026-11-20
---

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Activity commonly observed hours or days before ransomware deployment. Acting at this stage can prevent encryption entirely.

| Field | Value |
| --- | --- |
| ID | PB-RAN-006 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Defense Evasion](https://attack.mitre.org/tactics/TA0005/) (TA0005) | [T1562.001 Impair Defenses: Disable or Modify Tools](https://attack.mitre.org/techniques/T1562/001/) |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1003.001 OS Credential Dumping: LSASS Memory](https://attack.mitre.org/techniques/T1003/001/) |
| [Lateral Movement](https://attack.mitre.org/tactics/TA0008/) (TA0008) | [T1021.001 Remote Services: Remote Desktop Protocol](https://attack.mitre.org/techniques/T1021/001/) |

## Detection

- Security tooling disabled or uninstalled on one or more hosts.
- Credential dumping from LSASS memory.
- Remote desktop sessions from a server to many workstations.
- Remote administration tools installed outside the software catalogue.

## Triage

1. Correlate the alerts by account and time; two or more indicators on related hosts warrant escalation.
2. Identify the account used for lateral movement.

## Containment

1. Disable the lateral-movement account and isolate the affected hosts.
2. Re-enable security tooling and block tampering through EDR policy.

## Eradication

- Reset credentials for every account that signed in to the affected hosts.

## Recovery

- Monitor the affected segment closely for 7 days.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Two or more indicators are confirmed.

## Owner

Ransomware response lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Backup deletion attempt](Backup%20deletion%20attempt.md)
- [Initial containment (Contención inicial)](Contenci%C3%B3n%20inicial.md)
- [Privileged account misuse](../Account%20Compromise/Privileged%20account%20misuse.md)
