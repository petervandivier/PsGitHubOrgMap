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
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    $RepoRoot = Resolve-Path $GomConfiguration.Repository.Directory

    Push-Location $RepoRoot

    # TODO: do not nuke these directories. Instead, do a per-file delete as needed
    Remove-Item -Recurse "$RepoRoot/Repos/*.json"
    Export-GomRepo -OrganizationName $OrganizationName

    Remove-Item -Recurse "$RepoRoot/Teams/*.json"
    Export-GomTeam -OrganizationName $OrganizationName

    Remove-Item -Recurse "$RepoRoot/Users/*.json"
    Export-GomUser -OrganizationName $OrganizationName

    Pop-Location
}
