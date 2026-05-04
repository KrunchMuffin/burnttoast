function Get-BTScriptBlockHash {
    <#
        .SYNOPSIS
        Returns a SHA256 hash for a ScriptBlock based on its source text.

        .DESCRIPTION
        Hashes the exact source text of the ScriptBlock (the result of ToString()).
        Two ScriptBlocks with byte-identical source produce the same hash; any difference in
        whitespace, casing, or punctuation produces a different hash.

        Used to derive a stable SourceIdentifier for event registration so that registering the
        "same" handler twice does not create duplicate subscriptions.

        .PARAMETER ScriptBlock
        The [scriptblock] to hash.

        .INPUTS
        System.Management.Automation.ScriptBlock

        .OUTPUTS
        String (SHA256 hex)

        .EXAMPLE
        $hash = Get-BTScriptBlockHash { Write-Host 'Hello' }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [scriptblock]$ScriptBlock
    )
    process {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($ScriptBlock.ToString())
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $sha.ComputeHash($bytes)
        } finally {
            $sha.Dispose()
        }
        -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    }
}