---
dummy: true
id: PB-PHI-004
category: Phishing
severity: Low
attack:
  tactics: [TA0001]
  techniques: [T1566]
owner: Email security lead
last_review: 2026-11-20
---

# Reported suspicious email (quick card)

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Quick-reference card for the first response to a user-reported email. Use the full playbooks once maliciousness is confirmed.

| Field | Value |
| --- | --- |
| ID | PB-PHI-004 |
| Severity | Low ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1566 Phishing](https://attack.mitre.org/techniques/T1566/) |

## Quick checks

- Does the sender domain match the display name?
- Do links point to a domain other than the one shown?
- Was the message sent to many recipients at once?
- Did the email gateway already flag the message?

## If the email is malicious

- Link to a sign-in page: [Credential phishing link](Credential%20phishing%20link.md).
- Attachment: [Malicious attachment](Malicious%20attachment.md).
- Payment or data request: [Business email compromise](Business%20Email%20Compromise%20%28BEC%29.md).
- QR code: [QR code phishing](QR%20code%20phishing.md).

## If the email is benign

- Reply to the reporter with the outcome and thank them.
- Close the ticket as *False positive – user report*.

## Owner

Email security lead, SOC level 2. Last reviewed 2026-11-20.
