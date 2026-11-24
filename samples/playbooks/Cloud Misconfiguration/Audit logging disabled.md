---
dummy: true
id: PB-CLD-004
category: Cloud Misconfiguration
severity: High
attack:
  tactics: [TA0005]
  techniques: [T1562.008]
owner: Cloud security lead
last_review: 2026-11-20
---

# Audit logging disabled

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Diagnostic settings, audit logs or log export are disabled or redirected. Attackers do this to hide later activity.

| Field | Value |
| --- | --- |
| ID | PB-CLD-004 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Defense Evasion](https://attack.mitre.org/tactics/TA0005/) (TA0005) | [T1562.008 Impair Defenses: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/) |

## Detection

- Alert on deletion or change of a diagnostic setting.
- Gap in log ingestion from a subscription.

## Triage

1. Identify who made the change and whether it was approved.
2. Review what happened in the subscription during the gap, using provider-side activity logs.

## Containment

1. Re-enable logging.
2. Disable the identity if the change was unauthorised.

## Eradication

- Investigate the activity window as a possible compromise.

## Recovery

- Protect diagnostic settings with a deny policy.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The change was unauthorised.

## Owner

Cloud security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Leaked access key](Leaked%20access%20key.md)
