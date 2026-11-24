---
dummy: true
id: NEG-SEC-001
test_case: secret-scan
---

# Service account handover

Fictional test fixture. Every value below is fabricated and must be blocked by the F5 secret scan.

Connect to the file server `fs01.contoso.example` at 10.20.30.40 before rotating the account.

```text
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
Server=sql01;Database=Cases;User Id=svc_cases;Password=Winter2026Fabricated!;
```
