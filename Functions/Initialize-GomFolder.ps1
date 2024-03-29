function Initialize-GomFolder {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $RepoBaseDirectory
    )

    $Folder = New-Item -ItemType Directory -Path $RepoBaseDirectory -Force

    Set-Location $Folder

    New-Item -ItemType Directory -Name Users -Force
    New-Item -ItemType Directory -Name Teams -Force
    New-Item -ItemType Directory -Name Repos -Force
}
