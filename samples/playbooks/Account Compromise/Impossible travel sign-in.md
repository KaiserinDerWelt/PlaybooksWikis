---
dummy: true
id: PB-ACC-001
category: Account Compromise
severity: Medium
attack:
  tactics: [TA0001]
  techniques: [T1078.004]
owner: Identity security lead
last_review: 2026-11-20
---

# Impossible travel sign-in

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Two successful sign-ins for one account from locations too far apart to travel between in the time elapsed.

| Field | Value |
| --- | --- |
| ID | PB-ACC-001 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1078.004 Valid Accounts: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/) |

## Detection

- Identity provider risk detection for impossible or atypical travel.

## Triage

1. Check whether either location belongs to a corporate VPN egress point or a known proxy.
2. Contact the user through a channel other than email to confirm their location.
3. Review the device, browser and application for each sign-in.

## Containment

1. If the user does not recognise a sign-in: revoke sessions, reset the password and require MFA re-registration.

## Eradication

- Check for mailbox rules and new MFA methods; see [Mailbox rule review](Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md).

## Recovery

- Close as benign if the user confirms both sign-ins, and add a note for future triage.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The account is privileged or the user cannot be reached within 1 hour.

## Owner

Identity security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Mailbox rule review](Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md)
- [Session token theft](Session%20token%20theft.md)
