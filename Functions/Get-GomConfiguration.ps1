function Get-GomConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('PsObject','Json')]
        [string]
        $As = 'Json'
    )

    switch($As){
        'PsObject' { $GomConfiguration }
        'Json' {
            # PsObject.Copy() bugging out here. TODO: debug & .Copy() properly
            $ReturnObject = $GomConfiguration | 
                ConvertTo-Json -Depth 3 -WarningAction SilentlyContinue | 
                ConvertFrom-Json
            $ReturnObject.Repository.Directory = $ReturnObject.Repository.Directory.FullName
            $ReturnObject | ConvertTo-Json
        }
    }
}
