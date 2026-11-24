---
dummy: true
id: PB-DEV-004
category: Lost Device
severity: Medium
attack:
  tactics: [TA0009]
  techniques: [T1025]
owner: Endpoint security lead
last_review: 2026-11-20
---

# Lost removable media (quick card)

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Quick-reference card for lost USB drives or external disks containing company data.

| Field | Value |
| --- | --- |
| ID | PB-DEV-004 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1025 Data from Removable Media](https://attack.mitre.org/techniques/T1025/) |

## Questions for the user

- What data was on the device, and how sensitive is it?
- Was the device encrypted with an approved tool?
- When and where was it last seen?

## Decision

- Encrypted with an approved tool: record the loss and close.
- Unencrypted with personal or restricted data: escalate to the privacy officer.

## Follow-up

- Review whether the user needs removable media; see [Removable media misuse](../Insider%20Threat/Removable%20media%20misuse.md).

## Owner

Endpoint security lead, SOC level 2. Last reviewed 2026-11-20.
