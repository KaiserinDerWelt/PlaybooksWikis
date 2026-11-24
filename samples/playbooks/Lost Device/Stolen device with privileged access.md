---
dummy: true
id: PB-DEV-003
category: Lost Device
severity: High
attack:
  tactics: [TA0004, TA0009]
  techniques: [T1078.002, T1005]
owner: Endpoint security lead
last_review: 2026-11-20
---

# Stolen device with privileged access

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A device used for administration, such as a privileged access workstation, is stolen.

| Field | Value |
| --- | --- |
| ID | PB-DEV-003 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Privilege Escalation](https://attack.mitre.org/tactics/TA0004/) (TA0004) | [T1078.002 Valid Accounts: Domain Accounts](https://attack.mitre.org/techniques/T1078/002/) |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1005 Data from Local System](https://attack.mitre.org/techniques/T1005/) |

## Detection

- Report from the administrator or physical security.

## Triage

1. List the privileged accounts and cached credentials on the device.

## Containment

1. Wipe the device and revoke its certificates.
2. Reset every privileged credential used on the device, including service account secrets it could read.

## Eradication

- Review privileged activity since the time of loss.

## Recovery

- Issue a replacement through the privileged workstation build process.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always.

## Owner

Endpoint security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Lost laptop](Lost%20laptop.md)
- [Privileged account misuse](../Account%20Compromise/Privileged%20account%20misuse.md)
