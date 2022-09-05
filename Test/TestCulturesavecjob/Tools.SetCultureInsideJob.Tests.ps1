#Tools.SetCultureInsideJob.Tests.ps1
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
# @{Name='en-HK'}
)

$CulturesEntite=@(
  @{Name='en-GB'} #United Kingdom,dd/MM/yyyy
  @{Name='es-ES'} #Espagne,d/MM/yyyy
  @{Name='pt-PT'} #Portugal,dd-MM-yyyy
  @{Name='it-IT'} #Italie,dd/MM/yyyy
  @{Name='en-US'} #United States,M/d/yyyy
  @{Name='en-IN'} #India,d/M/yyyy
  @{Name='fr-FR'} #default,dd/MM/yyyy
  @{Name='en-HK'} #Hong Kong anglais, d/M/yyyy
  #@{Name='zh-HK'} #Hong Kong chinese, d/M/yyyy
  #@{Name='zh-CN'} #Chinese , yyyy/MM/dd
  #@{Name='ja-JP'} #Japan, yyyy/MM/dd
)

Describe 'ConvertTo-Datetime' -Tag 'Job' {
  BeforeAll {
      $ModulePath=Resolve-Path "$PsScriptRoot\Tools.psm1"

        #Appel dans un job une fonction dépendante de la culture
      function Get-JobResult{
        param($JobName,$Code)
            #Associe le code a la portée courante.
          $sbConvertDate=[ScriptBlock]::Create($Code)
          $Job=Start-Job -Name $JobName -ScriptBlock $sbConvertDate
          try {
            $Result=$Job|Wait-job|Receive-job -ErrorAction Stop
          } finally {
            $Job|Remove-job
          }
        Return $Result
      }
  }

  Context "When there is no error with a french valid date.'" {
    it "Convert a french date '27/04/2020' with the culture '<Name>'." -TestCases ($EnglishCultureNames+$CulturesEntite) {
      param($Name)
      try {
            #change la culture dans l'appelant, le job sera configuré avec la culture indiquée
           Set-Culture $Name

           $Name="Date$($Name -replace '-','_')"
           $Code=@"
           `$DebugPreference='SilentlyContinue'
           Import-module '$ModulePath'
           ConvertTo-Datetime -Date '27/04/2020'
"@
           Get-JobResult $Name $Code| Should -BeOfType [DateTime]
       } finally {
           Set-Culture 'Fr-fr'
       }
    }
  }
  
  Context "When there error whith an english valid date.'" {
    it "Impossible to convert a english date '04/27/2020' with the culture '<Name>'." -TestCases ($EnglishCultureNames+$CulturesEntite) {
      param($Name)
      try {
           Set-Culture $Name

           $Name="Date$($Name -replace '-','_')"
           $Code=@"
           `$DebugPreference='SilentlyContinue'
           Import-module '$ModulePath'
           ConvertTo-Datetime -Date '04/27/2020'
"@
           {Get-JobResult $Name $Code}| Should -Throw
       } finally {
           Set-Culture 'Fr-fr'
       }
    }
  }
}
