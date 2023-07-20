function Sync-GomUser {
<#
.Link
    https://docs.github.com/en/rest/orgs/members?apiVersion=2022-11-28#remove-an-organization-member
#>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName
    )

    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    Push-Location $GomConfiguration.Repository.Directory

    $ExistingUsers = Get-GitHubOrganizationMember -OrganizationName $OrganizationName
    $ConfigUsers = Get-ChildItem "Users/*.json" | ForEach-Object {
        $FilePath = $_.FullName
        Get-Content $FilePath | ConvertFrom-Json | Select-Object *, @{
            Label = 'FilePath'
            Expression = {"$FilePath"}
        }
    }

    foreach($User in $ConfigUsers) {
        $UserName = $User.Name
        if($UserName -NotIn $ExistingUsers.login){
            Write-Host "Adding user '$UserName' to Organization '$OrganizationName'."
            Deploy-GomUser -OrganizationName $OrganizationName -UserName $UserName
        } else{
            Write-Verbose "User '$UserName' already exists in Organization '$OrganizationName'."
        }
    }

    $ExistingUsers | Where-Object {
        $_.login -NotIn $ConfigUsers.Name
    } | ForEach-Object {
        $UserName = $_.login
        Write-Host "Removing user '$UserName' from Organization '$OrganizationName'."
        $RemoveUser = @{
            UriFragment = "orgs/$OrganizationName/members/$UserName"
            Method  = 'Delete'
            Description = "Remove user '$UserName' from organization '$OrganizationName'."
        }
        # ?TODO: log something here? Delete response contains no payload
        # n.b. double-delete attempt throws a reasonably helpful error
        Invoke-GHRestMethod @RemoveUser
    }

    Pop-Location
}
