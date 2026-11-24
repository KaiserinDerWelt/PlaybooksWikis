# Dummy playbooks

**Everything in this folder is fictional.** These playbooks were written for this portfolio project.
They contain no real company names, hosts, IP addresses, users, tools or incidents, and they are
not real incident-response guidance. Do not use them in a real incident.

Every page carries `dummy: true` in its front matter.

## What the set must cover (planned: 50 playbooks)

- About 10 incident categories (phishing, ransomware, account compromise, malware, data exfiltration,
  insider threat, DDoS, cloud misconfiguration, lost device, vulnerability exploitation), 4–6 playbooks each
- A common template (detection, triage, containment, eradication, recovery, escalation, owner),
  plus a few pages that break it
- Messy inputs on purpose: accented and spaced file names, Windows-1252 and UTF-16 files, CRLF line
  endings, missing H1s, relative links, images, one name collision
- Planted fake secrets and documentation-range IPs, to prove the secret scan blocks them
- One planted prompt-injection page, to prove the agent treats playbook text as data

Fake values use reserved documentation ranges (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24) and the
reserved `.example` domain, so nothing here can match a real system.
