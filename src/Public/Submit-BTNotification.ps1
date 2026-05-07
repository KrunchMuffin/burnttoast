function Submit-BTNotification {
    <#
        .SYNOPSIS
        Submits a completed toast notification for display.

        .DESCRIPTION
        The Submit-BTNotification function submits a completed toast notification to the operating system's notification manager for display.
        This function supports advanced scenarios such as event callbacks for user actions or toast dismissal, sequence numbering to ensure correct update order, unique identification for toast replacement, expiration control, and direct Action Center delivery.
        Supports colored action buttons: when a button generated via New-BTButton includes the -Color parameter
        ('Green' or 'Red'), the notification will style those buttons as "Success" (green) or "Critical" (red)
        to visually distinguish positive or destructive actions where supported.

        When an action ScriptBlock is supplied (Activated, Dismissed, or Failed), a SHA256 hash of its source text is used to generate a unique SourceIdentifier for event registration.
        This prevents duplicate handler registration for the same ScriptBlock, warning if a duplicate registration is attempted.

        If the -ReturnEventData switch is used and any event action scriptblocks are supplied (ActivatedAction, DismissedAction, FailedAction),
        the $Event automatic variable from the event will be assigned to $global:ToastEvent before invoking your script block.
        You can override the variable name used for event data by specifying -EventDataVariable. If supplied, the event data will be assigned to the chosen global variable in your event handler (e.g., -EventDataVariable 'CustomEvent' results in $global:CustomEvent).
        Specifying -EventDataVariable implicitly enables the behavior of -ReturnEventData.
        ActivatedAction event data includes the ToastNotification object as $Event.MessageData, allowing handlers to inspect the submitted XML content.

        .PARAMETER Content
        A ToastContent object to display, such as returned by New-BTContent. The content defines the visual and data parts of the toast.

        .PARAMETER SequenceNumber
        A number that sequences this notification's version. When updating a toast, a higher sequence number ensures the most recent notification is displayed, and older ones are not resurrected if received out-of-order.

        .PARAMETER UniqueIdentifier
        A string that uniquely identifies the toast notification. Submitting a new toast with the same identifier as a previous toast replaces the previous notification. Useful for updating or overwriting the same toast notification (e.g., for progress).

        .PARAMETER DataBinding
        Hashtable mapping strings to binding keys in a toast notification. Enables advanced updating scenarios; the original toast must include the relevant databinding keys to be updateable.

        .PARAMETER ExpirationTime
        A [datetime] specifying when the notification is no longer relevant and should be removed from the Action Center.

        .PARAMETER SuppressPopup
        If set, the notification is delivered directly to the Action Center (bypasses immediate display as a popup/toast notification).

        .PARAMETER ActivatedAction
        A script block executed if the user activates/clicks the toast notification.

        .PARAMETER DismissedAction
        A script block executed if the user dismisses the toast notification.

        .PARAMETER FailedAction
        A script block executed if the notification fails to display properly.

        .PARAMETER ReturnEventData
        If set, the $Event variable from notification activation/dismissal is made available as $global:ToastEvent within event action script blocks.

        .PARAMETER EventDataVariable
        If specified, assigns the $Event variable from notification callbacks to this global variable name (e.g., -EventDataVariable MyVar gives $global:MyVar in handlers). Implies ReturnEventData.

        .PARAMETER Urgent
        If set, designates the toast as an "Important Notification" (scenario 'urgent') which can break through Focus Assist, ensuring the notification is delivered even when user focus mode is enabled.

        .INPUTS
        Microsoft.Toolkit.Uwp.Notifications.ToastContent
        ToastContent objects (such as those produced by New-BTContent) may be piped in.

        .OUTPUTS
        None. This function submits a toast but returns no objects.

        .EXAMPLE
        Submit-BTNotification -Content $Toast1 -UniqueIdentifier 'Toast001'
        Submits the toast content object $Toast1 and tags it with a unique identifier so it can be replaced or updated.

        .EXAMPLE
        $Toast1, $Toast2 | Submit-BTNotification
        Submits each toast in turn from the pipeline.

        .LINK
        https://github.com/Windos/BurntToast/blob/main/Help/Submit-BTNotification.md
    #>

    [CmdletBinding(SupportsShouldProcess = $true,
                   HelpUri = 'https://github.com/Windos/BurntToast/blob/main/Help/Submit-BTNotification.md')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.Toolkit.Uwp.Notifications.ToastContent] $Content,
        [uint64] $SequenceNumber,
        [string] $UniqueIdentifier,
        [hashtable] $DataBinding,
        [datetime] $ExpirationTime,
        [switch] $SuppressPopup,
        [switch] $Urgent,
        [scriptblock] $ActivatedAction,
        [scriptblock] $DismissedAction,
        [scriptblock] $FailedAction,
        [switch] $ReturnEventData,
        [string] $EventDataVariable = 'ToastEvent'
    )

    begin {
        if (-not $IsWindows) {
            $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        }
        $CompatMgr = [Microsoft.Toolkit.Uwp.Notifications.ToastNotificationManagerCompat]

        function Add-BTNotificationDataBindingFallback {
            param (
                [Parameter(Mandatory)]
                [object] $Element,

                [Parameter(Mandatory)]
                [System.Collections.Generic.Dictionary[string,string]] $DataDictionary
            )

            if ($Element.GetType().Name -eq 'AdaptiveText' -and $Element.Text) {
                $BindingName = $Element.Text.BindingName

                if ($BindingName -and !$DataDictionary.ContainsKey($BindingName)) {
                    $DataDictionary.Add($BindingName, $BindingName)
                }
            } elseif ($Element.GetType().Name -eq 'AdaptiveProgressBar') {
                foreach ($PropertyName in 'Title', 'Value', 'ValueStringOverride', 'Status') {
                    $BindableValue = $Element.$PropertyName

                    if ($BindableValue) {
                        $BindingName = $BindableValue.BindingName

                        if ($BindingName -and !$DataDictionary.ContainsKey($BindingName)) {
                            $DataDictionary.Add($BindingName, $BindingName)
                        }
                    }
                }
            }

            $ChildrenProperty = $Element.PSObject.Properties['Children']

            if ($ChildrenProperty -and $ChildrenProperty.Value) {
                foreach ($Child in $ChildrenProperty.Value) {
                    Add-BTNotificationDataBindingFallback -Element $Child -DataDictionary $DataDictionary
                }
            }
        }
    }

    process {
        $ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::new()

        $ToastXmlContent = $Content.GetContent()

        if (-not $DataBinding) {
            $ToastXmlContent = $ToastXmlContent -replace '<text(.*?)>{', '<text$1>'
            $ToastXmlContent = $ToastXmlContent.Replace('}</text>', '</text>')
            $ToastXmlContent = $ToastXmlContent.Replace('="{', '="')
            $ToastXmlContent = $ToastXmlContent.Replace('}" ', '" ')
        }

        $ToastXml.LoadXml($ToastXmlContent)

        if ($Urgent) {
            try { $ToastXml.GetElementsByTagName('toast')[0].SetAttribute('scenario', 'urgent') } catch { }
        }

        if ($ToastXml.GetElementsByTagName('toast')[0].GetAttribute('scenario') -eq 'incomingCall') {
            foreach ($BindingElement in $ToastXml.GetElementsByTagName('binding')[0].ChildNodes) {
                if ($BindingElement.TagName -eq 'text') {
                    $BindingElement.SetAttribute('hint-callScenarioCenterAlign', 'true')
                }
            }
        }

        if ($ToastXml.GetXml() -match 'hint-actionId="(Red|Green)"') {
            try { $ToastXml.GetElementsByTagName('toast').SetAttribute('useButtonStyle', 'true') } catch { }

            foreach ($ActionElement in $ToastXml.GetElementsByTagName('actions')[0].ChildNodes) {
                if ($ActionElement.GetAttribute('hint-actionId') -eq 'Red') {
                    $ActionElement.SetAttribute('hint-buttonStyle', 'Critical')
                }
                if ($ActionElement.GetAttribute('hint-actionId') -eq 'Green') {
                    $ActionElement.SetAttribute('hint-buttonStyle', 'Success')
                }
            }
        }

        $Toast = [Windows.UI.Notifications.ToastNotification]::new($ToastXml)

        if ($DataBinding) {
            $DataDictionary = New-Object 'system.collections.generic.dictionary[string,string]'

            foreach ($Key in $DataBinding.Keys) {
                $DataDictionary.Add($Key, $DataBinding.$Key)
            }

            foreach ($Child in $Content.Visual.BindingGeneric.Children) {
                Add-BTNotificationDataBindingFallback -Element $Child -DataDictionary $DataDictionary
            }

            $Toast.Data = [Windows.UI.Notifications.NotificationData]::new($DataDictionary)
        }

        if ($UniqueIdentifier) {
            $Toast.Group = $UniqueIdentifier
            $Toast.Tag = $UniqueIdentifier
        }

        if ($ExpirationTime) {
            $Toast.ExpirationTime = $ExpirationTime
        }

        if ($SuppressPopup.IsPresent) {
            $Toast.SuppressPopup = $SuppressPopup
        }

        if ($SequenceNumber) {
            $Toast.Data.SequenceNumber = $SequenceNumber
        }

        if ($ActivatedAction -or $DismissedAction -or $FailedAction) {
            $Action_Activated = $ActivatedAction
            $Action_Dismissed = $DismissedAction
            $Action_Failed = $FailedAction

            if ($ReturnEventData -or $EventDataVariable -ne 'ToastEvent') {
                $EventReturn = '$global:{0} = $Event' -f $EventDataVariable
                if ($ActivatedAction) {
                    $Action_Activated = [ScriptBlock]::Create($EventReturn + "`n" + $Action_Activated.ToString())
                }
                if ($DismissedAction) {
                    $Action_Dismissed = [ScriptBlock]::Create($EventReturn + "`n" + $Action_Dismissed.ToString())
                }
                if ($FailedAction) {
                    $Action_Failed = [ScriptBlock]::Create($EventReturn + "`n" + $Action_Failed.ToString())
                }
            }

            if ($Action_Activated) {
                try {
                    $ActivatedHash = Get-BTScriptBlockHash $Action_Activated
                    $activatedParams = @{
                        InputObject      = $CompatMgr
                        EventName        = 'OnActivated'
                        Action           = $Action_Activated
                        MessageData      = $Toast
                        SourceIdentifier = "BT_Activated_$ActivatedHash"
                        ErrorAction      = 'Stop'
                    }
                    Register-ObjectEvent @activatedParams | Out-Null
                } catch {
                    Write-Warning "Duplicate or conflicting OnActivated ScriptBlock event detected: Activation action not registered. $_"
                }
                <#
                    EDGE CASES / NOTES
                    - Deduplication is by exact source text: two ScriptBlocks with byte-identical source share a
                      SourceIdentifier and only the first registers. Whitespace and casing differences count as
                      distinct, by design.
                    - Closure state is invisible to ToString(): two blocks with identical text but different
                      captured variables produce the same hash and only one registers.
                    - Any error during registration (including duplicate) is surfaced as a Warning so that
                      notification submission is not disrupted.
                #>
            }
            if ($Action_Dismissed -or $Action_Failed) {
                if ($Script:ActionsSupported) {
                    if ($Action_Dismissed) {
                        try {
                            $DismissedHash = Get-BTScriptBlockHash $Action_Dismissed
                            $dismissedParams = @{
                                InputObject      = $Toast
                                EventName        = 'Dismissed'
                                Action           = $Action_Dismissed
                                SourceIdentifier = "BT_Dismissed_$DismissedHash"
                                ErrorAction      = 'Stop'
                            }
                            Register-ObjectEvent @dismissedParams | Out-Null
                        } catch {
                            Write-Warning "Duplicate or conflicting Dismissed ScriptBlock event detected: Dismissed action not registered. $_"
                        }
                    }
                    if ($Action_Failed) {
                        try {
                            $FailedHash = Get-BTScriptBlockHash $Action_Failed
                            $failedParams = @{
                                InputObject      = $Toast
                                EventName        = 'Failed'
                                Action           = $Action_Failed
                                SourceIdentifier = "BT_Failed_$FailedHash"
                                ErrorAction      = 'Stop'
                            }
                            Register-ObjectEvent @failedParams | Out-Null
                        } catch {
                            Write-Warning "Duplicate or conflicting Failed ScriptBlock event detected: Failed action not registered. $_"
                        }
                    }
                } else {
                    Write-Warning $Script:UnsupportedEvents
                }
            }
        }

        if ($PSCmdlet.ShouldProcess("submitting: [$($Toast.GetType().Name)] with Id $UniqueIdentifier, Sequence Number $($Toast.Data.SequenceNumber) and XML: $($Content.GetContent())")) {
            $CompatMgr::CreateToastNotifier().Show($Toast)
        }
    }
}
