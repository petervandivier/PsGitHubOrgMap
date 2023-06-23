function Export-GomTeams {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]
        $RepoBaseDirectory = "."
    )

    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
        $RepoBaseDirectory = $GomConfiguration.Repository.Directory
    }

    Push-Location "$RepoBaseDirectory/Teams"

    Get-GitHubTeam -OrganizationName $OrganizationName | ForEach-Object {
        $TeamName = $_.TeamName

        [string[]]$members = (Get-GitHubTeamMember -OrganizationName $OrganizationName -TeamName $TeamName).UserName

        $TeamConfig = [PsCustomObject]@{
            Name = $TeamName
            Id = $_.TeamId
            Description = $_.Description
            Privacy = $_.privacy
            Members = $members
        }

        $OutFile = "${TeamName}.json"

        if(Test-Path $OutFile){
            $NewConfig = $TeamConfig | ConvertTo-Json -Compress
            $CurrentConfig = Get-Content $OutFile | ConvertFrom-Json | ConvertTo-Json -Compress
            if($NewConfig -eq $CurrentConfig){
                Write-Verbose "Config file for user '$TeamName' is accurate."
            } else {
                Write-Verbose "Updating config file for team '$TeamName'."
            }
        } else {
            Write-Verbose "Adding new config file for team '$TeamName'."
        }

        $TeamConfig | ConvertTo-Json | Set-Content $OutFile
    }

    Pop-Location
}