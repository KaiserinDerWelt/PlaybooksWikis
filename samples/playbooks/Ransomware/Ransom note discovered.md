---
dummy: true
id: PB-RAN-002
category: Ransomware
severity: Critical
attack:
  tactics: [TA0040]
  techniques: [T1486, T1657]
owner: Ransomware response lead
last_review: 2026-11-20
---

# Ransom note discovered

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A ransom note has been found on one or more systems. Encryption may be complete, ongoing or staged.

| Field | Value |
| --- | --- |
| ID | PB-RAN-002 |
| Severity | Critical ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1486 Data Encrypted for Impact](https://attack.mitre.org/techniques/T1486/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1657 Financial Theft](https://attack.mitre.org/techniques/T1657/) |

## Detection

- A text or HTML file with payment instructions appears in multiple folders.
- Desktop wallpaper changed to a ransom message.

## Triage

1. Photograph the note; do not open links or contact the actor.
2. Record the group name and any victim ID shown. Check threat intelligence for known decryptors.
3. Determine whether files are encrypted or the note was dropped without encryption (an extortion-only bluff).

## Containment

1. Apply [Initial containment](Contenci%C3%B3n%20inicial.md) if not already done.
2. Preserve one encrypted file and the note for analysis.

## Eradication

- Identify the initial access vector before rebuilding; restoring without closing it invites re-infection.

## Recovery

- Follow [Recovery and restoration](Recovery%20and%20restoration.md).

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always. Any decision about contact with the actor or payment belongs to executive leadership and legal counsel, never to the SOC.

## Owner

Ransomware response lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Initial containment (Contención inicial)](Contenci%C3%B3n%20inicial.md)
- [Recovery and restoration](Recovery%20and%20restoration.md)
