param()

function newDirectory {
   param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
       $Path,

        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
       $TaskName
   )

process {
    if (!(Test-Path -LiteralPath $Path))
    {
       Write-Verbose "$TaskName - create directory '$Path'."
       [System.IO.Directory]::CreateDirectory($path) >$null
    }
    else
    { Write-Verbose "$TaskName - directory already exists '$Path'." }
}
}

function GetModulePath {
param($Name)
  $List=@(Get-Module $Name -ListAvailable)
  if ($List.Count -eq 0)
  { Throw "Module '$Name' not found."}
   #Last version
  $List[0].Path
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name) -verbose:($VerbosePreference -eq 'Continue') -EA Stop
}

function Test-BOMFile{
  param (
     [Parameter(mandatory=$true)]
    $Path
   )

    $Params=@{
      Include=@('*.ps1','*.psm1','*.psd1','*.ps1xml','*.xml','*.txt');
      Exclude=@('*.bak','*.exe','*.dll')
    }

    Get-ChildItem -Path $Path -Recurse @Params |
        Where-Object { (-not $_.PSisContainer) -and ($_.Length -gt 0)}|
        ForEach-Object  {
        Write-Verbose "Test BOM for '$($_.FullName)'"
        # create storage object
        $EncodingInfo = 1 | Select-Object FileName,Encoding,BomFound,Endian
        # store file base name (remove extension so easier to read)
        $EncodingInfo.FileName = $_.FullName
        # get full encoding object
        $Encoding = Get-DTWFileEncoding $_.FullName
        # store encoding type name
        $EncodingInfo.Encoding = $Encoding.ToString().SubString($Encoding.ToString().LastIndexOf(".") + 1)
        # store whether or not BOM found
        $EncodingInfo.BomFound = "$($Encoding.GetPreamble())" -ne ""
        $EncodingInfo.Endian = ""
        # if Unicode, get big or little endian
        if ($Encoding.GetType().FullName -eq ([System.Text.Encoding]::Unicode.GetType().FullName)) {
            if ($EncodingInfo.BomFound) {
            if ($Encoding.GetPreamble()[0] -eq 254) {
                $EncodingInfo.Endian = "Big"
            } else {
                $EncodingInfo.Endian = "Little"
            }
            } else {
            $FirstByte = Get-Content -Path $_.FullName -Encoding byte -ReadCount 1 -TotalCount 1
            if ($FirstByte -eq 0) {
                $EncodingInfo.Endian = "Big"
            } else {
                $EncodingInfo.Endian = "Little"
            }
            }
        }
        $EncodingInfo
        }|
        #PS v2 Big Endian plante la signature de script
        Where-Object {($_.Encoding -ne "UTF8Encoding") -or ($_.Endian -eq "Big")}
}

# ----------------------- Misc configuration properties ---------------------------------

# Used by Edit-Template inside the 'RemoveConditionnal' task.
# Valid values are 'Debug' or 'Release'
# 'Release' : Remove the debugging/trace lines, include file, expand scriptblock, clean all directives
# 'Debug' : Do not change anything
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
[ValidateSet('Release','Debug')]  $BuildConfiguration='Release'

# ----------------------- Basic properties --------------------------------
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ProjectName= 'EtsDateTime'

# The root directories for the module's docs, src and test.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$SrcRootDir  = "$PSScriptRoot\Src"
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestRootDir = "$PSScriptRoot\Test"

# The $OutDir is where module files and updatable help files are staged for signing, install and publishing.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$OutDir = "$PSScriptRoot\RELEASES"

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ModuleOutDir = "$OutDir\$ProjectName"

# Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
# Typically you wouldn't put any file under the src dir unless the file was going to ship with
# the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$Exclude = @('*.bak')

# ------------------ Script analysis properties ---------------------------

# Enable/disable use of PSScriptAnalyzer to perform script analysis.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ScriptAnalysisEnabled = $true

# When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
# Valid values are Error, Warning, Information and None.  "None" will report errors but will not
# cause a build failure.  "Error" will fail the build only on diagnostic records that are of
# severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
# "Any" will fail the build on any diagnostic record, regardless of severity.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
[ValidateSet('Error', 'Warning', 'Any', 'None')]
$ScriptAnalysisFailBuildOnSeverityLevel = 'Error'

# Path to the PSScriptAnalyzer settings file.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ScriptAnalyzerSettingsPath = "$PSScriptRoot\ScriptAnalyzerSettings.psd1"

# Module names for additionnale custom rule
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
[String[]]$PSSACustomRules=$null
# @(
#   (GetModulePath -Name OptimizationRules)
#   (GetModulePath -Name ParameterSetRules)
# )

#MeasureLocalizedData
    #Full path of the module to control
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$LocalizedDataModule=$null

    #Full path of the function to control. If $null is specified only the primary module is analyzed.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$LocalizedDataFunctions=$null

#Cultures names to test the localized resources file.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CulturesLocalizedData='en-US','fr-FR'


# ---------------------- Testing properties -------------------------------

# Enable/disable Pester code coverage reporting.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CodeCoverageEnabled = $false

# CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
# acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
# like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$CodeCoverageFiles = "$SrcRootDir\*.ps1", "$SrcRootDir\*.psm1"


# ----------------------- Misc properties ---------------------------------

# Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
# This is typically used to write out test results so that they can be sent to a CI
# system like AppVeyor.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestOutputFile = $null

# Specifies the test output format to use when the TestOutputFile property is given
# a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TestOutputFormat = "NUnitXml"

# Execute or nor 'TestBOM' task
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$isTestBom=$true

###############################################################################
# Customize these tasks for performing operations before and/or after file staging.
###############################################################################

task RemoveConditionnal -If { return $false } {
#Traite les pseudo directives de parsing conditionnelle
#  #bug scope/limit PSake ?
#  # The first call works, but not the followings
#  #-Force reload the ScriptToProcess
#  Import-Module Template -Force

#  try {
#    $TempDirectory=New-TemporaryDirectory
#    $ModuleOutDir="$OutDir\$ModuleName"

#    Write-Verbose "Build with '$BuildConfiguration'"
#    Get-ChildItem  "$SrcRootDir\$ModuleName.psm1","$SrcRootDir\$ModuleName.psd1"|
#     Foreach-Object {
#       $Source=$_
#       $TempFileName="$TempDirectory\$($Source.Name)"
#       Write-Verbose "Edit : $($Source.FullName)"
#       Write-Verbose " to  : $TempFileName"
#       if ($BuildConfiguration -eq 'Release')
#       {

#          #Transforme les directives %Scriptblock%
#          $Lines=Get-Content -Path $Source -Encoding UTF8|
#                  Edit-String -Setting $TemplateDefaultSettings|
#                  Out-ArrayOfString

#          #On supprime les lignes de code de Debug,
#          #   supprime les lignes demandées,
#          #   inclut les fichiers,
#          #   nettoie toutes les directives restantes.

#          ,$Lines|
#            Edit-Template -ConditionnalsKeyWord 'DEBUG' -Include -Remove -Container $Source|
#            Edit-Template -Clean|
#            Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
#       }
#       elseif ($BuildConfiguration -eq 'Debug')
#       {
#          #On ne traite aucune directive et on ne supprime rien.
#          #On inclut uniquement les fichiers.

#          #'NODEBUG' est une directive inexistante et on ne supprime pas les directives
#          #sinon cela génére trop de différences en cas de comparaison de fichier
#          $Lines=Get-Content -Path $Source -Encoding UTF8|
#                   Edit-String -Setting  $TemplateDefaultSettings|
#                   Out-ArrayOfString

#          ,$Lines|
#            Edit-Template -ConditionnalsKeyWord 'NODEBUG' -Include -Container $Source|
#            Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
#       }
#       else
#       { throw "Invalid configuration name '$BuildConfiguration'" }
#      Copy-Item -Path $TempFileName -Destination $ModuleOutDir -Recurse -Verbose:($VerbosePreference -eq 'Continue') -EA Stop
#     }#foreach
#   } finally {
#     if (Test-Path $TempDirectory)
#     { Remove-Item $TempDirectory -Recurse -Force -Verbose:($VerbosePreference -eq 'Continue')  }
#   }
}


# Executes before the StageFiles task.
task BeforeStageFiles RemoveConditionnal, {
}

#Verifying file encoding BEFORE generation
task TestBOM -If { $isTestBom } {
#La régle 'UseBOMForUnicodeEncodedFile' de PSScripAnalyzer s'assure que les fichiers qui
# ne sont pas encodés ASCII ont un BOM (cette régle est trop 'permissive' ici).
#On ne veut livrer que des fichiers UTF-8.

  Write-verbose "Validation de l'encodage des fichiers du répertoire : $SrcRootDir"

  Import-Module DTW.PS.FileSystem

  $InvalidFiles=@(Test-BOMFile -path $SrcRootDir)
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
}

task TestLocalizedData -If { return $false } {
    # Import-module MeasureLocalizedData

    # if ($null -eq $LocalizedDataFunctions)
    # {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule }
    # else
    # {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule -Secondary $LocalizedDataFunctions}
    # if ($Result.Count -ne 0)
    # {
    #   $Result
    #   throw 'One or more MeasureLocalizedData errors were found. Build cannot continue!'
    # }
}

# Executes after the StageFiles task.
task AfterStageFiles TestBOM, TestLocalizedData, {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BeforeStageFiles phase of the Build task.
task BeforeBuild {
}

# #Verifying file encoding AFTER generation
task TestBOMAfterAll -If { $isTestBom } {
   Import-Module DTW.PS.FileSystem

  Write-Verbose  "Validation finale de l'encodage des fichiers du répertoire : $ModuleOutDir"
  $InvalidFiles=@(Test-BOMFile -path $ModuleOutDir)
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
}

# Executes after the Build task.
task AfterBuild TestBOMAfterAll, {
    Write-Host "La livraison se trouve dans le répertoire '$ModuleOutDir'"
    Write-Host "Configuration de '$Configuration' pour l'environnement de '$Environnement'"
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the Install task.
task BeforeInstall {
}

# Executes after the Install task.
task AfterInstall {
}