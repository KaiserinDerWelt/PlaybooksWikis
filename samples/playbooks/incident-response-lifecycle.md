---
dummy: true
---

# Incident response lifecycle

Every playbook in this set uses the same section structure, aligned with the incident response lifecycle in
[NIST SP 800-61](https://csrc.nist.gov/pubs/sp/800/61/r3/final). Revision 3 (April 2025) organizes incident
response around the NIST Cybersecurity Framework (CSF) 2.0 functions; the four-phase model of Revision 2 is
shown alongside because many teams still use its terms.

| Playbook section | SP 800-61 Rev. 2 phase | CSF 2.0 category (Rev. 3) |
| --- | --- | --- |
| Owner | Preparation | GV.RR Roles, Responsibilities, and Authorities |
| Detection | Detection and Analysis | DE.CM Continuous Monitoring; DE.AE Adverse Event Analysis |
| Triage | Detection and Analysis | RS.MA Incident Management; RS.AN Incident Analysis |
| Containment | Containment, Eradication, and Recovery | RS.MI Incident Mitigation |
| Eradication | Containment, Eradication, and Recovery | RS.MI Incident Mitigation |
| Recovery | Containment, Eradication, and Recovery | RC.RP Incident Recovery Plan Execution |
| Escalation | Detection and Analysis | RS.CO Incident Response Reporting and Communication |
| (common, below) | Post-Incident Activity | ID.IM Improvement |

## Section rules

- Detection lists the signals that start the playbook. It does not describe how detections are built.
- Triage steps are numbered and ordered. They end with a decision: benign, confirmed, or escalate.
- Containment steps are numbered. Containment comes before root-cause analysis when harm is ongoing.
- Each playbook maps to one or more [MITRE ATT&CK](https://attack.mitre.org/) techniques in its front matter
  (`attack.techniques`) and in its mapping table. See [ATT&CK coverage](attack-coverage.md).

Some playbooks deliberately use a different structure (quick-reference cards and the ransomware recovery
playbook). They are marked as such in their titles or summaries.

## Post-incident activity

Post-incident activity is common to all playbooks and is not repeated in each one. For every incident of
severity High or Critical, the incident owner holds a review within 10 working days that records:

1. Timeline from first signal to closure.
2. Which playbook was used, and where it was wrong, missing or unclear.
3. Detection gaps, with the ATT&CK techniques they relate to.
4. Actions, owners and due dates.

Playbook changes arising from the review are made by the category owner.
