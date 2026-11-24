#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../src/PlaybookSite/PlaybookSite.psd1') -Force
}

Describe 'ConvertTo-PlaybookSlug' {
    It 'removes accents and symbols' {
        ConvertTo-PlaybookSlug -Name 'Respuesta a Incidentes – Phishing (v2)' | Should -Be 'respuesta-a-incidentes-phishing-v2'
    }
    It 'handles Spanish characters' {
        ConvertTo-PlaybookSlug -Name 'Contraseña Comprometida' | Should -Be 'contrasena-comprometida'
    }
    It 'returns an empty string for names with no usable characters' {
        ConvertTo-PlaybookSlug -Name '###' | Should -Be ''
    }
    It 'truncates to the maximum length without a trailing hyphen' {
        $slug = ConvertTo-PlaybookSlug -Name ('a' * 79 + ' b') -MaxLength 80
        $slug.Length | Should -BeLessOrEqual 80
        $slug | Should -Not -Match '-$'
    }
}

InModuleScope PlaybookSite {

    Describe 'Path helpers' {
        It 'builds relative URLs between folders' {
            Get-PlaybookRelativeUrl -FromDirectory 'a/b' -ToPath 'assets/a/x.png' | Should -Be '../../assets/a/x.png'
            Get-PlaybookRelativeUrl -FromDirectory '' -ToPath 'x/y.md' | Should -Be 'x/y.md'
            Get-PlaybookRelativeUrl -FromDirectory 'a' -ToPath 'a/index.md' | Should -Be 'index.md'
            Get-PlaybookRelativeUrl -FromDirectory 'a/b' -ToPath 'a/c/d.md' | Should -Be '../c/d.md'
        }
        It 'resolves dot segments and refuses to escape the root' {
            Resolve-PlaybookRelativePath -BaseDirectory 'a/b' -RelativePath '../c/./d.md' | Should -Be 'a/c/d.md'
            Resolve-PlaybookRelativePath -BaseDirectory 'a' -RelativePath '../../x.md' | Should -BeNullOrEmpty
        }
    }

    Describe 'Get-PlaybookPathMap' {
        BeforeEach {
            $ctx = [pscustomobject]@{
                Errors   = [System.Collections.Generic.List[object]]::new()
                Warnings = [System.Collections.Generic.List[object]]::new()
            }
            $config = @{ slug = @{ maxLength = 80 } }
        }
        It 'maps pages, README and assets' {
            $inventory = @(
                [pscustomobject]@{ RelativePath = 'Ransomware/README.md'; Kind = 'Page' }
                [pscustomobject]@{ RelativePath = 'Ransomware/Contención Inicial.md'; Kind = 'Page' }
                [pscustomobject]@{ RelativePath = 'Ransomware/img/Flow Chart.PNG'; Kind = 'Asset' }
            )
            $map = Get-PlaybookPathMap -Inventory $inventory -Config $config -Context $ctx
            $map['Ransomware/README.md'] | Should -Be 'ransomware/index.md'
            $map['Ransomware/Contención Inicial.md'] | Should -Be 'ransomware/contencion-inicial.md'
            $map['Ransomware/img/Flow Chart.PNG'] | Should -Be 'assets/ransomware/img/flow-chart.png'
            $ctx.Errors.Count | Should -Be 0
        }
        It 'reports a collision when two names normalize to the same target' {
            $inventory = @(
                [pscustomobject]@{ RelativePath = 'Phishing/Triage.md'; Kind = 'Page' }
                [pscustomobject]@{ RelativePath = 'Phishing/triage .md'; Kind = 'Page' }
            )
            $null = Get-PlaybookPathMap -Inventory $inventory -Config $config -Context $ctx
            $ctx.Errors.Count | Should -Be 1
            $ctx.Errors[0].Code | Should -Be 'NameCollision'
        }
    }

    Describe 'ConvertTo-PlaybookNormalizedMarkdown' {
        It 'normalizes line endings and keeps an existing H1' {
            $r = ConvertTo-PlaybookNormalizedMarkdown -Text "# Phishing`r`n`r`nStep 1`r`n" -FallbackTitle 'x'
            $r.Text | Should -Be "# Phishing`n`nStep 1`n"
            $r.Title | Should -Be 'Phishing'
            $r.Issues | Should -BeNullOrEmpty
        }
        It 'adds a title from the file name when there is no H1' {
            $r = ConvertTo-PlaybookNormalizedMarkdown -Text "Some text`n" -FallbackTitle 'Lateral Movement'
            $r.Text | Should -BeLike '# Lateral Movement*'
            $r.Issues | Should -Contain 'TitleAdded'
        }
        It 'ignores a heading inside a code fence' {
            $r = ConvertTo-PlaybookNormalizedMarkdown -Text "``````bash`n# not a title`n```````n" -FallbackTitle 'Real'
            $r.Title | Should -Be 'Real'
        }
        It 'strips front matter when asked' {
            $r = ConvertTo-PlaybookNormalizedMarkdown -Text "---`nowner: soc`n---`n# T`n" -FallbackTitle 'x' -FrontMatter strip
            $r.Text | Should -Be "# T`n"
        }
        It 'keeps front matter by default' {
            $r = ConvertTo-PlaybookNormalizedMarkdown -Text "---`nowner: soc`n---`n# T`n" -FallbackTitle 'x'
            $r.Text | Should -BeLike "---`nowner: soc`n---*"
        }
        It 'flags unclosed front matter' {
            $r = ConvertTo-PlaybookNormalizedMarkdown -Text "---`nowner: soc`n# T`n" -FallbackTitle 'x'
            $r.Issues | Should -Contain 'UnclosedFrontMatter'
        }
    }

    Describe 'Update-PlaybookLinks' {
        BeforeAll {
            $map = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
            $map['Ransomware/README.md'] = 'ransomware/index.md'
            $map['Ransomware/Contención Inicial.md'] = 'ransomware/contencion-inicial.md'
            $map['Phishing/Triage.md'] = 'phishing/triage.md'
            $map['Ransomware/img/Flow Chart.png'] = 'assets/ransomware/img/flow-chart.png'
        }
        It 'rewrites a relative page link and keeps the anchor' {
            $r = Update-PlaybookLinks -Text 'See [triage](../Phishing/Triage.md#scope).' -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Text | Should -Be 'See [triage](../phishing/triage.md#scope).'
        }
        It 'decodes URL-encoded names' {
            $r = Update-PlaybookLinks -Text '[c](Contenci%C3%B3n%20Inicial.md)' -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Text | Should -Be '[c](contencion-inicial.md)'
        }
        It 'rewrites an image and reports the asset to copy' {
            $r = Update-PlaybookLinks -Text '![flow](img/Flow%20Chart.png "Flow")' -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Text | Should -Be '![flow](../assets/ransomware/img/flow-chart.png "Flow")'
            ($r.Results | Where-Object Status -eq 'Rewritten').AssetSource | Should -Be 'Ransomware/img/Flow Chart.png'
        }
        It 'rewrites reference definitions and HTML images' {
            $text = "[t]: ../Phishing/Triage.md`n<img src=""img/Flow Chart.png"" width=""400"">"
            $r = Update-PlaybookLinks -Text $text -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Text | Should -Be "[t]: ../phishing/triage.md`n<img src=""../assets/ransomware/img/flow-chart.png"" width=""400"">"
        }
        It 'leaves external links, anchors, code fences and inline code alone' {
            $text = "[ms](https://learn.microsoft.com) [top](#top) ``[x](Nope.md)```n```````n[y](Nope.md)`n``````"
            $r = Update-PlaybookLinks -Text $text -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Text | Should -Be $text
            @($r.Results | Where-Object Status -eq 'Unresolved').Count | Should -Be 0
        }
        It 'marks a missing target as unresolved' {
            $r = Update-PlaybookLinks -Text '[gone](Missing.md)' -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Results[0].Status | Should -Be 'Unresolved'
        }
        It 'accepts a case mismatch but flags it' {
            $r = Update-PlaybookLinks -Text '[t](../phishing/triage.md)' -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map
            $r.Results[0].Status | Should -Be 'Rewritten'
            $r.Results[0].CaseMismatch | Should -BeTrue
        }
        It 'blocks external links when they are not allowed' {
            $r = Update-PlaybookLinks -Text '[x](https://example.org)' -SourcePath 'Ransomware/README.md' -TargetPath 'ransomware/index.md' -PathMap $map -AllowExternal $false
            $r.Results[0].Status | Should -Be 'Blocked'
        }
    }

    Describe 'Secret scan' {
        BeforeAll {
            $config = @{
                secretScan = @{
                    allowlist              = @()
                    internalCidrs          = @('10.0.0.0/8', '192.168.0.0/16')
                    internalDomainSuffixes = @('corp.example.com')
                    internalAction         = 'block'
                    extraRules             = @()
                }
            }
            $rules = Get-PlaybookSecretRules -Config $config
        }
        It 'detects an AWS key and never returns the raw value' {
            $f = @(Find-PlaybookSecrets -Text 'key AKIAABCDEFGHIJKLMNOP here' -Path 'a.md' -Rules $rules -Config $config)
            $f.Count | Should -Be 1
            $f[0].Rule | Should -Be 'aws-access-key'
            $f[0].Preview | Should -Not -Match 'AKIAABCDEFGHIJKLMNOP'
        }
        It 'detects a password inside a code block' {
            $f = @(Find-PlaybookSecrets -Text "```````n`$cs = 'Server=db;User Id=sa;Password=Sup3rS3cret!;'`n``````" -Path 'a.md' -Rules $rules -Config $config)
            $f.Rule | Should -Contain 'connection-password'
        }
        It 'ignores obvious placeholders' {
            @(Find-PlaybookSecrets -Text 'password: <YOUR_PASSWORD>' -Path 'a.md' -Rules $rules -Config $config).Count | Should -Be 0
            @(Find-PlaybookSecrets -Text 'Password=********' -Path 'a.md' -Rules $rules -Config $config).Count | Should -Be 0
        }
        It 'flags internal IPs and host names but not public IPs' {
            @(Find-PlaybookSecrets -Text 'Isolate 10.20.30.40' -Path 'a.md' -Rules $rules -Config $config).Rule | Should -Contain 'internal-ip'
            @(Find-PlaybookSecrets -Text 'Block 8.8.8.8' -Path 'a.md' -Rules $rules -Config $config).Count | Should -Be 0
            @(Find-PlaybookSecrets -Text 'Check dc01.corp.example.com' -Path 'a.md' -Rules $rules -Config $config).Rule | Should -Contain 'internal-hostname'
        }
        It 'suppresses an allowlisted fingerprint' {
            $first = @(Find-PlaybookSecrets -Text 'Isolate 10.20.30.40' -Path 'a.md' -Rules $rules -Config $config)[0]
            $allowConfig = @{ secretScan = $config.secretScan.Clone() }
            $allowConfig.secretScan.allowlist = @($first.Fingerprint)
            @(Find-PlaybookSecrets -Text 'Isolate 10.20.30.40' -Path 'a.md' -Rules $rules -Config $allowConfig)[0].Allowlisted | Should -BeTrue
        }
    }

    Describe 'Test-PlaybookIpInCidr' {
        It 'matches addresses inside the range' {
            Test-PlaybookIpInCidr -Address '172.16.5.4' -Cidr '172.16.0.0/12' | Should -BeTrue
            Test-PlaybookIpInCidr -Address '172.32.0.1' -Cidr '172.16.0.0/12' | Should -BeFalse
            Test-PlaybookIpInCidr -Address '1.2.3.4' -Cidr '0.0.0.0/0' | Should -BeTrue
            Test-PlaybookIpInCidr -Address '10.0.0.1' -Cidr '10.0.0.1' | Should -BeTrue
        }
    }

    Describe 'New-PlaybookNavYaml' {
        It 'puts the index first, follows the order file, then sorts alphabetically' {
            $pages = @(
                [pscustomobject]@{ SourcePath = 'Ransomware/Zeta.md'; TargetPath = 'ransomware/zeta.md'; Title = 'Zeta' }
                [pscustomobject]@{ SourcePath = 'Ransomware/Alpha.md'; TargetPath = 'ransomware/alpha.md'; Title = 'Alpha' }
                [pscustomobject]@{ SourcePath = 'Ransomware/Detect.md'; TargetPath = 'ransomware/detect.md'; Title = 'Detect' }
                [pscustomobject]@{ SourcePath = 'Ransomware/README.md'; TargetPath = 'ransomware/index.md'; Title = 'Ransomware' }
            )
            $yaml = New-PlaybookNavYaml -Pages $pages -OrderLists @{ 'Ransomware' = @('Detect') }
            $lines = $yaml.Split("`n")
            $lines[0] | Should -Be 'nav:'
            $lines[1] | Should -Be "  - 'Ransomware':"
            $lines[2] | Should -Be "      - 'Ransomware': 'ransomware/index.md'"
            $lines[3] | Should -Be "      - 'Detect': 'ransomware/detect.md'"
            $lines[4] | Should -Be "      - 'Alpha': 'ransomware/alpha.md'"
            $lines[5] | Should -Be "      - 'Zeta': 'ransomware/zeta.md'"
        }
        It 'escapes single quotes in titles' {
            $pages = @([pscustomobject]@{ SourcePath = 'x.md'; TargetPath = 'x.md'; Title = "Attacker's tools" })
            (New-PlaybookNavYaml -Pages $pages -OrderLists @{}) | Should -BeLike "*'Attacker''s tools'*"
        }
    }

    Describe 'Compare-PlaybookManifest' {
        It 'reports added, changed, removed and no-change' {
            $current = [ordered]@{ contentHash = 'h2'; files = [ordered]@{ 'a.md' = '1'; 'b.md' = '2x'; 'c.md' = '3' } }
            $deployed = @{ contentHash = 'h1'; files = @{ 'a.md' = '1'; 'b.md' = '2'; 'd.md' = '4' } }
            $d = Compare-PlaybookManifest -Current $current -Deployed $deployed
            $d.Added | Should -Be @('c.md')
            $d.Changed | Should -Be @('b.md')
            $d.Removed | Should -Be @('d.md')
            $d.Unchanged | Should -Be 1
            $d.NoChanges | Should -BeFalse
        }
        It 'treats a missing deployed manifest as a first deployment' {
            $current = [ordered]@{ contentHash = 'h'; files = [ordered]@{ 'a.md' = '1' } }
            $d = Compare-PlaybookManifest -Current $current -Deployed $null
            $d.FirstDeployment | Should -BeTrue
            $d.NoChanges | Should -BeFalse
        }
    }

    Describe 'Expand-PlaybookConfigVariables' {
        BeforeAll { $env:PLAYBOOK_TEST_TENANT = 'tenant-123' }
        AfterAll { Remove-Item Env:PLAYBOOK_TEST_TENANT -ErrorAction SilentlyContinue }

        It 'replaces set variables, including inside arrays and nested tables' {
            $r = Expand-PlaybookConfigVariables -Value @{ azure = @{ tenantId = '${PLAYBOOK_TEST_TENANT}'; ids = @('${PLAYBOOK_TEST_TENANT}') } }
            $r.azure.tenantId | Should -Be 'tenant-123'
            $r.azure.ids[0] | Should -Be 'tenant-123'
        }
        It 'leaves unset variables as placeholders' {
            Expand-PlaybookConfigVariables -Value '${PLAYBOOK_TEST_NOT_SET}' | Should -Be '${PLAYBOOK_TEST_NOT_SET}'
        }
        It 'refuses remote stages while a placeholder is unresolved' {
            $cfg = @{ azure = @{ subscriptionId = '${PLAYBOOK_TEST_NOT_SET}'; resourceGroup = 'rg'; appName = 'app'; slot = 'staging'; tenantId = 't'; clientId = 'c' } }
            { Assert-PlaybookAzureConfig -Config $cfg } | Should -Throw '*not set*'
        }
    }

    Describe 'Read-PlaybookConfig' {
        It 'refuses a work folder inside the source folder' {
            $src = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'src') -Force
            $cfg = Join-Path $TestDrive 'bad.json'
            @{ sourcePath = $src.FullName; workPath = (Join-Path $src.FullName 'work') } | ConvertTo-Json | Set-Content $cfg
            { Read-PlaybookConfig -Path $cfg } | Should -Throw '*overlaps*'
        }
    }
}

Describe 'Publish-PlaybookSite -Offline (end to end)' -Tag 'Integration' {
    BeforeAll {
        $python = Get-Command python, python3 -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        $canBuild = $false
        if ($python) {
            & $python.Source -m mkdocs --version *> $null
            $canBuild = ($LASTEXITCODE -eq 0)
        }

        $root = Join-Path $TestDrive 'repo'
        $src = New-Item -ItemType Directory -Path (Join-Path $root 'playbooks/Ransomware/img') -Force
        Set-Content -LiteralPath (Join-Path $root 'playbooks/Ransomware/README.md') -Value "# Ransomware`n`nStart with [containment](Contención%20Inicial.md).`n`n![flow](img/flow.png)"
        Set-Content -LiteralPath (Join-Path $root 'playbooks/Ransomware/Contención Inicial.md') -Value "# Contención inicial`n`nIsolate the host. Back to [overview](README.md)."
        [System.IO.File]::WriteAllBytes((Join-Path $src.FullName 'flow.png'), [byte[]](0x89, 0x50, 0x4E, 0x47))
        $cfg = Join-Path $root 'config.json'
        @{ sourcePath = 'playbooks'; workPath = '.work'; build = @{ python = $(if ($python) { $python.Source } else { 'python' }) } } |
            ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $cfg
    }

    It 'validates, builds and zips the site' {
        if (-not $canBuild) { Set-ItResult -Skipped -Because 'MkDocs is not installed' ; return }
        $r = Publish-PlaybookSite -ConfigPath $cfg -Offline
        $r.Result | Should -Be 'ValidatedOffline'
        $r.Errors | Should -Be 0
        Test-Path (Join-Path $root '.work/site.zip') | Should -BeTrue
        Test-Path (Join-Path $root '.work/site/ransomware/contencion-inicial/index.html') | Should -BeTrue
        Test-Path (Join-Path $root '.work/site/_manifest.json') | Should -BeTrue
        Test-Path (Join-Path $root '.work/report/report.json') | Should -BeTrue
    }

    It 'fails closed when a page contains a secret' {
        if (-not $canBuild) { Set-ItResult -Skipped -Because 'MkDocs is not installed' ; return }
        Add-Content -LiteralPath (Join-Path $root 'playbooks/Ransomware/README.md') -Value "`nkey AKIAABCDEFGHIJKLMNOP"
        { Publish-PlaybookSite -ConfigPath $cfg -Offline } | Should -Throw "*SecretScan*"
        $report = Get-Content (Join-Path $root '.work/report/report.json') -Raw
        $report | Should -Not -Match 'AKIAABCDEFGHIJKLMNOP'
    }
}
