---
dummy: true
id: PB-INS-003
category: Insider Threat
severity: Medium
attack:
  tactics: [TA0010, TA0009]
  techniques: [T1052.001, T1005]
owner: Insider risk lead
last_review: 2026-11-20
---

# Removable media misuse

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Data copied to USB storage in breach of the removable media policy.

| Field | Value |
| --- | --- |
| ID | PB-INS-003 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Exfiltration](https://attack.mitre.org/tactics/TA0010/) (TA0010) | [T1052.001 Exfiltration Over Physical Medium: Exfiltration over USB](https://attack.mitre.org/techniques/T1052/001/) |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1005 Data from Local System](https://attack.mitre.org/techniques/T1005/) |

## Detection

- Device control alert for a write to an unapproved USB device.
- Large write volume to removable media.

## Triage

1. Identify the device serial number, files copied and their classification.
2. Check whether an exception to the policy exists for the user.

## Containment

1. Block the device serial number.

## Eradication

- Ask the manager to retrieve the device if company data was copied.

## Recovery

- Remind the user of the policy; repeated cases go to HR.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Restricted data was copied.

## Owner

Insider risk lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Departing employee data collection](Departing%20employee%20data%20collection.md)
- [Lost removable media (quick card)](../Lost%20Device/Lost%20removable%20media.md)
