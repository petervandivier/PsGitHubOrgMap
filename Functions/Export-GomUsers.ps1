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
        $UserConfig = [PsCustomObject]@{
            Name = $_.UserName
            Id = $_.UserId
        }

        if($_.site_admin){
            $UserConfig | Add-Member -MemberType NoteProperty -Name IsSiteAdmin -Value $true
        }

        if($_.type -ne 'User'){
            $UserConfig | Add-Member -MemberType NoteProperty -Name UserType -Value $_.type
        }

        $UserConfig | ConvertTo-Json | Set-Content "$($_.UserName).json"
    }

    Pop-Location
}