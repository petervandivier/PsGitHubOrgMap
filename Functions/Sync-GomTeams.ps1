function Sync-GomTeams {
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

    Push-Location $GomConfiguration.Repository.Directory

    $ExistingTeams = Get-GitHubTeam -OrganizationName $OrganizationName
    $ConfigTeams = Get-ChildItem "Teams/*.json" | ForEach-Object {
        Get-Content $_.FullName | ConvertFrom-Json
    }

    foreach($Team in $ConfigTeams){
        $TeamName = $Team.Name
        $ExistingTeam = $ExistingTeams | Where-Object name -eq $TeamName
        if($null -eq $ExistingTeam){
            Write-Verbose "Adding team '$TeamName' to ozrganization '$OrganizationName'."
        } else {
            Write-Verbose "Deploying exist team '$TeamName' in organization '$OrganizationName'."
        }
        Deploy-GomTeam `
            -OrganizationName $OrganizationName `
            -TeamName $TeamName `
            -Description $Team.Description `
            -Privacy $Team.Privacy `
            -Members $Team.Members
    }

    $ExistingTeams | Where-Object name -NotIn $ConfigTeams.Name | ForEach-Object {
        Write-Verbose "Deleting team '$TeamName' from organization '$OrganizationName'."
        Remove-GitHubTeam -OrganizationName $OrganizationName -TeamName $TeamName
    }

    Pop-Location
}
