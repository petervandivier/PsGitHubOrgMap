function Export-GomTeams {
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

    Push-Location "$RepoBaseDirectory/Teams"

    Get-GitHubTeam -OrganizationName $OrganizationName | ForEach-Object {
        [string[]]$members = (Get-GitHubTeamMember -OrganizationName $OrganizationName -TeamName $_.TeamName).UserName

        [PsCustomObject]@{
            Name = $_.TeamName
            Id = $_.TeamId
            Description = $_.Description
            Privacy = $_.privacy
            Members = $members
        } | ConvertTo-Json | Set-Content "$($_.TeamName).json"
    }

    Pop-Location
}