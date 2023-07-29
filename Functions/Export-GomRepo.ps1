function Export-GomRepo {
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
    $RepoBaseDirectory = Resolve-Path $GomConfiguration.Repository.Directory

    Get-GitHubRepository -OrganizationName $OrganizationName | ForEach-Object {
        $repoName = $_.name
        $teams = @{}
        $permissions = Invoke-GHRestMethod -UriFragment "repos/$OrganizationName/$repoName/teams" -Method Get

        if($permissions.Count -gt 0){
            $permissions | ForEach-Object{
                $teams.Add($_.name,$_.permission)
            }
        }

        $repo = [PsCustomObject]@{
            Name = $repoName
            Id = $_.RepositoryId
            Url = $_.RepositoryUrl
            Description = $_.description
            DefaultBranch = $_.default_branch
        }

        if($teams.Count -gt 0){
            $repo | Add-Member -MemberType NoteProperty -Name Teams -Value $teams
        }
        
        Write-Verbose "Looking for CODEOWNERS file in $repoName at .github/CODEOWNERS"
        try{
            $codeOwnersFile = $($_ | Get-GithubContent -path .github/CODEOWNERS)
        }
        catch{
            Write-Verbose "No CODEOWNERS file found...`n"
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
        
        $repo | ConvertTo-Json -Depth 5 | Set-Content "$RepoBaseDirectory/Repos/${repoName}.json"
        Write-Host "Added new config file for repo '$repoName'."
    }

    Pop-Location
}
