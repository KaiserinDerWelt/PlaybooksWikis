# SOC Playbook Wiki Deployment — Task Definition

Nov 23, 2026 · @KaiserinDerWelt

## Summary

Publish about 5,000 incident-handling playbooks (Markdown) as a static documentation site hosted on Azure App Service in the SOC subscription. Only SOC members can read it, only from AVD, and only with company-tenant accounts. An Azure Pipelines run on a self-hosted agent invokes a PowerShell tool that validates and normalizes the content, builds the site, and zip-deploys it through a private endpoint. Access is enforced by Entra app assignment, private networking and the subscription boundary, not by the script.

Decisions recorded 2026-11-23: publishing runs from a pipeline agent, and the content must live as a resource in the SOC subscription. The second decision rules out Azure DevOps Wiki as the target.

Decided 2026-11-23: the project becomes an AI portfolio sample. Phase 1 adds the first AI feature, an "Ask the playbooks" agent that answers analysts' questions with citations to the exact playbook section. Phase 2 adds alert-to-playbook triage from Microsoft Sentinel incidents. The portfolio build runs on **50 dummy playbooks** written for the sample; no real SOC content is used or published. The 5,000-file figures in this doc are the production design target.

Decided 2026-11-23: the portfolio repository ([KaiserinDerWelt/PlaybooksWikis](https://github.com/KaiserinDerWelt/PlaybooksWikis)) publishes the project structure, architecture, code and documentation only. Nothing is deployed and no CI runs from it; the Azure Pipelines YAML is included as reference architecture. The committed config holds environment-variable names, never IDs: `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID` and `AZURE_RESOURCE_GROUP` follow Azure naming, and project-specific values use the `PLAYBOOK_` prefix.

## Background and problem statement

First-level security engineers need one searchable, authoritative place for incident-handling guidance. The playbooks exist as about 5,000 .md files with no common conventions for names, links, images or front matter.

The infrastructure engineer (X) owns the deployment. Three things make it more than a copy job:

- **Volume:** 5,000 pages must be built and deployed as one versioned unit, so a release can be rolled back as a whole.
- **Content quality:** inconsistent Markdown breaks the site build (broken relative links, missing images, malformed front matter, unsafe file names).
- **Sensitivity:** playbooks describe detection gaps and response steps, and may contain internal hostnames, IPs or credentials. Exposing them to the wrong audience is a security incident in itself.

## Sample data

The portfolio sample uses 50 dummy playbooks. They are fictional, written for this project, and contain no real company names, hosts, IPs, users, tools or incidents. Real SOC playbooks are confidential and never enter the public repo, the pipeline artifacts or the evaluation set.

The dummy set still has to exercise every stage, so it deliberately includes:

- **Coverage:** about 10 incident categories (phishing, ransomware, account compromise, malware, data exfiltration, insider threat, DDoS, cloud misconfiguration, lost device, vulnerability exploitation), with 4–6 playbooks each
- **Structure:** a common template (detection, triage, containment, eradication, recovery, escalation, owner), plus a few pages that break it, to test the review rules
- **Messy inputs:** accented and spaced file names, Windows-1252 and UTF-16 files, CRLF line endings, missing H1s, relative links, images, one name collision
- **Planted secrets:** fake keys, passwords and internal IPs (documentation ranges and obviously fake values) to prove the secret scan blocks them
- **Planted injection:** one page containing an instruction aimed at the agent, to prove the agent treats playbook text as data

The dummy set lives in `samples/playbooks/` and is labelled as fictional in its README and in every page's front matter (`dummy: true`).

## Goal and success criteria

Goal: every SOC first-level engineer can find and read any playbook from AVD, and nobody else can, from anywhere. Phase 1 adds that they can also ask the playbooks a question and get a cited answer, or an honest "not covered".

The task is done when all of these are verified:

| # | Criterion | How it is verified |
| --- | --- | --- |
| 1 | All source playbooks are published, or excluded with a logged reason | Script report: source count = published + rejected |
| 2 | Zero broken internal links and zero missing images in the built site | Validation report run on the build output |
| 3 | Zero secrets detected in published content | Secret-scan report attached to the pipeline run |
| 4 | A SOC member on AVD can read the site | Test user sign-in from an AVD session host |
| 5 | A SOC member off AVD can't reach the site | Request from another network fails: no public endpoint |
| 6 | A non-SOC tenant user is denied, even on AVD | Sign-in fails because the user isn't assigned to the app |
| 7 | Accounts from other tenants and personal Microsoft accounts can't sign in | Test with an external account |
| 8 | Every resource (plan, app, private endpoint, agent, search, model) is in the SOC subscription | Resource inventory of the SOC resource group |
| 9 | Only the pipeline identity can deploy; basic-auth publishing and FTP are off | App configuration check + a failed deploy attempt with other credentials |
| 10 | Re-running with no source changes deploys nothing | Idempotency check in the run log |
| 11 | Every deployment is traceable to a commit, a pipeline run and a report | Pipeline history + run artifact |
| 12 | The agent meets every evaluation threshold on the golden set | F9b report attached to the run |
| 13 | Every agent answer cites a page and heading, or refuses | Evaluation report + manual review of 20 sampled answers |
| 14 | The agent API refuses unauthenticated and non-SOC callers | Same tests as criteria 5–7, against the API |
| 15 | Agent telemetry contains no question or answer text | Inspection of the log schema and a sample of entries |
| 16 | The public repo contains only the 50 dummy playbooks | Repo review before publishing; `dummy: true` on every page |

## Access requirements (original vs. reframed)

All three requirements are now enforceable, because the site is an Azure resource in the SOC subscription. Each one is enforced by a different layer, so no single misconfiguration opens the content.

| Requirement | Enforced by | Notes |
| --- | --- | --- |
| R1. Entra user in the SOC group | Single-tenant Entra app registration for App Service authentication (Easy Auth); *Assignment required* = Yes on the enterprise app; only the SOC group is assigned | Group-based app assignment needs Entra ID P1. Unauthenticated requests are redirected to sign-in, never served |
| R2. Access only from AVD | Private endpoint for the app with public network access disabled; NSG on the private-endpoint subnet allows only the AVD session-host subnet | Stronger than an IP allowlist: no public endpoint exists. App Service access restrictions don't apply to private-endpoint traffic, so the NSG is the control. Optional extra layer: a Conditional Access policy on the app |
| R3a. Company tenant only | Single-tenant app registration (*Accounts in this organizational directory only*) | Personal and other-tenant accounts fail at sign-in |
| R3b. Lives in the SOC subscription | App Service plan, web app, private endpoint, private DNS link and deployment agent all deployed to a SOC resource group; RBAC on that group limited to SOC admins and the pipeline identity | Now a hard requirement, met by placement plus RBAC |

## Target architecture

Three independent layers each have to say yes: the network (only the AVD subnet can reach the private endpoint), identity (single-tenant Entra app with SOC-only assignment), and the subscription boundary (every resource and its RBAC sit in the SOC subscription). The site is plain HTML generated from the Markdown, served by a Windows App Service plan (Basic tier or higher, needed for private endpoints).

&#91;embedded content: target architecture · access path and publish path\]

A SOC user on AVD reaches the private endpoint and passes Entra sign-in. The same user anywhere else has no network path to the site. A non-SOC user on AVD reaches the site but fails sign-in because they aren't assigned to the app. Deployments go through the private SCM endpoint, so a Microsoft-hosted agent can't deploy at all; that's why the agent is self-hosted inside the SOC VNet.

## Scope

The script owns the content pipeline: validate, build, deploy. The infrastructure (plan, app, private endpoint, Entra app, agent) is provisioned once as IaC and only checked by the script, so a content run can never widen access.

**In scope**

- PowerShell tool that validates, normalizes, builds and deploys the playbooks as a static site
- Normalizing file and folder names; generating site navigation
- Rewriting relative links; collecting images into the site's asset folder
- Handling YAML front matter (strip it, or map it to page metadata)
- Secret and sensitive-data scanning, with a hard stop on findings
- Building the static site with a Markdown site generator (choice is an open question)
- Zip-deploying the build to App Service from the pipeline agent through the private endpoint
- Idempotent re-runs: deploy only when the content hash changes; keep the previous build for rollback
- Run report (JSON + human-readable summary) and a `-WhatIf` dry run
- Pre-flight checks that confirm the access controls are in place before deploying (read-only)
- Azure Pipelines YAML that runs the tool on the self-hosted agent with a workload-identity-federation service connection
- IaC (Bicep) for the SOC resource group: plan, web app, private endpoint, private DNS link, NSG, agent VM or scale set
- **Phase 1 AI feature:** the Ask the playbooks agent (API, four tools, chat panel in the site), a search index and a model endpoint, all private
- Index (F9a) and Evaluate (F9b) pipeline stages, with the golden question set and thresholds
- The 50 dummy playbooks and their README marking them as fictional

**Out of scope**

- Writing or reviewing real playbook content (owned by the SOC); no real playbooks are used in the portfolio sample
- Creating the Entra app registration and group assignment (done once by an identity admin, change-controlled)
- Building or changing AVD itself; peering the AVD VNet to the SOC VNet is a dependency, not a deliverable
- Azure DevOps Wiki or any target outside the SOC subscription
- **Phase 2:** alert-to-playbook triage from Microsoft Sentinel incidents (see Roadmap)
- Any agent action beyond advice: no ticket submission, no containment actions, no changes to systems
- Translation, or converting formats other than Markdown
- Ongoing editorial workflow (PR reviews by SOC leads); recommended as a follow-up

## Script requirements

The script is a module with separate stages, each runnable on its own, so validation can run in CI long before anyone has publish rights.

**Functional**

| ID | Stage | Requirement |
| --- | --- | --- |
| F1 | Inventory | Scan the source tree; hash every file; record path, size and encoding |
| F2 | Normalize names | Map file and folder names to URL-safe slugs; detect collisions after mapping; keep a source-to-URL map |
| F3 | Normalize content | Convert to UTF-8 without BOM and LF line endings; validate or strip front matter; fix heading levels |
| F4 | Links and assets | Resolve relative links and images; rewrite them to site paths; copy images to the asset folder; report anything unresolved |
| F5 | Secret scan | Detect credentials, keys, tokens, connection strings, and internal IPs and hostnames by pattern list; any finding blocks the deploy |
| F6 | Navigation | Generate the generator's navigation file (by configured order or alphabetically) |
| F7 | Build | Run the site generator in strict mode (warnings fail the build); produce a zip and a content manifest (hash per page) |
| F8 | Diff | Compare the manifest with the one deployed last: added, changed, removed, unchanged; nothing changed = stop |
| F9 | Pre-flight | Read-only checks: the app is in the SOC subscription; public network access is off; Easy Auth is on with unauthenticated = redirect; *Assignment required* is set on the Entra app; basic-auth publishing and FTP are off |
| F9a | Index | Chunk changed pages by heading; embed; write to a staging search index; drop removed pages |
| F9b | Evaluate | Run the golden questions through the agent API against the staging index; fail below any threshold |
| F10 | Deploy | Zip-deploy to a staging slot through the private endpoint; smoke test; swap to production, then point the agent API at the new index. Keep the previous build and index for rollback |
| F11 | Report | JSON + Markdown summary: counts, rejections with reasons, diff, evaluation scores, build ID, commit, pipeline run, duration; published as a pipeline artifact |

**Non-functional**

- PowerShell 7.4+ on the self-hosted agent (Windows or Linux)
- Depends on Az.Accounts, Az.Websites and Microsoft.Graph.Applications (pre-flight only), plus the site generator. No AzureAD or MSOnline modules
- Authenticates as the pipeline's workload-identity-federation service connection. No PATs, client secrets or publishing profiles anywhere
- Pipeline identity RBAC: Website Contributor on the web app only, plus Reader on the SOC resource group for pre-flight
- `-WhatIf` / `SupportsShouldProcess` for every change; `-Stage` to run a single stage
- Idempotent: a re-run with no source changes deploys nothing
- Fails closed: any validation, secret-scan or pre-flight error stops the run before deploy
- Pipeline logs and artifacts contain the report only, never playbook content (the content is as sensitive as the site)
- Performance target: a full 5,000-file build and deploy under 20 minutes (assumption, to be confirmed)
- Config in a versioned JSON file: paths, subscription, resource group, app name, name rules, secret patterns, exclusions
- Pester tests for the name-mapping, link-rewriting and secret-scan logic

## Deployment flow

Each run is all-or-nothing: content checks and access checks both run before anything reaches the App Service, and every run ends with a report.

&#91;embedded content: publish run · 8 stages, 2 hard stops\]

Name collisions and unresolved links also stop the run at their stage. The first production run is a `-WhatIf` run against all 5,000 files, and its report becomes deliverable 6.

The diagram shows the content pipeline. Phase 1 inserts F9a Index and F9b Evaluate between Pre-flight and Deploy; a failed evaluation stops the run the same way a failed pre-flight does.

## AI agent, phase 1: Ask the playbooks

Feature 1 is an agent that a first-level analyst asks in plain language ("user reports MFA prompts they didn't trigger"). It finds the right playbook, quotes the relevant section and cites the page and heading. It advises only: it never deploys, approves, blocks or changes anything, and the deterministic pipeline stays the only gate.

**Tools the agent can call**

| Tool | Does | Returns |
| --- | --- | --- |
| `search_playbooks(query, category?)` | Hybrid search (keyword + vector) over heading-sized chunks | Top chunks with page, heading, score |
| `get_section(page, heading)` | Fetches the exact section text | Verbatim text, so answers quote instead of paraphrasing |
| `list_related(page)` | Follows links and escalation references | Related playbooks |
| `draft_incident_note(summary, page, steps)` | Drafts a ticket note for the analyst | Text only; never submitted anywhere |

**Guardrails**

- **Cite or refuse:** every answer cites at least one page and heading. If nothing relevant is retrieved, the answer is "No playbook covers this; escalate to L2". It never improvises containment steps.
- **Playbook text is data:** retrieved content goes into the prompt as quoted context, never as instructions. The planted-injection page tests this.
- **Same access model as the site:** the agent API sits behind the same Entra app assignment and private networking. A user who can't read the site can't ask the agent.
- **Inside the tenant:** model, search index and API all live in the SOC subscription with private endpoints and managed identity. No call to a public LLM API.
- **Content-free telemetry:** logs record category, retrieved page IDs, tool calls, latency and token counts, never the question or answer text.

**New pipeline stage: F9a Index** (after Pre-flight, before Deploy). Split pages into chunks by heading, create embeddings, and write them to a **staging index**. It reuses the F8 diff, so only added or changed pages are re-embedded and removed pages are dropped. The Deploy stage points the agent at the new index right after the site swap, so the site and the agent answer from the same release.

**Evaluation gate: F9b Evaluate.** A golden set of 60 questions over the dummy playbooks, each with its expected page and heading, including 10 questions no playbook covers and 5 injection attempts. Each run measures:

| Metric | Threshold to pass |
| --- | --- |
| Right page in the top 3 search results | ≥ 90% |
| Answer cites the expected page | ≥ 90% |
| Out-of-scope questions refused | 100% |
| Injection attempts ignored | 100% |
| Median answer latency | ≤ 8 s |

A run below any threshold fails before deploy, so a model, prompt or chunking change can't quietly make answers worse. The thresholds are starting assumptions, to be tuned after the first baseline run.

&#91;embedded content: agent architecture · question path and indexing path\]

The analyst's question goes from the site's chat panel to the agent API, which searches the index, fetches exact sections and asks the model to answer from them only. The pipeline fills the index from the same release it deploys, and F9b sends the golden questions through the agent API before every swap. The agent API is a second App Service app.

**Platform choices (decided 2026-11-23)**

| Component | Service | Configuration |
| --- | --- | --- |
| Model | Azure OpenAI (a chat model plus an embedding model deployment) | Private endpoint, public network access disabled, key authentication disabled; the agent API's managed identity has *Cognitive Services OpenAI User* |
| Search | Azure AI Search, Basic tier or higher (needed for private endpoints) | Private endpoint, key authentication disabled; the pipeline identity has *Search Index Data Contributor*, the agent API has *Search Index Data Reader* |
| Agent API | Second App Service app, on the same App Service plan as the site | Same Entra app registration and SOC-only assignment; private endpoint for inbound; VNet integration for outbound calls to Azure OpenAI and Search; no secrets in app settings |

The agent API reads the live index name from an app setting. Deploy updates that setting right after the site swap, so there is a gap of a few seconds between the two switches. Rollback restores both: the previous site from the staging slot and the previous index name, whose index is kept until the next successful release.

## Roadmap

Phase 1 delivers the site, the pipeline and the Ask the playbooks agent. Phase 2 adds alert-to-playbook triage from Microsoft Sentinel incidents, and starts only once phase 1 passes its evaluation gate.

&#91;embedded content: roadmap · 2 phases, 1 gate\]

Phase 2 is deliberately second. It reads live incident data, so it needs read-only Sentinel permissions, its own golden set of synthetic incidents with expected playbooks, and a separate security review. The phase 1 tools, index and evaluation harness are reused as they are; phase 2 adds one tool, `get_incident(id)`, and one new metric, correct playbook proposed for each incident. Phase 2 is out of scope for this task definition and will get its own.

## Risks, assumptions, dependencies

The biggest risk is access leaking through defaults, not the script failing.

**Risks**

| Risk | Impact | Mitigation |
| --- | --- | --- |
| *Assignment required* left off on the Entra app | Every tenant user can read the playbooks | Set in IaC; pre-flight F9 checks it on every run |
| Public network access re-enabled, or an access-restriction rule added "temporarily" | The site is reachable from the internet (still behind sign-in) | Azure Policy on the SOC resource group denying public network access; checked by F9 |
| The source repo or pipeline artifacts are less protected than the site | Playbooks leak around the controls | Source repo restricted to SOC + maintainers; artifacts hold only the report; short artifact retention |
| Self-hosted agent compromised or shared with other projects | Deploy rights and content exposed | Agent pool dedicated to this pipeline; agent in the SOC VNet; least-privilege identity (Website Contributor on one app) |
| AVD-to-SOC VNet peering or private DNS misconfigured | SOC users can't resolve or reach the site | Private DNS zone linked to the AVD VNet; connectivity test in criteria 4 |
| Secrets in playbooks | Credential exposure to a wider audience | F5 blocks the deploy; the SOC owns remediation |
| Client-side search index for 5,000 pages is too large | Slow page loads on AVD | Measure in the first dry run; fall back to per-section indexes if needed |
| Name collisions after normalization | Pages overwritten | F2 collision check fails the run |
| Git history keeps removed or rejected content | A secret stays recoverable in the source repo | Scan before the first commit; history rewrite procedure documented |

**Agent risks (phase 1)**

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Agent invents a containment step | An analyst acts on wrong guidance during an incident | Cite-or-refuse rule; answers quote `get_section` text; refusal rate on out-of-scope questions is a 100% gate |
| Instruction hidden in playbook text steers the agent | Wrong or harmful answer | Retrieved text passed as quoted data; planted-injection page and 5 injection questions in the golden set |
| Model, prompt or chunking change lowers quality silently | Answers get worse with no failing build | F9b thresholds fail the run; scores tracked per run in the report |
| Questions or answers end up in logs | Incident details exposed outside the SOC | Content-free telemetry schema; criterion 15 |
| Dummy data mistaken for real guidance | Fictional steps reused in a real incident | `dummy: true` on every page, a banner on every page of the sample site, and a README stating the content is fictional |
| Token cost grows with usage | Budget overrun | Per-user rate limit on the agent API; budget alert on the resource group |

**Assumptions**

- The tenant has Entra ID P1 (needed for group-based app assignment)
- The AVD VNet can be peered to the SOC VNet, or the private endpoint can sit in a subnet AVD already reaches
- A SOC Entra group exists and is maintained by the SOC
- The SOC subscription allows App Service (Basic tier or higher), private endpoints and a small agent VM or scale set
- The playbooks are CommonMark-compatible Markdown with local images
- Azure Pipelines can use a workload-identity-federation service connection to the SOC subscription

**Dependencies**

- Identity admin: Entra app registration, *Assignment required*, SOC group assignment
- SOC subscription owner: resource group, RBAC, Azure Policy, IaC deployment approval
- Network team: VNet peering to AVD, NSG on the private-endpoint subnet, private DNS zone link
- DevOps org admin: service connection, dedicated agent pool, SOC-only source repo
- SOC lead: content ownership, exclusions, remediating secret findings

## Open questions and deliverables

**Open questions (to settle before coding starts)**

- [x] Does R3b mean billing or physical placement?

  Decided 2026-11-23: the content must live as a resource in the SOC subscription. The target moves from Azure DevOps Wiki to App Service.
- [x] Where does the publish run?

  Decided 2026-11-23: from a pipeline agent, self-hosted in the SOC VNet.
- [x] Which AI feature comes first?

  Decided 2026-11-23: Ask the playbooks in phase 1; Sentinel triage in phase 2. The sample uses 50 dummy playbooks.
- [x] Model, agent API host and search?

  Decided 2026-11-23: Azure OpenAI, a second App Service app, and Azure AI Search.
- [ ] Azure OpenAI region: which region has both the chat and embedding models with quota, and is it acceptable for SOC data residency?
- [ ] Site generator: MkDocs Material (best search and navigation, needs Python on the agent) or DocFX (.NET, fits the existing stack)? The first script draft uses MkDocs Material.
- [ ] Private endpoint (recommended) or a public endpoint with an AVD-IP access restriction? The first script draft assumes private endpoint.
- [ ] Agent: a single VM, or a Managed DevOps Pool / scale set in the SOC VNet?
- [ ] Direct deploy, or an approval gate where a SOC lead signs off each release?
- [ ] Where do the playbooks live going forward: a SOC-only Azure DevOps repo, or an upstream system the pipeline syncs from?
- [ ] Front matter: strip it, or render it as page metadata (owner, severity, last review)?
- [ ] Navigation: a required structure (by incident type or severity), or alphabetical?
- [ ] Which internal patterns count as sensitive (domain suffixes, IP ranges, ticket formats)?
- [ ] Should reads be logged per user (App Service HTTP logs + sign-in logs to the SOC Log Analytics workspace)?

**Deliverables**

1. `Publish-PlaybookSite` PowerShell module (stages F1–F11, plus F9a Index and F9b Evaluate) with a sample config. First draft delivered 2026-11-23, without F9a and F9b
2. Azure Pipelines YAML for the self-hosted agent, with a workload-identity-federation service connection
3. Bicep for the SOC resource group: App Service plan and app, staging slot, private endpoint, NSG, private DNS link, agent, search, model endpoint, Azure Policy assignment
4. Pester test suite for name mapping, link rewriting and the secret scan
5. Setup runbook: Entra app registration and assignment, VNet peering, RBAC, first deployment
6. Validation report from the first `-WhatIf` run against the sample playbooks
7. Access test evidence for success criteria 4–9 and 14
8. Agent API with the four tools and the site's chat panel
9. 50 dummy playbooks in `samples/playbooks/`, marked as fictional
10. Golden question set (60 questions) and the first evaluation baseline report
