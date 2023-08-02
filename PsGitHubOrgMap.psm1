
Push-Location $PsScriptRoot

Get-ChildItem Functions -File -Recurse -Filter *.ps1 | ForEach-Object {
    . $_.FullName
    Export-ModuleMember $_.BaseName
}

if(. Scripts/Test-GomConfiguration.ps1 -ErrorAction SilentlyContinue){
    Import-GomConfiguration -ProfileName Default
} else {
    Write-Warning "You are missing a ``Default`` configuration for module PsGitHubOrgMap. Execute ``Initialize-GomConfiguration`` and then ``Import-GomConfiguration`` before proceeding."
}

Pop-Location
