function Sync-GomTeam {
<#
.Synopsis
    From an on-disk repo, deploy teams to an existing org. Delete teams not defined in config.
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName
    )

    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    $RepoRoot = Resolve-Path $GomConfiguration.Repository.Directory

    $ExistingTeams = Get-GitHubTeam -OrganizationName $OrganizationName
    $ConfigTeams = Get-ChildItem "$RepoRoot/Teams/*.json" | ForEach-Object {
        Get-Content $_ | ConvertFrom-Json
    }

    foreach($Team in $ConfigTeams){
        Deploy-GomTeam `
            -OrganizationName $OrganizationName `
            -TeamName $Team.Name `
            -Description $Team.Description `
            -Privacy $Team.Privacy `
            -Members $Team.Members
    }

    $ExistingTeams | Where-Object name -NotIn $ConfigTeams.Name | ForEach-Object {
        $TeamName = $_.TeamName
        Write-Verbose "Deleting team '$TeamName' from organization '$OrganizationName'."
        Remove-GitHubTeam -OrganizationName $OrganizationName -TeamName $TeamName
    }
}
