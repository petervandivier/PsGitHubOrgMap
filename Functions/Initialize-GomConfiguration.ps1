
function Initialize-GomConfiguration {
<#
.Description
    Given an existing local GomFolder, registers a local configuration
    Assigning an OrgName & Repo to the directory.

.Example
    $GomConfig = @{
        ProfileName = "DBTrenches"
        OrgName = "DBTrenches"
        Repo = "OrgMap"
        Directory = "~/GitHub/DbTrenches.Orgmap"
    }
    Initialize-GomConfiguration @GomConfig

#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ProfileName = 'Default',

        [Parameter(Mandatory)]
        [Alias('OrgName')]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [Alias('RepoName')]
        [string]
        $RepositoryName,

        [Parameter(Mandatory)]
        [string]
        $Directory
    )

    $GhOrganization = Invoke-GHRestMethod -UriFragment "orgs/$OrganizationName" -Method Get -ErrorAction SilentlyContinue

    if($null -eq $GhOrganization){
        throw "No GitHub Organization found with name '$OrganizationName'. Are you using the correct credentials?"
    }

    $Folder = New-Item -ItemType Directory -Path "$HOME/.PsGitHubOrgMap" -Force

    if(-Not (Test-Path $Directory)){
        Write-Warning "Supplied directory '$Directory' could not be resolved. Config file content will not be valid."
    }

    $OrganizationConfig = [PsCustomObject]@{
        PsGitHubOrgMap = [PsCustomObject]@{
            ModuleVersion = (Get-Module PsGitHubOrgMap)[0].Version.ToString()
        }
        OrganizationName = $OrganizationName
        Repository = [PsCustomObject]@{
            Name = $RepositoryName
            Directory = $Directory
        }
    } | ConvertTo-Json

    $ConfigFile = "${Folder}/${ProfileName}.json"

    if(Test-Path $ConfigFile){
        $BackupConfigFile = "${Folder}/${ProfileName}_$(Get-Date -Format FileDateTime).json"
        Write-Warning "Config file for profile '$ProfileName' already exists. Backing up to '$BackupConfigFile'."
        Move-Item -Path $ConfigFile -Destination $BackupConfigFile
    }

    New-Item -Path $ConfigFile -Value $OrganizationConfig | Out-Null

    $OrgIndex = "${Folder}/Organizations.csv"
    $OrgList = Import-Csv $OrgIndex

    if($OrgList.OrganizationName -Contains $OrganizationName) {
        ($OrgList | Where-Object OrganizationName -eq $OrganizationName).ProfileName = $ProfileName
    } else {
        $OrgList += [PsCustomObject]@{
            OrganizationName = $OrganizationName
            ProfileName = $ProfileName
        }
    }

    $OrgList | Export-Csv $OrgIndex -UseQuotes AsNeeded
}
