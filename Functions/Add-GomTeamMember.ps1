function Add-GomTeamMember {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [string]
        $TeamName,

        [Parameter(Mandatory)]
        [string]
        $UserName
    )

    $IsMember = Test-GitHubOrganizationMember -OrganizationName $OrganizationName -UserName $UserName

    if($IsMember){
        Write-Host "Adding user '$UserName' to team '$TeamName' in organization '$OrganizationName'."
        $AddUserToTeam = @{
            Method = 'Put'
            UriFragment = "orgs/$OrganizationName/teams/$TeamSlug/memberships/$UserName"
        }
        Invoke-GHRestMethod @AddUserToTeam
    } else {
        Write-Error "User '$UserName' is not a member of organization '$OrganizationName' so they cannot be added to team '$TeamName'."
    }
}
