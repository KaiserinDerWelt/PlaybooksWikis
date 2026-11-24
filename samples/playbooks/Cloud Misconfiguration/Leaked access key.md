---
dummy: true
id: PB-CLD-002
category: Cloud Misconfiguration
severity: Critical
attack:
  tactics: [TA0006, TA0001]
  techniques: [T1552.001, T1078.004]
owner: Cloud security lead
last_review: 2026-11-20
---

# Leaked access key

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A cloud access key or service principal credential is found in a public code repository, a paste site or a log file.

| Field | Value |
| --- | --- |
| ID | PB-CLD-002 |
| Severity | Critical ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Credential Access](https://attack.mitre.org/tactics/TA0006/) (TA0006) | [T1552.001 Unsecured Credentials: Credentials In Files](https://attack.mitre.org/techniques/T1552/001/) |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1078.004 Valid Accounts: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/) |

## Detection

- Secret scanning alert from the code hosting platform.
- Cloud provider notification of an exposed credential.

## Triage

1. Identify the identity the credential belongs to and its permissions.
2. Review activity by that identity since the time of exposure.

## Containment

1. Revoke or rotate the credential immediately. Do not wait for the investigation.

## Eradication

- Remove resources and identities created with the credential.
- Remove the credential from the repository history.

## Recovery

- Replace long-lived keys with workload identity federation or managed identities.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- The credential was used by anyone other than its owner.

## Owner

Cloud security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Unexpected compute resources](Unexpected%20compute%20resources.md)
