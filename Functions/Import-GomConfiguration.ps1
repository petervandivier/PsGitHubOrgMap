
function Import-GomConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name = 'Default'
    )

    $GomConfiguration = Get-Content "~/.PsGitHubOrgMap/Default.json" | ConvertFrom-Json

    $GomConfiguration.Repository.Directory = Resolve-Path $GomConfiguration.Repository.Directory | Get-Item

    New-Variable -Scope Global -Name GomConfiguration -Value $GomConfiguration -Force
}
