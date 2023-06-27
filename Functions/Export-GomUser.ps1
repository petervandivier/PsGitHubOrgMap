function Export-GomUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName
    )

    if($OrganizationName -ne $GomConfiguration.OrganizationName){
        Write-Warning "Changing active GitHub Org Map configuration from '$($GomConfiguration.OrganizationName)' to '$OrganizationName'."
        Import-GomConfiguration -OrganizationName $OrganizationName
    }

    $RepoRoot = $GomConfiguration.Repository.Directory

    Get-GitHubOrganizationMember -OrganizationName $OrganizationName | ForEach-Object {
        $UserName = $_.UserName

        $UserConfig = [PsCustomObject]@{
            Name = $UserName
            Id = $_.UserId
        }

        if($_.site_admin){
            $UserConfig | Add-Member -MemberType NoteProperty -Name IsSiteAdmin -Value $true
        }

        if($_.type -ne 'User'){
            $UserConfig | Add-Member -MemberType NoteProperty -Name UserType -Value $_.type
        }

        $OutFile = "${RepoRoot}/Users/${UserName}.json"

        if(Test-Path $OutFile){
            $NewConfig = $UserConfig | ConvertTo-Json -Compress
            $CurrentConfig = Get-Content $OutFile | ConvertFrom-Json | ConvertTo-Json -Compress
            if($NewConfig -eq $CurrentConfig){
                Write-Verbose "Config file for user '$UserName' is accurate."
            } else {
                Write-Verbose "Updating config file for user '$UserName'."
            }
        } else {
            Write-Verbose "Adding new config file for user '$UserName'."
        }

        $UserConfig | ConvertTo-Json | Set-Content $OutFile
    }
}
