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

    # Create the repository if it doesn't exist
    if($null -eq $ExistingRepo){        
        Write-Host "Deploying NEW repository '$RepoName' to organization '$OrganizationName'."
        $ExistingRepo = New-GitHubRepository -OrganizationName $OrganizationName -RepositoryName $RepoName -AutoInit $true
    }
    
    # Make sure the repo has the desired default branch
    $DesiredDefaultBranch = $RepoConfig.DefaultBranch
    $CurrentDefaultBranch = $ExistingRepo.default_branch
    $OriginalDefaultBranch = $CurrentDefaultBranch
    if ($DesiredDefaultBranch -and $CurrentDefaultBranch -ne $DesiredDefaultBranch ){
        Write-Verbose "Default branch on repo '$RepoName' doesn't match the desired default branch from the config, updates will be made..."
        
        # Make sure the desired default branch actually exists first
        try{
            Write-Verbose "Checking if branch '$DesiredDefaultBranch' exists already on repo '$RepoName'..."
            Get-GitHubRepositoryBranch -OwnerName $OrganizationName -RepositoryName $RepoName -BranchName $DesiredDefaultBranch | Out-Null
            Write-Verbose "Branch '$DesiredDefaultBranch' exists."
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException]{
            Write-Verbose "Branch '$DesiredDefaultBranch' doesn't exist yet on repo '$RepoName', creating..."
            New-GitHubBranch -OwnerName $OrganizationName -RepositoryName $RepoName -TargetBranchName $DesiredDefaultBranch -BranchName $CurrentDefaultBranch | Out-Null
            Write-Verbose "Successfully created branch '$DesiredDefaultBranch' on repo '$RepoName'."
        }

        # Then update the default branch on the repo
        Write-Verbose "Updating default branch on repo '$RepoName' from '$CurrentDefaultBranch' to '$DesiredDefaultBranch'..."
        $UpdateDefaultBranch = @{
            UriFragment = "/repos/$OrganizationName/$RepoName"
            Method = "Patch"
            Body = @{
                default_branch = $DesiredDefaultBranch
            } | ConvertTo-Json
        }
        Invoke-GHRestMethod @UpdateDefaultBranch | Out-Null
        Write-Verbose "Successfully updated default branch on repo '$RepoName' from '$CurrentDefaultBranch' to '$DesiredDefaultBranch'."
        $CurrentDefaultBranch = $DesiredDefaultBranch
    }

    # Make sure branch protection is set correctly
    if($null -ne $RepoConfig.DefaultBranchIsProtected){
        Write-Verbose "Fetching current branch protection status for branch '$CurrentDefaultBranch' in repo '$RepoName'..."
        try{
            Get-GitHubRepositoryBranchProtectionRule -OwnerName $OrganizationName -RepositoryName $RepoName -BranchName $CurrentDefaultBranch | Out-Null
            Write-Verbose "Branch '$CurrentDefaultBranch' IS currently protected."
            $DefaultBranchCurrentlyProtected = $true
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException]{
            Write-Verbose "Branch '$CurrentDefaultBranch' IS NOT currently protected."
            $DefaultBranchCurrentlyProtected = $false
        }
        # If the default branch has changed, lets remove the old protection rule
        if($CurrentDefaultBranch -ne $OriginalDefaultBranch){
            try{
                Write-Verbose "Checking for existing branch protection rule on old default branch '$OriginalDefaultBranch'..."
                Get-GitHubRepositoryBranchProtectionRule -OwnerName $OrganizationName -RepositoryName $RepoName -BranchName $OriginalDefaultBranch | Out-Null
                $OldDefaultBranchHasProtectionRule = $true
                Write-Verbose "Found existing protection rule for branch '$OriginalDefaultBranch'."
            }
            catch [Microsoft.PowerShell.Commands.HttpResponseException]{
                $OldDefaultBranchHasProtectionRule = $false
                Write-Verbose "No existing protection rule for old default branch '$OriginalDefaultBranch' found."
            }
            if($OldDefaultBranchHasProtectionRule -eq $true){
                Write-Warning "Removing branch protection rule for old default branch '$OriginalDefaultBranch' on repo '$RepoName'..."
                Remove-GitHubRepositoryBranchProtectionRule -OwnerName $OrganizationName -RepositoryName $RepoName -BranchName $OriginalDefaultBranch -Force | Out-Null
                Write-Verbose "Successfully removed branch protection for old default branch '$OriginalDefaultBranch' on repo '$RepoName'."
            }
        }
        
        if(-not $DefaultBranchCurrentlyProtected -and $RepoConfig.DefaultBranchIsProtected -eq $true){
            Write-Verbose "Configuring branch protection rule on repo '$RepoName' for branch '$CurrentDefaultBranch'..."
            New-GitHubRepositoryBranchProtectionRule `
                -OwnerName $OrganizationName `
                -RepositoryName $RepoName `
                -BranchName $CurrentDefaultBranch `
                -DismissStaleReviews `
                -RequireCodeOwnerReviews `
                -RequireUpToDateBranches `
                -RequiredApprovingReviewCount 1
                | Out-Null
            Write-Verbose "Sucessfully added branch protection on repo '$RepoName' for branch '$CurrentDefaultBranch'."
        }
        elseif ($DefaultBranchCurrentlyProtected -eq $true -and $RepoConfig.DefaultBranchIsProtected -eq $false) {
            Write-Warning "Removing branch protection for branch '$CurrentDefaultBranch' on repo '$RepoName'..."
            Remove-GitHubRepositoryBranchProtectionRule -OwnerName $OrganizationName -RepositoryName $RepoName -BranchName $CurrentDefaultBranch -Force | Out-Null
            Write-Verbose "Successfully removed branch protection on repo '$RepoName' for branch '$CurrentDefaultBranch'."
        }
        else{
            Write-Verbose "No branch protection changes needed for repo '$RepoName'."
        }
    }

    # Configure CODEOWNERS for the repository
    if($RepoConfig.CodeOwners){
        try{$ExistingContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(Get-GithubContent -Path $CodeOwnersPath -RepositoryName $RepoName -OwnerName $OrganizationName).content))}
        catch{$ExistingContent = ""}
        
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
            New-GitHubBranch -BranchName $CurrentDefaultBranch -TargetBranchName $TempBranchName -RepositoryName $RepoName -OwnerName $OrganizationName | Out-Null
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
