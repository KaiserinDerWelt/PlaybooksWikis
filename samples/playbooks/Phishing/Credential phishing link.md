---
dummy: true
id: PB-PHI-001
category: Phishing
severity: High
attack:
  tactics: [TA0001, TA0002]
  techniques: [T1566.002, T1204.001, T1078]
owner: Email security lead
last_review: 2026-11-20
---

# Credential phishing link

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A user received an email linking to a page that imitates the corporate sign-in portal, and may have entered their credentials.

| Field | Value |
| --- | --- |
| ID | PB-PHI-001 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1566.002 Phishing: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/) |
| [Execution](https://attack.mitre.org/tactics/TA0002/) (TA0002) | [T1204.001 User Execution: Malicious Link](https://attack.mitre.org/techniques/T1204/001/) |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1078 Valid Accounts](https://attack.mitre.org/techniques/T1078/) |

## Detection

- Email gateway alert for a link to a newly registered or look-alike domain.
- User report through the *Report phishing* button.
- Identity provider sign-in from an unfamiliar location shortly after the email was delivered.

## Triage

1. Retrieve the message and record sender, subject, delivery time and the defanged URL (for example `hxxps://login-portal-verify[.]example/session`).
2. Identify every recipient of the same campaign by sender, subject and URL.
3. Check proxy logs for which recipients opened the link.
4. For each user who opened it, review sign-ins in the following 24 hours. A successful sign-in from a new device or location means the account is compromised.

## Containment

1. Purge the message from all mailboxes.
2. Block the domain and URL on the email gateway and web proxy.
3. For users who entered credentials: reset the password, revoke all sessions and refresh tokens, and require MFA re-registration.

## Eradication

- Remove any MFA methods or devices registered by the attacker.
- Check for inbox rules created after the click; see [Mailbox rule review](../Account%20Compromise/Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md).

## Recovery

- Confirm that the user can sign in with the new credentials and MFA method.
- Monitor the account for 14 days for sign-ins from the attacker's infrastructure.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Any privileged account entered credentials.
- More than 10 users entered credentials.
- Mailbox data was accessed by the attacker.

## Owner

Email security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Impossible travel sign-in](../Account%20Compromise/Impossible%20travel%20sign-in.md)
- [Mailbox rule review](../Account%20Compromise/Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md)
- [Session token theft](../Account%20Compromise/Session%20token%20theft.md)
