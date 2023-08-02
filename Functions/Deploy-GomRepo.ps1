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
    $CodeOwnersPath = ".github/CODEOWNERS"
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
        $ExistingContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(Get-GithubContent -Path $CodeOwnersPath -RepositoryName $RepoName -OwnerName $OrganizationName).content))
        $CodeOwnersContent = ""
        foreach ($property in $($RepoConfig.CodeOwners | Get-Member -MemberType Properties)){
            $path = $property.Name
            $owners = $RepoConfig.CodeOwners.$path
            $CodeOwnersContent += "$path $owners`n"
        }
        Write-Verbose "Complete CODEOWNERS content for repo '$RepoName' is $CodeOwnersContent"
        
        if($ExistingContent -ne $CodeOwnersContent){
            $TempBranchName = "codeowners-$(Get-Date -Format FileDateTime)"
            Write-Verbose "Creating new branch '$TempBranchName' in repo '$RepoName' for CODEOWNERS changes."
            New-GitHubBranch -BranchName $ExistingRepo.default_branch -TargetBranchName $TempBranchName -RepositoryName $RepoName -OwnerName $OrganizationName | Out-Null
            Write-Verbose "Successfully created branch '$TempBranchName' in repo '$RepoName'."

            Write-Verbose "Writing new CODEOWNERS file to branch '$TempBranchName' in repo '$RepoName'."
            Set-GitHubContent -BranchName $TempBranchName -Path $CodeOwnersPath -RepositoryName $RepoName -OwnerName $OrganizationName -Content $CodeOwnersContent -CommitMessage "Updated CODEOWNERS`n[skip actions]"
            Write-Verbose "Successfully wrote CODEOWNERS file for repo '$RepoName' to $CodeOwnersPath in branch '$TempBranchName'."

            if($env:GITHUB_ACTION_LINK){$PRContext = "This PR was created by this Github Action run: $env:GITHUB_ACTION_LINK"}
            else{$PRContext = "This PR was created by user $env:USERNAME@$env:COMPUTERNAME with public IP $((Invoke-WebRequest -uri "http://ifconfig.me/ip").Content)."}
            $PullRequestBodyContent = "Updated CODEOWNERS. This PR was created automatically.`n`n$PRContext"

            Write-Verbose "Opening Pull Request to merge branch '$TempBranchName' into default branch '$($ExistingRepo.default_branch)'."
            $PullRequest = New-GitHubPullRequest -Title "Update CODEOWNERS" -Body $PullRequestBodyContent -RepositoryName $RepoName -OwnerName $OrganizationName -Head $TempBranchName -Base $ExistingRepo.default_branch
            Write-Verbose "Successfully created PR: $($PullRequest.html_url)"
        }
        else{Write-Verbose "CODEOWNERS content matches, no commits made to repo '$RepoName'."}
        
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
