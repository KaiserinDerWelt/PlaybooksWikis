---
dummy: true
id: PB-DOS-003
category: DDoS
severity: High
attack:
  tactics: [TA0040]
  techniques: [T1499.002, T1499.003]
owner: Network security lead
last_review: 2026-11-20
---

# Application layer flood

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

Large numbers of valid-looking HTTP requests exhaust the web application rather than the network.

| Field | Value |
| --- | --- |
| ID | PB-DOS-003 |
| Severity | High ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1499.002 Endpoint Denial of Service: Service Exhaustion Flood](https://attack.mitre.org/techniques/T1499/002/) |
| [Impact](https://attack.mitre.org/tactics/TA0040/) (TA0040) | [T1499.003 Endpoint Denial of Service: Application Exhaustion Flood](https://attack.mitre.org/techniques/T1499/003/) |

## Detection

- Web application firewall alert for request rates above the baseline.
- Application response times rise while network utilisation stays normal.

## Triage

1. Identify targeted URLs, especially expensive ones such as search or login.
2. Look for common request attributes: user agent, header order, source networks.

## Containment

1. Apply rate limiting or a challenge on the targeted URLs.
2. Block the request signature at the web application firewall.

## Eradication

- Not applicable.

## Recovery

- Add caching for expensive endpoints where possible.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- Login or payment functions are unavailable.

## Owner

Network security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [Volumetric attack](Volumetric%20attack.md)
