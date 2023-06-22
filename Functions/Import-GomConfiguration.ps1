
function Import-GomConfiguration {
    [CmdletBinding(DefaultParameterSetName='ByProfile')]
    param (
        [Parameter(ParameterSetName='ByProfile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ProfileName = 'Default',

        [Parameter(ParameterSetName='ByOrganization')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName
    )

    if($PsCmdlet.ParameterSetName -eq 'ByOrganization'){
        $ProfileName = (
            Get-Content $HOME/.PsGitHubOrgMap/Organizations.csv 
            | ConvertFrom-Csv
            | Where-Object OrganizationName -eq $OrganizationName
        ).ProfileName
        if($null -eq $ProfileName){
            throw "No profile mapping found in ~/.PsGitHubOrgMap/Organizations.csv for input Organization '$OrganizationName'."
        }
    }

    $GomConfiguration = Get-Content "~/.PsGitHubOrgMap/${ProfileName}.json" | ConvertFrom-Json

    if($null -eq $GomConfiguration){
        throw "Missing or invalid configuration for profile '$ProfileName'."
    }

    $GomConfiguration.Repository.Directory = Resolve-Path $GomConfiguration.Repository.Directory | Get-Item

    New-Variable -Scope Global -Name GomConfiguration -Value $GomConfiguration -Force

    $global:PSDefaultParameterValues['*Gom*:OrganizationName'] = $GomConfiguration.OrganizationName
    $global:PSDefaultParameterValues['*Gom*:RepoBaseDirectory'] = $GomConfiguration.Repository.Directory.ResolvedTarget
}
