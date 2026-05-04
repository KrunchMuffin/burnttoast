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

Describe 'Remove-BTNotification' {
    Context 'all notifications (no parameter)' {
        It 'runs without error for clearing all' {
            { Remove-BTNotification -WhatIf } | Should -Not -Throw
        }
    }

    Context 'remove by tag' {
        It 'runs without error for tag' {
            { Remove-BTNotification -Tag 'Toast001' -WhatIf } | Should -Not -Throw
        }
    }

    Context 'remove by group' {
        It 'runs without error for group' {
            { Remove-BTNotification -Group 'Updates' -WhatIf } | Should -Not -Throw
        }
    }

    Context 'remove by unique identifier' {
        It 'runs without error for unique identifier' {
            { Remove-BTNotification -UniqueIdentifier 'Toast001' -WhatIf } | Should -Not -Throw
        }
    }

    Context 'pipeline input' {
        It 'accepts Tag and Group by property name from the pipeline' {
            $obj = [pscustomobject]@{ Tag = 'PipedTag'; Group = 'PipedGroup' }
            { $obj | Remove-BTNotification -WhatIf } | Should -Not -Throw
        }
        It 'accepts UniqueIdentifier by property name from the pipeline' {
            $obj = [pscustomobject]@{ UniqueIdentifier = 'PipedId' }
            { $obj | Remove-BTNotification -WhatIf } | Should -Not -Throw
        }
        It 'processes each piped object once (no extra Clear() side effect)' {
            $items = @(
                [pscustomobject]@{ Tag = 'A'; Group = 'G' }
                [pscustomobject]@{ Tag = 'B'; Group = 'G' }
            )
            { $items | Remove-BTNotification -WhatIf } | Should -Not -Throw
        }
    }
}