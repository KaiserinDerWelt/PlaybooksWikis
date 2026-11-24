---
dummy: true
id: PB-INS-001
category: Insider Threat
severity: High
attack:
  tactics: [TA0009, TA0010]
  techniques: [T1213, T1052.001]
owner: Insider risk lead
last_review: 2026-11-20
---

# Departing employee data collection

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An employee who has resigned or been given notice collects company data beyond their normal need.

| Field | Value |
| --- | --- |
| ID | PB-INS-001 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1213 Data from Information Repositories](https://attack.mitre.org/techniques/T1213/) |
| [Exfiltration](https://attack.mitre.org/tactics/TA0010/) (TA0010) | [T1052.001 Exfiltration Over Physical Medium: Exfiltration over USB](https://attack.mitre.org/techniques/T1052/001/) |

## Detection

- HR leaver feed combined with a spike in downloads, prints or USB writes.
- Access to repositories outside the employee's team in the notice period.

## Triage

1. Work with HR and legal from the start. Do not contact the employee.
2. Compare activity in the notice period with the previous 90 days.
3. List data classifications involved.

## Containment

1. With HR approval, restrict USB writes and personal cloud uploads for the account.

## Eradication

- HR and legal decide on recovery of data and any formal action.

## Recovery

- Confirm the account is disabled on the last working day.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always to the insider risk lead and HR. Keep the case on a need-to-know basis.

## Owner

Insider risk lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Upload to personal cloud storage](../Data%20Exfiltration/Upload%20to%20personal%20cloud%20storage.md)
- [Removable media misuse](Removable%20media%20misuse.md)
