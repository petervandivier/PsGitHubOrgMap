function Deploy-GomTeam {
<#
.Synopsis
    Create a team & add users. If the team alreasy exists, update membership to match.
.Description
    Team membership is managed via a different endpoint than team attribute management.
    This function allows you to manage a team's attributes & membership via a single call.
    TeamName & TeamSlug are expected to be immutable for the purposes of this function.
.Link
    https://docs.github.com/en/rest/teams/members?apiVersion=2022-11-28#add-or-update-team-membership-for-a-user
.Link
    https://docs.github.com/en/rest/teams/members?apiVersion=2022-11-28#remove-team-membership-for-a-user
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [Alias('Name')]
        [string]
        $TeamName,

        [string]
        $Description,

        [string]
        $Privacy,

        [string[]]
        $Members
    )

    $TeamSettings = @{
        OrganizationName = $OrganizationName
        TeamName = $TeamName
        Description = $Description
        Privacy = $Privacy
    }
    $Team = Get-GitHubTeam -OrganizationName $OrganizationName 
    | Where-Object TeamName -eq $TeamName 
    if($null -eq $Team){
        Write-Verbose "Adding new team '$TeamName' to organization '$OrganizationName'."
        $Team = New-GitHubTeam @TeamSettings
        $TeamSlug = $Team.TeamSlug
        foreach($UserName in $Members) {
            Add-GomTeamMember `
                -OrganizationName $OrganizationName `
                -TeamName $TeamName `
                -UserName $UserName
        }
        Write-Verbose "Team '$TeamName' created in organization '$OrganizationName'. Exporting Id number to config."
        Export-GomTeams -OrganizationName $OrganizationName -TeamName $TeamName
        return
    } else {
        $UpdateNeeded = $false
        if($Team.description -ne $Description){
            Write-Verbose "Team '$TeamName' description will change from '$($Team.description)' to '$Description'"
            $UpdateNeeded = $true
        }
        if($Team.privacy -ne $Privacy){
            Write-Verbose "Team '$TeamName' privacy will change from '$($Team.privacy)' to '$Privacy'"
            $UpdateNeeded = $true
        }
        if($Team.privacy -ne $Privacy){
            Write-Verbose "Team '$TeamName' privacy will change from '$($Team.privacy)' to '$Privacy'"
            $UpdateNeeded = $true
        }
        if($UpdateNeeded){
            Write-Verbose "Updating config for team '$TeamName' in organization '$OrganizationName'."
            $Team = Set-GitHubTeam @TeamSettings
        } else {
            Write-Verbose "Deployment state for team '$TeamName' matches config. No action needed."
        }
        $TeamSlug = $Team.TeamSlug
        $Members = $Members | Sort-Object
        $ExistingMembers = (Get-GitHubTeamMember -OrganizationName $OrganizationName -TeamName $TeamName).login | Sort-Object
        $MembershipDelta = Compare-Object -Reference $ExistingMembers -Difference $Members -IncludeEqual
        $MembershipDelta | ForEach-Object {
            $UserName = $_.InputObject
            switch ($_.SideIndicator) {
                '=>' { 
                    Write-Verbose "Adding user '$UserName' to team '$TeamName' in organization '$OrganizationName'."
                    Add-GomTeamMember `
                        -OrganizationName $OrganizationName `
                        -TeamName $TeamName `
                        -UserName $UserName
                 }
                '<=' { 
                    Write-Verbose "Removing user '$UserName' from team '$TeamName' in organization '$OrganizationName'."
                    $RmUserFromTeam = @{
                        Method = 'Delete'
                        UriFragment = "orgs/$OrganizationName/teams/$TeamSlug/memberships/$UserName"
                    }
                    Invoke-GHRestMethod @RmUserFromTeam
                }
                '==' {
                    Write-Verbose "User '$UserName' is already a member of team '$TeamName'. No action taken."
                }
            }
        }
    }
}
