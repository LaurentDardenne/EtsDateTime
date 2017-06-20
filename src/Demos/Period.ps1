#Librairie Itenso.TimePeriod.dll

#doc:
# https://www.codeproject.com/Articles/168662/Time-Period-Library-for-NET
# Source : https://github.com/Giannoudis/TimePeriodLibrary

#todo
# pendant 15 jours durée (suis-je dans cette période ?)
# tout les 15 jours fréquence/périodicité
# avant 15 jours (date expiration ?)
# Après  15 jours (délai ?)
# 
#     #DateTimeOffset
#     #Représente un instant précis, généralement exprimé sous la forme d'une date et d'une heure, 
#     #par rapport au temps universel (UTC, Universal Time Coordinated).

$d1=new-object DateTime( 2011, 2, 22, 14, 0, 0 )
$d2=new-object DateTime( 2011, 2, 22, 18, 0, 0 ) 
$timeRange1=new-object Itenso.TimePeriod.TimeRange -ArgumentList $d1,$d2
"TimeRange1: " + $timeRange1
#TimeRange1: 22.02.2011 14:00:00 - 18:00:00 | 04:00:00

$date1 = New-Object DateTime( 2009, 11, 8, 7, 13, 59 )
"Date1: {0}" -F $date1
 # Date1: 08.11.2009 07:13:59
$date2 = New-Object DateTime( 2011, 3, 20, 19, 55, 28 )

$dateDiff = New-Object Itenso.TimePeriod.DateDiff($date1, $date2 )
"DateDiff.GetDescription(6): {0}" -F, $dateDiff.GetDescription(6)
