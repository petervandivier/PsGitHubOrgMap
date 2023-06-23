function Deploy-GomRepo {
    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess', 
        '',
        Justification = "Just passing the `-WhatIf` var through to child calls."
    )]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [Alias('RepositoryName')]
        [string]
        $RepoName
    )

    $RepoConfig = Get-Content "Repos/${RepoName}.json" | ConvertFrom-Json

    $ExistingRepo = Get-GitHubRepository -OwnerName $OrganizationName -RepositoryName $RepoName

    if($null -eq $ExistingRepo){
        Write-Verbose "Deploying NEW repository '$RepoName' to organization '$OrganizationName'."
        New-GitHubRepo
    } else {
        $ExistingPermissions = Invoke-GHRestMethod -UriFragment "repos/$OrganizationName/$RepoName/teams" -Method Get

        $SyncPerms = @{
            OrganizationName = $OrganizationName
            RepoName = $RepoName
            ConfigPermissions = $RepoConfig.Teams
            ExistingPermissions = $ExistingPermissions
        }

        Sync-GomRepositoryTeamPermissions @SyncPerms
    }
}
