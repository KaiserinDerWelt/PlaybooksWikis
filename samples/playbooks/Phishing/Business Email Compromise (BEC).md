---
dummy: true
id: PB-PHI-003
category: Phishing
severity: High
attack:
  tactics: [TA0005, TA0008, TA0009, TA0040]
  techniques: [T1656, T1534, T1114.003, T1657]
owner: Email security lead
last_review: 2026-11-20
---

# Business email compromise

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An attacker impersonates an executive or supplier, often from a compromised mailbox, to redirect a payment or obtain sensitive data.

| Field | Value |
| --- | --- |
| ID | PB-PHI-003 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Defense Evasion](https://attack.mitre.org/tactics/TA0005/) (TA0005) | [T1656 Impersonation](https://attack.mitre.org/techniques/T1656/) |
| [Lateral Movement](https://attack.mitre.org/tactics/TA0008/) (TA0008) | [T1534 Internal Spearphishing](https://attack.mitre.org/techniques/T1534/) |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1114.003 Email Collection: Email Forwarding Rule](https://attack.mitre.org/techniques/T1114/003/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1657 Financial Theft](https://attack.mitre.org/techniques/T1657/) |

## Detection

- Finance reports a request to change a supplier's bank details.
- Email from an internal executive sent from an unusual location or with a new reply-to address.
- Forwarding rule to an external address created on a finance or executive mailbox.

## Triage

1. Determine whether the sending mailbox is internal and compromised, or an external look-alike domain.
2. Ask finance whether any payment was made and, if so, the amount, date and destination bank.
3. Identify all recipients of messages from the attacker in the last 30 days.

## Containment

1. If a payment was made, ask finance to contact the bank immediately to request a recall. Time is the deciding factor.
2. If the mailbox is internal: reset credentials, revoke sessions and remove forwarding and hiding rules.
3. Block the look-alike domain on the email gateway.

## Eradication

- Review [Mailbox rule review](../Account%20Compromise/Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md) for every mailbox the attacker accessed.
- Search for internal phishing sent from the compromised mailbox and purge it.

## Recovery

- Confirm supplier bank details through a known contact, not through the email thread.
- Notify recipients of internal phishing that the messages were malicious.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Any payment left the organization.
- An executive mailbox was compromised.

## Owner

Email security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Mailbox rule review](../Account%20Compromise/Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md)
- [Credential phishing link](Credential%20phishing%20link.md)
