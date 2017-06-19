Import-Module -Name EtsDateTime

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
  #note :  11 jours en france + 2 pour l'alsace et la Moselle : Saint Étienne et le Vendredi saint
  Write-host "`r`nListe des jours fériés de 2017 (+ 2 pour l'Alsace et la Moselle)" -fore green
  $null = Read-Host 'Press Enter to continue...'
  $Dates=[Nager.Date.DateSystem]::GetPublicHoliday('fr',2017)
  ($Dates).Date
  
  Write-host "`r`nListe complètes des jours fériés Française de 2017 (Dom-Tom + Alsace + Moselle)" -fore green
  (Get-PublicHolidayFR -Year 2017).Date
  
  Write-host "`r`nListe des jours fériés de 2018 (+ 2 pour l'Alsace et la Moselle)" -fore green
  [Nager.Date.DateSystem]::GetPublicHoliday('fr',2018).Date
  
  Write-host "`r`nConnaitre les pays gérés par la librairie Nager.Date.dll"
  $null = Read-Host 'Press Enter to continue...'
  [Nager.Date.PublicHolidays.FranceProvider].Assembly.ExportedTypes|Select-Object Name
  
   Write-host "`r`nListe des code pays gérés par la librairie Nager.Date.dll"
   # [Nager.Date.CountryCode]::Fr
  [Enum]::GetNames([Nager.Date.CountryCode])
}
. Demo
