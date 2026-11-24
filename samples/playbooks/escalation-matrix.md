---
dummy: true
---

# Escalation matrix

All roles are fictional. Contact details are held in the on-call system, not in the playbooks.

## Severity levels

| Severity | Definition | Response target |
| --- | --- | --- |
| Critical | Ongoing business impact, or confirmed compromise of privileged access or regulated data | Incident commander engaged within 15 minutes |
| High | Confirmed compromise with limited scope, or a credible threat of Critical impact | Level 2 analyst engaged within 1 hour |
| Medium | Suspicious activity requiring investigation; no confirmed impact | Triage within 4 hours |
| Low | Policy violation or benign-looking report requiring confirmation | Triage within 1 working day |

## Escalation path

| From | To | When |
| --- | --- | --- |
| Level 1 analyst | Level 2 analyst on call | A playbook's escalation condition is met, or triage cannot be completed |
| Level 2 analyst | Category owner | Severity High, or the playbook does not cover the situation |
| Category owner | Incident commander | Severity Critical |
| Incident commander | Legal, privacy officer, communications, executive leadership | Regulated data, payments, extortion, media interest, or notification duties |

Insider threat cases go directly to the insider risk lead and HR, and are not discussed in shared channels.

If no playbook covers the situation, escalate to level 2. Do not improvise containment.
