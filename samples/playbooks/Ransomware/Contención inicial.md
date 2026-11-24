---
dummy: true
id: PB-RAN-001
category: Ransomware
severity: Critical
attack:
  tactics: [TA0040]
  techniques: [T1486, T1490]
owner: Ransomware response lead
last_review: 2026-11-20
---

# Initial containment (Contención inicial)

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

First actions in the opening hour of a suspected ransomware incident. The goal is to stop the spread before scoping is complete. (Contención inicial: the first containment step.)

| Field | Value |
| --- | --- |
| ID | PB-RAN-001 |
| Severity | Critical ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1486 Data Encrypted for Impact](https://attack.mitre.org/techniques/T1486/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1490 Inhibit System Recovery](https://attack.mitre.org/techniques/T1490/) |

## Detection

- EDR ransomware behaviour alert, or a user reports files with an unfamiliar extension.
- Multiple hosts raising alerts within minutes of each other.

## Triage

1. Do not spend more than 15 minutes on triage before containing.
2. Identify the first affected host and the account under which encryption is running.

## Containment

1. Isolate every affected host through EDR network containment. Do not power hosts off; memory evidence is lost.
2. Disable the account running the encryption process.
3. Block SMB between workstation segments at the internal firewall.
4. Suspend scheduled backup jobs so that encrypted data does not overwrite good copies.

## Eradication

- Hand over to [Mass file encryption on file share](Mass%20file%20encryption%20on%20file%20share.md) or [Ransom note discovered](Ransom%20note%20discovered.md) once spread has stopped.

## Recovery

- Recovery follows [Recovery and restoration](Recovery%20and%20restoration.md).

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always: ransomware is a Critical incident. Notify the incident commander immediately.

## Owner

Ransomware response lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Ransom note discovered](Ransom%20note%20discovered.md)
- [Mass file encryption on file share](Mass%20file%20encryption%20on%20file%20share.md)
- [Recovery and restoration](Recovery%20and%20restoration.md)
