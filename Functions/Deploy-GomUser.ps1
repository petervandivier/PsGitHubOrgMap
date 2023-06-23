function Deploy-GomUser {
<#
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
        $UserName
    )

    $User = Get-GitHubUser -UserName $UserName -ErrorAction SilentlyContinue
    if($null -eq $User){
        throw "User '$UserName' not found on GitHub."
    }

    $IsMember = Test-GitHubOrganizationMember -OrganizationName $OrganizationName -UserName $UserName
    if($IsMember){
        Write-Verbose "User '$UserName' is already a member of Organization '$OrganizationName'."
        return
    }

    # TODO: test & handle for double-invite
    # TODO: add support for add-as-admin/billing manager
    # TODO: add teams
    $InviteUser = @{
        UriFragment = "orgs/$OrganizationName/invitations"
        Method  = 'Post'
        Body = @{
            invitee_id = $User.id
            role = "direct_member"
        } | ConvertTo-Json -Compress
        Description = "Invite user '$UserName' to join organization '$OrganizationName'."
    }
    Invoke-GHRestMethod @InviteUser
}
