function Export-GomRepo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]
        $RepoBaseDirectory = "."
    )

    Push-Location "$RepoBaseDirectory/Repos"

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

        $repo | ConvertTo-Json -Depth 5 | Set-Content "${repoName}.json"
    }

    Pop-Location
}