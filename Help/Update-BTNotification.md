# Update-BTNotification

## SYNOPSIS

Updates an existing toast notification.

## DESCRIPTION

The `Update-BTNotification` function updates a toast notification by matching `UniqueIdentifier` and replacing or updating its contents/data.
`DataBinding` provides the values to update in the notification, and `SequenceNumber` ensures correct ordering if updates overlap.

`UniqueIdentifier` accepts pipeline input by property name, so selected objects returned from `Get-BTHistory` can be piped in.

## PARAMETERS

| Name              | Type     | Description                                                                                             | Mandatory |
|-------------------|----------|---------------------------------------------------------------------------------------------------------|-----------|
| `SequenceNumber`  | UInt64   | Used for notification versioning; higher numbers indicate newer content to prevent out-of-order display. | No        |
| `UniqueIdentifier`| String   | String uniquely identifying the toast notification to update.                                            | No        |
| `DataBinding`     | Hashtable| Hashtable containing the data binding keys/values to update.                                             | No        |

## INPUTS

System.Object

Objects with a `UniqueIdentifier` property may be piped in by property name.

## OUTPUTS

None.

## EXAMPLES

### Example 1

```powershell
$data = @{ Key = 'Value' }
Update-BTNotification -UniqueIdentifier 'ID001' -DataBinding $data
```

Updates notification with key 'ID001' using new data binding values.

### Example 2

```powershell
Get-BTHistory | Update-BTNotification -DataBinding @{ Status = 'Done' }
```

Updates each piped notification by matching its `UniqueIdentifier` property.

## LINKS

- [Submit-BTNotification](Submit-BTNotification.md)
- [New-BurntToastNotification](New-BurntToastNotification.md)
