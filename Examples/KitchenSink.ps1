<#
.SYNOPSIS
Shows a kitchen sink BurntToast V2 notification.

.DESCRIPTION
Run this from the repository root or pass -ModulePath to point at another
BurntToast.psd1. The script demonstrates images, hero art, styled text,
columns, progress, input, context menu items, colored buttons, headers,
attribution, sound, timestamps, expiration, unique identifiers, and click
handlers.

.EXAMPLE
.\Examples\KitchenSink.ps1

.EXAMPLE
.\Examples\KitchenSink.ps1 -WhatIf

.EXAMPLE
.\Examples\KitchenSink.ps1 -ModulePath "$HOME\Documents\PowerShell\Modules\BurntToast\2.0.0\BurntToast.psd1"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [string] $ModulePath = (Join-Path $PSScriptRoot '..\src\BurntToast.psd1'),

    [string] $AppLogo = (Join-Path $PSScriptRoot '..\src\Images\BurntToast-Logo.png'),

    [string] $HeroImage = (Join-Path $PSScriptRoot '..\images\BurntToast-Wide.png')
)

Import-Module $ModulePath -Force

$toastId = 'burnttoast-v2-kitchen-sink'

$activateAction = {
    param($Sender, $EventArgs)

    $Global:BurntToastKitchenSinkActivated = @{
        Sender    = $Sender
        EventArgs = $EventArgs
        Time      = Get-Date
    }

    Start-Process 'https://github.com/Windos/BurntToast'
}

$dismissAction = {
    param($Sender, $EventArgs)

    $Global:BurntToastKitchenSinkDismissed = @{
        Sender    = $Sender
        EventArgs = $EventArgs
        Time      = Get-Date
    }
}

$approveButton = New-BTButton `
    -Content 'Approve' `
    -Arguments 'burnttoast://approval?action=approve' `
    -Color Green

$deleteButton = New-BTButton `
    -Content 'Delete' `
    -Arguments 'burnttoast://approval?action=delete' `
    -Color Red

$openButton = New-BTButton `
    -Content 'Open repo' `
    -Arguments 'https://github.com/Windos/BurntToast'

$logo = New-BTImage `
    -Source $AppLogo `
    -AppLogoOverride `
    -Crop Circle `
    -AlternateText 'BurntToast logo'

$hero = New-BTImage `
    -Source $HeroImage `
    -HeroImage `
    -AlternateText 'BurntToast wide banner'

$progress = New-BTProgressBar `
    -Title 'Release readiness' `
    -Status 'Polishing examples' `
    -Value 0.86 `
    -ValueDisplay '86%'

$header = New-BTHeader `
    -Id 'burnttoast-v2' `
    -Title 'BurntToast V2' `
    -Arguments 'burnttoast://header/v2'

$leftColumn = New-BTColumn -Weight 4 -Children @(
    New-BTText -Text 'Version:' -Style Base
    New-BTText -Text 'Status:' -Style Base
    New-BTText -Text 'Scope:' -Style Base
)

$rightColumn = New-BTColumn -Weight 6 -Children @(
    New-BTText -Text '2.0.0' -Style BaseSubtle
    New-BTText -Text 'Local build' -Style BaseSubtle
    New-BTText -Text 'Kitchen sink' -Style BaseSubtle
)

$snoozeItems = @(
    New-BTSelectionBoxItem -Id '5' -Content '5 minutes'
    New-BTSelectionBoxItem -Id '15' -Content '15 minutes'
    New-BTSelectionBoxItem -Id '60' -Content '1 hour'
)

$snoozeInput = New-BTInput `
    -Id 'snoozeTime' `
    -Title 'Remind me again in' `
    -DefaultSelectionBoxItemId '15' `
    -Items $snoozeItems

$replyInput = New-BTInput `
    -Id 'notes' `
    -Title 'Optional note' `
    -PlaceholderContent 'Type a quick note'

$contextItem = New-BTContextMenuItem `
    -Content 'Open PowerShell help' `
    -Arguments 'https://learn.microsoft.com/powershell/'

$actions = New-BTAction `
    -Inputs $snoozeInput, $replyInput `
    -Buttons $approveButton, $deleteButton, $openButton `
    -ContextMenuItems $contextItem

$title = New-BTText -Text 'BurntToast V2 kitchen sink' -Style Header
$body = New-BTText -Text 'Images, colored buttons, columns, progress, inputs, actions, attribution, and events in one toast.' -Style Body -Wrap
$hint = New-BTText -Text 'Tip: run this script with -WhatIf to inspect without sending.' -Style CaptionSubtle -Wrap

$binding = New-BTBinding `
    -Children $title, $body, $progress, $hint `
    -Column $leftColumn, $rightColumn `
    -AppLogoOverride $logo `
    -HeroImage $hero `
    -Attribution 'BurntToast local V2 example' `
    -Language 'en-US'

$visual = New-BTVisual -BindingGeneric $binding

$audio = New-BTAudio -Source 'ms-winsoundevent:Notification.Reminder'

$content = New-BTContent `
    -Visual $visual `
    -Actions $actions `
    -Audio $audio `
    -Header $header `
    -Launch 'burnttoast://kitchen-sink?source=body' `
    -ActivationType Protocol `
    -CustomTimestamp (Get-Date)

if ($PSCmdlet.ShouldProcess($toastId, 'Submit kitchen sink BurntToast notification')) {
    Submit-BTNotification `
        -Content $content `
        -UniqueIdentifier $toastId `
        -ExpirationTime (Get-Date).AddMinutes(30) `
        -ActivatedAction $activateAction `
        -DismissedAction $dismissAction `
        -EventDataVariable 'BurntToastKitchenSinkEventData'
}

