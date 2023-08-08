function Export-GomRepo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName
    )
    $CodeOwnersPath = ".github/CODEOWNERS"
    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }
    $RepoBaseDirectory = Resolve-Path $GomConfiguration.Repository.Directory

    Get-GitHubRepository -OrganizationName $OrganizationName | ForEach-Object {
        $ExistingRepo = $_
        $repoName = $ExistingRepo.name
        Write-Verbose "Starting export for repo '$repoName'."
        $JSONConfigFilePath = "$RepoBaseDirectory/Repos/${repoName}.json"
        $teams = @{}
        $permissions = Invoke-GHRestMethod -UriFragment "repos/$OrganizationName/$repoName/teams" -Method Get

        if($permissions.Count -gt 0){
            $permissions | ForEach-Object{
                $teams.Add($_.name,$_.permission)
            }
        }

        $repo = [PsCustomObject]@{
            Name = $repoName
            Id = $ExistingRepo.RepositoryId
            Url = $ExistingRepo.RepositoryUrl
            Description = $ExistingRepo.description
            DefaultBranch = $ExistingRepo.default_branch
        }
        
        # Get teams  
        if($teams.Count -gt 0){
            $repo | Add-Member -MemberType NoteProperty -Name Teams -Value $teams
        }
        
        # Get Branch Protection
        Write-Verbose "Checking for protection status on branch '$($ExistingRepo.default_branch)'"
        try{
            Get-GitHubRepositoryBranchProtectionRule -OwnerName $OrganizationName -RepositoryName $repoName -BranchName $ExistingRepo.default_branch | Out-Null
            $DefaultBranchCurrentlyProtected = $true
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException]{
            $DefaultBranchCurrentlyProtected = $false
        }

        $repo | Add-Member -MemberType NoteProperty -Name DefaultBranchIsProtected -Value $DefaultBranchCurrentlyProtected
        
        # Get CODEOWNERS
        Write-Verbose "Looking for CODEOWNERS file in repo '$repoName' at $CodeOwnersPath"
        try{
            $codeOwnersFile = $($_ | Get-GithubContent -path $CodeOwnersPath)
        }
        catch{
            Write-Verbose "No CODEOWNERS file found in repo '$repoName'."
            $codeOwnersFile = $null
        }
        
        if($codeOwnersFile){ 
            $codeOwnersContent = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($codeOwnersFile.content))
            Write-Verbose "Found codeowners with content`n$codeOwnersContent"
            $lines = $codeOwnersContent -split "`n"
            $codeOwnersJson = @{}
            foreach ($line in $lines) {
                $lineChunks = $line -split " "
                $path = $lineChunks[0]
                $teamAssignments = $lineChunks[1..$lineChunks.Length] -join " "
                if($path){
                    $codeOwnersJson[$path] = $teamAssignments
                }
            }
            $repo | Add-Member -MemberType NoteProperty -Name CodeOwners -Value $codeOwnersJson
        }
        
        try{$existingJSONContent = Get-Content -Path $JSONConfigFilePath -ErrorAction Stop}
        catch{$existingJSONContent = @{}}

        if(Compare-Object $existingJSONContent $($repo | ConvertTo-Json)){
            $repo | ConvertTo-Json -Depth 5 | Set-Content $JSONConfigFilePath
            Write-Host "Updated config file for repo '$repoName'."
        }
        else{Write-Verbose "No changes required for repo '$repoName'."}
    }

    Pop-Location
}
