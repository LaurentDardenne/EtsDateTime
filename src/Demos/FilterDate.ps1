Import-Module EtsDateTime

Function Demo {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
param()
  Write-host "Crée un générateur de filtre de date.`r`nPar défaut on manipule : [System.IO.FileSystemInfo].CreationTime"

  $Filtre= New-FactoryFilterDate 
  $Filtre|Format-List

  Write-host 'Crée un filtre recherchant les fichiers de la semaine dernière: $Filtre.AfterThisDate(-7)'
  Write-host "Contenu du scriptblock généré : $($Filtre.AfterThisDate(-7))"
  $AfterThisDate=$Filtre.AfterThisDate(-7)
  
  Write-host "On modifie la propriété 'LastWriteTime' du filtre"
  $Filtre.PropertyName="LastWriteTime"
  $Filtre.Description
  Write-host "Le contenu du scriptblock généré utilise la nouvelle propriété : $($Filtre.AfterThisDate(-7))"

  Push-Location $env:Temp
   #Création d'une varaible pour un usage multiple
  Get-ChildItem|Where-Object $AfterThisDate

   #Accés directe pour un usage unique
  Get-ChildItem|Where-Object $Filtre.AfterThisDate(-7)
  
  Write-host "`$Filtre.Tostring() renvoi le résultat de l'appel à ThisDate qui est paramétré avec la date du jour."
  Write-host "$Filtre"
  try {
    $Filtre.PropertyName="StartTime" 
  } catch {
    Write-Warning "Tentative avec Force=`$false : $_"
  }
  Write-host "On modifie la propriété et la classe du filtre"
  $Filtre.Force=$True
  $Filtre.PropertyName="StartTime" 
  $Filtre.Class=[System.Diagnostics.Process]
  $Filtre.Description
  Write-host "Le contenu du scriptblock généré utilise la nouvelle propriété : $($Filtre.AfterThisDate(-7))"

  Write-host 'Crée un générateur de filtre de date, on précise la classe et la propriété ciblée :'
  Write-host '  New-FactoryFilterDate "StartTime" "System.Diagnostics.Process"'
  $Filtre= New-FactoryFilterDate "StartTime" "System.Diagnostics.Process" ; $Filtre 
  Notepad
  $LastMinutes=$Filtre.LastMinutes(-3)
  Get-Process |Where-Object $LastMinutes

  Write-host "Modifie les propriétes d'un objet filtre :"
  Write-host '$Filtre.Set("TimeGenerated","System.Diagnostics.EventLogEntry",$False)'
  $Filtre.Set("TimeGenerated","System.Diagnostics.EventLogEntry",$False) ; $Filtre
  
  #Filtre les eventlog généré le 10 mai 2017 et ceux créés le 2 juin 2017
  $TheseDates=$Filtre.TheseDates("(^10/05/2017|^02/06/2017)")
  Get-Eventlog Application|Where-Object $TheseDates|Select-Object -First 3 

  #Cette appel fonctionne, mais aucun contrôle n'est alors 
  # effectué sur la valeur de l'argument
  #$Filtre.ReBuildProperty("Force","Test")

  function Use-Culture ([System.Globalization.CultureInfo]$culture =(throw "USAGE: Using-Culture -Culture culture -Script {scriptblock}"),
                          [ScriptBlock]$script=(throw "USAGE: Using-Culture -Culture culture -Script {scriptblock}"))
  { 
    #http://keithhill.spaces.live.com/Blog/cns!5A8D2641E0963A97!7132.entry

      $OldCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
      $OldUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
      try {
          [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
          [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture        
          Invoke-Command $script    
      }    
      finally {        
          [System.Threading.Thread]::CurrentThread.CurrentCulture = $OldCulture        
          [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OldUICulture    
      }    
  }

  $Filtre= New-FactoryFilterDate
  $ThisDate=$Filtre.ThisDate("30/12/2009")

  Use-Culture en-US {
    #  $DtPattern=(Get-Culture).DateTimeFormat.ShortDatePattern
    #  $DtPattern
    #  $DtPattern=[System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.ShortDatePattern
    #  $DtPattern
    #  
    $Filtre= New-FactoryFilterDate
    $ThisDate=$Filtre.ThisDate("12/30/2009")
    $Filtre.ThisDate
    $ThisDate
  }
  $Filtre.ThisDate
  $ThisDate

  # Mixte
  $Filtre= New-FactoryFilterDate 
  $Filtre.ThisDate((3).Days().Ago())
  Pop-Location
}
. Demo