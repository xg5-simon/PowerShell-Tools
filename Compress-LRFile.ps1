function Compress-LRFile {
    <#
        .SYNOPSIS
            Compress a file using the Compress-Archive cmdlet
        .DESCRIPTION
            Compress a file using the Compress-Archive cmdlet
        .PARAMETER Path
            The path to the file to compress
        .PARAMETER Destination
            The destination path for the compressed file
        .EXAMPLE
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Path,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$Destination
    )

    Compress-Archive -Path $Path -DestinationPath $Destination
}
