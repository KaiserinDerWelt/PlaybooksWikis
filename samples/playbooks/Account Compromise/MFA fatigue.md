---
dummy: true
id: PB-ACC-002
category: Account Compromise
severity: High
attack:
  tactics: [TA0006]
  techniques: [T1621]
owner: Identity security lead
last_review: 2026-11-20
---

# MFA fatigue

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A user receives repeated MFA push requests they did not initiate. The attacker already holds the password and hopes the user will approve one prompt.

| Field | Value |
| --- | --- |
| ID | PB-ACC-002 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1621 Multi-Factor Authentication Request Generation](https://attack.mitre.org/techniques/T1621/) |

## Detection

- User reports MFA prompts they did not trigger.
- Identity provider logs show multiple denied or timed-out MFA requests followed by an approval.

## Triage

1. Ask the user whether they approved any prompt.
2. Review sign-in logs for the source IP address and the application targeted.
3. Treat the password as compromised regardless of the answer.

## Containment

1. Reset the password and revoke sessions.
2. If a prompt was approved, follow [Session token theft](Session%20token%20theft.md) as well.
3. Block the source IP address at the identity provider.

## Eradication

- Remove any MFA method registered after the first unsolicited prompt.

## Recovery

- Move the user to number matching or a phishing-resistant MFA method.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- A prompt was approved.

## Owner

Identity security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Session token theft](Session%20token%20theft.md)
- [QR code phishing](../Phishing/QR%20code%20phishing.md)
