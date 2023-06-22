function Deploy-GomRepo {
    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess', 
        '',
        Justification = "Just passing the `-WhatIf` var through to child calls."
    )]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,

        [Parameter(Mandatory)]
        [Alias('RepositoryName')]
        [string]
        $RepoName
    )

    $ExistingRepo = Get-GitHubRepository -OwnerName $OrganizationName -RepositoryName $RepoName

    if($null -eq $ExistingRepo){
        Write-Verbose "Deploying NEW repository '$RepoName' to organization '$OrganizationName'."
        New-GitHubRepo
    } else {
        Set-GitHubRepository
    }
}
