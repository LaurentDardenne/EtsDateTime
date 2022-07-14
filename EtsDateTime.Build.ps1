#Requires -Modules InvokeBuild
<#
.Synopsis
    Build script invoked by Invoke-Build.

.Description
    Build the Powershell project EtsDatetime
#>
[CmdletBinding()]
param(
    [string] $Configuration,
    [string] $Environnement
)

$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose'))
{ $VerbosePreference = "Continue" }

if ($PSBoundParameters.ContainsKey('Debug'))
{ $DebugPreference = "Continue" }

. $PSScriptRoot\EtsDatetime.BuildSettings.ps1

###############################################################################
# Core task implementations. Avoid modifying these tasks.
###############################################################################
task . Build

task Init {
    NewDirectory -Path $ModuleOutDir -TaskName $Task.Name
}

task Clean Init, {
    # Maybe a bit paranoid but this task nuked \ on my laptop. Good thing I was not running as admin.
    if ($ModuleOutDir.Length -gt 3) 
    {
        Get-ChildItem $ModuleOutDir | Remove-Item -Recurse -Force -Verbose:($VerbosePreference -eq 'Continue')
    }
    else 
    {
        Write-Verbose "$($Task.Name) - `$ModuleOutDir  '$ModuleOutDir' must be longer than 3 characters."
    }
}

task StageFiles Init, Clean, BeforeStageFiles, CoreStageFiles, AfterStageFiles, {
}

task CoreStageFiles {
    Copy-Item -Path $SrcRootDir\* -Destination "$OutDir\$ProjectName" -Recurse -Exclude $Exclude -Verbose:($VerbosePreference -eq 'Continue')
    Copy-Item -Path $DocRootDir\* -Destination "$OutDir\$ProjectName\Docs" -Recurse -Exclude $Exclude -Verbose:($VerbosePreference -eq 'Continue')
    Write-Host "The files have been copied to '$ModuleOutDir'"
}

task Build Init, Clean, BeforeBuild, StageFiles, Analyze, AfterBuild, {
}

task Analyze StageFiles, {
    if (!$ScriptAnalysisEnabled) {
        "Script analysis is not enabled. Skipping $($Task.Name) task."
        return
    }

    if (!(Get-Module PSScriptAnalyzer -ListAvailable)) {
        "PSScriptAnalyzer module is not installed. Skipping $($Task.Name) task."
        return
    }

    "ScriptAnalysisFailBuildOnSeverityLevel set to: $ScriptAnalysisFailBuildOnSeverityLevel"

    $analysisResult = Invoke-ScriptAnalyzer -Path $ModuleOutDir -Settings $ScriptAnalyzerSettingsPath -Recurse -Verbose:($VerbosePreference -eq 'Continue') #-IncludeDefaultRules
    $analysisResult | Format-Table
    switch ($ScriptAnalysisFailBuildOnSeverityLevel) {
        'None' {
            return
        }

        {$_ -in 'Error','ParseError'} {
            $Count=@($analysisResult | Where-Object {$_.Severity -eq 'Error' -or $_.Severity -eq 'ParseError'}).Count
            Assert ( $Count -eq 0 )  'One or more ScriptAnalyzer errors were found. Build cannot continue.'
        }

        'Warning' {
            $Count=@($analysisResult | Where-Object {$_.Severity -eq 'Warning' -or $_.Severity -eq 'Error' -or $_.Severity -eq 'ParseError'}).Count
            Assert ( $Count -eq 0)  'One or more ScriptAnalyzer warnings were found. Build cannot continue.'
        }
        default {
            Assert ($analysisResult.Count -eq 0) 'One or more ScriptAnalyzer issues were found. Build cannot continue.'
        }
    }
}

task Install Build, BeforeInstall, CoreInstall, AfterInstall, {
}

task CoreInstall {
    if (!(Test-Path -LiteralPath $InstallPath)) {
        Write-Verbose 'Creating install directory'
        New-Item -Path $InstallPath -ItemType Directory -Verbose:($VerbosePreference -eq 'Continue') > $null
    }

    Copy-Item -Path $ModuleOutDir\* -Destination $InstallPath -Verbose:($VerbosePreference -eq 'Continue') -Recurse -Force
    "Module installed into $InstallPath"
}

task Test Build, {
    if (!(Get-Module Pester -ListAvailable)) {
        "Pester module is not installed. Skipping $($Task.Name) task."
        return
    }

    Import-Module Pester

    try {
        Microsoft.PowerShell.Management\Push-Location -LiteralPath $TestRootDir

        if ($TestOutputFile) {
            $testing = @{
                OutputFile   = $TestOutputFile
                OutputFormat = $TestOutputFormat
                PassThru     = $true
                Verbose      = $VerbosePreference
            }
        }
        else {
            $testing = @{
                PassThru     = $true
                Verbose      = $VerbosePreference
            }
        }

        # To control the Pester code coverage, a boolean $CodeCoverageEnabled is used.
        if ($CodeCoverageEnabled) {
            $testing.CodeCoverage = $CodeCoverageFiles
        }

        $testResult = Invoke-Pester @testing

        Assert ( $testResult.FailedCount -eq 0) 'One or more Pester tests failed, build cannot continue.'

        if ($CodeCoverageEnabled) {
            $testCoverage = [int]($testResult.CodeCoverage.NumberOfCommandsExecuted /
                                  $testResult.CodeCoverage.NumberOfCommandsAnalyzed * 100)
            "Pester code coverage on specified files: ${testCoverage}%"
        }
    }
    finally {
        Microsoft.PowerShell.Management\Pop-Location
        Remove-Module $ModuleName -ErrorAction SilentlyContinue -Force
    }
}
