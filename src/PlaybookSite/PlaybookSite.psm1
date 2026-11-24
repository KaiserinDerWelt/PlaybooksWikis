#Requires -Version 7.4
<#
    PlaybookSite module
    Validates, normalizes, builds and deploys the SOC incident-handling playbooks
    as a static MkDocs site on Azure App Service (private endpoint + Easy Auth).

    Stage map (matches the task definition):
      F1  Inventory         Get-PlaybookInventory
      F2  NormalizeNames    Get-PlaybookPathMap
      F3  NormalizeContent  ConvertTo-PlaybookNormalizedMarkdown
      F4  LinksAndAssets    Update-PlaybookLinks
      F5  SecretScan        Find-PlaybookSecrets
      F6  Navigation        New-PlaybookMkDocsConfig
      F7  Build             Invoke-PlaybookBuild
      F8  Diff              Compare-PlaybookManifest
      F9  Preflight         Test-PlaybookPreflight
      F10 Deploy            Invoke-PlaybookDeploy
      F11 Report            Write-PlaybookReport (always runs)

    Design rules:
      - Fail closed: any error in a stage stops the run before anything is deployed.
      - Logs and reports never contain playbook content or secret values.
      - Local stages (F1-F7) need no Azure access; -Offline runs only those.
#>

Set-StrictMode -Version Latest

$script:StageNames = @(
    'Inventory', 'NormalizeNames', 'NormalizeContent', 'LinksAndAssets',
    'SecretScan', 'Navigation', 'Build', 'Diff', 'Preflight', 'Deploy'
)
$script:ManifestFileName = '_manifest.json'
$script:ArmResource = 'https://management.azure.com/'
$script:GraphResource = 'https://graph.microsoft.com/'

foreach ($assembly in 'System.IO.Compression', 'System.IO.Compression.ZipFile') {
    try { Add-Type -AssemblyName $assembly -ErrorAction Stop } catch { Write-Verbose "Assembly $assembly already available." }
}

#region ---------- Generic helpers ----------

function Merge-PlaybookHashtable {
    param([hashtable]$Default, [hashtable]$Override)
    $result = @{}
    foreach ($key in $Default.Keys) { $result[$key] = $Default[$key] }
    if ($null -eq $Override) { return $result }
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key) -and $result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $result[$key] = Merge-PlaybookHashtable -Default $result[$key] -Override $Override[$key]
        }
        else {
            $result[$key] = $Override[$key]
        }
    }
    return $result
}

function Get-PlaybookShortHash {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text, [int]$Length = 8)
    $bytes = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Text))
    return ([System.Convert]::ToHexString($bytes).ToLowerInvariant()).Substring(0, $Length)
}

function Get-PlaybookRelativeUrl {
    <#
        Relative URL from a directory to a file, both given as '/'-separated paths
        relative to the same root. Pure string logic: no dependency on the current
        directory or on the OS path separator.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$FromDirectory,
        [Parameter(Mandatory)][string]$ToPath
    )
    $from = @($FromDirectory.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries))
    $to = @($ToPath.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries))
    $common = 0
    while ($common -lt $from.Count -and $common -lt ($to.Count - 1) -and $from[$common] -eq $to[$common]) { $common++ }
    $up = @(for ($i = $common; $i -lt $from.Count; $i++) { '..' })
    $down = @(for ($i = $common; $i -lt $to.Count; $i++) { $to[$i] })
    return (@($up) + @($down)) -join '/'
}

function Resolve-PlaybookRelativePath {
    <# Joins a '/'-separated relative path onto a base directory and resolves '.' and '..'. Returns $null if it escapes the root. #>
    param([AllowEmptyString()][string]$BaseDirectory, [Parameter(Mandatory)][string]$RelativePath)
    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $BaseDirectory.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)) { $parts.Add($p) }
    foreach ($p in $RelativePath.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)) {
        if ($p -eq '.') { continue }
        if ($p -eq '..') {
            if ($parts.Count -eq 0) { return $null }
            $parts.RemoveAt($parts.Count - 1)
            continue
        }
        $parts.Add($p)
    }
    return ($parts -join '/')
}

function Get-PlaybookParentPath {
    param([Parameter(Mandatory)][string]$Path)
    $i = $Path.LastIndexOf('/')
    if ($i -lt 0) { return '' }
    return $Path.Substring(0, $i)
}

function Get-PlaybookFenceMask {
    <# Returns a bool per line: $true when the line is a code-fence line or inside a fenced block. #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Lines)
    $mask = [bool[]]::new($Lines.Count)
    $open = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $m = [regex]::Match($Lines[$i], '^\s{0,3}(?<fence>`{3,}|~{3,})')
        if ($null -eq $open) {
            if ($m.Success) { $open = $m.Groups['fence'].Value; $mask[$i] = $true }
        }
        else {
            $mask[$i] = $true
            if ($m.Success -and $m.Groups['fence'].Value[0] -eq $open[0] -and $m.Groups['fence'].Value.Length -ge $open.Length -and
                $Lines[$i].Trim() -eq $m.Groups['fence'].Value) {
                $open = $null
            }
        }
    }
    return , $mask
}

function ConvertTo-PlaybookYamlString {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    return "'" + $Value.Replace("'", "''") + "'"
}

function Add-PlaybookIssue {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][ValidateSet('Error', 'Warning')][string]$Level,
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Message,
        [string]$Path
    )
    $issue = [pscustomobject]@{ Stage = $Stage; Code = $Code; Path = $Path; Message = $Message }
    if ($Level -eq 'Error') { $Context.Errors.Add($issue) } else { $Context.Warnings.Add($issue) }
}

function Get-PlaybookValue {
    <# Safe nested lookup ('a.b.c') over hashtables and objects; returns $null for any missing step (strict-mode safe). #>
    param($Object, [Parameter(Mandatory)][string]$Path)
    $current = $Object
    foreach ($part in $Path.Split('.')) {
        if ($null -eq $current) { return $null }
        if ($current -is [System.Collections.IDictionary]) {
            if (-not $current.Contains($part)) { return $null }
            $current = $current[$part]
        }
        else {
            $property = $current.PSObject.Properties[$part]
            if (-not $property) { return $null }
            $current = $property.Value
        }
    }
    return $current
}

function Get-PlaybookAccessToken {
    param([string]$ResourceUrl = $script:ArmResource)
    $token = Get-AzAccessToken -ResourceUrl $ResourceUrl -ErrorAction Stop
    # Az.Accounts 5+ returns a SecureString; older versions return plain text.
    if ($token.Token -is [securestring]) { return (ConvertFrom-SecureString -SecureString $token.Token -AsPlainText) }
    return [string]$token.Token
}

function Assert-PlaybookAzureModules {
    foreach ($name in 'Az.Accounts', 'Az.Websites') {
        if (-not (Get-Module -ListAvailable -Name $name)) {
            throw "Module '$name' is required for the remote stages (Diff, Preflight, Deploy). Install it on the agent, or run with -Offline."
        }
    }
    if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
        throw 'No Azure context. Run inside the AzurePowerShell@5 task (workload identity federation) or Connect-AzAccount first.'
    }
}

function Invoke-PlaybookArmGet {
    param([Parameter(Mandatory)][string]$Path, [string]$ApiVersion = '2024-04-01', [switch]$AllowNotFound)
    $response = Invoke-AzRestMethod -Method GET -Path "$($Path)?api-version=$ApiVersion" -ErrorAction Stop
    if ($AllowNotFound -and $response.StatusCode -eq 404) { return $null }
    if ($response.StatusCode -ge 400) { throw "ARM GET $Path returned $($response.StatusCode)." }
    return ($response.Content | ConvertFrom-Json -Depth 20 -AsHashtable)
}

function Get-PlaybookSitePath {
    param([Parameter(Mandatory)][hashtable]$Azure, [string]$Slot)
    $path = "/subscriptions/$($Azure.subscriptionId)/resourceGroups/$($Azure.resourceGroup)/providers/Microsoft.Web/sites/$($Azure.appName)"
    if ($Slot -and $Slot -ne 'production') { $path += "/slots/$Slot" }
    return $path
}

function Get-PlaybookHostName {
    <# Returns the site or SCM host name of the app or slot from ARM (works for private-endpoint and custom DNS setups). #>
    param([Parameter(Mandatory)][hashtable]$Azure, [string]$Slot, [switch]$Scm)
    $site = Invoke-PlaybookArmGet -Path (Get-PlaybookSitePath -Azure $Azure -Slot $Slot)
    $names = @(Get-PlaybookValue $site 'properties.enabledHostNames')
    $hostName = if ($Scm) { $names | Where-Object { $_ -like '*.scm.*' } | Select-Object -First 1 }
                else { $names | Where-Object { $_ -notlike '*.scm.*' } | Select-Object -First 1 }
    if (-not $hostName) { throw "Could not find the $(if ($Scm) { 'SCM' } else { 'site' }) host name for slot '$Slot'." }
    return $hostName
}

function Get-PlaybookDeployedManifest {
    param([Parameter(Mandatory)][hashtable]$Azure, [string]$Slot = 'production')
    $scmHost = Get-PlaybookHostName -Azure $Azure -Slot $Slot -Scm
    $headers = @{ Authorization = "Bearer $(Get-PlaybookAccessToken)" }
    $response = Invoke-WebRequest -Uri "https://$scmHost/api/vfs/site/wwwroot/$($script:ManifestFileName)" -Headers $headers -SkipHttpErrorCheck -ErrorAction Stop
    if ($response.StatusCode -eq 404) { return $null }
    if ($response.StatusCode -ge 400) { throw "Reading the deployed manifest returned HTTP $($response.StatusCode)." }
    return ($response.Content | ConvertFrom-Json -Depth 10 -AsHashtable)
}

#endregion

#region ---------- Configuration ----------

function Read-PlaybookConfig {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Config file '$Path' not found." }
    $configFile = (Resolve-Path -LiteralPath $Path).ProviderPath
    $raw = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json -AsHashtable -Depth 20

    $defaults = @{
        siteName   = 'SOC Incident Playbooks'
        exclude    = @()
        slug       = @{ maxLength = 80 }
        content    = @{
            frontMatter      = 'keep'          # keep | strip
            fallbackEncoding = 'windows-1252'  # '' disables transcoding (non-UTF-8 files then fail)
            ensureTitle      = $true
            assetExtensions  = @('.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.pdf')
        }
        links      = @{ allowExternal = $true }
        navigation = @{ orderFileName = '_order.txt' }
        secretScan = @{
            allowlist              = @()
            internalCidrs          = @('10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16')
            internalDomainSuffixes = @()
            internalAction         = 'block'   # block | warn
            extraRules             = @()
        }
        build      = @{
            python          = 'python'
            language        = 'en'
            validateAnchors = 'warn'           # warn = strict build fails on broken #anchors; info = ignore
        }
        azure      = @{
            subscriptionId         = ''
            resourceGroup          = ''
            appName                = ''
            slot                   = 'staging'
            tenantId               = ''
            clientId               = ''
            allowedPrincipalIds    = @()
            requirePrivateEndpoint = $true
            checkEntraAssignment   = $true
            deployTimeoutMinutes   = 20
        }
    }
    $config = Merge-PlaybookHashtable -Default $defaults -Override $raw
    $config = Expand-PlaybookConfigVariables -Value $config

    foreach ($key in 'sourcePath', 'workPath') {
        if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace([string]$config[$key])) {
            throw "Config '$configFile' is missing required key '$key'."
        }
    }

    # Relative paths are resolved against the config file's folder, not the current directory.
    $base = Split-Path -Parent $configFile
    foreach ($key in 'sourcePath', 'workPath') {
        $value = [string]$config[$key]
        if (-not [System.IO.Path]::IsPathRooted($value)) { $value = Join-Path $base $value }
        $config[$key] = [System.IO.Path]::GetFullPath($value)
    }

    if (-not (Test-Path -LiteralPath $config.sourcePath -PathType Container)) {
        throw "sourcePath '$($config.sourcePath)' does not exist."
    }

    # The work folder is wiped on every run: refuse any overlap with the source tree.
    $src = $config.sourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    $work = $config.workPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if ($src.StartsWith($work, [System.StringComparison]::OrdinalIgnoreCase) -or $work.StartsWith($src, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "workPath '$($config.workPath)' overlaps sourcePath '$($config.sourcePath)'. They must be separate folders."
    }

    if ($config.content.frontMatter -notin 'keep', 'strip') { throw "content.frontMatter must be 'keep' or 'strip'." }
    if ($config.secretScan.internalAction -notin 'block', 'warn') { throw "secretScan.internalAction must be 'block' or 'warn'." }

    $config['configPath'] = $configFile
    return $config
}

function Expand-PlaybookConfigVariables {
    <#
        Replaces ${NAME} placeholders in config strings with environment variables, so the committed
        config holds variable names only (AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, ...), never IDs.
        Unset variables are left as the placeholder; Assert-PlaybookAzureConfig rejects them before
        any remote stage, while -Offline runs work without them.
    #>
    param($Value)
    if ($Value -is [string]) {
        return [regex]::Replace($Value, '\$\{(?<name>[A-Za-z_][A-Za-z0-9_]*)\}', {
                param($m)
                $resolved = [Environment]::GetEnvironmentVariable($m.Groups['name'].Value)
                if ([string]::IsNullOrEmpty($resolved)) { return $m.Value }
                return $resolved
            })
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $copy = @{}
        foreach ($key in @($Value.Keys)) { $copy[$key] = Expand-PlaybookConfigVariables -Value $Value[$key] }
        return $copy
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return , @(foreach ($item in $Value) { Expand-PlaybookConfigVariables -Value $item })
    }
    return $Value
}

function Assert-PlaybookAzureConfig {
    param([Parameter(Mandatory)][hashtable]$Config)
    foreach ($key in 'subscriptionId', 'resourceGroup', 'appName', 'slot', 'tenantId', 'clientId') {
        if ([string]::IsNullOrWhiteSpace([string]$Config.azure[$key])) { throw "azure.$key is required for the remote stages." }
    }
    $unresolved = @(foreach ($key in $Config.azure.Keys) {
            foreach ($v in @($Config.azure[$key])) { if ($v -is [string] -and $v -match '\$\{[A-Za-z_][A-Za-z0-9_]*\}') { "azure.$key ($v)" } }
        })
    if ($unresolved.Count -gt 0) {
        throw "Environment variable(s) not set for: $($unresolved -join ', '). Set them before running remote stages, or use -Offline."
    }
    if ($Config.azure.slot -eq 'production') { throw 'azure.slot must be a staging slot, not production.' }
}

#endregion

#region ---------- F1 Inventory ----------

function Get-PlaybookInventory {
    param([Parameter(Mandatory)][hashtable]$Config)

    $root = $Config.sourcePath
    $assetExtensions = @($Config.content.assetExtensions | ForEach-Object { $_.ToLowerInvariant() })
    $orderFile = [string]$Config.navigation.orderFileName

    foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
        $relative = [System.IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')

        # Skip hidden files and folders (.git, .vscode, .attachments handled via links only).
        if (@($relative.Split('/') | Where-Object { $_.StartsWith('.') }).Count -gt 0) { continue }

        $excluded = $false
        foreach ($pattern in @($Config.exclude)) { if ($relative -like $pattern) { $excluded = $true; break } }
        if ($excluded) { continue }

        $extension = $file.Extension.ToLowerInvariant()
        $kind = if ($extension -eq '.md') { 'Page' }
                elseif ($orderFile -and $file.Name -eq $orderFile) { 'Order' }
                elseif ($extension -in $assetExtensions) { 'Asset' }
                else { 'Other' }

        [pscustomobject]@{
            RelativePath = $relative
            FullPath     = $file.FullName
            Kind         = $kind
            Length       = $file.Length
            Sha256       = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
}

#endregion

#region ---------- F2 Normalize names ----------

function ConvertTo-PlaybookSlug {
    <#
    .SYNOPSIS
        Converts a file or folder name to a URL-safe slug: lowercase ASCII letters, digits and hyphens.
    .EXAMPLE
        ConvertTo-PlaybookSlug 'Respuesta a Incidentes – Phishing (v2)'   # respuesta-a-incidentes-phishing-v2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][string]$Name,
        [int]$MaxLength = 80
    )
    process {
        $decomposed = $Name.Normalize([System.Text.NormalizationForm]::FormD)
        $builder = [System.Text.StringBuilder]::new()
        foreach ($ch in $decomposed.ToCharArray()) {
            if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
                [void]$builder.Append($ch)
            }
        }
        $slug = ($builder.ToString().ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
        if ($slug.Length -gt $MaxLength) { $slug = $slug.Substring(0, $MaxLength).TrimEnd('-') }
        return $slug
    }
}

function Get-PlaybookPathMap {
    <#
        Maps every page and asset source path to its target path in the docs folder.
        Pages keep their folder structure; assets go under 'assets/'.
        Collisions after normalization are errors (two sources would overwrite one target).
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Inventory,
        [Parameter(Mandatory)][hashtable]$Config,
        [Parameter(Mandatory)]$Context
    )

    $maxLength = [int]$Config.slug.maxLength
    $map = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
    $targets = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($item in $Inventory | Where-Object { $_.Kind -in 'Page', 'Asset' }) {
        $segments = $item.RelativePath.Split('/')
        $folders = @(for ($i = 0; $i -lt $segments.Count - 1; $i++) {
                $s = ConvertTo-PlaybookSlug -Name $segments[$i] -MaxLength $maxLength
                if (-not $s) { $s = 'section-' + (Get-PlaybookShortHash -Text $segments[$i]) }
                $s
            })

        $fileName = $segments[-1]
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $extension = [System.IO.Path]::GetExtension($fileName).ToLowerInvariant()

        if ($item.Kind -eq 'Page') {
            $slug = if ($baseName -in 'readme', 'index') { 'index' } else { ConvertTo-PlaybookSlug -Name $baseName -MaxLength $maxLength }
            if (-not $slug) { $slug = 'page-' + (Get-PlaybookShortHash -Text $item.RelativePath) }
            $target = (@($folders) + "$slug.md") -join '/'
            if ($target -like 'assets/*') {
                Add-PlaybookIssue -Context $Context -Level Error -Stage 'NormalizeNames' -Code 'ReservedFolder' -Path $item.RelativePath `
                    -Message "A top-level folder that normalizes to 'assets' is reserved for images."
                continue
            }
        }
        else {
            $slug = ConvertTo-PlaybookSlug -Name $baseName -MaxLength $maxLength
            if (-not $slug) { $slug = 'asset-' + (Get-PlaybookShortHash -Text $item.RelativePath) }
            $target = (@('assets') + @($folders) + "$slug$extension") -join '/'
        }

        if ($targets.ContainsKey($target)) {
            Add-PlaybookIssue -Context $Context -Level Error -Stage 'NormalizeNames' -Code 'NameCollision' -Path $item.RelativePath `
                -Message "Normalizes to '$target', which is already used by '$($targets[$target])'. Rename one of them."
            continue
        }
        $targets[$target] = $item.RelativePath
        $map[$item.RelativePath] = $target
    }

    return , $map
}

#endregion

#region ---------- F3 Normalize content ----------

function Read-PlaybookText {
    param(
        [Parameter(Mandatory)][string]$FullPath,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][hashtable]$Config,
        [Parameter(Mandatory)]$Context
    )
    $bytes = [System.IO.File]::ReadAllBytes($FullPath)

    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        Add-PlaybookIssue -Context $Context -Level Warning -Stage 'NormalizeContent' -Code 'Transcoded' -Path $RelativePath -Message 'Converted from UTF-16 LE.'
        return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        Add-PlaybookIssue -Context $Context -Level Warning -Stage 'NormalizeContent' -Code 'Transcoded' -Path $RelativePath -Message 'Converted from UTF-16 BE.'
        return [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
    }

    $offset = if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { 3 } else { 0 }
    try {
        $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
        return $strictUtf8.GetString($bytes, $offset, $bytes.Length - $offset)
    }
    catch [System.Text.DecoderFallbackException] {
        $fallback = [string]$Config.content.fallbackEncoding
        if (-not $fallback) {
            Add-PlaybookIssue -Context $Context -Level Error -Stage 'NormalizeContent' -Code 'InvalidEncoding' -Path $RelativePath -Message 'File is not valid UTF-8.'
            return $null
        }
        [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
        Add-PlaybookIssue -Context $Context -Level Warning -Stage 'NormalizeContent' -Code 'Transcoded' -Path $RelativePath -Message "Not valid UTF-8; converted from $fallback. Check accented characters."
        return [System.Text.Encoding]::GetEncoding($fallback).GetString($bytes)
    }
}

function ConvertTo-PlaybookNormalizedMarkdown {
    <#
        LF line endings, front matter kept or stripped, guaranteed H1 title, single trailing newline.
        Returns Text, Title and Issues (codes only; the caller logs them).
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$FallbackTitle,
        [ValidateSet('keep', 'strip')][string]$FrontMatter = 'keep',
        [bool]$EnsureTitle = $true
    )
    $issues = [System.Collections.Generic.List[string]]::new()
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    if ($normalized.Length -gt 0 -and $normalized[0] -eq [char]0xFEFF) { $normalized = $normalized.Substring(1) }

    $frontMatterText = $null
    $body = $normalized
    if ($normalized.StartsWith("---`n")) {
        $m = [regex]::Match($normalized, '\A---\n(?<fm>.*?)\n(?:---|\.\.\.)[ \t]*(?:\n|\z)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($m.Success) {
            $frontMatterText = $m.Groups['fm'].Value
            $body = $normalized.Substring($m.Length)
        }
        else {
            $issues.Add('UnclosedFrontMatter')
        }
    }

    $lines = $body.Split("`n")
    $mask = Get-PlaybookFenceMask -Lines $lines
    $title = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($mask[$i]) { continue }
        $h = [regex]::Match($lines[$i], '^\s{0,3}#\s+(?<t>.+?)\s*#*\s*$')
        if ($h.Success) { $title = $h.Groups['t'].Value; break }
    }
    if (-not $title -and $frontMatterText) {
        $t = [regex]::Match($frontMatterText, '(?m)^title:\s*["'']?(?<t>.+?)["'']?\s*$')
        if ($t.Success) { $title = $t.Groups['t'].Value }
    }
    if (-not $title) {
        $title = $FallbackTitle
        if ($EnsureTitle) {
            $body = "# $FallbackTitle`n`n" + $body.TrimStart("`n")
            $issues.Add('TitleAdded')
        }
    }

    $body = $body.TrimEnd() + "`n"
    $result = if ($FrontMatter -eq 'keep' -and $null -ne $frontMatterText) { "---`n$frontMatterText`n---`n`n$body" } else { $body }

    return [pscustomobject]@{ Text = $result; Title = $title; Issues = $issues.ToArray() }
}

#endregion

#region ---------- F4 Links and assets ----------

function Resolve-PlaybookLinkTarget {
    <#
        Maps one link URL found in a page to its new URL.
        Returns a result with Url (new or unchanged), Status (Rewritten | External | Anchor | Unresolved | Blocked)
        and AssetSource when the target is an asset that must be copied.
    #>
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$TargetPath,
        [Parameter(Mandatory)][System.Collections.Generic.Dictionary[string, string]]$PathMap,
        [bool]$AllowExternal = $true
    )
    $raw = $Url.Trim()
    if ($raw.StartsWith('<') -and $raw.EndsWith('>')) { $raw = $raw.Substring(1, $raw.Length - 2) }

    if ($raw -match '^[a-zA-Z][a-zA-Z0-9+.\-]*:' -or $raw.StartsWith('//')) {
        $status = if ($AllowExternal) { 'External' } else { 'Blocked' }
        return [pscustomobject]@{ Url = $Url; Status = $status; AssetSource = $null; CaseMismatch = $false }
    }
    if ($raw.StartsWith('#') -or $raw -eq '') {
        return [pscustomobject]@{ Url = $Url; Status = 'Anchor'; AssetSource = $null; CaseMismatch = $false }
    }

    $fragment = ''
    $hashIndex = $raw.IndexOf('#')
    if ($hashIndex -ge 0) { $fragment = $raw.Substring($hashIndex); $raw = $raw.Substring(0, $hashIndex) }
    $queryIndex = $raw.IndexOf('?')
    if ($queryIndex -ge 0) { $raw = $raw.Substring(0, $queryIndex) }

    $decoded = [System.Uri]::UnescapeDataString($raw).Replace('\', '/')
    $candidate = if ($decoded.StartsWith('/')) { Resolve-PlaybookRelativePath -BaseDirectory '' -RelativePath $decoded }
                 else { Resolve-PlaybookRelativePath -BaseDirectory (Get-PlaybookParentPath -Path $SourcePath) -RelativePath $decoded }

    $unresolved = [pscustomobject]@{ Url = $Url; Status = 'Unresolved'; AssetSource = $null; CaseMismatch = $false }
    if ($null -eq $candidate) { return $unresolved }

    $candidates = @($candidate)
    if (-not [System.IO.Path]::HasExtension($candidate)) {
        $candidates += "$candidate.md", "$candidate/README.md", "$candidate/readme.md", "$candidate/index.md"
    }

    $found = $null
    $caseMismatch = $false
    foreach ($c in $candidates) { if ($PathMap.ContainsKey($c)) { $found = $c; break } }
    if (-not $found) {
        # Authors on Windows often get the case wrong; accept it but report it.
        foreach ($c in $candidates) {
            $match = $PathMap.Keys | Where-Object { $_ -ieq $c } | Select-Object -First 1
            if ($match) { $found = $match; $caseMismatch = $true; break }
        }
    }
    if (-not $found) { return $unresolved }

    $newTarget = $PathMap[$found]
    $relative = Get-PlaybookRelativeUrl -FromDirectory (Get-PlaybookParentPath -Path $TargetPath) -ToPath $newTarget
    $assetSource = if ($newTarget.StartsWith('assets/')) { $found } else { $null }
    return [pscustomobject]@{ Url = "$relative$fragment"; Status = 'Rewritten'; AssetSource = $assetSource; CaseMismatch = $caseMismatch }
}

function Update-PlaybookLinks {
    <#
        Rewrites inline links, images, reference definitions and HTML src/href in one page.
        Code fences and inline code spans are left untouched.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$TargetPath,
        [Parameter(Mandatory)][System.Collections.Generic.Dictionary[string, string]]$PathMap,
        [bool]$AllowExternal = $true
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $resolve = {
        param([string]$u)
        $r = Resolve-PlaybookLinkTarget -Url $u -SourcePath $SourcePath -TargetPath $TargetPath -PathMap $PathMap -AllowExternal $AllowExternal
        $results.Add($r)
        return $r.Url
    }

    $inlinePattern = '(?<pre>!?\[(?:[^\[\]]|\[[^\]]*\])*\]\()(?<url><[^>]*>|[^)\s]+)(?<post>(?:\s+(?:"[^"]*"|''[^'']*''|\([^)]*\)))?\))'
    $referencePattern = '^(?<pre>\s{0,3}\[[^\]]+\]:\s*)(?<url><[^>]*>|\S+)(?<post>.*)$'
    $htmlPattern = '(?<pre><(?:img|a|source)\b[^>]*?\b(?:src|href)\s*=\s*(?<q>["'']))(?<url>.*?)(?<post>\k<q>)'

    $lines = $Text.Split("`n")
    $mask = Get-PlaybookFenceMask -Lines $lines
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($mask[$i]) { continue }
        $line = $lines[$i]
        if ($line.IndexOf('](') -lt 0 -and $line.IndexOf(']:') -lt 0 -and $line.IndexOf('src') -lt 0 -and $line.IndexOf('href') -lt 0) { continue }

        # Protect inline code spans.
        $spans = [System.Collections.Generic.List[string]]::new()
        $line = [regex]::Replace($line, '(`+)(?:(?!\1).)+?\1', {
                param($m)
                $spans.Add($m.Value)
                return "$([char]0xE000)$($spans.Count - 1)$([char]0xE001)"
            })

        $line = [regex]::Replace($line, $inlinePattern, {
                param($m)
                return $m.Groups['pre'].Value + (& $resolve $m.Groups['url'].Value) + $m.Groups['post'].Value
            })
        $line = [regex]::Replace($line, $referencePattern, {
                param($m)
                return $m.Groups['pre'].Value + (& $resolve $m.Groups['url'].Value) + $m.Groups['post'].Value
            })
        $line = [regex]::Replace($line, $htmlPattern, {
                param($m)
                return $m.Groups['pre'].Value + (& $resolve $m.Groups['url'].Value) + $m.Groups['post'].Value
            })

        $line = [regex]::Replace($line, "$([char]0xE000)(\d+)$([char]0xE001)", {
                param($m)
                return $spans[[int]$m.Groups[1].Value]
            })
        $lines[$i] = $line
    }

    return [pscustomobject]@{
        Text    = $lines -join "`n"
        Results = $results.ToArray()
    }
}

#endregion

#region ---------- F5 Secret scan ----------

function ConvertTo-PlaybookIpNumber {
    param([Parameter(Mandatory)][string]$Address)
    $bytes = [System.Net.IPAddress]::Parse($Address).GetAddressBytes()
    if ($bytes.Count -ne 4) { throw "'$Address' is not an IPv4 address." }
    return ([long]$bytes[0] -shl 24) + ([long]$bytes[1] -shl 16) + ([long]$bytes[2] -shl 8) + [long]$bytes[3]
}

function Test-PlaybookIpInCidr {
    param([Parameter(Mandatory)][string]$Address, [Parameter(Mandatory)][string]$Cidr)
    $parts = $Cidr.Split('/')
    $prefix = if ($parts.Count -gt 1) { [int]$parts[1] } else { 32 }
    $mask = if ($prefix -eq 0) { [long]0 } else { ([long]4294967295 -shl (32 - $prefix)) -band [long]4294967295 }
    return ((ConvertTo-PlaybookIpNumber $Address) -band $mask) -eq ((ConvertTo-PlaybookIpNumber $parts[0]) -band $mask)
}

function Get-PlaybookSecretRules {
    param([Parameter(Mandatory)][hashtable]$Config)
    $rules = @(
        @{ id = 'private-key';          action = 'block'; pattern = '-----BEGIN (?:[A-Z]+ )*PRIVATE KEY-----' }
        @{ id = 'aws-access-key';       action = 'block'; pattern = '\b(?:AKIA|ASIA)[0-9A-Z]{16}\b' }
        @{ id = 'github-token';         action = 'block'; pattern = '\bgh[pousr]_[A-Za-z0-9]{36,}\b' }
        @{ id = 'slack-token';          action = 'block'; pattern = '\bxox[abprs]-[A-Za-z0-9-]{10,}' }
        @{ id = 'azure-storage-key';    action = 'block'; pattern = '(?i)AccountKey=(?<v>[A-Za-z0-9+/=]{40,})' }
        @{ id = 'azure-sas-signature';  action = 'block'; pattern = '(?i)[?&]sig=(?<v>[A-Za-z0-9%+/=]{20,})' }
        @{ id = 'jwt';                  action = 'block'; pattern = '\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' }
        @{ id = 'connection-password';  action = 'block'; pattern = '(?i)\b(?:password|pwd)\s*=\s*(?<v>[^;\s''"]{4,})' }
        @{ id = 'secret-assignment';    action = 'block'; pattern = '(?i)\b(?:secret|token|api[_-]?key|client[_-]?secret|passwd|password)\b["'']?\s*[:=]\s*["'']?(?<v>[^\s"'',;]{8,})' }
    )
    foreach ($suffix in @($Config.secretScan.internalDomainSuffixes)) {
        if ([string]::IsNullOrWhiteSpace($suffix)) { continue }
        $rules += @{
            id      = 'internal-hostname'
            action  = $Config.secretScan.internalAction
            pattern = '(?i)\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.' + [regex]::Escape($suffix.TrimStart('.')) + '\b'
        }
    }
    foreach ($extra in @($Config.secretScan.extraRules)) {
        if (-not $extra.id -or -not $extra.pattern) { throw 'Each secretScan.extraRules entry needs id and pattern.' }
        $rules += @{ id = $extra.id; pattern = $extra.pattern; action = if ($extra.action) { $extra.action } else { 'block' } }
    }
    foreach ($rule in $rules) { $rule['regex'] = [regex]::new($rule.pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled) }
    return $rules
}

function Get-PlaybookRedactedValue {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    if ($Value.Length -le 6) { return '****' }
    return $Value.Substring(0, 2) + '****' + "($($Value.Length) chars)"
}

function Find-PlaybookSecrets {
    <#
        Scans normalized page text line by line (code blocks included: that is where secrets usually hide).
        Findings carry a redacted preview and a fingerprint; the raw value is never returned.
        A fingerprint listed in secretScan.allowlist suppresses that exact finding (reviewed false positive).
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object[]]$Rules,
        [Parameter(Mandatory)][hashtable]$Config
    )
    $allowlist = [System.Collections.Generic.HashSet[string]]::new([string[]]@($Config.secretScan.allowlist), [System.StringComparer]::OrdinalIgnoreCase)
    $placeholder = '(?i)^(?:<[^>]*>|\$\{[^}]*\}|\$\([^)]*\)|\{\{[^}]*\}\}|\*+|x{4,}|redacted|changeme|example|placeholder|your[-_a-z]*)$'
    $ipPattern = '\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b'
    $internalCidrs = @($Config.secretScan.internalCidrs)

    $lines = $Text.Split("`n")
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $hits = [System.Collections.Generic.List[object]]::new()

        foreach ($rule in $Rules) {
            foreach ($m in $rule.regex.Matches($line)) {
                $value = if ($m.Groups['v'].Success) { $m.Groups['v'].Value } else { $m.Value }
                if ($value -match $placeholder) { continue }
                $hits.Add(@{ Rule = $rule.id; Action = $rule.action; Value = $value })
            }
        }
        foreach ($m in [regex]::Matches($line, $ipPattern)) {
            foreach ($cidr in $internalCidrs) {
                if (Test-PlaybookIpInCidr -Address $m.Value -Cidr $cidr) {
                    $hits.Add(@{ Rule = 'internal-ip'; Action = $Config.secretScan.internalAction; Value = $m.Value })
                    break
                }
            }
        }

        foreach ($hit in $hits) {
            $fingerprint = Get-PlaybookShortHash -Text "$Path|$($hit.Rule)|$($hit.Value)" -Length 16
            [pscustomobject]@{
                Path        = $Path
                Line        = $i + 1
                Rule        = $hit.Rule
                Action      = $hit.Action
                Fingerprint = $fingerprint
                Preview     = Get-PlaybookRedactedValue -Value $hit.Value
                Allowlisted = $allowlist.Contains($fingerprint)
            }
        }
    }
}

#endregion

#region ---------- F6 Navigation + MkDocs config ----------

function Get-PlaybookOrderLists {
    <# Reads optional order files: one original file or folder name per line, '#' for comments. Keyed by source folder. #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Inventory)
    $orders = @{}
    foreach ($item in $Inventory | Where-Object Kind -eq 'Order') {
        $names = @(Get-Content -LiteralPath $item.FullPath -Encoding utf8 |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and -not $_.StartsWith('#') })
        $orders[(Get-PlaybookParentPath -Path $item.RelativePath)] = $names
    }
    return $orders
}

function New-PlaybookNavYaml {
    <#
        Builds the MkDocs 'nav' block from the page list. Folders show their original names,
        pages show their H1 title. Order: index page first, then entries listed in the folder's
        order file, then the rest alphabetically.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Pages,
        [Parameter(Mandatory)][hashtable]$OrderLists
    )

    $root = @{ Folders = @{}; Pages = [System.Collections.Generic.List[object]]::new(); SourceDir = ''; Name = '' }
    foreach ($page in $Pages) {
        $sourceSegments = $page.SourcePath.Split('/')
        $targetSegments = $page.TargetPath.Split('/')
        $node = $root
        for ($i = 0; $i -lt $targetSegments.Count - 1; $i++) {
            $key = $targetSegments[$i]
            if (-not $node.Folders.ContainsKey($key)) {
                $node.Folders[$key] = @{
                    Folders   = @{}
                    Pages     = [System.Collections.Generic.List[object]]::new()
                    SourceDir = ($sourceSegments[0..$i] -join '/')
                    Name      = $sourceSegments[$i]
                }
            }
            $node = $node.Folders[$key]
        }
        $node.Pages.Add($page)
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('nav:')

    $emit = $null
    $emit = {
        param($node, [string]$indent)
        $order = @()
        if ($OrderLists.ContainsKey($node.SourceDir)) { $order = @($OrderLists[$node.SourceDir]) }

        $entries = [System.Collections.Generic.List[object]]::new()
        foreach ($p in $node.Pages) {
            $sourceName = $p.SourcePath.Split('/')[-1]
            $isIndex = $p.TargetPath.Split('/')[-1] -eq 'index.md'
            $rank = [array]::IndexOf($order, $sourceName)
            if ($rank -lt 0) { $rank = [array]::IndexOf($order, [System.IO.Path]::GetFileNameWithoutExtension($sourceName)) }
            $entries.Add([pscustomobject]@{ Kind = 'Page'; Item = $p; Display = $p.Title; Rank = $(if ($isIndex) { -1 } elseif ($rank -ge 0) { $rank } else { [int]::MaxValue }) })
        }
        foreach ($f in $node.Folders.Values) {
            $rank = [array]::IndexOf($order, $f.Name)
            $entries.Add([pscustomobject]@{ Kind = 'Folder'; Item = $f; Display = $f.Name; Rank = $(if ($rank -ge 0) { $rank } else { [int]::MaxValue }) })
        }

        foreach ($e in $entries | Sort-Object -Property Rank, @{ Expression = { $_.Display.ToLowerInvariant() } }) {
            if ($e.Kind -eq 'Page') {
                $lines.Add("$indent- $(ConvertTo-PlaybookYamlString $e.Item.Title): $(ConvertTo-PlaybookYamlString $e.Item.TargetPath)")
            }
            else {
                $lines.Add("$indent- $(ConvertTo-PlaybookYamlString $e.Display):")
                & $emit $e.Item ($indent + '    ')
            }
        }
    }
    & $emit $root '  '
    return $lines -join "`n"
}

function New-PlaybookHomePage {
    <# Generates docs/index.md when the source has no root README/index, so the site has a landing page. #>
    param([Parameter(Mandatory)][string]$SiteName, [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Pages)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# $SiteName")
    $lines.Add('')
    $lines.Add('Use search (top of the page) or browse the sections below.')
    $lines.Add('')
    $topLevel = $Pages | Group-Object { if ($_.TargetPath.Contains('/')) { $_.TargetPath.Split('/')[0] } else { '' } } | Sort-Object Name
    foreach ($group in $topLevel) {
        if ($group.Name -eq '') {
            foreach ($p in $group.Group | Sort-Object Title) { $lines.Add("- [$($p.Title)]($($p.TargetPath))") }
        }
        else {
            $first = $group.Group | Sort-Object @{ Expression = { $_.TargetPath -notlike '*/index.md' } }, TargetPath | Select-Object -First 1
            $lines.Add("- [$($first.SourcePath.Split('/')[0])]($($first.TargetPath)) ($($group.Count) playbooks)")
        }
    }
    return ($lines -join "`n") + "`n"
}

function New-PlaybookMkDocsConfig {
    param(
        [Parameter(Mandatory)][hashtable]$Config,
        [Parameter(Mandatory)][string]$NavYaml
    )
    $anchors = [string]$Config.build.validateAnchors
    return @"
site_name: $(ConvertTo-PlaybookYamlString $Config.siteName)
docs_dir: docs
site_dir: site
use_directory_urls: true
theme:
  name: material
  language: $($Config.build.language)
  font: false            # no Google Fonts calls from AVD: the site works without internet egress
  features:
    - navigation.indexes
    - navigation.top
    - search.suggest
    - search.highlight
    - content.code.copy
plugins:
  - search
markdown_extensions:
  - admonition
  - attr_list
  - tables
  - toc:
      permalink: true
  - pymdownx.details
  - pymdownx.superfences
validation:
  nav:
    omitted_files: warn
    not_found: warn
    absolute_links: warn
  links:
    not_found: warn
    absolute_links: warn
    unrecognized_links: warn
    anchors: $anchors
$NavYaml
"@
}

function Get-PlaybookWebConfig {
    return @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <staticContent>
      <remove fileExtension=".json" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <remove fileExtension=".woff2" />
      <mimeMap fileExtension=".woff2" mimeType="font/woff2" />
      <clientCache cacheControlMode="DisableCache" />
    </staticContent>
    <httpProtocol>
      <customHeaders>
        <remove name="X-Powered-By" />
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="DENY" />
        <add name="Referrer-Policy" value="no-referrer" />
      </customHeaders>
    </httpProtocol>
    <security>
      <requestFiltering>
        <hiddenSegments>
          <add segment="_manifest.json" />
        </hiddenSegments>
      </requestFiltering>
    </security>
  </system.webServer>
</configuration>
'@
}

#endregion

#region ---------- F7 Build ----------

function Get-PlaybookContentManifest {
    <# Deterministic manifest of the docs folder (hash per file) plus one content hash for the whole release. #>
    param([Parameter(Mandatory)][string]$DocsPath, [Parameter(Mandatory)][string]$MkDocsConfigPath, [string]$GeneratorVersion)
    $files = [ordered]@{}
    foreach ($f in Get-ChildItem -LiteralPath $DocsPath -Recurse -File | Sort-Object FullName) {
        $rel = [System.IO.Path]::GetRelativePath($DocsPath, $f.FullName).Replace('\', '/')
        $files[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $configHash = (Get-FileHash -LiteralPath $MkDocsConfigPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sortedKeys = @($files.Keys) | Sort-Object -CaseSensitive
    $material = (@($sortedKeys | ForEach-Object { "$($_):$($files[$_])" }) + "mkdocs.yml:$configHash" + "generator:$GeneratorVersion") -join "`n"
    return [ordered]@{
        schema      = 1
        contentHash = Get-PlaybookShortHash -Text $material -Length 64
        generator   = $GeneratorVersion
        configHash  = $configHash
        fileCount   = $files.Count
        files       = $files
    }
}

function Invoke-PlaybookBuild {
    param([Parameter(Mandatory)][hashtable]$Config, [Parameter(Mandatory)]$Context)
    $WhatIfPreference = $false   # local build output only

    $python = [string]$Config.build.python
    if (-not (Get-Command -Name $python -CommandType Application -ErrorAction SilentlyContinue)) {
        Add-PlaybookIssue -Context $Context -Level Error -Stage 'Build' -Code 'PythonMissing' -Message "Python executable '$python' not found on the agent."
        return
    }
    $versionOutput = & $python -m mkdocs --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-PlaybookIssue -Context $Context -Level Error -Stage 'Build' -Code 'GeneratorMissing' -Message "MkDocs not available via '$python -m mkdocs'. Install requirements.txt on the agent."
        return
    }
    $generatorVersion = ([string]($versionOutput | Select-Object -First 1)).Trim()

    $output = & $python -m mkdocs build --strict --clean --config-file $Context.Paths.MkDocsConfig 2>&1
    $exit = $LASTEXITCODE
    foreach ($line in $output) {
        $text = [string]$line
        if ($text -match '^(WARNING|ERROR)\s*-\s*(?<msg>.+)$') {
            Add-PlaybookIssue -Context $Context -Level Error -Stage 'Build' -Code 'StrictBuild' -Message $Matches['msg'].Trim()
        }
    }
    if ($exit -ne 0) {
        if ($Context.Errors.Count -eq 0) {
            Add-PlaybookIssue -Context $Context -Level Error -Stage 'Build' -Code 'BuildFailed' -Message "mkdocs build exited with code $exit."
        }
        return
    }

    $manifest = Get-PlaybookContentManifest -DocsPath $Context.Paths.Docs -MkDocsConfigPath $Context.Paths.MkDocsConfig -GeneratorVersion $generatorVersion
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $Context.Paths.Site $script:ManifestFileName) -Encoding utf8NoBOM
    $Context.Manifest = $manifest

    if (Test-Path -LiteralPath $Context.Paths.Zip) { Remove-Item -LiteralPath $Context.Paths.Zip -Force }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Context.Paths.Site, $Context.Paths.Zip, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    $Context.Build = [ordered]@{
        Generator = $generatorVersion
        ZipBytes  = (Get-Item -LiteralPath $Context.Paths.Zip).Length
        SiteFiles = @(Get-ChildItem -LiteralPath $Context.Paths.Site -Recurse -File).Count
    }
}

#endregion

#region ---------- F8 Diff ----------

function Compare-PlaybookManifest {
    param([Parameter(Mandatory)]$Current, $Deployed)
    $currentFiles = $Current.files
    $deployedFiles = if ($Deployed -and $Deployed.ContainsKey('files')) { $Deployed.files } else { @{} }

    $added = [System.Collections.Generic.List[string]]::new()
    $changed = [System.Collections.Generic.List[string]]::new()
    $removed = [System.Collections.Generic.List[string]]::new()
    $unchanged = 0
    foreach ($key in $currentFiles.Keys) {
        if (-not $deployedFiles.ContainsKey($key)) { $added.Add($key) }
        elseif ($deployedFiles[$key] -ne $currentFiles[$key]) { $changed.Add($key) }
        else { $unchanged++ }
    }
    foreach ($key in $deployedFiles.Keys) { if (-not $currentFiles.Contains($key)) { $removed.Add($key) } }

    return [pscustomobject]@{
        FirstDeployment = ($null -eq $Deployed)
        DeployedHash    = if ($Deployed) { $Deployed.contentHash } else { $null }
        CurrentHash     = $Current.contentHash
        NoChanges       = ($Deployed -and $Deployed.contentHash -eq $Current.contentHash)
        Added           = $added.ToArray()
        Changed         = $changed.ToArray()
        Removed         = $removed.ToArray()
        Unchanged       = $unchanged
    }
}

#endregion

#region ---------- F9 Preflight ----------

function Test-PlaybookPreflight {
    <# Read-only checks that the access controls are in place. Every failed check is an error. #>
    param([Parameter(Mandatory)][hashtable]$Config)
    $azure = $Config.azure
    $checks = [System.Collections.Generic.List[object]]::new()
    $add = { param($name, [bool]$pass, $detail) $checks.Add([pscustomobject]@{ Check = $name; Passed = $pass; Detail = $detail }) }

    $context = Get-AzContext
    & $add 'Azure context is the SOC subscription' ($context.Subscription.Id -eq $azure.subscriptionId) "Context: $($context.Subscription.Id)"
    & $add 'Azure context is the company tenant' ($context.Tenant.Id -eq $azure.tenantId) "Context: $($context.Tenant.Id)"

    $sitePath = Get-PlaybookSitePath -Azure $azure
    $site = Invoke-PlaybookArmGet -Path $sitePath -AllowNotFound
    if ($null -eq $site) {
        & $add 'Web app exists in the SOC resource group' $false $sitePath
        return $checks.ToArray()
    }
    & $add 'Web app exists in the SOC resource group' $true (Get-PlaybookValue $site 'id')
    $httpsOnly = [bool](Get-PlaybookValue $site 'properties.httpsOnly')
    & $add 'HTTPS only' $httpsOnly "httpsOnly=$httpsOnly"

    if ($azure.requirePrivateEndpoint) {
        $publicAccess = Get-PlaybookValue $site 'properties.publicNetworkAccess'
        & $add 'Public network access disabled' ($publicAccess -eq 'Disabled') "publicNetworkAccess=$publicAccess"
        $pe = Invoke-PlaybookArmGet -Path "$sitePath/privateEndpointConnections"
        $approved = @(@(Get-PlaybookValue $pe 'value') | Where-Object {
                (Get-PlaybookValue $_ 'properties.privateLinkServiceConnectionState.status') -eq 'Approved'
            })
        & $add 'Approved private endpoint' ($approved.Count -ge 1) "$($approved.Count) approved connection(s)"
    }

    $slot = Invoke-PlaybookArmGet -Path (Get-PlaybookSitePath -Azure $azure -Slot $azure.slot) -AllowNotFound
    & $add "Staging slot '$($azure.slot)' exists" ($null -ne $slot) ''

    $web = Invoke-PlaybookArmGet -Path "$sitePath/config/web"
    $ftps = Get-PlaybookValue $web 'properties.ftpsState'
    & $add 'FTP disabled' ($ftps -eq 'Disabled') "ftpsState=$ftps"

    foreach ($target in @('production', $azure.slot)) {
        $base = Get-PlaybookSitePath -Azure $azure -Slot $target
        foreach ($kind in 'scm', 'ftp') {
            $policy = Invoke-PlaybookArmGet -Path "$base/basicPublishingCredentialsPolicies/$kind" -AllowNotFound
            $allowed = if ($policy) { [bool](Get-PlaybookValue $policy 'properties.allow') } else { $true }
            & $add "Basic-auth publishing off ($kind, $target)" (-not $allowed) "allow=$allowed"
        }

        $auth = Invoke-PlaybookArmGet -Path "$base/config/authsettingsV2" -AllowNotFound
        $platformOn = [bool](Get-PlaybookValue $auth 'properties.platform.enabled')
        & $add "Easy Auth enabled ($target)" $platformOn ''
        if ($platformOn) {
            $requireAuth = [bool](Get-PlaybookValue $auth 'properties.globalValidation.requireAuthentication')
            $action = Get-PlaybookValue $auth 'properties.globalValidation.unauthenticatedClientAction'
            & $add "Authentication required ($target)" ($requireAuth -and $action -in 'RedirectToLoginPage', 'Return401') "requireAuthentication=$requireAuth, action=$action"
            $aadEnabled = [bool](Get-PlaybookValue $auth 'properties.identityProviders.azureActiveDirectory.enabled')
            $clientId = Get-PlaybookValue $auth 'properties.identityProviders.azureActiveDirectory.registration.clientId'
            $issuer = [string](Get-PlaybookValue $auth 'properties.identityProviders.azureActiveDirectory.registration.openIdIssuer')
            & $add "Entra provider uses the configured app ($target)" ($aadEnabled -and $clientId -eq $azure.clientId) "clientId=$clientId"
            & $add "Entra issuer is single-tenant ($target)" ($issuer -match [regex]::Escape($azure.tenantId) -and $issuer -notmatch '/(common|organizations|consumers)(/|$)') "issuer=$issuer"
        }
    }

    if ($azure.checkEntraAssignment) {
        $filter = [System.Uri]::EscapeDataString("appId eq '$($azure.clientId)'")
        $spResponse = Invoke-AzRestMethod -Method GET -ResourceId $script:GraphResource `
            -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=$filter&`$select=id,appRoleAssignmentRequired"
        if ($spResponse.StatusCode -ge 400) {
            & $add 'Entra app readable via Graph' $false "HTTP $($spResponse.StatusCode). The pipeline identity needs Application.Read.All, or set azure.checkEntraAssignment=false."
        }
        else {
            $sp = @(Get-PlaybookValue ($spResponse.Content | ConvertFrom-Json -AsHashtable) 'value') | Select-Object -First 1
            & $add 'Enterprise app exists' ($null -ne $sp) ''
            if ($sp) {
                & $add 'Assignment required on the enterprise app' ([bool]$sp.appRoleAssignmentRequired) "appRoleAssignmentRequired=$($sp.appRoleAssignmentRequired)"
                $assigned = Invoke-AzRestMethod -Method GET -ResourceId $script:GraphResource `
                    -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo?`$select=principalId,principalType&`$top=999"
                if ($assigned.StatusCode -ge 400) { throw "Reading app role assignments returned HTTP $($assigned.StatusCode)." }
                $principals = @(Get-PlaybookValue ($assigned.Content | ConvertFrom-Json -AsHashtable) 'value')
                $unexpected = @($principals | Where-Object { $_['principalId'] -notin @($azure.allowedPrincipalIds) })
                & $add 'Only approved principals assigned' ($principals.Count -ge 1 -and $unexpected.Count -eq 0) "$($principals.Count) assigned, $($unexpected.Count) not in allowedPrincipalIds"
            }
        }
    }

    return $checks.ToArray()
}

#endregion

#region ---------- F10 Deploy ----------

function Invoke-PlaybookZipDeploy {
    param([Parameter(Mandatory)][hashtable]$Azure, [Parameter(Mandatory)][string]$ZipPath, [Parameter(Mandatory)][string]$Slot)
    $scmHost = Get-PlaybookHostName -Azure $Azure -Slot $Slot -Scm
    $headers = @{ Authorization = "Bearer $(Get-PlaybookAccessToken)" }

    # Entra bearer token against Kudu: works with basic-auth publishing disabled.
    $response = Invoke-WebRequest -Method POST -Uri "https://$scmHost/api/zipdeploy?isAsync=true" -Headers $headers `
        -InFile $ZipPath -ContentType 'application/zip' -SkipHttpErrorCheck -ErrorAction Stop
    if ($response.StatusCode -notin 200, 202) { throw "Zip deploy to slot '$Slot' returned HTTP $($response.StatusCode)." }

    $statusUrl = [string]($response.Headers['Location'] | Select-Object -First 1)
    if (-not $statusUrl) { $statusUrl = "https://$scmHost/api/deployments/latest" }

    $deadline = (Get-Date).AddMinutes([int]$Azure.deployTimeoutMinutes)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        $headers.Authorization = "Bearer $(Get-PlaybookAccessToken)"
        $status = Invoke-RestMethod -Uri $statusUrl -Headers $headers -ErrorAction Stop
        if (Get-PlaybookValue $status 'complete') {
            # Kudu status: 3 = failed, 4 = success
            $id = Get-PlaybookValue $status 'id'
            $code = Get-PlaybookValue $status 'status'
            if ($code -eq 4) { return [pscustomobject]@{ DeploymentId = $id; Status = 'Success' } }
            throw "Kudu reported deployment $id as failed (status $code)."
        }
    }
    throw "Deployment to slot '$Slot' did not finish within $($Azure.deployTimeoutMinutes) minutes."
}

function Test-PlaybookSmoke {
    <# Slot checks: the deployed manifest matches this build, and anonymous requests are NOT served. #>
    param([Parameter(Mandatory)][hashtable]$Azure, [Parameter(Mandatory)][string]$Slot, [Parameter(Mandatory)][string]$ExpectedHash)
    $checks = [System.Collections.Generic.List[object]]::new()

    $manifest = Get-PlaybookDeployedManifest -Azure $Azure -Slot $Slot
    $checks.Add([pscustomobject]@{ Check = "Manifest on '$Slot' matches build"; Passed = ($manifest -and $manifest.contentHash -eq $ExpectedHash); Detail = '' })

    $siteHost = Get-PlaybookHostName -Azure $Azure -Slot $Slot
    $anonymous = Invoke-WebRequest -Uri "https://$siteHost/" -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction Stop
    $checks.Add([pscustomobject]@{
            Check  = "Anonymous request to '$Slot' is not served"
            Passed = ($anonymous.StatusCode -in 302, 401, 403)
            Detail = "HTTP $($anonymous.StatusCode)"
        })
    return $checks.ToArray()
}

#endregion

#region ---------- F11 Report ----------

function Write-PlaybookReport {
    param([Parameter(Mandatory)]$Context)
    $WhatIfPreference = $false   # the report is always written, including -WhatIf runs
    New-Item -ItemType Directory -Path $Context.Paths.Report -Force | Out-Null

    $Context.FinishedAt = (Get-Date).ToUniversalTime().ToString('o')
    $diff = $Context.Diff
    $report = [ordered]@{
        result      = $Context.Result
        startedAt   = $Context.StartedAt
        finishedAt  = $Context.FinishedAt
        operator    = if ($env:BUILD_REQUESTEDFOR) { $env:BUILD_REQUESTEDFOR } else { [Environment]::UserName }
        commit      = $env:BUILD_SOURCEVERSION
        pipelineRun = $env:BUILD_BUILDID
        whatIf      = $Context.WhatIf
        offline     = $Context.Offline
        stages      = $Context.Stages
        counts      = [ordered]@{
            sourceFiles   = @($Context.Inventory).Count
            pages         = @($Context.Inventory | Where-Object Kind -eq 'Page').Count
            assetsCopied  = $Context.AssetsCopied
            ignoredFiles  = @($Context.Inventory | Where-Object Kind -eq 'Other').Count
            published     = @($Context.Pages).Count
            errors        = $Context.Errors.Count
            warnings      = $Context.Warnings.Count
            findings      = @($Context.Findings | Where-Object { -not $_.Allowlisted }).Count
            allowlisted   = @($Context.Findings | Where-Object { $_.Allowlisted }).Count
        }
        build       = $Context.Build
        contentHash = if ($Context.Manifest) { $Context.Manifest.contentHash } else { $null }
        diff        = if ($diff) {
            [ordered]@{
                firstDeployment = $diff.FirstDeployment
                added = $diff.Added.Count; changed = $diff.Changed.Count; removed = $diff.Removed.Count; unchanged = $diff.Unchanged
                addedPaths = @($diff.Added | Select-Object -First 200); changedPaths = @($diff.Changed | Select-Object -First 200); removedPaths = @($diff.Removed | Select-Object -First 200)
            }
        } else { $null }
        preflight   = $Context.Preflight
        deployment  = $Context.Deployment
        errors      = $Context.Errors
        warnings    = $Context.Warnings
        findings    = $Context.Findings
    }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $Context.Paths.Report 'report.json') -Encoding utf8NoBOM

    $md = [System.Collections.Generic.List[string]]::new()
    $md.Add("# Playbook site run: $($Context.Result)")
    $md.Add('')
    $md.Add("Started $($Context.StartedAt) UTC, finished $($Context.FinishedAt) UTC. Commit ``$($env:BUILD_SOURCEVERSION)``, run $($env:BUILD_BUILDID).")
    $md.Add('')
    $md.Add('| Measure | Value |')
    $md.Add('| --- | --- |')
    foreach ($k in $report.counts.Keys) { $md.Add("| $k | $($report.counts[$k]) |") }
    if ($diff) { $md.Add("| diff (added / changed / removed) | $($diff.Added.Count) / $($diff.Changed.Count) / $($diff.Removed.Count) |") }
    $md.Add('')
    $md.Add('## Stages')
    $md.Add('')
    $md.Add('| Stage | Seconds | Errors |')
    $md.Add('| --- | --- | --- |')
    foreach ($s in $Context.Stages) { $md.Add("| $($s.Stage) | $($s.Seconds) | $($s.Errors) |") }
    if ($Context.Errors.Count -gt 0) {
        $md.Add('')
        $md.Add('## Errors (first 100)')
        $md.Add('')
        foreach ($e in $Context.Errors | Select-Object -First 100) { $md.Add("- **$($e.Code)** ``$($e.Path)``: $($e.Message)") }
    }
    $blocking = @($Context.Findings | Where-Object { -not $_.Allowlisted })
    if ($blocking.Count -gt 0) {
        $md.Add('')
        $md.Add('## Secret-scan findings (first 100)')
        $md.Add('')
        $md.Add('Add a fingerprint to `secretScan.allowlist` only after review confirms it is a false positive.')
        $md.Add('')
        foreach ($f in $blocking | Select-Object -First 100) { $md.Add("- ``$($f.Path)``:$($f.Line) $($f.Rule) ($($f.Action)) $($f.Preview) fingerprint ``$($f.Fingerprint)``") }
    }
    if ($Context.Preflight) {
        $md.Add('')
        $md.Add('## Pre-flight')
        $md.Add('')
        foreach ($c in $Context.Preflight) { $md.Add("- $(if ($c.Passed) { 'PASS' } else { 'FAIL' }) $($c.Check) $($c.Detail)") }
    }
    ($md -join "`n") + "`n" | Set-Content -LiteralPath (Join-Path $Context.Paths.Report 'report.md') -Encoding utf8NoBOM
}

#endregion

#region ---------- Entry points ----------

function Publish-PlaybookSite {
    <#
    .SYNOPSIS
        Validates, builds and deploys the SOC playbooks site (stages F1-F11).
    .PARAMETER ConfigPath
        Path to the JSON config file.
    .PARAMETER StopAfter
        Last stage to run. Stages before it always run, because each one feeds the next.
    .PARAMETER Offline
        Local validation only (F1-F7). No Azure access needed: use it for PR builds.
    .PARAMETER Force
        Deploy even when the content hash matches the deployed one.
    .PARAMETER ReportPath
        Where report.json and report.md are written. Defaults to <workPath>/report.
    .EXAMPLE
        Publish-PlaybookSite -ConfigPath ./config/playbooksite.config.json -Offline
    .EXAMPLE
        Publish-PlaybookSite -ConfigPath ./config/playbooksite.config.json -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [ValidateSet('Inventory', 'NormalizeNames', 'NormalizeContent', 'LinksAndAssets', 'SecretScan', 'Navigation', 'Build', 'Diff', 'Preflight', 'Deploy')]
        [string]$StopAfter = 'Deploy',
        [switch]$Offline,
        [switch]$Force,
        [string]$ReportPath
    )

    $config = Read-PlaybookConfig -Path $ConfigPath
    $work = $config.workPath
    $ctx = [pscustomobject]@{
        Config       = $config
        StartedAt    = (Get-Date).ToUniversalTime().ToString('o')
        FinishedAt   = $null
        Result       = 'Running'
        WhatIf       = [bool]$WhatIfPreference
        Offline      = [bool]$Offline
        Paths        = [pscustomobject]@{
            Docs         = Join-Path $work 'docs'
            Site         = Join-Path $work 'site'
            MkDocsConfig = Join-Path $work 'mkdocs.yml'
            Zip          = Join-Path $work 'site.zip'
            Report       = if ($ReportPath) { [System.IO.Path]::GetFullPath($ReportPath) } else { Join-Path $work 'report' }
        }
        Errors       = [System.Collections.Generic.List[object]]::new()
        Warnings     = [System.Collections.Generic.List[object]]::new()
        Stages       = [System.Collections.Generic.List[object]]::new()
        Inventory    = @()
        PathMap      = $null
        Pages        = [System.Collections.Generic.List[object]]::new()
        AssetsCopied = 0
        Findings     = [System.Collections.Generic.List[object]]::new()
        Manifest     = $null
        Build        = $null
        Diff         = $null
        Preflight    = $null
        Deployment   = $null
    }

    # Effective last stage: -Offline stops after Build, -WhatIf after Diff (as in the task definition).
    $last = [array]::IndexOf($script:StageNames, $StopAfter)
    if ($Offline) { $last = [Math]::Min($last, [array]::IndexOf($script:StageNames, 'Build')) }
    if ($WhatIfPreference) { $last = [Math]::Min($last, [array]::IndexOf($script:StageNames, 'Diff')) }
    $remote = $last -ge [array]::IndexOf($script:StageNames, 'Diff')
    if ($remote) { Assert-PlaybookAzureConfig -Config $config; Assert-PlaybookAzureModules }

    try {
        foreach ($dir in $ctx.Paths.Docs, $ctx.Paths.Site) {
            if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force -WhatIf:$false }
            New-Item -ItemType Directory -Path $dir -Force -WhatIf:$false | Out-Null
        }

        for ($index = 0; $index -le $last; $index++) {
            $stage = $script:StageNames[$index]
            $errorsBefore = $ctx.Errors.Count
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            Write-Host "[$stage] started"

            switch ($stage) {
                'Inventory' {
                    $ctx.Inventory = @(Get-PlaybookInventory -Config $config)
                    $pageCount = @($ctx.Inventory | Where-Object Kind -eq 'Page').Count
                    if ($pageCount -eq 0) { Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code 'NoPages' -Message "No .md files found under sourcePath." }
                    Write-Host "  $pageCount pages, $(@($ctx.Inventory).Count) files in total"
                }
                'NormalizeNames' {
                    $ctx.PathMap = Get-PlaybookPathMap -Inventory $ctx.Inventory -Config $config -Context $ctx
                }
                'NormalizeContent' {
                    foreach ($item in $ctx.Inventory | Where-Object Kind -eq 'Page') {
                        if (-not $ctx.PathMap.ContainsKey($item.RelativePath)) { continue }
                        $text = Read-PlaybookText -FullPath $item.FullPath -RelativePath $item.RelativePath -Config $config -Context $ctx
                        if ($null -eq $text) { continue }
                        $fallbackTitle = [System.IO.Path]::GetFileNameWithoutExtension($item.RelativePath.Split('/')[-1])
                        if ($fallbackTitle -in 'README', 'readme', 'index') {
                            $parent = Get-PlaybookParentPath -Path $item.RelativePath
                            $fallbackTitle = if ($parent) { $parent.Split('/')[-1] } else { $config.siteName }
                        }
                        $normalized = ConvertTo-PlaybookNormalizedMarkdown -Text $text -FallbackTitle $fallbackTitle `
                            -FrontMatter $config.content.frontMatter -EnsureTitle ([bool]$config.content.ensureTitle)
                        foreach ($code in $normalized.Issues) {
                            if ($code -eq 'UnclosedFrontMatter') {
                                Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code $code -Path $item.RelativePath -Message "Front matter starts with '---' but is never closed."
                            }
                            elseif ($code -eq 'TitleAdded') {
                                Add-PlaybookIssue -Context $ctx -Level Warning -Stage $stage -Code $code -Path $item.RelativePath -Message 'No H1 heading; added one from the file name.'
                            }
                        }
                        $ctx.Pages.Add([pscustomobject]@{
                                SourcePath = $item.RelativePath
                                TargetPath = $ctx.PathMap[$item.RelativePath]
                                Title      = $normalized.Title
                                Text       = $normalized.Text
                            })
                    }
                }
                'LinksAndAssets' {
                    $assetsToCopy = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
                    foreach ($page in $ctx.Pages) {
                        $updated = Update-PlaybookLinks -Text $page.Text -SourcePath $page.SourcePath -TargetPath $page.TargetPath `
                            -PathMap $ctx.PathMap -AllowExternal ([bool]$config.links.allowExternal)
                        foreach ($r in $updated.Results) {
                            switch ($r.Status) {
                                'Unresolved' { Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code 'UnresolvedLink' -Path $page.SourcePath -Message "Link target not found: $($r.Url)" }
                                'Blocked' { Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code 'ExternalLinkBlocked' -Path $page.SourcePath -Message "External links are not allowed: $($r.Url)" }
                                'Rewritten' {
                                    if ($r.AssetSource) { [void]$assetsToCopy.Add($r.AssetSource) }
                                    if ($r.CaseMismatch) { Add-PlaybookIssue -Context $ctx -Level Warning -Stage $stage -Code 'LinkCaseMismatch' -Path $page.SourcePath -Message "Link case differs from the file name: $($r.Url)" }
                                }
                            }
                        }
                        $page.Text = $updated.Text
                        $destination = Join-Path $ctx.Paths.Docs $page.TargetPath
                        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force -WhatIf:$false | Out-Null
                        [System.IO.File]::WriteAllText($destination, $page.Text, [System.Text.UTF8Encoding]::new($false))
                    }
                    foreach ($assetSource in $assetsToCopy) {
                        $destination = Join-Path $ctx.Paths.Docs $ctx.PathMap[$assetSource]
                        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force -WhatIf:$false | Out-Null
                        Copy-Item -LiteralPath (Join-Path $config.sourcePath $assetSource) -Destination $destination -Force -WhatIf:$false
                    }
                    $ctx.AssetsCopied = $assetsToCopy.Count
                    $unreferenced = @($ctx.Inventory | Where-Object { $_.Kind -eq 'Asset' -and -not $assetsToCopy.Contains($_.RelativePath) }).Count
                    if ($unreferenced -gt 0) {
                        Add-PlaybookIssue -Context $ctx -Level Warning -Stage $stage -Code 'UnreferencedAssets' -Message "$unreferenced asset file(s) are not referenced by any page and were not published."
                    }
                }
                'SecretScan' {
                    $rules = Get-PlaybookSecretRules -Config $config
                    foreach ($page in $ctx.Pages) {
                        foreach ($finding in Find-PlaybookSecrets -Text $page.Text -Path $page.SourcePath -Rules $rules -Config $config) {
                            $ctx.Findings.Add($finding)
                            if ($finding.Allowlisted) { continue }
                            $level = if ($finding.Action -eq 'block') { 'Error' } else { 'Warning' }
                            Add-PlaybookIssue -Context $ctx -Level $level -Stage $stage -Code "Secret:$($finding.Rule)" -Path "$($finding.Path):$($finding.Line)" `
                                -Message "Fingerprint $($finding.Fingerprint), value $($finding.Preview)"
                        }
                    }
                }
                'Navigation' {
                    $pages = @($ctx.Pages)
                    if (-not ($pages | Where-Object TargetPath -eq 'index.md')) {
                        $homePage = New-PlaybookHomePage -SiteName $config.siteName -Pages $pages
                        [System.IO.File]::WriteAllText((Join-Path $ctx.Paths.Docs 'index.md'), $homePage, [System.Text.UTF8Encoding]::new($false))
                        $pages = @([pscustomobject]@{ SourcePath = 'index.md'; TargetPath = 'index.md'; Title = 'Home'; Text = $homePage }) + $pages
                    }
                    $nav = New-PlaybookNavYaml -Pages $pages -OrderLists (Get-PlaybookOrderLists -Inventory $ctx.Inventory)
                    $yaml = New-PlaybookMkDocsConfig -Config $config -NavYaml $nav
                    [System.IO.File]::WriteAllText($ctx.Paths.MkDocsConfig, $yaml, [System.Text.UTF8Encoding]::new($false))
                    [System.IO.File]::WriteAllText((Join-Path $ctx.Paths.Docs 'web.config'), (Get-PlaybookWebConfig), [System.Text.UTF8Encoding]::new($false))
                }
                'Build' {
                    Invoke-PlaybookBuild -Config $config -Context $ctx
                }
                'Diff' {
                    $deployed = Get-PlaybookDeployedManifest -Azure $config.azure -Slot 'production'
                    $ctx.Diff = Compare-PlaybookManifest -Current $ctx.Manifest -Deployed $deployed
                    Write-Host "  added $($ctx.Diff.Added.Count), changed $($ctx.Diff.Changed.Count), removed $($ctx.Diff.Removed.Count), unchanged $($ctx.Diff.Unchanged)"
                }
                'Preflight' {
                    $ctx.Preflight = @(Test-PlaybookPreflight -Config $config)
                    foreach ($c in $ctx.Preflight | Where-Object { -not $_.Passed }) {
                        Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code 'PreflightFailed' -Message "$($c.Check). $($c.Detail)"
                    }
                }
                'Deploy' {
                    if ($ctx.Diff.NoChanges -and -not $Force) {
                        Write-Host '  Content hash matches production: nothing to deploy.'
                        $ctx.Deployment = [ordered]@{ Status = 'Skipped'; Reason = 'NoChanges' }
                        break
                    }
                    $azure = $config.azure
                    if ($PSCmdlet.ShouldProcess("$($azure.appName) (slot $($azure.slot), then swap to production)", 'Deploy playbook site')) {
                        $zip = Invoke-PlaybookZipDeploy -Azure $azure -ZipPath $ctx.Paths.Zip -Slot $azure.slot
                        $smoke = @(Test-PlaybookSmoke -Azure $azure -Slot $azure.slot -ExpectedHash $ctx.Manifest.contentHash)
                        $ctx.Deployment = [ordered]@{ Status = 'DeployedToSlot'; KuduDeploymentId = $zip.DeploymentId; SlotChecks = $smoke }
                        $failed = @($smoke | Where-Object { -not $_.Passed })
                        if ($failed.Count -gt 0) {
                            foreach ($c in $failed) { Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code 'SlotCheckFailed' -Message "$($c.Check). $($c.Detail)" }
                            break   # production untouched
                        }

                        Switch-AzWebAppSlot -ResourceGroupName $azure.resourceGroup -Name $azure.appName `
                            -SourceSlotName $azure.slot -DestinationSlotName 'production' -ErrorAction Stop | Out-Null
                        $after = @(Test-PlaybookSmoke -Azure $azure -Slot 'production' -ExpectedHash $ctx.Manifest.contentHash)
                        $ctx.Deployment.Status = 'Swapped'
                        $ctx.Deployment['ProductionChecks'] = $after
                        foreach ($c in $after | Where-Object { -not $_.Passed }) {
                            Add-PlaybookIssue -Context $ctx -Level Error -Stage $stage -Code 'ProductionCheckFailed' `
                                -Message "$($c.Check). $($c.Detail) Run Invoke-PlaybookRollback to swap back."
                        }
                    }
                }
            }

            $timer.Stop()
            $stageErrors = $ctx.Errors.Count - $errorsBefore
            $ctx.Stages.Add([pscustomobject]@{ Stage = $stage; Seconds = [Math]::Round($timer.Elapsed.TotalSeconds, 1); Errors = $stageErrors })
            Write-Host "[$stage] finished in $([Math]::Round($timer.Elapsed.TotalSeconds, 1)) s, $stageErrors error(s)"

            if ($ctx.Errors.Count -gt 0) {
                throw "Stage '$stage' failed with $($ctx.Errors.Count) error(s). Nothing was deployed past this point. See the report."
            }
        }

        $ctx.Result = if ($WhatIfPreference) { 'WhatIf' }
                      elseif ($Offline) { 'ValidatedOffline' }
                      elseif ($ctx.Deployment -and $ctx.Deployment.Status -eq 'Skipped') { 'NoChanges' }
                      elseif ($last -lt [array]::IndexOf($script:StageNames, 'Deploy')) { "StoppedAfter$StopAfter" }
                      else { 'Deployed' }
    }
    catch {
        $ctx.Result = 'Failed'
        if ($ctx.Errors.Count -eq 0) {
            Add-PlaybookIssue -Context $ctx -Level Error -Stage 'Run' -Code 'Exception' -Message $_.Exception.Message
        }
        throw
    }
    finally {
        Write-PlaybookReport -Context $ctx
        Write-Host "Result: $($ctx.Result). Report: $($ctx.Paths.Report)"
    }

    return [pscustomobject]@{
        Result      = $ctx.Result
        ContentHash = if ($ctx.Manifest) { $ctx.Manifest.contentHash } else { $null }
        Errors      = $ctx.Errors.Count
        Warnings    = $ctx.Warnings.Count
        ReportPath  = $ctx.Paths.Report
    }
}

function Invoke-PlaybookRollback {
    <#
    .SYNOPSIS
        Swaps production with the staging slot, which holds the previous release after a deploy.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([Parameter(Mandatory)][string]$ConfigPath)

    $config = Read-PlaybookConfig -Path $ConfigPath
    Assert-PlaybookAzureConfig -Config $config
    Assert-PlaybookAzureModules
    $azure = $config.azure

    $slotManifest = Get-PlaybookDeployedManifest -Azure $azure -Slot $azure.slot
    if (-not $slotManifest) { throw "Slot '$($azure.slot)' has no release to roll back to." }

    if ($PSCmdlet.ShouldProcess("$($azure.appName): restore release $($slotManifest.contentHash.Substring(0, 12)) from slot '$($azure.slot)'", 'Swap slots')) {
        Switch-AzWebAppSlot -ResourceGroupName $azure.resourceGroup -Name $azure.appName `
            -SourceSlotName $azure.slot -DestinationSlotName 'production' -ErrorAction Stop | Out-Null
        $checks = @(Test-PlaybookSmoke -Azure $azure -Slot 'production' -ExpectedHash $slotManifest.contentHash)
        $checks | Format-Table -AutoSize | Out-String | Write-Host
        if (@($checks | Where-Object { -not $_.Passed }).Count -gt 0) { throw 'Rollback swap completed but production checks failed.' }
    }
}

#endregion

Export-ModuleMember -Function Publish-PlaybookSite, Invoke-PlaybookRollback, ConvertTo-PlaybookSlug
