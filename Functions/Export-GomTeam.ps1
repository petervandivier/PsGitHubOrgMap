function Export-GomTeam {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [string]
        $TeamName
    )

    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    $RepoRoot = $GomConfiguration.Repository.Directory

    $Teams = Get-GitHubTeam -OrganizationName $OrganizationName 

    if($PSBoundParameters.ContainsKey('TeamName')){
        Write-Verbose "Exporting single team: '$TeamName'."
        $Teams = $Teams | Where-Object name -eq $TeamName
        if($null -eq $Team){
            throw "No existing team found with name '$TeamName' in organization '$OrganizationName'."
        }
    }

    $Teams | ForEach-Object {
        $TeamName = $_.TeamName

        [string[]]$members = (
            Get-GitHubTeamMember -OrganizationName $OrganizationName -TeamName $TeamName
        ).UserName | Sort-Object

        $TeamConfig = [PsCustomObject]@{
            Name = $TeamName
            Id = $_.TeamId
            Description = $_.Description
            Privacy = $_.privacy
            Members = $members
        }

        $OutFile = "${RepoRoot}/Teams/${TeamName}.json"

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
}
