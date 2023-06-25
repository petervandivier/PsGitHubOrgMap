function Sync-GomTeams {
<#
.Synopsis
    From an on-disk repo, deploy assets to an existing org.
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

    Push-Location $GomConfiguration.Repository.Directory

    $ExistingTeams = Get-GitHubTeam -OrganizationName $OrganizationName
    $ConfigTeams = Get-ChildItem "Teams/*.json" | ForEach-Object {
        $FilePath = $_.FullName
        Get-Content $FilePath | ConvertFrom-Json | Select-Object *, @{
            Label = 'Organization'
            Expression = {"$OrganizationName"}
        } -ExcludeProperty Id
    }

    foreach($Team in $ConfigTeams){
        $TeamName = $Team.Name
        $ExistingTeam = $ExistingTeams | Where-Object name -eq $TeamName
        if($null -eq $ExistingTeam){
            Write-Verbose "Adding team '$TeamName' to Organization '$OrganizationName'."
            Deploy-GomTeam @Team
        } else {
            if($ConfigMatches){
                Write-Verbose "Deployment state for team '$TeamName' matches config. No action needed."
            } else {

            }
        }
    }

    $ExistingTeams | Where-Object name -NotIn $ConfigTeams.Name | ForEach-Object {
        Write-Verbose "Deleting team '$TeamName' from organization '$OrganizationName'."
        Remove-GitHubTeam -OrganizationName $OrganizationName -TeamName $TeamName
    }

    Pop-Location
}
