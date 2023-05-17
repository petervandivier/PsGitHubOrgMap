
Push-Location $PsScriptRoot

Get-ChildItem Functions -File -Recurse -Filter *.ps1 | ForEach-Object {
    . $_.FullName
    Export-ModuleMember $_.BaseName
}

Pop-Location
