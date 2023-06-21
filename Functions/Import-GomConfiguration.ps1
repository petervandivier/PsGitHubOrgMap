
function Import-GomConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name = 'Default'
    )

    $GomConfiguration = Get-Content "~/.PsGitHubOrgMap/${Name}.json" | ConvertFrom-Json

    $GomConfiguration.Repository.Directory = Resolve-Path $GomConfiguration.Repository.Directory | Get-Item

    New-Variable -Scope Global -Name GomConfiguration -Value $GomConfiguration -Force

    $global:PSDefaultParameterValues['*Gom*:OrganizationName'] = $GomConfiguration.OrganizationName
    $global:PSDefaultParameterValues['*Gom*:RepoBaseDirectory'] = $GomConfiguration.Repository.Directory.ResolvedTarget
}
