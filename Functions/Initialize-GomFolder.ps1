function Initialize-GomFolder {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $RepoBaseDirectory
    )

    $Folder = New-Item -ItemType Directory -Path $RepoBaseDirectory

    Set-Location $Folder

    New-Item -ItemType Directory -Name Users
    New-Item -ItemType Directory -Name Teams
    New-Item -ItemType Directory -Name Repos
}
