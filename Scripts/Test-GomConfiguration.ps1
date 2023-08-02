<#
.Description
    Not sure why this doesn't work as a function but it only works as a script
#>
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]
    $ProfileName = 'Default'
)

$ConfigFilePath = "~/.PsGitHubOrgMap/${ProfileName}.json"
$ErrorCount = 0

$CurrentAuthenticatedUser = (Invoke-GHRestMethod -UriFragment "user" -Method Get).login
Write-Verbose "You are currently authenticated as ${CurrentAuthenticatedUser}."

if($false -eq (Test-Path $ConfigFilePath)){
    Write-Error "Config file not found for profile ${ProfileName}."
    $ErrorCount++
} else {
    Write-Verbose "Config file exists for profile ${ProfileName}."

    $Config = Get-Content $ConfigFilePath | ConvertFrom-Json

    if($null -eq $Config.PsGitHubOrgMap.ModuleVersion){
        Write-Warning "Config file for profile ${ProfileName} missing PSModule version pin."
    } else {
        Write-Verbose "Config file for profile ${ProfileName} is pinned to PSModule version '$($Config.PsGitHubOrgMap.ModuleVersion)'."
    }

    $Organization = Invoke-GHRestMethod -UriFragment "orgs/$($Config.OrganizationName)" -Method Get
    if($null -eq $Organization){
        Write-Error "Organization '$($Config.OrganizationName)' not reachable by user '$CurrentAuthenticatedUser'."
        $ErrorCount++
    } else {
        Write-Verbose "Organization '$($Config.OrganizationName)' is reachable by user '$CurrentAuthenticatedUser'."
    }

    $RepoBaseDirectory = $Config.Repository.Directory
    if(Test-Path $RepoBaseDirectory){
        Write-Verbose "Local path '$($RepoBaseDirectory)' exists."
        foreach($subdir in @('Users','Teams','Repos')){
            if($false -eq (Test-Path $RepoBaseDirectory/$subdir -PathType Container)){
                Write-Error "Config repo is missing subdirectory '/$subdir'. Execute ``Initialize-GomFolder '$RepoBaseDirectory'``"
                $ErrorCount++
            }
        }

    } else {
        Write-Error "Local path '$($RepoBaseDirectory)' not found. Execute ``Initialize-GomFolder '$RepoBaseDirectory'``"
        $ErrorCount++
    }

    #?TODO? validate $Config.Repository.Name
}

if($ErrorCount -eq 0){
    Write-Verbose "Config file for profile '$ProfileName' validated without errors."
    $true
    return
} else {
    Write-Error "Config file validation for profile '$ProfileName' failed. See previous errors."
    $false
    return
}
