
function Initialize-GomConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name = 'Default'
    )

    $Folder = New-Item -ItemType Directory -Path "$HOME/.PsGitHubOrgMap" -Force

    New-Item -Path "$Folder/$Name.json" -Value "{}" -ErrorAction SilentlyContinue | Out-Null
}
