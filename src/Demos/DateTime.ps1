Import-Module -Name EtsDateTime


#MSDN documentation
#
#French
  # Choisir entre DateTime, DateTimeOffset, TimeSpan et TimeZoneInfo :
  #  https://msdn.microsoft.com/fr-fr/library/bb384267(v=vs.110).aspx
  #
  # Conversion entre DateTime et DateTimeOffset :
  #  https://msdn.microsoft.com/fr-fr/library/bb546101(v=vs.110).aspx

#English
  # Choosing between DateTime, DateTimeOffset, TimeSpan, and TimeZoneInfo :
  #  https://msdn.microsoft.com/en-us/library/bb384267(v=vs.110).aspx
  #
  # Converting between DateTime and DateTimeOffset :
  #  https://msdn.microsoft.com/en-us/library/bb546101(v=vs.110).aspx
  #

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
  Write-host "`r`nToujours enregistrer une date au format UTC !" -Fore Green
  $Date=Get-Date
  $UTC=$Date.ToUniversalTime()
  #Remplace au lieu de  :
  # $timeZone = [TimeZone]::CurrentTimeZone
  # $timeZone.ToUniversalTime($Date)

  Write-host ("`r`nDate locale={0}" -F $Date)  -Fore Green
  Write-host ("`r`nDate UTC={0}" -F $UTC)  -Fore Green
  Write-host ("`r`nDate UTC to LocalTime={0}" -F ($UTC.ToLocalTime()))  -Fore Green

  $TimeZone=[TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
  Write-host ("`r`nEastern Standard Time : {0}" -F [TimeZoneInfo]::ConvertTimeFromUtc($UTC,$TimeZone))
  Write-host ("`r`nHier {0} (affichage avec la culture courante)" -F ([DateTime]::Now.PreviousDay()))
  Write-host "`r`nHier $([DateTime]::Now.PreviousDay()) (affichage avec la culture invariant (US par défaut))"
  #Lorsque l'on résoud une variable entre des doubles quotes,
  # PowerShell formate les nombres et les dates avec la culture invariant et pas la culture en cours (Get-Culture)

  Write-host ("`r`nDemain {0}" -F [DateTime]::Now.NextDay())
  Write-host ("`r`nAujourd'hui {0}" -F [DateTime]::Now)
  Write-host ("`r`nAujourd'hui à 11h55 {0}" -F [DateTime]::Now.SetTime(11, 55, 0))

  Write-Host "`r`nLe type [Int] propose des méthodes simplifiant la construction de date"
  Write-Host ("`r`nIl y a 3 jours  (3).Days().Ago() : {0}" -F (3).Days().Ago())
  Write-Host ("`r`nDans 3 jours  (-3).Days().Ago() : {0}" -F (-3).Days().Ago())
  Write-Host ("`r`Une durée de 3 jours et 14 minutes  (3).Days() + (14).Minutes()" -F  ((3).Days() + (14).Minutes()) )

   #ToString() utilise la culture courante pour le formatage de DateTime
   #Peut renvoyer une date de l'année suivante, selon la date d'interrogation
  Write-host "`r`nRenvoi la date du prochain Lundi : $([DateTime]::Now.Next([DayOfWeek]::Monday).ToString())"

   #Format de date basé sur la culture courante (Fr)
  $Date ='05/06/2017' -as [Datetime]
  Write-host "`r`nRenvoi la date du prochain Lundi à partir du lundi 5 juin 2017: $(($Date.Next([DayOfWeek]::Monday)).ToString())"

  #Dans 15 jours, c'est selon ...
  Write-host "`r`nDans 2 semaines (jours ouvrables ) : $(([DateTime]::Now.AddDays((2*5-1))).ToString())"

  #Ne tient pas compte des jours fériés
  #-1 pour le jour en cours
  Write-host "`r`nDans 2 semaines (jours ouvré ) : $(([DateTime]::Now.AddBusinessDays(((2*5)-1))).ToString())"
}
. Demo