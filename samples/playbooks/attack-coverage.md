---
dummy: true
---

# MITRE ATT&CK coverage

Techniques from the [MITRE ATT&CK Enterprise matrix](https://attack.mitre.org/matrices/enterprise/) referenced by the 50 sample playbooks, grouped by the tactic in which the playbooks address them. A technique listed here means a playbook describes how to respond to it, not that detection exists for it.

64 techniques across 11 tactics.

## Initial Access (TA0001)

| Technique | Playbooks |
| --- | --- |
| [T1078 Valid Accounts](https://attack.mitre.org/techniques/T1078/) | [PB-PHI-001](Phishing/Credential%20phishing%20link.md), [PB-INS-002](Insider%20Threat/Unauthorised%20access%20to%20sensitive%20records.md), [PB-DEV-001](Lost%20Device/Lost%20laptop.md), [PB-DEV-002](Lost%20Device/Lost%20mobile%20phone.md) |
| [T1078.004 Valid Accounts: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/) | [PB-ACC-001](Account%20Compromise/Impossible%20travel%20sign-in.md), [PB-CLD-002](Cloud%20Misconfiguration/Leaked%20access%20key.md) |
| [T1133 External Remote Services](https://attack.mitre.org/techniques/T1133/) | [PB-CLD-005](Cloud%20Misconfiguration/Overly%20permissive%20network%20rule.md), [PB-VUL-003](Vulnerability%20Exploitation/VPN%20appliance%20compromise.md) |
| [T1190 Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/) | [PB-CLD-005](Cloud%20Misconfiguration/Overly%20permissive%20network%20rule.md), [PB-VUL-001](Vulnerability%20Exploitation/Public-facing%20application%20exploit.md), [PB-VUL-003](Vulnerability%20Exploitation/VPN%20appliance%20compromise.md) |
| [T1195.002 Supply Chain Compromise: Compromise Software Supply Chain](https://attack.mitre.org/techniques/T1195/002/) | [PB-VUL-006](Vulnerability%20Exploitation/Compromised%20software%20update.md) |
| [T1566 Phishing](https://attack.mitre.org/techniques/T1566/) | [PB-PHI-004](Phishing/reported_suspicious_email.md) |
| [T1566.001 Phishing: Spearphishing Attachment](https://attack.mitre.org/techniques/T1566/001/) | [PB-PHI-002](Phishing/Malicious%20attachment.md), [PB-PHI-005](Phishing/QR%20code%20phishing.md) |
| [T1566.002 Phishing: Spearphishing Link](https://attack.mitre.org/techniques/T1566/002/) | [PB-PHI-001](Phishing/Credential%20phishing%20link.md) |

## Execution (TA0002)

| Technique | Playbooks |
| --- | --- |
| [T1059.001 Command and Scripting Interpreter: PowerShell](https://attack.mitre.org/techniques/T1059/001/) | [PB-MAL-003](Malware/Malicious%20PowerShell%20execution.md) |
| [T1059.005 Command and Scripting Interpreter: Visual Basic](https://attack.mitre.org/techniques/T1059/005/) | [PB-PHI-002](Phishing/Malicious%20attachment.md) |
| [T1204.001 User Execution: Malicious Link](https://attack.mitre.org/techniques/T1204/001/) | [PB-PHI-001](Phishing/Credential%20phishing%20link.md), [PB-PHI-005](Phishing/QR%20code%20phishing.md) |
| [T1204.002 User Execution: Malicious File](https://attack.mitre.org/techniques/T1204/002/) | [PB-PHI-002](Phishing/Malicious%20attachment.md), [PB-MAL-001](Malware/Commodity%20malware%20detection.md) |

## Persistence (TA0003)

| Technique | Playbooks |
| --- | --- |
| [T1098 Account Manipulation](https://attack.mitre.org/techniques/T1098/) | [PB-ACC-006](Account%20Compromise/Privileged%20account%20misuse.md) |
| [T1176.001 Software Extensions: Browser Extensions](https://attack.mitre.org/techniques/T1176/001/) | [PB-MAL-005](Malware/Suspicious%20browser%20extension.md) |
| [T1505.003 Server Software Component: Web Shell](https://attack.mitre.org/techniques/T1505/003/) | [PB-VUL-002](Vulnerability%20Exploitation/Web%20shell%20discovered.md) |
| [T1547.001 Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder](https://attack.mitre.org/techniques/T1547/001/) | [PB-MAL-001](Malware/Commodity%20malware%20detection.md) |

## Privilege Escalation (TA0004)

| Technique | Playbooks |
| --- | --- |
| [T1068 Exploitation for Privilege Escalation](https://attack.mitre.org/techniques/T1068/) | [PB-VUL-004](Vulnerability%20Exploitation/Privilege%20escalation%20exploit.md) |
| [T1078.002 Valid Accounts: Domain Accounts](https://attack.mitre.org/techniques/T1078/002/) | [PB-ACC-006](Account%20Compromise/Privileged%20account%20misuse.md), [PB-DEV-003](Lost%20Device/Stolen%20device%20with%20privileged%20access.md) |

## Defense Evasion (TA0005)

| Technique | Playbooks |
| --- | --- |
| [T1027 Obfuscated Files or Information](https://attack.mitre.org/techniques/T1027/) | [PB-MAL-003](Malware/Malicious%20PowerShell%20execution.md) |
| [T1562.001 Impair Defenses: Disable or Modify Tools](https://attack.mitre.org/techniques/T1562/001/) | [PB-RAN-006](Ransomware/Pre-encryption%20indicators.md) |
| [T1562.008 Impair Defenses: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/) | [PB-CLD-004](Cloud%20Misconfiguration/Audit%20logging%20disabled.md) |
| [T1564.008 Hide Artifacts: Email Hiding Rules](https://attack.mitre.org/techniques/T1564/008/) | [PB-ACC-004](Account%20Compromise/Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md) |
| [T1578.002 Modify Cloud Compute Infrastructure: Create Cloud Instance](https://attack.mitre.org/techniques/T1578/002/) | [PB-CLD-003](Cloud%20Misconfiguration/Unexpected%20compute%20resources.md) |
| [T1656 Impersonation](https://attack.mitre.org/techniques/T1656/) | [PB-PHI-003](Phishing/Business%20Email%20Compromise%20%28BEC%29.md) |

## Credential Access (TA0006)

| Technique | Playbooks |
| --- | --- |
| [T1003.001 OS Credential Dumping: LSASS Memory](https://attack.mitre.org/techniques/T1003/001/) | [PB-RAN-006](Ransomware/Pre-encryption%20indicators.md) |
| [T1110.003 Brute Force: Password Spraying](https://attack.mitre.org/techniques/T1110/003/) | [PB-ACC-003](Account%20Compromise/Password%20spraying.md) |
| [T1111 Multi-Factor Authentication Interception](https://attack.mitre.org/techniques/T1111/) | [PB-DEV-002](Lost%20Device/Lost%20mobile%20phone.md) |
| [T1539 Steal Web Session Cookie](https://attack.mitre.org/techniques/T1539/) | [PB-ACC-005](Account%20Compromise/Session%20token%20theft.md), [PB-MAL-002](Malware/Infostealer.md) |
| [T1552.001 Unsecured Credentials: Credentials In Files](https://attack.mitre.org/techniques/T1552/001/) | [PB-CLD-002](Cloud%20Misconfiguration/Leaked%20access%20key.md) |
| [T1555.003 Credentials from Password Stores: Credentials from Web Browsers](https://attack.mitre.org/techniques/T1555/003/) | [PB-MAL-002](Malware/Infostealer.md) |
| [T1557 Adversary-in-the-Middle](https://attack.mitre.org/techniques/T1557/) | [PB-ACC-005](Account%20Compromise/Session%20token%20theft.md) |
| [T1621 Multi-Factor Authentication Request Generation](https://attack.mitre.org/techniques/T1621/) | [PB-ACC-002](Account%20Compromise/MFA%20fatigue.md) |

## Lateral Movement (TA0008)

| Technique | Playbooks |
| --- | --- |
| [T1021.001 Remote Services: Remote Desktop Protocol](https://attack.mitre.org/techniques/T1021/001/) | [PB-RAN-006](Ransomware/Pre-encryption%20indicators.md) |
| [T1021.002 Remote Services: SMB/Windows Admin Shares](https://attack.mitre.org/techniques/T1021/002/) | [PB-RAN-004](Ransomware/Mass%20file%20encryption%20on%20file%20share.md) |
| [T1210 Exploitation of Remote Services](https://attack.mitre.org/techniques/T1210/) | [PB-VUL-005](Vulnerability%20Exploitation/Exploitation%20of%20remote%20services.md) |
| [T1534 Internal Spearphishing](https://attack.mitre.org/techniques/T1534/) | [PB-PHI-003](Phishing/Business%20Email%20Compromise%20%28BEC%29.md) |
| [T1550.001 Use Alternate Authentication Material: Application Access Token](https://attack.mitre.org/techniques/T1550/001/) | [PB-ACC-005](Account%20Compromise/Session%20token%20theft.md) |

## Collection (TA0009)

| Technique | Playbooks |
| --- | --- |
| [T1005 Data from Local System](https://attack.mitre.org/techniques/T1005/) | [PB-INS-003](Insider%20Threat/Removable%20media%20misuse.md), [PB-DEV-001](Lost%20Device/Lost%20laptop.md), [PB-DEV-003](Lost%20Device/Stolen%20device%20with%20privileged%20access.md) |
| [T1025 Data from Removable Media](https://attack.mitre.org/techniques/T1025/) | [PB-DEV-004](Lost%20Device/Lost%20removable%20media.md) |
| [T1074.001 Data Staged: Local Data Staging](https://attack.mitre.org/techniques/T1074/001/) | [PB-EXF-003](Data%20Exfiltration/Staged%20archive%20creation.md) |
| [T1114.003 Email Collection: Email Forwarding Rule](https://attack.mitre.org/techniques/T1114/003/) | [PB-PHI-003](Phishing/Business%20Email%20Compromise%20%28BEC%29.md), [PB-ACC-004](Account%20Compromise/Revisi%C3%B3n%20de%20reglas%20de%20buz%C3%B3n.md) |
| [T1213 Data from Information Repositories](https://attack.mitre.org/techniques/T1213/) | [PB-INS-001](Insider%20Threat/Departing%20employee%20data%20collection.md) |
| [T1213.002 Data from Information Repositories: Sharepoint](https://attack.mitre.org/techniques/T1213/002/) | [PB-EXF-005](Data%20Exfiltration/Bulk%20download%20from%20document%20repository.md) |
| [T1530 Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/) | [PB-EXF-005](Data%20Exfiltration/Bulk%20download%20from%20document%20repository.md), [PB-CLD-001](Cloud%20Misconfiguration/Publicly%20exposed%20storage.md) |
| [T1560.001 Archive Collected Data: Archive via Utility](https://attack.mitre.org/techniques/T1560/001/) | [PB-EXF-003](Data%20Exfiltration/Staged%20archive%20creation.md) |

## Exfiltration (TA0010)

| Technique | Playbooks |
| --- | --- |
| [T1041 Exfiltration Over C2 Channel](https://attack.mitre.org/techniques/T1041/) | [PB-MAL-002](Malware/Infostealer.md), [PB-EXF-002](Data%20Exfiltration/Large%20outbound%20transfer.md) |
| [T1048 Exfiltration Over Alternative Protocol](https://attack.mitre.org/techniques/T1048/) | [PB-EXF-002](Data%20Exfiltration/Large%20outbound%20transfer.md), [PB-EXF-004](Data%20Exfiltration/DNS%20tunnelling.md) |
| [T1052.001 Exfiltration Over Physical Medium: Exfiltration over USB](https://attack.mitre.org/techniques/T1052/001/) | [PB-INS-001](Insider%20Threat/Departing%20employee%20data%20collection.md), [PB-INS-003](Insider%20Threat/Removable%20media%20misuse.md) |
| [T1567.002 Exfiltration Over Web Service: Exfiltration to Cloud Storage](https://attack.mitre.org/techniques/T1567/002/) | [PB-EXF-001](Data%20Exfiltration/Upload%20to%20personal%20cloud%20storage.md) |

## Command and Control (TA0011)

| Technique | Playbooks |
| --- | --- |
| [T1071.001 Application Layer Protocol: Web Protocols](https://attack.mitre.org/techniques/T1071/001/) | [PB-MAL-004](Malware/Command%20and%20control%20beaconing.md) |
| [T1071.004 Application Layer Protocol: DNS](https://attack.mitre.org/techniques/T1071/004/) | [PB-MAL-004](Malware/Command%20and%20control%20beaconing.md), [PB-EXF-004](Data%20Exfiltration/DNS%20tunnelling.md) |
| [T1105 Ingress Tool Transfer](https://attack.mitre.org/techniques/T1105/) | [PB-MAL-003](Malware/Malicious%20PowerShell%20execution.md) |

## Impact (TA0040)

| Technique | Playbooks |
| --- | --- |
| [T1485 Data Destruction](https://attack.mitre.org/techniques/T1485/) | [PB-RAN-003](Ransomware/Backup%20deletion%20attempt.md), [PB-INS-004](Insider%20Threat/Sabotage%20by%20privileged%20user.md) |
| [T1486 Data Encrypted for Impact](https://attack.mitre.org/techniques/T1486/) | [PB-RAN-001](Ransomware/Contenci%C3%B3n%20inicial.md), [PB-RAN-002](Ransomware/Ransom%20note%20discovered.md), [PB-RAN-004](Ransomware/Mass%20file%20encryption%20on%20file%20share.md), [PB-RAN-005](Ransomware/Recovery%20and%20restoration.md) |
| [T1489 Service Stop](https://attack.mitre.org/techniques/T1489/) | [PB-INS-004](Insider%20Threat/Sabotage%20by%20privileged%20user.md) |
| [T1490 Inhibit System Recovery](https://attack.mitre.org/techniques/T1490/) | [PB-RAN-001](Ransomware/Contenci%C3%B3n%20inicial.md), [PB-RAN-003](Ransomware/Backup%20deletion%20attempt.md) |
| [T1496 Resource Hijacking](https://attack.mitre.org/techniques/T1496/) | [PB-CLD-003](Cloud%20Misconfiguration/Unexpected%20compute%20resources.md) |
| [T1498 Network Denial of Service](https://attack.mitre.org/techniques/T1498/) | [PB-DOS-004](DDoS/Extortion%20DDoS%20threat.md) |
| [T1498.001 Network Denial of Service: Direct Network Flood](https://attack.mitre.org/techniques/T1498/001/) | [PB-DOS-001](DDoS/Volumetric%20attack.md) |
| [T1498.002 Network Denial of Service: Reflection Amplification](https://attack.mitre.org/techniques/T1498/002/) | [PB-DOS-002](DDoS/Reflection%20amplification.md) |
| [T1499.002 Endpoint Denial of Service: Service Exhaustion Flood](https://attack.mitre.org/techniques/T1499/002/) | [PB-DOS-003](DDoS/Application%20layer%20flood.md) |
| [T1499.003 Endpoint Denial of Service: Application Exhaustion Flood](https://attack.mitre.org/techniques/T1499/003/) | [PB-DOS-003](DDoS/Application%20layer%20flood.md) |
| [T1531 Account Access Removal](https://attack.mitre.org/techniques/T1531/) | [PB-INS-004](Insider%20Threat/Sabotage%20by%20privileged%20user.md) |
| [T1657 Financial Theft](https://attack.mitre.org/techniques/T1657/) | [PB-PHI-003](Phishing/Business%20Email%20Compromise%20%28BEC%29.md), [PB-RAN-002](Ransomware/Ransom%20note%20discovered.md), [PB-DOS-004](DDoS/Extortion%20DDoS%20threat.md) |
