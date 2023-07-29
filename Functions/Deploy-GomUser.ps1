function Deploy-GomUser {
<#
.Synopsis
    Invite a user to an organization.
.Description
    Note: an invite is idempotent. Attempting to re-sending the same invite multiple times
    should have no adverse affect.
.Link
    https://docs.github.com/en/rest/orgs/members?apiVersion=2022-11-28#create-an-organization-invitation
#>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [string]
        $UserName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserRole
    )

    $User = Get-GitHubUser -UserName $UserName -ErrorAction SilentlyContinue
    if($null -eq $User){
        throw "User '$UserName' not found on GitHub."
    }

    $IsMember = Test-GitHubOrganizationMember -OrganizationName $OrganizationName -UserName $UserName
    if($IsMember){
        Write-Verbose "User '$UserName' is already a member of Organization '$OrganizationName'. Ensuring '$UserName' has $UserRole level permissions..."
        $UpdateRole = @{
            UriFragment = "orgs/$OrganizationName/memberships/$UserName"
            Method = "Put"
            Body = @{
                role = $UserRole
            } | ConvertTo-Json -Compress
        }
        Invoke-GHRestMethod @UpdateRole | Out-Null
        return
    } else {
        $InviteUser = @{
            UriFragment = "orgs/$OrganizationName/invitations"
            Method  = 'Post'
            Body = @{
                invitee_id = $User.id
                role = if($UserRole -eq "admin") {"admin"} else {"direct_member"}
            } | ConvertTo-Json -Compress
            Description = "Invite user '$UserName' to join organization '$OrganizationName'."
        }
        Write-Host "Inviting user '$UserName' to join organization '$OrganizationName' with $UserRole permissions."
        $Invite = Invoke-GHRestMethod @InviteUser

        $Invite.inviter = $Invite.inviter | Select-Object -ExcludeProperty *url, gravatar_id
        $RepoRoot = $GomConfiguration.Repository.Directory
        $InvitesDirectory = New-Item -Path "$RepoRoot/Users/Invites" -ItemType Directory -Force
        $Invite | ConvertTo-Json | Set-Content "${InvitesDirectory}/${UserName}.json" -Force | Out-Null
    }
}
