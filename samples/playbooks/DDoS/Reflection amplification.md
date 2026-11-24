---
dummy: true
id: PB-DOS-002
category: DDoS
severity: High
attack:
  tactics: [TA0040]
  techniques: [T1498.002]
owner: Network security lead
last_review: 2026-11-20
---

# Reflection amplification

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

The attacker spoofs the victim's address in requests to third-party servers (DNS, NTP, memcached), which send much larger responses to the victim.

| Field | Value |
| --- | --- |
| ID | PB-DOS-002 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1498.002 Network Denial of Service: Reflection Amplification](https://attack.mitre.org/techniques/T1498/002/) |

## Detection

- Large volume of UDP responses from many sources on ports 53, 123 or 11211.

## Triage

1. Identify the reflected protocol and the targeted addresses.
2. Check that the organization's own servers are not being used as reflectors.

## Containment

1. Filter the reflected protocol for the target at the DDoS protection layer.

## Eradication

- If internal servers act as reflectors, restrict them to internal clients.

## Recovery

- Remove temporary filters once the attack has ended for 24 hours.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Internal servers are participating in an attack on a third party.

## Owner

Network security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Volumetric attack](Volumetric%20attack.md)
