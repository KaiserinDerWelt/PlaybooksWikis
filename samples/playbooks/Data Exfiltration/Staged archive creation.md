---
dummy: true
id: PB-EXF-003
category: Data Exfiltration
severity: Medium
attack:
  tactics: [TA0009]
  techniques: [T1560.001, T1074.001]
owner: Data protection lead
last_review: 2026-11-20
---

# Staged archive creation

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Large, often password-protected archives created in temporary or unusual folders: a common step before exfiltration.

| Field | Value |
| --- | --- |
| ID | PB-EXF-003 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1560.001 Archive Collected Data: Archive via Utility](https://attack.mitre.org/techniques/T1560/001/) |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1074.001 Data Staged: Local Data Staging](https://attack.mitre.org/techniques/T1074/001/) |

## Detection

- EDR alert for an archiving utility run with encryption options.
- Large archive files appearing in temporary, recycle bin or public folders.

## Triage

1. List the source folders included in the archive.
2. Identify the account and whether the activity matches the user's role.

## Containment

1. Quarantine the archive and isolate the host if activity is unexplained.

## Eradication

- Determine whether the archive left the network; if so, continue with [Large outbound transfer](Large%20outbound%20transfer.md).

## Recovery

- Delete the archive after evidence is preserved.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The archive contains sensitive data and its transfer cannot be ruled out.

## Owner

Data protection lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Large outbound transfer](Large%20outbound%20transfer.md)
- [Departing employee data collection](../Insider%20Threat/Departing%20employee%20data%20collection.md)
