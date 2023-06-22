[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 
    '',
    Justification = "Pester scoping can't handle variables."
)]Param()

BeforeAll {
    $manifest =  Import-PowershellDataFile $PsScriptRoot/../PsGitHubOrgMap.psd1
    $control = ($manifest.FunctionsToExport) -join "`n"
    $test = ($manifest.FunctionsToExport | Sort-Object) -join "`n"
}

Describe "The manifest file" {
    It "Should list FunctionsToExport alphabetically." {
        Compare-Object -Reference $control -Difference $test | Should -BeNullOrEmpty
    }
}
