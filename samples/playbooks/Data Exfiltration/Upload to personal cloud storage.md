---
dummy: true
id: PB-EXF-001
category: Data Exfiltration
severity: High
attack:
  tactics: [TA0010]
  techniques: [T1567.002]
owner: Data protection lead
last_review: 2026-11-20
---

# Upload to personal cloud storage

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Corporate data uploaded to a personal cloud storage account.

| Field | Value |
| --- | --- |
| ID | PB-EXF-001 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Exfiltration](https://attack.mitre.org/tactics/TA0010/) (TA0010) | [T1567.002 Exfiltration Over Web Service: Exfiltration to Cloud Storage](https://attack.mitre.org/techniques/T1567/002/) |

## Detection

- Data loss prevention alert for an upload to an unsanctioned storage service.
- Proxy logs show large uploads to a consumer storage domain.

## Triage

1. Identify the files, their classification and the destination account.
2. Determine whether the user is the account owner or the device is compromised.
3. If the user is leaving the organization, also apply [Departing employee data collection](../Insider%20Threat/Departing%20employee%20data%20collection.md).

## Containment

1. Block the destination service for the user.
2. Ask the user's manager and HR before contacting the user if insider activity is suspected.

## Eradication

- Request deletion from the external account and written confirmation.

## Recovery

- Record the data involved for the privacy assessment.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Personal or regulated data was uploaded.

## Owner

Data protection lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Departing employee data collection](../Insider%20Threat/Departing%20employee%20data%20collection.md)
- [Large outbound transfer](Large%20outbound%20transfer.md)
