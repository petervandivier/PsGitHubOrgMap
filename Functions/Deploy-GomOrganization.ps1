function Deploy-GomOrganization {
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
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$($OrganizationName)'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    Push-Location $GomConfiguration.Repository.Directory

    Sync-GomUsers -OrganizationName $OrganizationName

    Get-ChildItem Teams/* | ForEach-Object {
        Deploy-GomTeam -OrganizationName $OrganizationName -TeamName $_.BaseName
    }

    Get-ChildItem Repos/* | ForEach-Object {
        Deploy-GomRepo -OrganizationName $OrganizationName -RepoName $_.BaseName
    }

    Pop-Location
}
