
Function Get-WeekOfMonth ([datetime]$Date = $(Get-Date)) {
#nb de WE restant
	[int]$Day = $Date.Day
	Return [math]::Ceiling($Day / 7)
}

#POC
Function New-FactoryFilterDate {
 <#
.SYNOPSIS
 Crée un objet générateur de filtres de recherche.
 Les filtres sont basés sur une propriété, de type date, d'un objet de n'importe quelle classe.
.DESCRIPTION
  Long description
.EXAMPLE
  $Filtre= New-FilterDateFile
    #renvoi un scriptblock par défaut
  $sb=$ExecutionContext.InvokeCommand.NewScriptBlock("$filtre")
  Get-Childitem $pwd|Where $sb|Select Name,"$($Filtre.PropertyName)"

    #Filtre les fichiers d'il y a une semaine.
  $AfterThisDate=$Filtre.AfterThisDate(-7)
    #affiche le code du scriptblock
  $AfterThisDate
  Get-Childitem $pwd|Where $AfterThisDate|Select Name, "CreationTime"

   #Filtre les fichiers créés le 25 octobre 2009 et ceux créés le 31 octobre 2009
  $TheseDates=$Filtre.TheseDates("(^25/10/2009|^31/10/2009)")
  Get-Childitem $pwd|Where $TheseDates|Select Name,"CreationTime"

   #Filtre les fichiers créés le 30 décembre 2009.
  $ThisDate=$Filtre.ThisDate("30/12/2009")

   #Filtre les fichiers créés :
   # Il y a une semaine,
   # ceux du 25 octobre 2009 et ceux du 31 octobre 2009.
  $FiltrePlusieursDates=$Filtre.Combine( @($AfterThisDate, $TheseDates))
  Get-Childitem $pwd|Where $FiltrePlusieursDates |Select Name,"CreationTime"

    #Modifie l'ensemble des champs du générateur de filtre.
  $Filtre.Set("TimeGenerated","System.Diagnostics.EventLogEntry",$False)

  Note:
  Suppose lors de la recherche que la date de l'ordinateur est bien le jour calendaire courant.
  Le validité d'un scriptblock n'est connue que lors de son exécution.

.INPUTS

.OUTPUTS
  [PSObject]

.NOTES
  Cette fonction renvoie un objet de type PSObject, ses membres sont :
  Propriétés :
  ----------
  PropertyName   : [String]. Nom de la propriété contenant la date de recherche.
                    Comme on utilise des méthodes du framework dotnet,
                    faites attention à la casse du nom !
                    Son contenu est utilisé en interne uniquement lors de la création d'un scriptblock de recherche.
                    Valeur par défaut : CreationTime

  Class          : [Type]. Nom de la classe contenant la propriété $PropertyName.
                    Son contenu est utilisé en interne pour vérifier si la propriété
                    $PropertyName existe bien dans la classe ciblée par un des filtres.
                    Valeur par défaut : [System.IO.FileSystemInfo]

  Force          : [Boolean]. A utiliser si la propriété référence un membre synthétique.
                    Dans ce cas, on ne teste pas l'existence de ce membre dans la classe,
                    de plus le respect de la casse du nom de propriété n'est plus nécessaire.
                    Valeur par défaut : False

  Description    : [String]. Contient le nom de la propriété et le nom de la classe en cours.


  Méthodes
  ----------
  La pluspart renvoient un scriptblock pouvant être utilisé avec Where-Object.

  ThisDate       : Recherche les fichiers de la date spécifiée. Les deux opérandes sont de type String.
                   Attend un argument de type string contenant une date au format de la culture en cours.
                   Fr = "28/12/2009"

  TheseDates     : Recherche les fichiers des dates spécifiées. Les deux opérandes sont de type String.
                   Attend un argument de type string contenant une regex référençant des dates au format de la culture en cours.
                   Fr : "(^30/12/2009|^15/01/2009)" Us : "(^12/30/2009|^1/15/2009)"

  AfterThisDate  : Recherche les fichiers postérieurs ou égaux à la date spécifiée. Les deux opérandes sont de type DateTime.
                   Attend un argument de type entier, négatif ou zéro. Cf. Notes

  BeforeThisDate : Recherche les fichiers antérieurs la date spécifiée. Les deux opérandes sont de type DateTime.
                   Attend un argument de type entier, négatif ou zéro. Cf. Notes

  LastMinutes    : Recherche les fichiers agés de n minutes. Les deux opérandes sont de type DateTime.
                   Attend un argument de type entier, négatif. Cf. Notes

  LastHours      : Recherche les fichiers agés de n heures. Les deux opérandes sont de type DateTime.
                   Attend un argument de type entier, négatif. Cf. Notes

  LastMonths     : Recherche les fichiers agés de n mois. Les deux opérandes sont de type DateTime.
                   Attend un argument de type entier, négatif. Cf. Notes

  LastYears      : Recherche les fichiers agés de n années. Les deux opérandes sont de type DateTime.
                   Attend un argument de type entier, négatif. Cf. Notes

  Combine        : Crée un filtre contenant plusieurs clauses combinées et utilisant l'opérateur -or
                   Attend un argument de type tableau de scriptblock.

  ToString        : Renvoi une string résultant de l'appel à ThisDate paramétré avec la date du jour.

  Set             : Affecte une ou plusieurs propriété en une passe.
                    L'ordre de passage des paramètres est le suivant :
                      PropertyName :  [string] ou le résultat de Object.ToString()
                      Class        :  [string] ou [type]
                      Force        :  [string] ou [Boolean]

  ReBuildProperty : Méthode privée, ne pas l'utiliser.
#>

 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                     Justification="New-FactoryFilterDate do not change the system state, only the application 'context'")]
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression",'')]
param (
    #Nom de la propriété contenant la date de recherche.
    #Son contenu est utilisé en interne uniquement lors de la création d'un scriptblock de recherche.
    #Faites attention à la casse du nom de propriété car cette fonction utilise en interne des méthodes sensibles à la casse.
    #Valeur par défaut : CreationTime
   [string] $PropertyName,

    #Type de la classe contenant la propriété $PropertyName.
    #Son contenu est utilisé en interne pour vérifier si la propriété $PropertyName
    #existe bien dans la classe ciblée par un des filtres.
    #Valeur par défaut : [System.IO.FileSystemInfo]
   [type]   $Class,

    #A utiliser si la propriété référence un membre synthétique.
    #Dans ce cas, on ne teste pas l'existence de ce membre dans la classe,
    #de plus le respect de la casse du nom de propriété n'est plus nécessaire.
   [switch] $Force
)

#todo :
#  localisation des msg
#  $filter.ThisDate('6/2/2017') -> ('06/02/2017') ( DOC ->pas de test sur la cohérence du format de date selon la culture)
#  passer une date au lieu d'une chaine et la convertir au format cours
#   Pb de culture
#        Code contenant une déclaration de filtre Fr sur un poste Us
#        Job $usingFilter déclarer en Fr sur le local, excécuté sur un distant en US
# https://stackoverflow.com/questions/9760237/what-does-cultureinfo-invariantculture-mean



  #Construit le code de génération d'un scriptblock
 $Script=New-Object System.Text.StringBuilder '$ExecutionContext.InvokeCommand.NewScriptBlock("'
 $Script.Append('''{0:$([System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.ShortDatePattern)}''') > $null
 $Script.Append(' -f `$_.$($this.PropertyName) -eq ''$($Args[0])''') > $null
 $Script.Append('")') >$null

  # 1) Avec
  #  $Filtre= New-FactoryFilterDate
  #  $Filtre.ThisDate.Script contient le code suivant :
  #    $ExecutionContext.InvokeCommand.NewScriptBlock("{0:$([System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.ShortDatePattern)} -f `$_.$($this.PropertyName) -eq '$($Args[0])'")
 $ThisDate=$Script.ToString()
 $Script.Clear() > $null
  # 2) Lors de l'exécution du code $Filtre.ThisDate.Script
  #   On récupère la culture du thread et pas celle du poste.
  #   Ainsi, lors de l'appel de la création du code, on adapte la localisation au contexte d'exécution
  #   puis on substitue $this.PropertyName et $Args[0] et enfin on renvoi un scriptblock :
  #    {0:dd/MM/yyyy} -f $_.$($this.PropertyName) -eq '$($Args[0])'

  # 3) Le scriptblock renvoyé pour $Filtre.ThisDate("30/12/2009") est :
  #    {'{0:dd/MM/yyyy}' -f $_.CreationTime -eq '30/12/2009'}


   #On construit le code de création d'un scriptblock
 $CodeNewSB='$ExecutionContext.InvokeCommand.NewScriptBlock("`$_.$($this.PropertyName)'

  # Code généré              "`$_.LastWriteTime -match '$($Args[0])'"
  # renvoie lors de l'appel  {$_.LastWriteTime -match "(^10/07/2009|^10/31/2009)"}
  #Conversion explicite de PropertyName afin d'utiliser les informations de la culture courante
  #Si on utilise une conversion implicite, PowerShell utilise la culture invariant, c'est-à-dire US.
 $TheseDates=$CodeNewSB+'.ToString() -match ''$($Args[0])''")'

 $AfterThisDate=$CodeNewSB+' -ge [DateTime]::Today.Adddays($($Args[0]))")'
 $BeforeThisDate=$CodeNewSB+' -lt [DateTime]::Today.Adddays($($Args[0]))")'
 $LastMinutes=$CodeNewSB+'-ge [DateTime]::Now.AddMinutes(`$(`$Args[0]))")'
 $LastHours=$CodeNewSB+' -ge [DateTime]::Now.AddHours($($Args[0]))")'
 $LastMonths=$CodeNewSB+' -ge [DateTime]::Now.AddMonths($($Args[0]))")'
 $LastYears=$CodeNewSB+' -ge [DateTime]::Now.AddYears($($Args[0]))")'

  #Construction de l'objet Filtre
 $Object=New-Object PSObject|
    Add-Member -TypeName 'FactoryFilterDate' -Passthru|

    Add-Member ScriptMethod ThisDate -value ([scriptblock]::Create(@"
 #Args[0] attend une string contenant une date dans le format de la culture courante. Fr = "28/12/2009"
$ThisDate
"@)) -Passthru|

    Add-Member ScriptMethod TheseDates -value ([scriptblock]::Create(@"
 #Args[0] attend une string contenant une regex référençant des dates dans le format de la culture courante. Fr = "(^31/10/2009|^13/12/2009)"
$TheseDates
"@)) -Passthru|

    Add-Member ScriptMethod AfterThisDate -value ([scriptblock]::Create(@"
 #Args[0] attend un entier négatif ou zéro.
$AfterThisDate
"@)) -Passthru|

    Add-Member ScriptMethod BeforeThisDate -value ([scriptblock]::Create(@"
 #Args[0] attend un entier négatif ou zéro.
$BeforeThisDate
"@)) -Passthru|

    Add-Member ScriptMethod LastMinutes -value ([scriptblock]::Create(@"
 #Args[0] attend un entier négatif.
$LastMinutes
"@)) -Passthru|

    Add-Member ScriptMethod LastHours -value ([scriptblock]::Create(@"
 #Args[0] attend un entier négatif.
$LastHours
"@)) -Passthru|

    Add-Member ScriptMethod LastMonths -value ([scriptblock]::Create(@"
 #Args[0] attend un entier négatif.
$LastMonths
"@)) -Passthru|

    Add-Member ScriptMethod LastYears -value ([scriptblock]::Create(@"
 #Args[0] attend un entier négatif.
$LastYears
"@)) -Passthru|
    Add-Member ScriptMethod Combine -value ([scriptblock]::Create(@"
 #Combine deux scriptblocs (créés ou pas par ce générateur)
 #La condition de recherche des scriptblokss combinés se base sur un -OR
`$ArraySB=`$Args[0] -as [String[]]|% {"(`$_)"}
`$Local:Ofs=" -or "
`$sb=`$ExecutionContext.InvokeCommand.NewScriptBlock("`$ArraySB")
`$sb
"@)) -Passthru|
    # S'adapte dynamiquement, un noteproperty est figé lros de la déclaration
    Add-Member ScriptProperty Description -Value {
      "Générateur de filtre de recherche sur une date, utilisant la propriété $($this.PropertyName) de la classe [$($this.Class)].`r`nCe filtre peut être utilisé avec Where-Object."
    } -Passthru|
  #Ajoute des propriétés "dynamiques",
  #A chaque affectation elle se recrée.
  #Les valeurs ne peuvent être que d'un type scalaire.
    Add-Member ScriptMethod ReBuildProperty -value {
            #On modifie la valeur du getter
          $Getter=$ExecutionContext.InvokeCommand.NewScriptBlock($Args[1])
            #On réutilise le code du setter
            #(ici on est certains de ne récupérer qu'un seul élément).
          $Setter=($this.PsObject.Properties.Match($Args[0]))[0]
            #On supprime le membre actuel.
          [void]$this.PsObject.Properties.Remove($Args[0])
            #Puis on le reconstruit dynamiquement.
          $ANewMySelf=New-Object System.Management.Automation.PSScriptProperty($Args[0],$Getter,$Setter.SetterScript)
          [void]$this.PsObject.Properties.Add($ANewMySelf)
          } -Passthru|
     #Args[0] attend une string non $null ni vide.
    Add-Member ScriptProperty PropertyName  -value {"CreationTime"} -SecondValue {
           if ([string]::IsNullOrEmpty($args[0]) )
            {Throw "La propriété PropertyName doit être renseignée."}
           if (!$this.Force)
           {  #Contrôle l'existence du nom de propriété
             $PropertyInfo=($this.Class).GetMember($Args[0])
             if ($PropertyInfo.Count -eq 0)
              {Throw "La propriété $($Args[0]) n'existe pas dans la classe $(($this.Class).ToString())."}
             elseif ($PropertyInfo[0].PropertyType -ne [System.DateTime])
              {Throw "La valeur affectée à la propriété Propertyname ($($Args[0])) doit être une propriété du type [System.DateTime]."}
           }

           $this.ReBuildProperty("PropertyName", "`"$($Args[0])`"")
    } -Passthru|
     #Args[0] attend un type.
    Add-Member ScriptProperty Class  -value {[System.IO.FileSystemInfo]} -SecondValue {
           if ($Args[0] -isnot [Type])
            {Throw "La valeur affectée à la propriété Class ($($Args[0])) doit être un nom de type, tel que [System.IO.FileSystemInfo]."}

           $this.ReBuildProperty("Class", "[$($Args[0] -as [String])]")
     } -Passthru|
     #Args[0] attend un boolean.
    Add-Member ScriptProperty Force -value {$false} -SecondValue {
           if ($Args[0] -isnot [Boolean])
            {Throw "La valeur affectée à la propriété à la propriété Force ($($Args[0])) doit être de type [boolean]."}

           $this.ReBuildProperty("Force", "`$$($Args[0].ToString())")
    } -Passthru|
    Add-Member -Force -MemberType ScriptMethod ToString {
            $this.ThisDate((get-date -format ([System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.ShortDatePattern)))
    } -PassThru|
      #Attend 1, 2 ou 3 paramètres
    Add-Member ScriptMethod Set {
          if (![string]::IsNullOrEmpty($args[1]))
           { $this.Class=$args[1] -as [Type]}
          if (![string]::IsNullOrEmpty($args[0]))
           {$this.PropertyName=$args[0] -as [string]}
          if (![string]::IsNullOrEmpty($args[2]))
           {$this.Force=$args[2] -as [boolean]}
    } -PassThru
 $Object.Set($PropertyName,$Class,$Force.IsPresent)
 $Object
}


Export-ModuleMember -Function New-FactoryFilterDate