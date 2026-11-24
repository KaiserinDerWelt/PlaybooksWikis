---
dummy: true
id: PB-EXF-005
category: Data Exfiltration
severity: High
attack:
  tactics: [TA0009]
  techniques: [T1213.002, T1530]
owner: Data protection lead
last_review: 2026-11-20
---

# Bulk download from document repository

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An account downloads or syncs an unusually large number of documents from a collaboration site or document library.

| Field | Value |
| --- | --- |
| ID | PB-EXF-005 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1213.002 Data from Information Repositories: Sharepoint](https://attack.mitre.org/techniques/T1213/002/) |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1530 Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/) |

## Detection

- Alert for mass download or sync from a document library.
- Access to sites the account has never used before.

## Triage

1. Determine whether the account is compromised or used by its owner.
2. List the sites and the classification of the downloaded documents.

## Containment

1. Revoke the account's sessions and block sync from unmanaged devices.

## Eradication

- If the account was compromised, follow the account compromise playbooks.

## Recovery

- Review site permissions that allowed broad access.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Restricted documents were downloaded.

## Owner

Data protection lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Unauthorised access to sensitive records](../Insider%20Threat/Unauthorised%20access%20to%20sensitive%20records.md)
- [Upload to personal cloud storage](Upload%20to%20personal%20cloud%20storage.md)
