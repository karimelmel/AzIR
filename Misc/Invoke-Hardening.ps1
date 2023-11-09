<#
.SYNOPSIS
    Function for downloading and executing HardeningKitty
    https://github.com/scipag/HardeningKitty

.DESCRIPTION
    Triggers three distinctive functions as a single line to apply hardening and passing the parameters.
    
.PARAMETER FileFindingList
    The path to the CSV file for HardeningKitty configuration.

.PARAMETER HardeningKittyPath
    The path to where HardeningKitty module is imported from.

.PARAMETER UnzipPath
    The path to where the downloaded file is unzipped to.

.PARAMETER PackageUrl
    The URL to the zip package to download and extract.

.NOTES
    All parameters are passed in the super-function to the corresponding functions. 

.EXAMPLE 
    Invoke-Hardening
    Invoke-Hardening -FileFindingList <path to custom file finding list>
#>

function Invoke-Hardening {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]
        $FileFindingList = (Join-Path -Path $env:TEMP -ChildPath "SecurityBaseline\HardeningKitty-v.0.9.0\lists\finding_list_0x6d69636b_machine.csv"),
        [string]
        $HardeningKittyPath = ( Join-Path $env:TEMP -ChildPath "SecurityBaseline\HardeningKitty-v.0.9.0" ),
        [Parameter(Mandatory = $false)]
        [string]
        $UnzipPath = ( Join-Path $env:TEMP -ChildPath "SecurityBaseline" ),
        [Parameter(Mandatory = $false)]
        [string]
        $PackageUrl = "https://github.com/scipag/HardeningKitty/archive/refs/tags/v.0.9.0.zip"
    )

    function Get-UnzippedPackage {
        param(
            [Parameter(Mandatory = $true)]
            [string]
            $PackageUrl,
            [Parameter(Mandatory = $true)]
            [string]
            $UnzipPath
        )
        try {

            Write-Information -MessageData "Downloading the zip package from the $PackageUrl"
            $package = Invoke-WebRequest $PackageUrl -UseBasicParsing

            Write-Information -MessageData "Creating a new temporary directory"
            $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))

            Write-Information -MessageData "Saving the package content to a temporary file"
            $tempFile = Join-Path $tempDir.FullName "package.zip"
            [IO.File]::WriteAllBytes($tempFile, $package.Content)
        
            Write-Information -MessageData "Extracting the contents of the zip file to the destination directory"
            Expand-Archive -Path $tempFile -DestinationPath $UnzipPath -Force

            Write-Information -MessageData "Removing the temporary directory and its contents"
            Remove-Item $tempDir.FullName -Recurse -Force
        }
        catch {
            Write-Error -Message "Failed to download and unzip package from $Url. $_"
        }
    }

    function Invoke-HardeningKittyHelper {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]
            $FileFindingList,
            [Parameter(Mandatory = $true)]
            [string]
            $HardeningKittyPath
        )
        try {
            Write-Information -MessageData "Importing the HardeningKitty module"
            Import-Module -Name (Join-Path -Path $HardeningKittyPath -ChildPath "HardeningKitty.psm1") -ErrorAction Stop
        }
        catch {
            Write-Error -Message "Failed to import module from $HardeningKittyPath. $_"
            return
        }
    
        try {
            Write-Information -MessageData "Invoking the HardeningKitty script with the FileFindingList provided"
            Invoke-HardeningKitty -FileFindingList $FileFindingList -Mode HailMary -Log -Report -SkipRestorePoint
        }
        catch {
            Write-Error -Message "Failed to run Invoke-HardeningKitty. $_"
        }
    }

    $GetUnzippedPackageParams = @{ 
        PackageUrl = $PackageUrl 
        UnzipPath  = $UnzipPath
    }
    Get-UnzippedPackage @GetUnzippedPackageParams

    $InvokeHardeningKittyHelperParams = @{
        FileFindingList    = $FileFindingList 
        HardeningKittyPath = $HardeningKittyPath
    }
    Invoke-HardeningKittyHelper @InvokeHardeningKittyHelperParams
}

Invoke-Hardening