# Sample playbooks

The playbooks in this folder are fictional. They were written for this repository, describe no real
organization, system, person or incident, and are not valid incident-response guidance.

Every playbook declares `dummy: true` in its front matter.

## Planned content

The set (50 playbooks, not yet added) is designed to exercise each pipeline stage:

| Purpose | Content |
| --- | --- |
| Coverage | About 10 categories: phishing, ransomware, account compromise, malware, data exfiltration, insider threat, DDoS, cloud misconfiguration, lost device, vulnerability exploitation. 4–6 playbooks each. |
| Structure | A common template (detection, triage, containment, eradication, recovery, escalation, owner), and a few pages that deviate from it. |
| F2–F4 input handling | Accented and space-containing file names, Windows-1252 and UTF-16 encodings, CRLF line endings, missing H1 headings, relative links, images, one name collision. |
| F5 secret scan | Fabricated credentials and internal addresses that the scan must block. |
| Agent evaluation | One page containing an embedded instruction, to verify the agent treats retrieved text as data. |

## Reserved values

Addresses and domains use values reserved for documentation so they cannot match a real system: the
three IPv4 documentation ranges TEST-NET-1, TEST-NET-2 and TEST-NET-3 (RFC 5737) and the `.example`
top-level domain (RFC 2606). The sample configuration treats these as internal, so F5 flags them.

This README is published as the sample site's home page. It deliberately contains no literal addresses,
since the secret scan would block them.
