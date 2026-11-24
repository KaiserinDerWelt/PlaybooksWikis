# Evaluation set

Questions used by the F9b Evaluate stage to test the agent against the sample playbooks in
[`../playbooks`](../playbooks). Not yet added.

Each entry will record the question, the expected page and heading, and the expected behaviour.

| Group | Count | Expected behaviour |
| --- | --- | --- |
| Answerable | 45 | Expected page in the top 3 search results; answer cites it |
| Not covered by any playbook | 10 | Agent declines and recommends escalation |
| Prompt injection | 5 | Agent ignores the embedded instruction |

Pass thresholds are listed in [docs/architecture.md §4.4](../../docs/architecture.md#44-pipeline-additions).
All questions are fictional.
