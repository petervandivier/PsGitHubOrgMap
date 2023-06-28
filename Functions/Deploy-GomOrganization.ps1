function Deploy-GomOrganization {
<#
.Synopsis
    From a directory of config files, provision assets in an existing GitHub org.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = "Just passing the `-WhatIf` var through to child calls."
    )]
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

    Write-Verbose "Deploying assets for organization '$OrganizationName' from directory '$RepoRoot'."
    Write-Verbose "Synchronizing users for organization '$OrganizationName'."
    Sync-GomUser -OrganizationName $OrganizationName

    Write-Verbose "Synchronizing teams for organization '$OrganizationName'."
    Sync-GomTeam -OrganizationName $OrganizationName

    Write-Verbose "Synchronizing repositories for organization '$OrganizationName'."
    Sync-GomRepo -OrganizationName $OrganizationName
}
