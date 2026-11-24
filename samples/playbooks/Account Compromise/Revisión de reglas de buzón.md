---
dummy: true
id: PB-ACC-004
category: Account Compromise
severity: High
attack:
  tactics: [TA0009, TA0005]
  techniques: [T1114.003, T1564.008]
owner: Identity security lead
last_review: 2026-11-20
---

# Mailbox rule review

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

After an account compromise, attackers create inbox rules that forward mail externally or hide replies from the user. This playbook finds and removes them.

| Field | Value |
| --- | --- |
| ID | PB-ACC-004 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Collection](https://attack.mitre.org/tactics/TA0009/) (TA0009) | [T1114.003 Email Collection: Email Forwarding Rule](https://attack.mitre.org/techniques/T1114/003/) |
| [Defense Evasion](https://attack.mitre.org/tactics/TA0005/) (TA0005) | [T1564.008 Hide Artifacts: Email Hiding Rules](https://attack.mitre.org/techniques/T1564/008/) |

## Detection

- Alert for a new forwarding rule to an external domain.
- Rule that moves messages containing words such as *invoice*, *payment* or *password* to an obscure folder or deletes them.

## Triage

1. Export all inbox rules and mailbox forwarding settings for the account.
2. Compare creation times with the suspected compromise window.
3. Identify any mail that was forwarded or hidden.

## Containment

1. Disable and record the malicious rules before deleting them.
2. Remove mailbox-level forwarding to external addresses.

## Eradication

- Search other mailboxes for rules with the same name or destination.

## Recovery

- Restore hidden messages to the inbox and inform the user.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Forwarded mail contained personal or regulated data.

## Owner

Identity security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Business email compromise](../Phishing/Business%20Email%20Compromise%20%28BEC%29.md)
- [Impossible travel sign-in](Impossible%20travel%20sign-in.md)
