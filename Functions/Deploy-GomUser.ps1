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
        Write-Verbose "User '$UserName' is already a member of Organization '$OrganizationName'. Validating permissions..." 
        $GetUserRole = @{
            UriFragment = "orgs/$OrganizationName/memberships/$UserName"
            Method = "Get"
        }
        
        $CurrentRole = $(Invoke-GHRestMethod @GetUserRole).Role
        if($CurrentRole -ne $UserRole){
            Write-Verbose "User '$USerName' is currently assigned the '$CurrentRole' role. Assigning user '$UserName' to role '$UserRole'."
            $UpdateRole = @{
                UriFragment = "orgs/$OrganizationName/memberships/$UserName"
                Method = "Put"
                Body = @{
                    role = $UserRole
                } | ConvertTo-Json -Compress
            }
            Invoke-GHRestMethod @UpdateRole | Out-Null
            Write-Verbose "Successfully updated user '$UserName'."
            return
        }
        else{Write-Verbose "User '$UserName' already has their role correctly set."}
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
        Write-Host "Inviting user '$UserName' to join organization '$OrganizationName' with with role '$UserRole'."
        $Invite = Invoke-GHRestMethod @InviteUser
        Write-Host "Successfully invited user '$UserName' to organization '$OrganizationName'"
        $Invite.inviter = $Invite.inviter | Select-Object -ExcludeProperty *url, gravatar_id
        $RepoRoot = $GomConfiguration.Repository.Directory
        $InvitesDirectory = New-Item -Path "$RepoRoot/Users/Invites" -ItemType Directory -Force
        $Invite | ConvertTo-Json | Set-Content "${InvitesDirectory}/${UserName}.json" -Force | Out-Null
    }
}
