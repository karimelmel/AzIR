function Invoke-PSAzIRGetInstanceMetadata  {
    [CmdLetBinding()]
    param ( 
        [Parameter(Mandatory = $false)]
        [string]
        $FileName = "metdata_$((Get-Date -Format 'yyyyMMddHHmmss')).json",
        [Parameter(Mandatory = $false)]
        [string]
        $FilePath = ( $env:TEMP )

    )
    if(-not($PSBoundParameters.ContainsKey('FileName')) -and $FileName) {
        $FileName = (Join-Path $FilePath -ChildPath $FileName".json" )
    }
    Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | ConvertTo-Json -Depth 64 | Out-File -FilePath $FileName
}

Invoke-PSAzIRGetInstanceMetadata  
