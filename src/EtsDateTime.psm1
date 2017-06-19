
$IsoCountiesFR=@{}

 #Le fichier Data\ISO 3166-2.csv contient les codes des départements Français
 # au format ISO 3166-2:FR . 
 #L'encodage est correctement rendu dans un éditeur, mais pas dans la console, problème de code page à priori.
 #
 #Pays.Région.Département.Nom (Nom de pays ou de région ou de département)
 #Country,County,Subdivision,Name
 #note :  Wallis & Futuna est un departement mais aussi une entrée de niveau pays...
 #        comme la Guadeloupe ou Monaco.
foreach ($Line in Import-csv "$PSScriptRoot\Data\ISO 3166-2.csv" -Encoding UTF8)
{
  if (($Line.Country -eq 'FR') -and ($Line.County -ne ''))
  {
      #Nom de départements + noms de région des DOM/TOM
    if ($Line.Subdivision -ne '') 
    { $IsoCountiesFR.Add($Line.Name,$Line.Subdivision) }
    else
    { $IsoCountiesFR.Add($Line.Name,$Line.County) }
  }
}

Function Get-PublicHolidayFR{
<#
    .SYNOPSIS
      Returning the french public holidays
#>   
   param ( 
      #The year of the calendar
     [Parameter(Mandatory=$true)]
     [ValidateScript({$_ -gt 0}) ]
    [int] $year
   )
#todo https://fr.wikipedia.org/wiki/Jour_f%C3%A9ri%C3%A9#.C2.A0France
#47e et 46e jours avant Pâques -	Mardi gras et Mercredi des cendres 
# Jours fériés supplémentaires spécifiques aux Antilles -> Guadeloupe,Martinique,Saint-Martin,Saint-Barthélemy


 #Jours fériés nationaux, communs à tous les département plus le Vendredi Saint et la Saint-Etienne
$T=[Nager.Date.DateSystem]::GetPublicHoliday('FR',$year) -as [Nager.Date.Model.PublicHoliday[]]

foreach ($PublicHoliday in $T)
{
  #On utilise tjr la notion de nom de département, 
  # sauf pour les DOM/TOM où on utilise le nom de région
  #ex: Pour la Martinique on utilise le code ISO 3166-2 ('FR-MQ') et pas le code INSEE (972)
  #    Les codes ISO 3166-2 de la majorité des départements ('FR-54') sont similaires aux codes INSEE (54 : Meurthe-et-Moselle)  
  #
  #La hashtable $IsoCountiesFR contient l'association  ( nom de département , code ISO 3166-2 )

 Switch ($PublicHoliday.Name) {
    #Vendredi saint
   'Good Friday' { $PublicHoliday.Counties=@('FR-54','FR-67','FR-68','FR-GP','FR-GF','FR-MQ','FR-PF') }
    #Saint-Étienne
   "St. Stephen's Day" { $PublicHoliday.Counties=@('FR-54','FR-67','FR-68') }
 }
}
$PH=New-Object "System.Collections.Generic.List[Nager.Date.Model.PublicHoliday]" 
$PH.AddRange($T)
 # Ajoute les jours fériés spécifiques à certains départements Français
 #  public PublicHoliday(int year, int month, int day, string localName, string englishName, CountryCode countryCode, int? launchYear = null, string[] counties = null, bool countyOfficialHoliday = true, bool countyAdministrationHoliday = true)
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 4, 27, "Abolition de l'esclavage", 'Abolition of Slavery','Fr',$null,
                                        @($IsoCountiesFR.Mayotte)))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 4, 28, 'Saint Pierre Chanel', 'Saint Pierre Chanel','Fr',$null,
                                        @($IsoCountiesFR.'Wallis-et-Futuna')))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 5, 22, "Abolition de l'esclavage", 'Abolition of Slavery','Fr',$null,
                                        @($IsoCountiesFR.Martinique)))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 5, 27, "Abolition de l'esclavage", 'Abolition of Slavery','Fr',$null,
                                        @($IsoCountiesFR.Guadeloupe,$IsoCountiesFR.'Saint-Barthélemy',$IsoCountiesFR.'Saint-Martin')))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 6, 10, "Abolition de l'esclavage", 'Abolition of Slavery','Fr',$null,
                                        @($IsoCountiesFR.'Guyane (française)')))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 6, 29, "Fête de l'autonomie", 'Autonomy Day','Fr',$null,
                                        @($IsoCountiesFR.'Polynésie française')))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 7, 21, 'Fête Victor Schoelcher', 'Victor Schoelcher Day','Fr',$null,
                                        @($IsoCountiesFR.Guadeloupe,$IsoCountiesFR.'Saint-Barthélemy',$IsoCountiesFR.'Saint-Martin',$IsoCountiesFR.Martinique))) # pas certains pour 'FR-BL','FR-MF'
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 7, 29, 'Fête du Territoire', 'Territory Day','Fr',$null,
                                        @($IsoCountiesFR.'Wallis-et-Futuna')))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 9, 24, 'Fête de la citoyenneté', 'Citizenship Day','Fr',$null,
                                        @($IsoCountiesFR.'Nouvelle-Calédonie')))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 11, 2, 'Fête des morts', "All Souls' day",'Fr',$null,
                                        @($IsoCountiesFR.Martinique)))
 $PH.Add( [Nager.Date.Model.PublicHoliday]::new($year, 12, 20, "Abolition de l'esclavage", 'Abolition of Slavery','Fr',$null,
                                        @($IsoCountiesFR.Réunion)))
 return ,$PH
    <# 
    A Mayotte les jours fériés et chômés diffère : 1er Janvier,Lundi de Pâques, 1er Mai, Ide el Kébîr 
    Ide el Kébîr est la fin du ramadan, le 1 jour du dixième mois lunaire
  
      Jours fériés payés et non obligatoirement chômés
    - 27 Avril (Abolition de l’esclavage),
    - 8 Mai,
    - Jeudi de l’Ascension,
    - Lundi de Pentecôte,
    - 14 Juillet,
    - 15 Août (Assomption)
    - 1er Novembre (Toussaint),
    - 11 Novembre,
    - 25 Décembre (Noël)
    - Miradji (ou miraj 'ascension'?), Ide el Fitr et Maoulida (Mawlid, naissance du prophète) :
      fêtes religieuses mobiles. Dépendent d'un calendrier lunaire, exemple ->  System.Globalization.UmAlQuraCalendar
    #>
}

Function Get-WeekOfMonth ([datetime]$Date = $(Get-Date)) {
#nb de WE restant
	[int]$Day = $Date.Day
	Return [math]::Ceiling($Day / 7)
}

Export-ModuleMember  -Variable IsoCountiesFR `
                     -Function Get-PublicHolidayFR