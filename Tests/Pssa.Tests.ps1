
Describe "PowerShell Script Analyzer" {
    It "Should return an empty object" {
        Invoke-ScriptAnalyzer -Path $PsScriptRoot/.. -Recurse | Should -BeNullOrEmpty
    }
}
