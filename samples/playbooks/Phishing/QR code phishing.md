---
dummy: true
id: PB-PHI-005
category: Phishing
severity: Medium
attack:
  tactics: [TA0001, TA0002]
  techniques: [T1566.001, T1204.001]
owner: Email security lead
last_review: 2026-11-20
---

# QR code phishing

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

An email contains a QR code that leads to a credential-harvesting page. The user typically scans it with a personal phone, outside corporate web filtering.

| Field | Value |
| --- | --- |
| ID | PB-PHI-005 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1566.001 Phishing: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/) |
| [Execution](https://attack.mitre.org/tactics/TA0002/) (TA0002) | [T1204.001 User Execution: Malicious Link](https://attack.mitre.org/techniques/T1204/001/) |

## Detection

- Email gateway image analysis flags a QR code in an image or PDF attachment.
- User report of an email asking to scan a code to *re-validate MFA*.

## Triage

1. Decode the QR code in the analysis sandbox and record the defanged URL.
2. Identify all recipients of the campaign.
3. Ask recipients whether they scanned the code; proxy logs will not show phone traffic.
4. Review sign-ins for recipients who scanned it.

## Containment

1. Purge the message and block the decoded domain.
2. For users who entered credentials, follow the containment steps in [Credential phishing link](Credential%20phishing%20link.md).

## Eradication

- Remove any MFA methods the attacker registered.

## Recovery

- Send a short awareness note to recipients explaining the technique.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Credentials were entered by more than 5 users.

## Owner

Email security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Credential phishing link](Credential%20phishing%20link.md)
- [MFA fatigue](../Account%20Compromise/MFA%20fatigue.md)
