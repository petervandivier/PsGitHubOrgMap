function Export-GomUsers {
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

    Push-Location "$RepoBaseDirectory/Users"

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

        $OutFile = "${UserName}.json"

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

    Pop-Location
}