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

        Write-Host "Adding new config file for repo '$repoName'."
        $repo | ConvertTo-Json -Depth 5 | Set-Content "$RepoBaseDirectory/Repos/${repoName}.json"
    }

    Pop-Location
}
