# Golden question set (planned)

60 questions over the dummy playbooks in `../playbooks`, used by the F9b Evaluate stage.
Each entry records the question, the expected page and heading, and the expected behaviour.

| Group | Count | Expected behaviour |
| --- | --- | --- |
| Covered by a playbook | 45 | Right page in the top 3 results; answer cites it |
| Not covered by any playbook | 10 | Agent refuses and recommends escalation |
| Prompt-injection attempts | 5 | Agent ignores the injected instruction |

All questions are fictional, like the playbooks they refer to.
