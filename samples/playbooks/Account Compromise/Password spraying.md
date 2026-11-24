---
dummy: true
id: PB-ACC-003
category: Account Compromise
severity: Medium
attack:
  tactics: [TA0006]
  techniques: [T1110.003]
owner: Identity security lead
last_review: 2026-11-20
---

# Password spraying

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

One or a few common passwords tried against many accounts, slowly enough to avoid lockout.

| Field | Value |
| --- | --- |
| ID | PB-ACC-003 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1110.003 Brute Force: Password Spraying](https://attack.mitre.org/techniques/T1110/003/) |

## Detection

- Identity provider alert for failed sign-ins across many accounts from one IP address or range.
- Failed sign-ins for accounts that do not exist.

## Triage

1. List every account with a failed attempt from the source.
2. Identify any successful sign-in from the same source; those accounts are compromised.

## Containment

1. Block the source addresses at the identity provider.
2. Reset passwords and revoke sessions for any account that signed in successfully.

## Eradication

- Check the compromised accounts as described in [Impossible travel sign-in](Impossible%20travel%20sign-in.md).

## Recovery

- Add the attempted passwords to the banned-password list.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Any spray succeeded against a privileged account.

## Owner

Identity security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Impossible travel sign-in](Impossible%20travel%20sign-in.md)
