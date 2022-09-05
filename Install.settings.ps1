###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

Properties {
    # ----------------------- Basic properties --------------------------------

    $InstallationScope='CurrentUser'

    #Location of nuget feed
    $Repositories=@(
      [PsCustomObject]@{
          name='OttoMatt'
          publishlocation='https://www.myget.org/F/ottomatt/api/v2/package'
          sourcelocation='https://www.myget.org/F/ottomatt/api/v2'
      },
      [PsCustomObject]@{
          name='DevOttoMatt'
          publishlocation='https://www.myget.org/F/devottomatt/api/v2/package'
          sourcelocation='https://www.myget.org/F/devottomatt/api/v2'
      }
    )

    #Common modules
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PSGallery=@{
       Modules=@('Pester','PsScriptAnalyzer','BuildHelpers','platyPS')
       Scripts=@()
     }
    #Personnal modules & script (French documentation only)
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $MyGet=@{
       Modules=@('Log4Posh','MeasureLocalizedData','PowerShell-Beautifier','Template','OptimizationRules','ParameterSetRules')
       Scripts=@('Lock-File', 'Using-Culture')
     }
}
