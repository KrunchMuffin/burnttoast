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

Describe 'Submit-BTNotification' {
    Context 'content and unique identifier' {
        It 'runs without error for submitting with identifier' {
            $mockContent = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            { Submit-BTNotification -Content $mockContent -UniqueIdentifier 'Toast001' -WhatIf } | Should -Not -Throw
        }
    }
    Context 'event handler deduplication/registration' {
        It 'registers a unique action event without error' {
            $mockContent = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            $action = { Write-Host "Activated!" }
            { Submit-BTNotification -Content $mockContent -ActivatedAction $action -WhatIf } | Should -Not -Throw
        }
        It 'warns and does not throw on duplicate action registration' {
            $mockContent = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            $action = { Write-Host "Activated!" }

            $transcriptPath = "$env:TEMP\BTTranscript-$PID.txt"
            Start-Transcript -Path $transcriptPath -Force | Out-Null
            try {
                $null = Submit-BTNotification -Content $mockContent -ActivatedAction $action -WhatIf 2>&1
            } finally {
                Stop-Transcript | Out-Null
            }

            $transcript = Get-Content $transcriptPath -Raw
            $transcript | Should -Match "Duplicate or conflicting OnActivated ScriptBlock event detected"
            Remove-Item $transcriptPath -Force
        }
        It 'allows distinct handler actions without deduplication warning' {
            $mockContent = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            $a1 = { Write-Host "A" }
            $a2 = { Write-Host "B" }
            $null = Submit-BTNotification -Content $mockContent -ActivatedAction $a1 -WhatIf 2>&1
            $output = Submit-BTNotification -Content $mockContent -ActivatedAction $a2 -WhatIf 2>&1
            $output | Should -Not -Contain "Duplicate or conflicting OnActivated ScriptBlock event detected"
        }
    }
    Context 'Urgent scenario' {
        It 'runs without error with -Urgent' {
            $mockContent = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            { Submit-BTNotification -Content $mockContent -Urgent -WhatIf } | Should -Not -Throw
        }
    }
    Context 'pipeline input' {
        It 'accepts a single ToastContent from the pipeline' {
            $mockContent = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            { $mockContent | Submit-BTNotification -WhatIf } | Should -Not -Throw
        }
        It 'accepts multiple ToastContent objects from the pipeline' {
            $a = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            $b = [Activator]::CreateInstance([Microsoft.Toolkit.Uwp.Notifications.ToastContent])
            { $a, $b | Submit-BTNotification -WhatIf } | Should -Not -Throw
        }
    }
    Context 'data binding fallbacks' {
        It 'runs without error when static text is nested inside columns' {
            $labels = New-BTText -Style Base -Text 'unbind_title'
            $values = New-BTText -Style BaseSubtle -Text 'unbind_subtitle'
            $progress = New-BTProgressBar -Status 'bind_status' -Value 'bind_value' -ValueDisplay 'bind_value_display'

            $col1 = New-BTColumn -Children $labels -Weight 4
            $col2 = New-BTColumn -Children $values -Weight 6

            $binding = New-BTBinding -Column $col1, $col2 -Children $progress
            $visual = New-BTVisual -BindingGeneric $binding
            $content = New-BTContent -Visual $visual
            $data = @{
                bind_status        = 'Status initial'
                bind_value         = 0.5
                bind_value_display = 'Progress start'
            }

            { Submit-BTNotification -Content $content -DataBinding $data -UniqueIdentifier ([guid]::NewGuid().ToString()) -WhatIf } | Should -Not -Throw
        }
    }
}
