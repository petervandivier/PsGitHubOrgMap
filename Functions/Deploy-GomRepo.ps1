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

    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    $RepoRoot = Resolve-Path $GomConfiguration.Repository.Directory

    $RepoConfig = Get-Content "${RepoRoot}/Repos/${RepoName}.json" | ConvertFrom-Json

    $ExistingRepo = Get-GitHubRepository -OwnerName $OrganizationName -RepositoryName $RepoName -ErrorAction SilentlyContinue

    if($null -eq $ExistingRepo){
        Write-Host "Deploying NEW repository '$RepoName' to organization '$OrganizationName'."
        New-GitHubRepository -OrganizationName $OrganizationName -RepositoryName $RepoName | Format-List
    }

    if($RepoConfig.CodeOwners){
        $CodeOwnersContent = ""
        foreach ($property in $($RepoConfig.CodeOwners | Get-Member -MemberType Properties)){
            $path = $($property.Name)
            $owners = $RepoConfig.CodeOwners.$path
            $CodeOwnersContent += "$path $owners`n"
        }
        Write-Verbose "Complete CODEOWNERS content is`n$CodeOwnersContent"
        Set-GitHubContent -Path .github/CODEOWNERS -RepositoryName $RepoName -OwnerName $OrganizationName -Content $CodeOwnersContent -CommitMessage "Added CODEOWNERS"
        Write-Host "Wrote CODEOWNERS file for $RepoName to .github/CODEOWNERS"
    }
    
    $ExistingPermissions = Invoke-GHRestMethod -UriFragment "repos/$OrganizationName/$RepoName/teams" -Method Get

    if(
        $null -eq $RepoConfig.Teams -and
        $null -eq $ExistingPermissions
    ){
        Write-Verbose "No permissions found in config or deployment for repo '$RepoName'."
    } else {
        Write-Verbose "Synchronizing permissions for repo '$RepoName'."
        Sync-GomRepositoryTeamPermission `
            -OrganizationName $OrganizationName `
            -RepoName $RepoName `
            -ConfigPermissions $RepoConfig.Teams `
            -ExistingPermissions $ExistingPermissions
    }
}
