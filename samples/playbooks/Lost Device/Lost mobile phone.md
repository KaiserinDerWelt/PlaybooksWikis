---
dummy: true
id: PB-DEV-002
category: Lost Device
severity: Medium
attack:
  tactics: [TA0001, TA0006]
  techniques: [T1078, T1111]
owner: Endpoint security lead
last_review: 2026-11-20
---

# Lost mobile phone

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A phone with corporate email or an authenticator app is lost or stolen.

| Field | Value |
| --- | --- |
| ID | PB-DEV-002 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1078 Valid Accounts](https://attack.mitre.org/techniques/T1078/) |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1111 Multi-Factor Authentication Interception](https://attack.mitre.org/techniques/T1111/) |

## Detection

- User report to the service desk.

## Triage

1. Check whether the phone is enrolled in device management and protected by a passcode.
2. Identify whether it holds the user's only MFA method.

## Containment

1. Issue a selective wipe of corporate data.
2. Remove the phone as an MFA method and issue a temporary access pass.

## Eradication

- Not applicable.

## Recovery

- Register MFA on the replacement phone.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The phone was unenrolled or had no passcode.

## Owner

Endpoint security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Lost laptop](Lost%20laptop.md)
- [MFA fatigue](../Account%20Compromise/MFA%20fatigue.md)
