@{
    RootModule           = 'PlaybookSite.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = '65b52de1-b332-4429-8192-8a72b98d230b'
    Author               = 'SOC Platform Engineering'
    Description          = 'Validates, builds and deploys the SOC incident-handling playbooks as a static site on Azure App Service (stages F1-F11).'
    PowerShellVersion    = '7.4'
    CompatiblePSEditions = @('Core')

    # Az.Accounts / Az.Websites are only needed for the remote stages (Diff, Preflight, Deploy).
    # They are checked at runtime so that offline validation runs work without them.
    FunctionsToExport    = @(
        'Publish-PlaybookSite'
        'Invoke-PlaybookRollback'
        'ConvertTo-PlaybookSlug'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags = @('SOC', 'Playbooks', 'MkDocs', 'AppService', 'Azure')
        }
    }
}
