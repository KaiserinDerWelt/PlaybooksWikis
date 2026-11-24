---
dummy: true
id: PB-EXF-002
category: Data Exfiltration
severity: High
attack:
  tactics: [TA0010]
  techniques: [T1048, T1041]
owner: Data protection lead
last_review: 2026-11-20
---

# Large outbound transfer

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An unusually large volume of data leaves the network from one host or account.

| Field | Value |
| --- | --- |
| ID | PB-EXF-002 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Exfiltration](https://attack.mitre.org/tactics/TA0010/) (TA0010) | [T1048 Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/) |
| [Exfiltration](https://attack.mitre.org/tactics/TA0010/) (TA0010) | [T1041 Exfiltration Over C2 Channel](https://attack.mitre.org/techniques/T1041/) |

## Detection

- Network baseline alert for outbound volume several times above the host's normal level.
- Transfer to a destination never seen before, outside business hours.

## Triage

1. Identify the process, protocol and destination.
2. Rule out approved activity: backups, software updates, data sharing with partners.
3. Check for staging beforehand; see [Staged archive creation](Staged%20archive%20creation.md).

## Containment

1. Block the destination and isolate the host if the transfer is unexplained.

## Eradication

- Find how the attacker reached the host and close that path.

## Recovery

- Estimate what was sent from file access logs and transfer size.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The transfer is unexplained and exceeds 1 GB.

## Owner

Data protection lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Staged archive creation](Staged%20archive%20creation.md)
- [Command and control beaconing](../Malware/Command%20and%20control%20beaconing.md)
