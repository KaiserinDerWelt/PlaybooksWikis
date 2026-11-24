---
dummy: true
id: PB-DEV-001
category: Lost Device
severity: Medium
attack:
  tactics: [TA0009, TA0001]
  techniques: [T1005, T1078]
owner: Endpoint security lead
last_review: 2026-11-20
---

# Lost laptop

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A corporate laptop is reported lost or stolen.

| Field | Value |
| --- | --- |
| ID | PB-DEV-001 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1005 Data from Local System](https://attack.mitre.org/techniques/T1005/) |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1078 Valid Accounts](https://attack.mitre.org/techniques/T1078/) |

## Detection

- User or manager report to the service desk.

## Triage

1. Confirm disk encryption status in device management.
2. Record last check-in time and location if available.
3. Determine whether the user stored data locally outside synced folders.

## Containment

1. Issue a remote lock and, if the device is not recovered within 24 hours, a remote wipe.
2. Revoke the device's certificates and sessions.

## Eradication

- Remove the device from device management after the wipe is confirmed.

## Recovery

- Issue a replacement device.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The disk was not encrypted.

## Owner

Endpoint security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Stolen device with privileged access](Stolen%20device%20with%20privileged%20access.md)
- [Lost mobile phone](Lost%20mobile%20phone.md)
