#Tools.Test_Date.Tests.ps1
$EnglishCultureNames=@(
  @{Name='en-AU'}
  @{Name='en-CA'}
# @{Name='en-GB'} #culture déclarée via une entité
# @{Name='en-IN'}
  @{Name='en-IE'}
  @{Name='en-NZ'}
  @{Name='en-PH'}
  @{Name='en-SG'}
# @{Name='en-US'}
  @{Name='en-ZA'}
)

$CulturesEntite=@(
  @{Name='en-GB'} #United Kingdom,dd/MM/yyyy
  @{Name='es-ES'} #Espagne,d/MM/yyyy
  @{Name='pt-PT'} #Portugal,dd-MM-yyyy
  @{Name='it-IT'} #Italie,dd/MM/yyyy
  @{Name='en-US'} #United States,M/d/yyyy
  @{Name='en-IN'} #India,d/M/yyyy
  @{Name='fr-FR'} #default,dd/MM/yyyy
)

Describe 'ConvertTo-Datetime' -Tag 'Convert' {

  BeforeAll {
    function Use-Culture {
    ##############################################################################  
    ##  
    ## Use-Culture.ps1  
    ##
    ## From Windows PowerShell Cookbook (O'Reilly)
    ## by Lee Holmes (http://www.leeholmes.com/guide)
    ##  
    ## Invoke a scriptblock under the given culture
    ##
    ## ie:  
    ##  
    ## PS >Use-Culture fr-FR { [DateTime]::Parse("25/12/2007") }
    ## 
    ## mardi 25 décembre 2007 00:00:00##   
    ##  
    ##############################################################################  

    param(
        [System.Globalization.CultureInfo] $culture = 
            $(throw "Please specify a culture"),
        [ScriptBlock] $script = $(throw "Please specify a scriptblock")
    )

    ## A helper function to set the current culture
    function Set-myCulture([System.Globalization.CultureInfo] $culture)
    {
        [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
        [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
    }

    ## Remember the original culture information
    $oldCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
    
    ## Restore the original culture information if
    ## the user's script encounters errors.
    trap { Set-myCulture $oldCulture }

    ## Set the current culture to the user's provided
    ## culture.
    Set-myCulture $culture

    ## Invoke the user's scriptblock
    & $script

    ## Restore the original culture information.
    Set-myCulture $oldCulture
    }
   }

  Context "When there is no error with a french valid date.'" -Tag 'UseCulture'{
    it "Convert a french date '27/04/2020' with the culture '<Name>'." -TestCases ($EnglishCultureNames+$CulturesEntite) {
      param($Name)
            #change la culture dans l'appelant, le job sera configuré avec la culture indiquée
           Use-Culture -Culture $Name -Script {
	         Write-Warning "With use-culture $(Get-Culture)"
           $DebugPreference='Continue'
           Import-module $PsScriptRoot\Tools.psm1
           ConvertTo-Datetime -Date '27/04/2020'}| Should -BeOfType [DateTime]

    }
  }

}
