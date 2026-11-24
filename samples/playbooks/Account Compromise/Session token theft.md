---
dummy: true
id: PB-ACC-005
category: Account Compromise
severity: High
attack:
  tactics: [TA0006, TA0008]
  techniques: [T1539, T1557, T1550.001]
owner: Identity security lead
last_review: 2026-11-20
---

# Session token theft

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An attacker steals a session cookie or token, usually through an adversary-in-the-middle phishing kit, and replays it to bypass MFA.

| Field | Value |
| --- | --- |
| ID | PB-ACC-005 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1539 Steal Web Session Cookie](https://attack.mitre.org/techniques/T1539/) |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1557 Adversary-in-the-Middle](https://attack.mitre.org/techniques/T1557/) |
| [Lateral Movement](https://attack.mitre.org/tactics/TA0008/) (TA0008) | [T1550.001 Use Alternate Authentication Material: Application Access Token](https://attack.mitre.org/techniques/T1550/001/) |

## Detection

- Sign-in with a valid token from an IP address and device that never completed MFA.
- Same session ID used from two distant locations.

## Triage

1. Find the original phishing email or infostealer infection that exposed the token.
2. List the applications accessed with the stolen session.

## Containment

1. Revoke all sessions and refresh tokens for the account. A password reset alone does not invalidate stolen tokens.
2. Block the replaying IP address.

## Eradication

- If an infostealer was involved, follow [Infostealer](../Malware/Infostealer.md).

## Recovery

- Enforce token protection or device-bound sessions where supported.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Data was downloaded with the stolen session.

## Owner

Identity security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Credential phishing link](../Phishing/Credential%20phishing%20link.md)
- [Infostealer](../Malware/Infostealer.md)
- [MFA fatigue](MFA%20fatigue.md)
