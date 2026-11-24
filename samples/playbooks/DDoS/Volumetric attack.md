---
dummy: true
id: PB-DOS-001
category: DDoS
severity: High
attack:
  tactics: [TA0040]
  techniques: [T1498.001]
owner: Network security lead
last_review: 2026-11-20
---

# Volumetric attack

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Traffic volume saturates internet links or upstream capacity, making public services unreachable.

| Field | Value |
| --- | --- |
| ID | PB-DOS-001 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1498.001 Network Denial of Service: Direct Network Flood](https://attack.mitre.org/techniques/T1498/001/) |

## Detection

- DDoS protection service alert for traffic above the baseline.
- Link utilisation at capacity with packet loss.

## Triage

1. Identify the target IP addresses and services.
2. Record traffic volume, packet rate and protocols.

## Containment

1. Confirm that DDoS protection is in mitigation mode for the target.
2. Ask the internet service provider for upstream filtering if the link remains saturated.

## Eradication

- Not applicable; the attack ends when the attacker stops or mitigation absorbs it.

## Recovery

- Monitor for 24 hours after traffic returns to normal; attacks often resume.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- A customer-facing service is unavailable for more than 15 minutes.

## Owner

Network security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Reflection amplification](Reflection%20amplification.md)
- [Extortion DDoS threat](Extortion%20DDoS%20threat.md)
