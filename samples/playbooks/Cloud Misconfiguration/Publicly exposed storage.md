---
dummy: true
id: PB-CLD-001
category: Cloud Misconfiguration
severity: High
attack:
  tactics: [TA0009]
  techniques: [T1530]
owner: Cloud security lead
last_review: 2026-11-20
---

# Publicly exposed storage

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A cloud storage container or bucket allows anonymous read or list access.

| Field | Value |
| --- | --- |
| ID | PB-CLD-001 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1530 Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/) |

## Detection

- Cloud security posture alert for public access on a storage account.
- External report from a researcher.

## Triage

1. Identify the data stored and its classification.
2. Review storage access logs for anonymous reads since public access was enabled.

## Containment

1. Disable anonymous access.

## Eradication

- Find the deployment template or change that enabled public access and correct it.

## Recovery

- Apply a policy that denies public access at the subscription or account level.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Anonymous reads of sensitive data are found in the logs.

## Owner

Cloud security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Leaked access key](Leaked%20access%20key.md)
- [Bulk download from document repository](../Data%20Exfiltration/Bulk%20download%20from%20document%20repository.md)
