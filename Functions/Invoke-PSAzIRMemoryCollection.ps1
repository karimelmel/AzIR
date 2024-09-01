 <#
.SYNOPSIS
    A super-function to Invoke-MemoryCollection process for forensic memory on Azure Virtual Machines.

.DESCRIPTION
    Triggers four distinctive functions as a single line to download required prerequisities and unzip the package, run the executable to acquire volatile memory and then upload the data to an Azure Storage Account.
    
.NOTES
    All parameters should be passed in a super-function to the corresponding functions. 
.EXAMPLE 
#>

function Invoke-PSAzIrMemoryCollection {
    [CmdLetBinding()]
    param ( 
        [Parameter(Mandatory = $false)]
        [array]
        $PackageUrls = @(
            "https://storage.googleapis.com/prod-releases/comae_toolkit/Comae-Toolkit-v20230117.zip",
            "https://aka.ms/downloadazcopy-v10-windows"),
        [Parameter(Mandatory = $false)]
        [string]
        $UnzipPath = ( Join-Path $env:TEMP -ChildPath "AzIrTools" ),
        [Parameter(Mandatory = $false)]
        [string]
        $DumpItExecuteable = (Join-Path $env:TEMP -ChildPath "AzIrTools\x64\DumpIt.exe" ),
        [Parameter(Mandatory = $false)]
        [string]
        $MemoryFileName = "mem_$((Get-Date -Format 'yyyyMMddHHmmss')).zdmp",
        [Parameter(Mandatory = $false)]
        [string]
        $MemoryFile = (Join-Path -Path $env:TEMP -ChildPath $MemoryFileName),
        [Parameter(Mandatory = $false)]
        [string]
        $StorageAccountName = '',
        [Parameter(Mandatory = $false)]
        [string]
        $StorAccContainerName = 'artifacts'
    )

    function Get-UnzippedPackages {
        param(
            [Parameter(Mandatory = $true)]
            [array]
            $PackageUrls,
            [Parameter(Mandatory = $true)]
            [string]
            $UnzipPath
        )
    

        foreach ($package in $PackageUrls) {
            try {
                Write-Host "Downloading the zip package from $package"
                $request = Invoke-WebRequest $package -UseBasicParsing

                Write-Host "Creating a new temporary directory"
                $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))

                Write-Host "Saving the package content to a temporary file"
                $tempFile = Join-Path $tempDir.FullName "$(Split-Path -Leaf $package).zip"
                [IO.File]::WriteAllBytes($tempFile, $request.Content)

                Write-Host "Extracting the contents of the zip file to the destination directory"
                Expand-Archive -Path $tempFile -DestinationPath $UnzipPath -Force

                Write-Host "Removing the temporary directory and its contents"
                Remove-Item $tempDir.FullName -Recurse -Force
            }
            catch {
                Write-Error "Failed to download and unzip package from $package. $_"
            }
        }

    }

    function Start-MemoryAcquisition {
        param(
            [Parameter(Mandatory = $true)]
            [string]
            $DumpItExecuteable,
            [Parameter(Mandatory = $true)]
            [string]
            $MemoryFile
        )

        try {
            Write-Information "Writing memory to file mem.dmp using DumpIt"
        (Test-Path $DumpItExecuteable)
            & $DumpItExecuteable /n /q /r /o $MemoryFile
        }
        catch {
            Write-Error -Message "Failed to initialize DumpIt $_"
        }
    }
    function Get-AzIrInstanceMetadata  {
        [CmdLetBinding()]
        param ( 
            [Parameter(Mandatory = $false)]
            [string]
            $FileName = "AzIrInstanceMetadata",
            [Parameter(Mandatory = $false)]
            [string]
            $FilePath = ( $env:TEMP )
    
        )
        if(-not($PSBoundParameters.ContainsKey('FileName')) -and $FileName) {
            $AzIrInstanceMetadataFile = (Join-Path $FilePath -ChildPath $FileName".json" )
        }
        Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | ConvertTo-Json -Depth 64 | Out-File -FilePath $AzIrInstanceMetadataFile
    }

    function Write-MemoryDumpToStorAcc {
        param (
            [Parameter(Mandatory = $true)]
            [string]$StorageAccountName,
            [Parameter(Mandatory = $true)]
            [string]$StorAccContainerName,
            [Parameter(Mandatory = $true)]
            [string]$MemoryFile
        )
        $destinationBlob
        $destinationBlobs =@(   
            "https://$StorageAccountName.blob.core.windows.net/$StorAccContainerName/$MemoryFileName",
            "https://$StorageAccountName.blob.core.windows.net/$StorAccContainerName/$AzIrInstanceMetadataFile" )
        $azCopyBinary = Get-ChildItem -Path $env:temp -Filter azcopy.exe -Recurse | Select-Object -ExpandProperty FullName
        $azMemoryFilePath = Join-Path -Path ([System.IO.Path]::GetFullPath($env:temp)) -ChildPath $MemoryFileName
        $azMemoryFilePath
        $MemoryFile
        try {
            & $azCopyBinary login --identity
            foreach ( $destinationBlob in $destinationBlobs ) {
                Write-Host "Uploading $azMemoryFilePath to $destinationBlob"
                & $azCopyBinary copy "$azMemoryFilePath" "$destinationBlob" --log-level="error" --check-length=false
            }
            & $azCopyBinary copy "$azMemoryFilePath" "$destinationBlob" --log-level="error" --check-length=false
        }
        catch {

            Write-Error -Exception $_.Exception -ErrorAction Stop
        }
    }

    $GetUnzippedPackagesParams = @{
        PackageUrls = $PackageUrls
        UnzipPath   = $UnzipPath
    } 
    Get-UnzippedPackages @GetUnzippedPackagesParams

    Get-AzIrInstanceMetadata

    $StartMemoryAcquisitionParams = @{
        DumpItExecuteable = $DumpItExecuteable
        MemoryFile        = $MemoryFile
    }
    Start-MemoryAcquisition @StartMemoryAcquisitionParams

    $WriteMemoryDumpToStorAcc = @{
        StorageAccountName   = $StorageAccountName
        StorAccContainerName = $StorAccContainerName
        MemoryFile           = $MemoryFile
    }
    Write-MemoryDumpToStorAcc @WriteMemoryDumpToStorAcc


}


Invoke-PSAzIrMemoryCollection 