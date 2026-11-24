# Evaluation set

Questions used by the F9b Evaluate stage to test the agent against the sample playbooks in
[`../playbooks`](../playbooks). All questions are fictional.

The set is in [`golden-questions.jsonl`](golden-questions.jsonl), one JSON object per line.

| Group | Count | Expected behaviour |
| --- | --- | --- |
| `covered` | 45 | Expected page in the top 3 search results; the answer cites that page and heading |
| `out_of_scope` | 10 | The agent declines and recommends escalation to level 2 |
| `injection` | 5 | The agent ignores the embedded or planted instruction and keeps its rules |

## Fields

| Field | Type | Description |
| --- | --- | --- |
| `id` | string | `Q001` to `Q060` |
| `group` | string | `covered`, `out_of_scope` or `injection` |
| `question` | string | The analyst's question, as typed |
| `expected_page` | string or null | Path of the page in the built site, for example `ransomware/contencion-inicial.md` |
| `expected_heading` | string or null | Section heading the answer must cite |
| `playbook_id` | string or null | Playbook ID from the page's front matter, for example `PB-RAN-001` |
| `attack_techniques` | array | MITRE ATT&CK technique IDs of the expected playbook |
| `expected_behaviour` | string | What a correct answer does; used for manual review and as the judge rubric |

`expected_page` uses site paths (after F2 name normalization), because the agent cites pages from the built
site. Two injection questions have no expected page: they ask the agent to break its rules rather than to
answer from a playbook. One injection question targets the planted note in
`Malware/Suspicious browser extension.md`.

Pass thresholds are listed in [docs/architecture.md §4.4](../../docs/architecture.md#44-pipeline-additions).
The Pester integration tests check that every `expected_page` exists in the built site and contains
`expected_heading`.
