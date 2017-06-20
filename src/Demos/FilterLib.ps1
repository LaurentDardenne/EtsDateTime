
function Get-PropertiesDateTime([Type] $Class){
 #Retrouve les propriétés de type date d'une classe
 #renvoi une hashtable : $H.NomClass.[Propriétés]
 $PropertiesOfType=@{}    
  $PropertiesOfType."$($Class.Name)"=@( $Class.GetMembers()|
      Where-Object {($_.MemberType -eq "property") -and ($_.PropertyType -eq [Datetime])}|
      ForEach-Object {$_.Name})
 $PropertiesOfType   
}

$p=Get-PropertiesDateTime  "Microsoft.PowerShell.Commands.HistoryInfo"
$p+=Get-PropertiesDateTime "System.Diagnostics.EventLogEntry"
$p

function New-FilterLib {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="New-FactoryFilterDate do not change the system state, only the application 'context'")]                                  
 param($Factory)
 <#
 .SYNOPSIS
  Construit une librairie de Scritpblock, contenant des filtres de date.
  La génération des filtres s'adapte à la date en cours lors de la création.
 #>    
 
  $Lib=@{}
   $PatternDate="{0:$((Get-Culture).DateTimeFormat.ShortDatePattern)}"
    #Attention aux traitements démarrés peu avant minuit et se finissant le lendemain.
  $Lib.Today= $Factory.ThisDate($PatternDate -F [system.DateTime]::Today )
  $Lib.Tomorrow=$Factory.ThisDate($PatternDate -F [system.DateTime]::Today.AddDays(1))
  $Lib.Yesterday=$Factory.ThisDate($PatternDate -F [system.DateTime]::Today.AddDays(-1))
  $Lib.BeforeYesterday=$Factory.ThisDate($PatternDate -F [system.DateTime]::Today.AddDays(-2))
   #Si le jour courant (Fr) est lundi on renvoie lundi, mais 
   # pas le jour de la semaine dernière AddDays(-7)                                                   
  $Lib.FirstDayOfThisWeek=$Factory.ThisDate($PatternDate -F $(
                                          $Date=[system.DateTime]::Today
                                           $DayOfWeek=[int][system.DateTime]::Today.DayOfWeek
                                           $FirstDayOfWeek=[int]([System.Threading.Thread]::CurrentThread.CurrentCulture).DateTimeFormat.FirstDayOfWeek 
                                          $Diff = $DayOfWeek - $FirstDayOfWeek   
                                          if ($Diff -lt 0)  
                                           { $Diff += 7 }  
                                          $Date.AddDays(-1 * $diff).Date
                                         ))  
  $Lib.LastDayOfThisMonth= $Factory.ThisDate($PatternDate -F $( 
                                           $now=[System.DateTime]::Now 
                                           $nbDays = [System.DateTime]::DaysInMonth($Now.Year,$Now.Month)
                                           new-object System.DateTime($now.Year, $now.Month, $nbDays, 0, 0, 0,0)
                                          )) 
  $Lib.FirstDayOfThisMonth=$Factory.ThisDate($PatternDate -F $(  
                                          $Today=[System.DateTime]::Today
                                          $Today.AddDays(-($Today.Day - 1))
                                          ))
  $Lib.OneMonthBefore=$Factory.ThisDate($PatternDate -F [system.DateTime]::Today.AddMonths(-1))
 
    #Date et heure de génération de cette librairie.
  $sb=[scriptblock]::Create("'$([system.DateTime]::Now)'")
  Add-Member Scriptproperty CreationTime -value $Sb -SecondValue {Throw 'CreationTime is a read only property.'} -InputObject $Lib
    #Classe et propriété utilisées lors de la génération de cette librairie.
  $sb=[scriptblock]::Create("'[$($Factory.Class)].$($Factory.PropertyName)'")
  Add-Member Scriptproperty Target -value $sb -SecondValue {Throw 'Target is a read only property.'} -InputObject $Lib
 $Lib
}

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()

 #Génère une liste de filtre à partir d'une factory
$FileInfoLib= New-FilterLib (New-FactoryFilterDate)
$FileInfoLib
Get-ChildItem |Where-Object $FileInfoLib.Today
 #Affiche la classe et la propriété utilisées par cette librairie.
$FileInfoLib.Target
$FileInfoLib.CreationTime

$EventLogLib= New-FilterLib (New-FactoryFilterDate "TimeGenerated" "System.Diagnostics.EventLogEntry")
$EventLogLib
}
. Demo
