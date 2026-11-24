# PlaybooksWikis

A pipeline that publishes Markdown incident-response playbooks as a private static site on Azure App
Service, restricted to members of a SOC group connecting from Azure Virtual Desktop. A second phase adds
a retrieval agent that answers analyst questions from the playbooks and cites the section it used.

This repository is a reference implementation. Nothing in it is deployed and no pipeline runs from it.
Content under `samples/` is fictional and must not be used as operational guidance.

![Target architecture](docs/images/target-architecture.png)

## Contents

| Path | Description |
| --- | --- |
| `src/PlaybookSite/` | PowerShell module. Exports `Publish-PlaybookSite`, `Invoke-PlaybookRollback` and `ConvertTo-PlaybookSlug`. |
| `tests/PlaybookSite.Tests.ps1` | Pester 5 suite: unit tests for the pure functions, plus `Integration` tests that build the sample set offline and run the failing cases. |
| `config/playbooksite.config.json` | Sample configuration. Azure values are `${VAR}` placeholders resolved from the environment. |
| `config/negative-*.config.json` | Configurations for the failing test cases in `samples/negative/`. |
| `pipelines/publish-playbooks.yml` | Azure Pipelines definition: offline validation on pull requests, deployment from `main`. Reference only. |
| `samples/playbooks/` | 50 fictional playbooks in 10 categories, mapped to MITRE ATT&CK and structured on the NIST SP 800-61 lifecycle. |
| `samples/eval/` | Evaluation set for the agent: 60 questions in `golden-questions.jsonl`. |
| `samples/negative/` | Inputs that must stop a run: planted secrets and a name collision. |
| `docs/architecture.md` | Architecture, pipeline stages, agent design, operational requirements. |
| `docs/task-definition.md` | Requirements, acceptance criteria, risks and decision log. |

## Pipeline overview

`Publish-PlaybookSite` runs a fixed sequence of stages. Each stage feeds the next, and any error stops
the run before deployment (fail-closed). A report is written on every run, including failed ones.

| Stage | Purpose |
| --- | --- |
| F1 Inventory | Enumerate and hash source files |
| F2 NormalizeNames | Map file and folder names to URL-safe slugs; reject collisions |
| F3 NormalizeContent | Convert to UTF-8/LF, validate front matter, add a missing H1 |
| F4 LinksAndAssets | Rewrite relative links and images to site paths; reject unresolved targets |
| F5 SecretScan | Pattern-based detection of credentials, tokens, internal IPs and host names |
| F6 Navigation | Generate `mkdocs.yml`, navigation, home page and `web.config` |
| F7 Build | `mkdocs build --strict`, content manifest, zip package |
| F8 Diff | Compare the manifest with the one in production |
| F9 Preflight | Read-only verification of network, authentication and Entra assignment settings |
| F10 Deploy | Zip deploy to the staging slot, smoke test, slot swap, production smoke test |
| F11 Report | `report.json` and `report.md`; never contains page content or secret values |

Stage details and the checks performed by F9 are in [docs/architecture.md](docs/architecture.md).

## Requirements

- PowerShell 7.4 or later
- Pester 5.5 or later
- Python 3 with the packages in `requirements.txt` (MkDocs 1.6, Material for MkDocs 9.7)
- For stages F8 to F10 only: Az.Accounts and Az.Websites, and an authenticated Azure context

## Usage

Run the tests:

```powershell
Invoke-Pester ./tests
```

Integration tests that need a site build are skipped if `python -m mkdocs` is unavailable.

Run stages F1 to F7 locally, without Azure access:

```powershell
Import-Module ./src/PlaybookSite/PlaybookSite.psd1
Publish-PlaybookSite -ConfigPath ./config/playbooksite.config.json -Offline
```

Output is written under `workPath` (`.work/` with the sample configuration): the built site in
`.work/site`, the package in `.work/site.zip` and the report in `.work/report`. The work folder is
cleared at the start of each run and must not overlap `sourcePath`.

Other run modes:

| Command | Behaviour |
| --- | --- |
| `Publish-PlaybookSite -ConfigPath <path> -WhatIf` | Runs F1 to F8 and reports what would be deployed |
| `Publish-PlaybookSite -ConfigPath <path> -StopAfter <stage>` | Stops after the named stage |
| `Publish-PlaybookSite -ConfigPath <path>` | Full run; skips deployment if the content hash matches production |
| `Publish-PlaybookSite -ConfigPath <path> -Force` | Full run; deploys even if the content is unchanged |
| `Invoke-PlaybookRollback -ConfigPath <path>` | Swaps the staging slot (previous release) back into production |

`-ReportPath` overrides the report location. The function returns an object with `Result`,
`ContentHash`, `Errors`, `Warnings` and `ReportPath`; `Result` is one of `ValidatedOffline`, `WhatIf`,
`NoChanges`, `Deployed`, `StoppedAfter<Stage>` or `Failed`.

## Configuration

Relative paths in the configuration file are resolved against the file's own folder. Strings of the
form `${NAME}` are replaced with the value of the environment variable `NAME`. Unresolved placeholders
are allowed for offline runs; the Azure stages refuse to start while any remain.

| Variable | Used for |
| --- | --- |
| `AZURE_SUBSCRIPTION_ID` | Subscription that hosts the site |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_RESOURCE_GROUP` | Resource group of the web app |
| `PLAYBOOK_SITE_APP_NAME` | App Service app name |
| `PLAYBOOK_SITE_AUTH_CLIENT_ID` | Client ID of the Entra app registration used by App Service authentication |
| `PLAYBOOK_SOC_GROUP_OBJECT_ID` | Object ID of the only group permitted on that app |

`AZURE_CLIENT_ID` is not used for the App Service authentication app because Azure Identity libraries
interpret it as the identity of the calling process.

Secret-scan findings can be suppressed individually by adding their fingerprint (shown in the report)
to `secretScan.allowlist`, after review confirms a false positive.

## Status

| Item | State |
| --- | --- |
| Module, stages F1 to F11 | Implemented; not yet run against Azure |
| Pester tests | Implemented; 44 tests passing |
| Architecture and task definition | Written |
| Sample playbooks (50) and evaluation set (60 questions) | Complete; the sample set builds offline with no errors |
| Search indexing (F9a), evaluation gate (F9b), agent API | Not started |
| Bicep templates for the resource group | Not started |
| Microsoft Sentinel triage (phase 2) | Not started |

## Security

Do not commit real playbooks, tenant or subscription identifiers, or credentials. Keep GitHub secret
scanning and push protection enabled. Test fixtures for the secret scanner use fabricated values.

## License

No license has been granted. All rights reserved.
