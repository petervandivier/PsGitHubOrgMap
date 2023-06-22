function Export-GomOrganization {
<#
.Synopsis
    Remove all files & re-initialize a GitHub Org Map to diff changes
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

    Remove-Item -Recurse Repos/*
    Export-GomRepos -OrganizationName $OrganizationName

    Remove-Item -Recurse Teams/*
    Export-GomTeams -OrganizationName $OrganizationName

    Remove-Item -Recurse Users/*
    Export-GomUsers -OrganizationName $OrganizationName

    Pop-Location
}
