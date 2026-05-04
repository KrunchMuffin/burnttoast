function Optimize-BTImageSource {
    param (
        [Parameter(Mandatory)]
        [String] $Source,

        [Switch] $ForceRefresh
    )

    if ([bool]([System.Uri]$Source).IsUnc -or ([System.Uri]$Source).Scheme -like 'http*') {
        $RemoteFileName = $Source -replace '/|:|\\', '-'

        $NewFilePath = '{0}\{1}' -f $Env:TEMP, $RemoteFileName

        if (!(Test-Path -Path $NewFilePath) -or $ForceRefresh) {
            try {
                if ([bool]([System.Uri]$Source).IsUnc) {
                    Copy-Item -Path $Source -Destination $NewFilePath -Force -ErrorAction Stop
                } else {
                    Invoke-WebRequest -Uri $Source -OutFile $NewFilePath -ErrorAction Stop
                }
            } catch {
                Write-Warning -Message "The image source '$Source' could not be retrieved, falling back to icon. $_"
                return $null
            }
        }

        $NewFilePath
    } else {
        try {
            (Get-Item -Path $Source -ErrorAction Stop).FullName
        } catch {
            Write-Warning -Message "The image source '$Source' doesn't exist, falling back to icon."
            return $null
        }
    }
}
