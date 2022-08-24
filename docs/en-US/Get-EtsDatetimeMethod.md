---
external help file: EtsDateTime-help.xml
Module Name: EtsDateTime
online version:
schema: 2.0.0
---

# Get-EtsDatetimeMethod

## SYNOPSIS
Get the extension methods list, added by the 'EtsDatetime' module.

## SYNTAX

```
Get-EtsDatetimeMethod [-help] [<CommonParameters>]
```

## DESCRIPTION
Get the names of extension methods list.
Return a hashtable, the key is a type name et the values are the method names.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-EtsDatetimeMethod
name                           Value
----                           -----
System.Int32                   {Years, Quarters, Months, Weeks...}
System.String                  {ToMsrcID, ToTimeOfDay}
System.DateTimeOffset          ...
...
```

### Example 2
```powershell
PS C:\> Get-EtsDatetimeMethod -help
```

## PARAMETERS

### -help
Run hh.exe for 'DateTimeExtensions.chm' and 'FluentDatetime.chm' helper files.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### none

## OUTPUTS

### [Hashtable]
