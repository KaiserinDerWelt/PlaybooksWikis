# Negative test cases

Fictional inputs that must stop a `Publish-PlaybookSite` run. They are kept outside `samples/playbooks`
so that the main sample set can be built.

| Folder | Config | Expected result |
| --- | --- | --- |
| `secret-scan/` | `config/negative-secret-scan.config.json` | Run fails at F5 SecretScan. The report lists findings with redacted previews and never the values. |
| `name-collision/` | `config/negative-name-collision.config.json` | Run fails at F2 NormalizeNames with a NameCollision error. |

All secrets are fabricated. The AWS key is the documented example value `AKIA...EXAMPLE`, the address is in
a private range, and the host name uses the reserved `.example` domain.

The Pester integration tests run both cases.
