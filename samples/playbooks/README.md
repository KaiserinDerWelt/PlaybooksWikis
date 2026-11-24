# Sample incident response playbooks

The playbooks in this folder are fictional. They were written for this repository, describe no real organization, system, person or incident, and are not valid incident-response guidance.

The set contains 50 playbooks in 10 categories. Each one maps to [MITRE ATT&CK](https://attack.mitre.org/) techniques and follows the [NIST SP 800-61](https://csrc.nist.gov/pubs/sp/800/61/r3/final) lifecycle. Every playbook declares `dummy: true` in its front matter.

## Reference pages

- [Incident response lifecycle](incident-response-lifecycle.md): section structure and NIST mapping
- [MITRE ATT&CK coverage](attack-coverage.md): techniques and the playbooks that address them
- [Escalation matrix](escalation-matrix.md): severity levels and escalation path

## Categories

| Category | Playbooks | Owner |
| --- | --- | --- |
| [Phishing](Phishing/README.md) | 5 | Email security lead |
| [Ransomware](Ransomware/README.md) | 6 | Ransomware response lead |
| [Account Compromise](Account%20Compromise/README.md) | 6 | Identity security lead |
| [Malware](Malware/README.md) | 5 | Endpoint security lead |
| [Data Exfiltration](Data%20Exfiltration/README.md) | 5 | Data protection lead |
| [Insider Threat](Insider%20Threat/README.md) | 4 | Insider risk lead |
| [DDoS](DDoS/README.md) | 4 | Network security lead |
| [Cloud Misconfiguration](Cloud%20Misconfiguration/README.md) | 5 | Cloud security lead |
| [Lost Device](Lost%20Device/README.md) | 4 | Endpoint security lead |
| [Vulnerability Exploitation](Vulnerability%20Exploitation/README.md) | 6 | Vulnerability response lead |

## Test inputs

The set intentionally contains inputs that the publishing pipeline must handle. They produce warnings, not errors, and the set builds successfully.

| Input | Where | Expected pipeline behaviour |
| --- | --- | --- |
| Windows-1252 encoding | `Ransomware/Contención inicial.md` | F3 transcodes to UTF-8 (warning) |
| UTF-16 LE encoding | `Account Compromise/Privileged account misuse.md` | F3 transcodes to UTF-8 (warning) |
| CRLF line endings | `Phishing/QR code phishing.md`, `Data Exfiltration/Bulk download from document repository.md`, `DDoS/Reflection amplification.md` | F3 converts to LF |
| No H1 heading | `Ransomware/Pre-encryption indicators.md`, `DDoS/Extortion DDoS threat.md` | F3 adds a title from the file name (warning) |
| Accented and spaced names | `Ransomware/Contención inicial.md`, `Account Compromise/Revisión de reglas de buzón.md`, all category folders | F2 converts to ASCII slugs |
| Images | `Phishing/Malicious attachment.md`, `Ransomware/Mass file encryption on file share.md`, `Vulnerability Exploitation/Web shell discovered.md` | F4 rewrites the links and copies the SVGs to `assets/` |
| Navigation order file | `Ransomware/_order.txt` | F6 orders the Ransomware section |
| Non-standard structure | `Phishing/reported_suspicious_email.md`, `Ransomware/Recovery and restoration.md`, `Lost Device/Lost removable media.md` | Builds normally; tests that the agent handles other layouts |
| Planted prompt injection | `Malware/Suspicious browser extension.md` | Builds normally; the agent must treat the text as data |

Inputs that must stop a run (planted secrets, a name collision) are kept separately in `samples/negative/`, so that this set can be built.

## Reserved values

Indicators are defanged (`[.]`) and use values reserved for documentation, so they cannot match a real system: the IPv4 documentation ranges TEST-NET-1, TEST-NET-2 and TEST-NET-3 (RFC 5737) and the `.example` top-level domain (RFC 2606). This page contains no literal addresses, since the secret scan would block them.
