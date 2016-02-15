<#
.SYNOPSIS
    Save a URLs HTML source code to file.
.DESCRIPTION
    This script downloads a given URLs HTML source code and saves it to a file.
.PARAMETER getsource
    URL to download the HTML source code from.
.PARAMETER directory
    Specifies a path to save results to. 
.EXAMPLE
    C:\PS> .\Get-Page-Source.ps1 -getsource www.google.com -directory C:\Temp -p
    Prompt for authentication details, get the HTML source code for www.google.com and save results to the C:\Temp directory.

.TODO

.NOTES
    Author: Simon
    Date:   2016 FEB 15
    Not a Powershell guru so go easy.
#>

[CmdletBinding(DefaultParameterSetName='-p')]

Param (    
    [Parameter(Mandatory=$true)][string]$getsource, # URL to retrieve source code for.
    [Parameter(Mandatory=$true)][string]$directory,  # Directory to save results.
    [Parameter(ParameterSetName='-p', Mandatory=$false)][switch]$p, # Use proxy that requires authentication
    [Parameter(ParameterSetName='-u', Mandatory=$false)][switch]$u, # Use unauthenticated proxy.
    [Parameter(ParameterSetName='-s', Mandatory=$false)][switch]$s, # Use system configured proxy settings. May or may not require authentication, depends on system configuration.
    [Parameter(Mandatory=$false)][switch]$t # Supress screen output
)

function SaveResults { param([string]$results)
    if (-Not $t.IsPresent) {
        Write-Host $results | ConvertTo-HTML
    }

    $savedir = "$directory\$(Get-Date -f yyyy_MMM_dd_HHMMss)_$getsource.source"
    [io.file]::WriteAllText($savedir, $results) # | ConvertTo-HTML
}

function Get-Results {
    $source_code = (Invoke-webrequest -URI $getsource -SessionVariable $web).Content   
    Return $source_code
}

if ($p.IsPresent) {
    $web = New-Object System.Net.WebClient
    $auth = Get-Credential
    $web.Proxy.Credentials=$auth
    $source = Get-Results
    SaveResults($source)
}

if ($u.IsPresent) {
    $source = Get-Results
    SaveResults($source)
}

if ($s.IsPresent) {
    $web = New-Object System.Net.WebClient
    $source = Get-Results
    SaveResults($source)
}
