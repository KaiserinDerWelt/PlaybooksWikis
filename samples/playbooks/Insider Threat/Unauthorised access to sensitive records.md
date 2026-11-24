---
dummy: true
id: PB-INS-002
category: Insider Threat
severity: High
attack:
  tactics: [TA0001]
  techniques: [T1078]
owner: Insider risk lead
last_review: 2026-11-20
---

# Unauthorised access to sensitive records

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An employee looks up records they have no business reason to access, such as colleague, customer or patient records.

| Field | Value |
| --- | --- |
| ID | PB-INS-002 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1078 Valid Accounts](https://attack.mitre.org/techniques/T1078/) |

## Detection

- Application audit alert for access to records of a VIP or of colleagues.
- Searches by name rather than by case or ticket number.

## Triage

1. Confirm with the employee's manager whether a business reason exists, without revealing the investigation.
2. Export the access log for the period.

## Containment

1. With HR approval, restrict the employee's access to the application.

## Eradication

- Not applicable; this is an HR and privacy matter once confirmed.

## Recovery

- The privacy officer assesses whether data subjects must be notified.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always to the privacy officer and HR.

## Owner

Insider risk lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Bulk download from document repository](../Data%20Exfiltration/Bulk%20download%20from%20document%20repository.md)
- [Departing employee data collection](Departing%20employee%20data%20collection.md)
