function Sync-GomRepo {
<#
.Synopsis
    From a directory of config files, deploy repositories to an existing org. Delete repos not defined in config.
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

    $ConfigRepos = Get-ChildItem "$RepoRoot/Repos/*.json" | ForEach-Object {
        Get-Content $_ | ConvertFrom-Json
    }

    $ExistingRepos = Get-GitHubRepository -OrganizationName $OrganizationName

    foreach($Repo in $ConfigRepos){
        Deploy-GomRepo `
            -OrganizationName $OrganizationName `
            -RepoName $Repo.Name `
    }

    $ExistingRepos | Where-Object name -NotIn $ConfigRepos.Name | ForEach-Object {
        $RepoName = $_.name
        Write-Verbose "Deleting Repo '$RepoName' from organization '$OrganizationName'."
        Remove-GitHubRepo -OrganizationName $OrganizationName -RepoName $RepoName
    }
}
