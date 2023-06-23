function Sync-GomRepositoryTeamPermissions {
    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess', 
        '',
        Justification = "Just passing the `-WhatIf` var through to child calls."
    )]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [Alias('RepositoryName')]
        [string]
        $RepoName,

        [Parameter(Mandatory)]
        [Alias('ConfigPerms')]
        [PsCustomObject]
        $ConfigPermissions,

        [Parameter(Mandatory)]
        [Alias('ExistingPerms')]
        [PsCustomObject]
        $ExistingPermissions
    )

    $JoinedPermissions = $ConfigPermissions.PsObject.Properties | ForEach-Object {
        $TeamName = $_.Name
        $TeamRole = $_.Value
        $ExistingTeam = $ExistingPermissions | Where-Object name -eq $TeamName
        if($null -eq $ExistingTeam){
            $Action = 'ADD_TEAM'
        } elseif ($TeamRole -eq $ExistingTeam.permission) {
            $Action = 'NO_ACTION'
        } else {
            $Action = 'UPDATE_ROLE'
        }
        [PsCustomObject]@{
            TeamName = $TeamName
            TeamRole = $TeamRole
            Action = $Action
            PreviousRole = $ExistingTeam.permission
        }
    }

    $ExistingPermissions | Where-Object {
        $_.name -NotIn $JoinedPermissions.TeamName
    } | ForEach-Object {
        $JoinedPermissions += [PSCustomObject]@{
            TeamName = $TeamName
            TeamRole = $null
            Action = 'DELETE_TEAM'
        }
    }

    foreach($Permission in $JoinedPermissions){
        $TeamName = $Permission.TeamName
        $TeamRole = $Permission.TeamRole
        switch ($Permission.Action) {
            'NO_ACTION' {
                Write-Verbose "Config matches deployment for Team '$TeamName' with role '$TeamRole' in repo '$RepoName'." 
            }
            'ADD_TEAM' {
                Write-Verbose "Adding team '$TeamName' with role '$TeamRole' to repo '$RepoName'."
                Set-GitHubRepositoryTeamPermission
            }
            'UPDATE_ROLE' {
                Write-Verbose "Updating team '$TeamName' with role '$TeamRole' to repo '$RepoName'."
                Set-GitHubRepositoryTeamPermission

            }
            'DELETE_TEAM' {
                Write-Verbose "Remoive team '$TeamName' with role '$TeamRole' from repo '$RepoName'."
                Remove-GitHubRepositoryTeamPermission
            }
        }
    }
}