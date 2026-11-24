---
dummy: true
id: PB-CLD-005
category: Cloud Misconfiguration
severity: Medium
attack:
  tactics: [TA0001]
  techniques: [T1133, T1190]
owner: Cloud security lead
last_review: 2026-11-20
---

# Overly permissive network rule

> **Fictional sample.** Written for a reference implementation. Not operational guidance.

A network security rule allows management ports or an internal service from any internet address.

| Field | Value |
| --- | --- |
| ID | PB-CLD-005 |
| Severity | Medium ([definitions](../escalation-matrix.md#severity-levels)) |
| Lifecycle | [NIST SP 800-61 phases](../incident-response-lifecycle.md) |

## MITRE ATT&CK mapping

| Tactic | Technique |
| --- | --- |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1133 External Remote Services](https://attack.mitre.org/techniques/T1133/) |
| [Initial Access](https://attack.mitre.org/tactics/TA0001/) (TA0001) | [T1190 Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/) |

## Detection

- Posture alert for remote desktop or SSH open to the internet.

## Triage

1. Identify the resource behind the rule and who created it.
2. Review connection logs for internet sources that reached the port.

## Containment

1. Restrict the rule to the approved source ranges or remove it.

## Eradication

- If connections from unknown sources succeeded, investigate the host.

## Recovery

- Use just-in-time access or a bastion service for management.

## Escalation

Escalate according to the [escalation matrix](../escalation-matrix.md) when:

- A successful sign-in from an unknown source is found.

## Owner

Cloud security lead, SOC level 2. Last reviewed 2026-11-20.

## Related playbooks

- [VPN appliance compromise](../Vulnerability%20Exploitation/VPN%20appliance%20compromise.md)
