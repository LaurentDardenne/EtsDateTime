Import-Module -Name EtsDateTime

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
  #Connaitre les date de passage heure d'été/heure d'hiver
  # Les départements et collectivités d'outre-mer (DOM-COM) n'observent pas l'heure d'été, à l'exception de Saint-Pierre-et-Miquelon.
  
  #FR : Dans les départements métropolitains de la République française, à compter de l'année 2002 et pour les années suivantes, la période de 
  #     l'heure d'été commence le dernier dimanche du mois de mars à 2 heures du matin. A cet instant, il est ajouté une heure à l'heure légale.
  #Note pour ce court interval il est possible de créer des datetime qui n'existe pas en 'réalité'.
  
  Write-host ("`r`nDate de passage à l'heure d'été : {0}" -F  [DateTime]::Now.Setday(1).SetMonth(3).LastDayOfWeekOfTheMonth([DayOfWeek]::Sunday).Sethour(2))
  
  #FR : Dans les départements métropolitains de la République française, à compter de l'année 2002 et pour les années suivantes, la période de 
  #     l'heure d'été se termine le dernier dimanche du mois d'octobre à 3 heures du matin. A cet instant, il est retranché une heure à l'heure légale.
  
  Write-host ("`r`nDate de passage à l'heure d'hiver : {0}" -F   [DateTime]::Now.Setday(1).SetMonth(10).LastDayOfWeekOfTheMonth([DayOfWeek]::Sunday).Sethour(3))
  
  $Year=[DateTime]::Now.Year
  $Date=[DateTime]::Now.Setday(1).SetMonth(10).SetYear($Year+1).LastDayOfWeekOfTheMonth([DayOfWeek]::Sunday).Sethour(3)
    Write-host ("`r`nDate de passage à l'heure d'hiver de l'année prochaine : {0}" -F $Date)
  
   
   #Tjr $false pour une date au format UTC
  Write-host ("`r`nEst-ce l'heure d'été ? {0}" -F  $Date.Sethour(2).IsDaylightSavingTime())
  
  Write-host "`r`nL'API IsDaylightSavingTime se base sur une ou des régles (si plusieurs fuseaux)"
  $Rules=[TimeZoneInfo]::Local.GetAdjustmentRules()
  $Rules[0].DaylightTransitionStart
  $Rules[0].DaylightTransitionEnd
}
. Demo