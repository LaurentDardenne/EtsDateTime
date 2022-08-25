Import-Module -Name EtsDateTime


#MSDN documentation
  # Choosing between DateTime, DateTimeOffset, TimeSpan, and TimeZoneInfo :
  #  https://msdn.microsoft.com/en-us/library/bb384267(v=vs.110).aspx
  #
  # Converting between DateTime and DateTimeOffset :
  #  https://msdn.microsoft.com/en-us/library/bb546101(v=vs.110).aspx
  #

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
  Write-host "`r`nAlways save a date in UTC format!" -Fore Green
  $Date=Get-Date
  $UTC=$Date.ToUniversalTime()
  # Instead  :
  # $timeZone = [TimeZone]::CurrentTimeZone
  # $timeZone.ToUniversalTime($Date)

  Write-host ("`r`nDate ={0}" -F $Date)  -Fore Green
  Write-host ("`r`nDate UTC={0}" -F $UTC)  -Fore Green
  Write-host ("`r`nDate UTC to LocalTime={0}" -F ($UTC.ToLocalTime()))  -Fore Green

  $TimeZone=[TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
  Write-host ("`r`nEastern Standard Time : {0}" -F [TimeZoneInfo]::ConvertTimeFromUtc($UTC,$TimeZone))
  Write-host ("`r`nYesterday {0} (display with current culture)" -F ([DateTime]::Now.PreviousDay()))
  Write-host "`r`nYesterday $([DateTime]::Now.PreviousDay()) (display with invariant culture (default US))"
  #When resolving a variable between double quotes,
  # PowerShell formats numbers and dates with the invariant culture and not the current culture (Get-Culture)

  Write-host ("`r`nToday {0}" -F [DateTime]::Now)
  Write-host ("`r`nToday at 11:55 a.m. {0}" -F [DateTime]::Now.SetTime(11, 55, 0))
  Write-host ("`r`ntomorrow {0}" -F [DateTime]::Now.NextDay())

  Write-Host "`r`nThe [Int] type offers extension methods simplifying date construction."
  Write-Host ("`r`n3 days ago (3).Days().Ago() : {0}" -F (3).Days().Ago())
  Write-Host ("`r`nIn 3 days  (-3).Days().Ago() : {0}" -F (-3).Days().Ago())
  Write-Host ("`r`A duration of 3 days and 14 minutes (3).Days() + (14).Minutes()" -F ((3).Days() + (14).Minutes()) )

   #ToString() uses the current culture for DateTime formatting
   #May return a date in the next year, depending on the query date
  Write-host "`r`nReturns the date of the next Monday : $([DateTime]::Now.Next([DayOfWeek]::Monday).ToString())"

   #Date format based on the current culture (En)
  $Date ='05/06/2017' -as [Datetime]
  Write-host "`r`nReturns the date of the next Monday from Monday, May 6, 2017: $(($Date.Next([DayOfWeek]::Monday)).ToString())"

   #In 15 days, it's according to...
  Write-host "`r`nIn 2 weeks (working days): $(([DateTime]::Now.AddDays((2*5-1))).ToString())"

   #Does not take public holidays into account
   #-1 for the current day
  Write-host "`r`nIn 2 weeks (open days): $(([DateTime]::Now.AddBusinessDays(((2*5)-1))).ToString())"
}
. Demo