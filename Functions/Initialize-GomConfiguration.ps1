
function Initialize-GomConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ProfileName = 'Default',

        [Parameter(Mandatory)]
        [string]
        $OrganizationName
    )

    $GhOrganization = Invoke-GHRestMethod -UriFragment "orgs/$OrganizationName" -Method Get -ErrorAction SilentlyContinue

    if($null -eq $GhOrganization){
        throw "No GitHub Organization found with name '$OrganizationName'. Are you using the correct credentials?"
    }

    $Folder = New-Item -ItemType Directory -Path "$HOME/.PsGitHubOrgMap" -Force

    New-Item -Path "${Folder}/${ProfileName}.json" -Value "{}" -ErrorAction SilentlyContinue | Out-Null


    [PsCustomObject]@{
        OrganizationName = $OrganizationName
        ProfileName = $ProfileName
    } | Export-Csv -Append "${Folder}/Organizations.csv" -UseQuotes AsNeeded
}
