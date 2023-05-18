function Export-GomRepos {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $OrganizationName,

        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]
        $RepoBaseDirectory = "."
    )

    Push-Location "$RepoBaseDirectory/Repos"

    Get-GitHubRepository -OrganizationName $OrganizationName | ForEach-Object {
        [PsCustomObject]@{
            Name = $_.name
            Id = $_.RepositoryId
            Url = $_.RepositoryUrl
            Description = $_.description
            DefaultBranch = $_.default_branch
            Permissions = $_.permissions
        } | ConvertTo-Json -Depth 5 | Set-Content "$($_.name).json"
    }

    Pop-Location
}