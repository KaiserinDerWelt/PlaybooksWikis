---
dummy: true
id: PB-EXF-004
category: Data Exfiltration
severity: High
attack:
  tactics: [TA0011, TA0010]
  techniques: [T1071.004, T1048]
owner: Data protection lead
last_review: 2026-11-20
---

# DNS tunnelling

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Data encoded into DNS queries to an attacker-controlled domain. DNS is often allowed where other protocols are blocked.

| Field | Value |
| --- | --- |
| ID | PB-EXF-004 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Command and Control](https://attack.mitre.org/tactics/TA0011/) (TA0011) | [T1071.004 Application Layer Protocol: DNS](https://attack.mitre.org/techniques/T1071/004/) |
| [Exfiltration](https://attack.mitre.org/tactics/TA0010/) (TA0010) | [T1048 Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/) |

## Detection

- High volume of queries with long, high-entropy subdomains to one parent domain, for example `a9f3c1e0b7.data-sync[.]example`.
- Unusual record types (TXT, NULL) at high frequency.

## Triage

1. Identify the querying host and process.
2. Estimate the data volume from query count and label length.

## Containment

1. Sinkhole the parent domain on internal resolvers.
2. Isolate the host.

## Eradication

- Remove the tunnelling tool or implant.

## Recovery

- Ensure hosts can resolve only through internal resolvers.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Always, because tunnelling indicates a deliberate operator.

## Owner

Data protection lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Command and control beaconing](../Malware/Command%20and%20control%20beaconing.md)
