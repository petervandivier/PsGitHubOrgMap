function Deploy-GomOrganization {
<#
.Synopsis
    From a directory of config files, provision assets in an existing GitHub org.
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName
    )

    Sync-GomUser -OrganizationName $OrganizationName

    Sync-GomTeam -OrganizationName $OrganizationName

    Sync-GomRepo -OrganizationName $OrganizationName
}
