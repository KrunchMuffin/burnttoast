BeforeAll {
    if (Get-Module -Name 'BurntToast') {
        Remove-Module -Name 'BurntToast'
    }

    if ($ENV:BURNTTOAST_MODULE_ROOT) {
        Import-Module $ENV:BURNTTOAST_MODULE_ROOT -Force
    } else {
        Import-Module "$PSScriptRoot/../src/BurntToast.psd1" -Force
    }
}

Describe 'BurntToast Module' {
    Context 'meta validation' {
        It 'should import functions' {
            (Get-Module BurntToast).ExportedFunctions.Count | Should -Be 21
        }

        It 'should import aliases' {
            (Get-Module BurntToast).ExportedAliases.Count | Should -Be 1
        }

        It 'should declare output types for all exported functions' {
            $MissingOutputType = Get-Command -Module BurntToast -CommandType Function |
                Where-Object { $null -eq $_.OutputType -or $_.OutputType.Count -eq 0 }

            $MissingOutputType.Name | Should -BeNullOrEmpty
        }

        It 'should preserve Update-BTNotification ShouldProcess and HelpUri metadata' {
            $Command = Get-Command Update-BTNotification
            $Metadata = [System.Management.Automation.CommandMetadata]::new($Command)

            $Command.CmdletBinding | Should -BeTrue
            $Metadata.SupportsShouldProcess | Should -BeTrue
            $Metadata.HelpUri | Should -Be 'https://github.com/Windos/BurntToast/blob/main/Help/Update-BTNotification.md'
        }
    }
}
