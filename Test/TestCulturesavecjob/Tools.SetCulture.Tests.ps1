#Tools.SetCulture.Tests.ps1
$EnglishCultureNames=@(
  @{Name='en-AU'}
  @{Name='en-CA'}
# @{Name='en-GB'} 
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
BeforeAll {
  Import-module $PsScriptRoot\Tools.psm1
  Function Use-CultureHC {
    <#
    .SYNOPSIS
        Run PowerShell code in another culture 

    .DESCRIPTION
        This function allows us to run PowerShell code in another culture 
        (regional settings).

    .PARAMETER CultureInfo
        The culture ID you want to use: 
        en-US (English), de-DE (German), nl-BE (Belgium), ..

    .PARAMETER ScriptBlock
        PowerShell code, like a script block, that you want to run using the 
        specified culture.

    .EXAMPLE
        Use-CultureHC -CultureInfo 'en-US' -ScriptBlock { Get-Date }
        Outputs the current date in US format.

    .EXAMPLE
        Use-CultureHC -CultureInfo 'de-DE' -ScriptBlock { Get-Date }
        Use-CultureHC de-DE {Get-Date}
        Outputs the current date in German format.

    .EXAMPLE
         [system.Globalization.CultureInfo]::GetCultures('AllCultures')
         This command will list all the supported cultures on the system.
    #>

    Param (
        [Parameter(Mandatory)]
        [System.Globalization.CultureInfo]$CultureInfo,
        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock
    )

    Process {
        Trap {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
        }
        $currentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
        [System.Threading.Thread]::CurrentThread.CurrentCulture = $CultureInfo
        Invoke-Command $ScriptBlock
        [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    }
 }  
}

Describe 'ConvertTo-Datetime' -Tag 'SetCulture' {
  Context "When there is no error with a french valid date.'" {
    it "Convert a french date '27/04/2020' with the culture '<Name>'." -TestCases ($EnglishCultureNames+$CulturesEntite) {
      param($Name)
      try {
           Use-CultureHC -CultureInfo $Name -ScriptBlock{
            $DebugPreference='SilentlyContinue'
            ConvertTo-Datetime -Date '27/04/2020'| Should -BeOfType [DateTime]
           }
       } finally {
           Set-Culture 'Fr-fr'
       }
    }
  }

  Context "When there error whith an english valid date.'" {
    it "Impossible to convert a english date '04/27/2020' with the culture '<Name>'." -TestCases ($EnglishCultureNames+$CulturesEntite) {
      param($Name)
      try {
           Use-CultureHC -CultureInfo $Name -ScriptBlock{
            $DebugPreference='SilentlyContinue'
            ConvertTo-Datetime -Date '04/27/2020' | Should -Throw
           }
       } finally {
           Set-Culture 'Fr-fr'
       }
    }
  } 
}
