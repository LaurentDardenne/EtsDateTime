﻿###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

Function Test-CIEnvironment {
  return (Test-Path env:APPVEYOR)
}

Function Get-ApiKeyIntoCI {
     #Read Appveyor environment variable (encrypted)
    Write-host "ApiKey for the configuration : '$BuildConfiguration'"

    if ($BuildConfiguration -eq 'Debug')
    { return $Env:MY_APPVEYOR_DevMyGetApiKey }
    else
    { return $Env:MY_APPVEYOR_MyGetApiKey }
}


function GetPowershellGetPath {
 #extracted from PowerShellGet/PSModule.psm1

  $IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
  if($IsInbox)
  {
      $ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
  }
  else
  {
      $ProgramFilesPSPath = $PSHome
  }

  if($IsInbox)
  {
      try
      {
          $MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
      }
      catch
      {
          $MyDocumentsFolderPath = $null
      }

      $MyDocumentsPSPath = if($MyDocumentsFolderPath)
                                  {
                                      Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
                                  }
                                  else
                                  {
                                      Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
                                  }
  }
  elseif($IsWindows)
  {
      $MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath 'Documents\PowerShell'
  }
  else
  {
      $MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath ".local/share/powershell"
  }

  $Result=[PSCustomObject]@{

   AllUsersModules = Microsoft.PowerShell.Management\Join-Path -Path $ProgramFilesPSPath -ChildPath "Modules"
   AllUsersScripts = Microsoft.PowerShell.Management\Join-Path -Path $ProgramFilesPSPath -ChildPath "Scripts"

   CurrentUserModules = Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsPSPath -ChildPath "Modules"
   CurrentUserScripts = Microsoft.PowerShell.Management\Join-Path -Path $MyDocumentsPSPath -ChildPath "Scripts"
  }
  return $Result
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

Function Find-ExternalModuleDependencies {
<#
    .SYNOPSIS
     Détermine, selon le repository courant, le ou les modules externes dépendant.
     Les noms de module retournés pourront être insérés dans la clé 'ExternalModuleDependencies' d'un manifest de module

    .EXAMPLE
     $ManifestPath='.\OptimizationRules.psd1'
     $ModuleNames=Read-ModuleDependency $ManifestPath -AsHashTable
     $EMD=Find-ExternalModuleDependencies $ModuleNames -Repository $PublishRepository
#>
  Param(
      [ValidateNotNullOrEmpty()]
     [System.Collections.Hashtable[]] $ModuleSpecification,

       [ValidateNotNullOrEmpty()]
     [String] $Repository
)

 [System.Collections.Hashtable[]] $Modules=$ModuleSpecification|ForEach-Object{$_.Clone()}

 $EMD=@(
     Foreach ($Module in $Modules) {
        try {
        # En cas d'erreur de module introuvable, Find-Module ne propose pas son nom dans une propriété de l'exception levée,
        # on les traite donc un par un.
        #
        #Note :
        # La recherche ne peut se faire sur le GUID (FQN) mais uniquement sur le nom ET un numéro de version.
        # Il existe donc un risque minime de collision entre 2 repositories.
        #
        #Scénario :
        # On suppose que les versions de production d'un module ne sont pas dispatchées entre les repositories
        # PSGallery : Repository principal de production. Il est toujours déclaré.
        # MyGet     : Repository secondaire de production public ou privé. Déclaré selon les besoins.
        # DEVMyGet  : Repository secondaire de test public ou privé. Il devrait toujours être déclaré :
        #              Validation de la chaîne de publication, test d'intégration.
        #
        #Seul les modules requis (RequiredModule) qui ne sont pas external sont installés implicitement par Install-Module,
        # ceux indiqués external (ExternalModuleDependencies) doivent l'être explicitement.
        #Dans Powershell une dépendances externe de module ne précise pas le repository cible, mais indique que la dépendance est dans un autre repository.
        #
        #Si on ne précise pas le paramètre -Repository avec Install-Module, Powershell installera le premier repository hébergeant le nom du module
        # répondant aux critéres de recherche.

        #
        #Si aucun module ne correspond aux critéres de recherche portant sur une version, Find-Module ne renvoit rien.
        #On ne sait donc pas différencier le cas où d'autres versions existent mais pas celle demandée et le cas où aucune version du module existe dans le repository.
        # (Elle peut exister mais ailleurs). Le module sera alors considéré comme externe.
        #
        #Update-ModuleManifest ne complète pas le contenu de la clé -ExternalModuleDependencies mais remplace le contenu existant.

        Write-Verbose  "Find-ExternalModuleDependencies : $($Module|Out-String)"
        $Module.Add('Repository',$Repository)

        Find-Module @Module -EA Stop > $null
        } catch {
            Write-Debug "Not found : $($Params|Out-String)"
            if (($_.CategoryInfo -match '^ObjectNotFound') -and ($_.FullyQualifiedErrorId -match '^NoMatchFoundForCriteria') )
            {
                #Insert into ExternalModuleDependencies
               Write-Output $Module.Name
            }
            else
            {throw $_}
        }
     }
 )
 if ($EMD.Count -ne 0)
 {
    #todo bug:
    #https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/19210978-update-modulemanifest-externalmoduledependencies
   if ($EMD.Count -eq 1)
   { $EMD +=$EMD[0] }
   Write-Verbose "ExternalModuleDependencies : $EMD"
   Return $EMD
 }
}

Function Read-ModuleDependency {
#Reads a module manifest and returns the contents of the RequiredModules key.
# todo read NestedModules :
# The RequiredModules and NestedModules lists of PSModuleInfo are used in preparing the dependency list of a module to be published.
#
#https://github.com/PowerShell/PSScriptAnalyzer/issues/546
#With that in mind, this should only warn when:
#
# (a) a module manifest defines one or more NestedModules; and
# (b) the same manifest does not define RootModule/ModuleToProcess; and
# (c) one of the NestedModules is a script or binary module in the same folder as the manifest with the same name.

   Param (
     [Parameter(Mandatory = $true)]
     [string] $ManifestPath
  )

  $PSmoduleInfo = $ev = $null
  $PSmoduleInfo  = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $ManifestPath `
                                                                 -ErrorVariable ev `
                                                                 -Verbose:$VerbosePreference
  if($ev)
  { throw (New-Object System.Exception -ArgumentList "Unable to read the manifest $Data",$_.Exception)  }

  if (($PSmoduleInfo.RequiredModules -eq $null) -or ($PSmoduleInfo.RequiredModules.Count -eq 0))
  { Write-Verbose "RequireModules empty or unknown : $Data" }

  Foreach ($ModuleInfo in $PSmoduleInfo.RequiredModules)
  {
      #Microsoft.PowerShell.Commands.ModuleSpecification : 'RequiredVersion' need PS version 5.0
      #Instead, one build splatting for Find-Module : Name, Repository et MinimumVersion ou MaximumVersion ou RequiredVersion
    Write-Debug "$($ModuleInfo|Out-String)"
    $Result=@{}


    $Result.Add('Name',$ModuleInfo.ModuleName)
    if ($ModuleInfo.Contains('ModuleVersion'))
    { $Result.Add('MinimumVersion',$ModuleInfo.ModuleVersion)}
    elseif ($ModuleInfo.Contains('RequiredVersion'))
    {$Result.Add('MinimumVersion',$ModuleInfo.ModuleVersion)}
    elseif ($ModuleInfo.Contains('RequiredVersion'))
    {}
    

    Write-Output $Result
  }
  Foreach ($ModuleInfo in $PSmoduleInfo.RequiredModules)
  {
    $RequiredPSModuleInfos = $PSModuleInfo.NestedModules | Microsoft.PowerShell.Core\Where-Object {
                          -not $_.ModuleBase.StartsWith($PSModuleInfo.ModuleBase, [System.StringComparison]::OrdinalIgnoreCase) -or
                          -not $_.Path -or 
                          -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $_.Path)
                         }
  }
}
Function New-ScriptFileName {
 [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions","",
                                                    Justification="New-ScriptFileName do not change the system state, it create only a file name.")]
  <#
  .SYNOPSIS
    Create a new file name from a type data file (.ps1xml).
    The name of the new file is equal to the "$TargetDirectory\$($File.Basename).ps1"

  .INPUTS
    [string]
  .OUTPUTS
    [string]
  #>
  param(
    # Specifies a path to one or more .ps1xml type data file.
     [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                HelpMessage="Path to one or more .ps1Xml type data file.")]
     [Alias("PSPath")]
     [ValidateNotNullOrEmpty()]
    [string] $File,

     # The destination directory for news files. The default value is : $env:temp
      [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
    [string] $TargetDirectory
  
  )
  process {
    $ScriptFile=[System.IO.FileInfo]::New($File)
    Write-output ("{0}\{1}{2}" -F $TargetDirectory,$ScriptFile.BaseName,'.ps1')
  }
}
 
Function Export-ScriptMethod {
  <#
  .SYNOPSIS
    Extract scriptblocs of a ScriptMethod from a type data file (.ps1Xml) and create a new file.
    The name of the new file is equal to the "$TargetDirectory\$($File.Basename).ps1"
    This file can be used with Invoke-ScriptAnalyzer.
  .DESCRIPTION
    Long description
  .INPUTS
    [string]
  .OUTPUTS
    [string]
  .NOTES
    General notes
  #>
  param(
    # Specifies a path to one or more .ps1xml type data file.
     [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                HelpMessage="Path to one or more .ps1Xml type data file.")]
     [Alias("PSPath")]
     [ValidateNotNullOrEmpty()]
    [string] $File,

     # The destination directory for news files. The default value is : $env:temp
     [ValidateNotNullOrEmpty()]
    [string] $TargetDirectory=$env:TEMP
  
  )
  process {
    Write-Debug "Read '$File'"
    [Xml]$Xml=Get-Content $File
    #On suppose le fichier xml comme étant un fichier de type Powershell (ETS) valide
    [int]$Count=0
    
    $NewFile=New-ScriptFileName -File $File -TargetDirectory $TargetDirectory
    
    $Script=New-Object System.Text.StringBuilder "# $File`r`n"
    foreach ($Type in $Xml.Types.Type)
    { 
      foreach ($ScriptMethod in $Type.Members.ScriptMethod)
      { 
          Write-Debug "Extract ScriptMethod : '$($Type.Name).$($ScriptMethod.Name)' "
          $Script.AppendLine("# $($Type.Name)") >$null
          $Script.Append("Function Name$Count") >$null
          $Script.AppendLine(".$($ScriptMethod.Name) {") >$null
          $Script.AppendLine($ScriptMethod.Script+"`r`n}") >$null  
          $count++
      }
    }
    Write-Debug "Write '$NewFile'"
    Set-Content -Value $Script.ToString() -Path $NewFile -Encoding UTF8
    Write-output $NewFile
 }
}

Properties {
    # ----------------------- Misc configuration properties ---------------------------------

    # Specifies the paths of the installed scripts
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PSGetInstalledPath=GetPowershellGetPath

    # Used by Edit-Template inside the 'RemoveConditionnal' task.
    # Valid values are 'Debug' or 'Release'
    # 'Release' : Remove the debugging/trace lines, include file, expand scriptblock, clean all directives
    # 'Debug' : Do not change anything
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    [ValidateSet('Release','Debug')]  $BuildConfiguration='Release'

    #To manage the ApiKey differently
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $isCIEnvironment=Test-CIEnvironment

    # ----------------------- Basic properties --------------------------------
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ProjectName= 'EtsDateTime'

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ProjectUrl= 'https://github.com/LaurentDardenne/EtsDateTime.git'

    # The root directories for the module's docs, src and test.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DocsRootDir = "$PSScriptRoot\docs"
    $SrcRootDir  = "$PSScriptRoot\src"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestRootDir = "$PSScriptRoot\test"

    # The name of your module should match the basename of the PSD1 file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ModuleName = Get-Item $SrcRootDir/*.psd1 |
                      Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } |
                      Select-Object -First 1 | Foreach-Object BaseName

    # The $OutDir is where module files and updatable help files are staged for signing, install and publishing.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $OutDir = "$PSScriptRoot\Release"

    # The local installation directory for the install task. Defaults to your home Modules location.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $InstallPath = Join-Path (Split-Path $profile.CurrentUserAllHosts -Parent) `
                             "Modules\$ModuleName\$((Test-ModuleManifest -Path $SrcRootDir\$ModuleName.psd1).Version.ToString())"

    #PSSA rules have no function to document
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $IsHelpGeneration=$true

    # Default Locale used for help generation, defaults to en-US.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DefaultLocale = 'en-US'

    # Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
    # Typically you wouldn't put any file under the src dir unless the file was going to ship with
    # the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Exclude = @("$ModuleName.psm1","$ModuleName.psd1",'*.bak')
    if ($BuildConfiguration -eq 'Release')
    { $Exclude +="${ModuleName}Log4Posh.Config.xml"}

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
    [String[]]$PSSACustomRules=@(
      (GetModulePath -Name OptimizationRules)
      (GetModulePath -Name ParameterSetRules)
    )

    #MeasureLocalizedData
     #Full path of the module to control
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $LocalizedDataModule="$SrcRootDir\$ModuleName.psm1"

     #Full path of the function to control. If $null is specified only the primary module is analyzed.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $LocalizedDataFunctions=$null

    #Cultures names to test the localized resources file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CulturesLocalizedData='en-US','fr-FR'

    # ------------------- Script signing properties ---------------------------

    # Set to $true if you want to sign your scripts. You will need to have a code-signing certificate.
    # You can specify the certificate's subject name below. If not specified, you will be prompted to
    # provide either a subject name or path to a PFX file.  After this one time prompt, the value will
    # saved for future use and you will no longer be prompted.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptSigningEnabled = $false

    # Specify the Subject Name of the certificate used to sign your scripts.  Leave it as $null and the
    # first time you build, you will be prompted to enter your code-signing certificate's Subject Name.
    # This variable is used only if $SignScripts is set to $true.
    #
    # This does require the code-signing certificate to be installed to your certificate store.  If you
    # have a code-signing certificate in a PFX file, install the certificate to your certificate store
    # with the command below. You may be prompted for the certificate's password.
    #
    # Import-PfxCertificate -FilePath .\myCodeSigingCert.pfx -CertStoreLocation Cert:\CurrentUser\My
    #
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertSubjectName = $null

    # Certificate store path.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertPath = "Cert:\"

    # -------------------- File catalog properties ----------------------------

    # Enable/disable generation of a catalog (.cat) file for the module.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CatalogGenerationEnabled = $false

    # Select the hash version to use for the catalog file: 1 for SHA1 (compat with Windows 7 and
    # Windows Server 2008 R2), 2 for SHA2 to support only newer Windows versions.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CatalogVersion = 2

    # ---------------------- Testing properties -------------------------------

    # Enable/disable Pester code coverage reporting.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageEnabled = $false

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageFiles = "$SrcRootDir\*.ps1", "$SrcRootDir\*.psm1"

    # -------------------- Publishing properties ------------------------------

    # Your NuGet API key for the nuget feed (PSGallery, Myget, Private).  Leave it as $null and the first time you publish,
    # you will be prompted to enter your API key.  The build will store the key encrypted in the
    # $NuGetApiKeyPath file, so that on subsequent publishes you will no longer be prompted for the API key.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NuGetApiKey = $null

    # Name of the repository you wish to publish to.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PublishRepository = $RepositoryName

    # Name of the repository for the development version
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Dev_PublishRepository = 'DevOttoMatt'

    # Path to encrypted APIKey file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NuGetApiKeyPath = "$env:LOCALAPPDATA\Plaster\SecuredBuildSettings\$PublishRepository-ApiKey.clixml"

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    # The contents of this file are used during publishing for the ReleaseNotes parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ReleaseNotesPath = "$PSScriptRoot\ChangeLog.md"


    # ----------------------- Misc properties ---------------------------------

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter. PFX passwords will not be stored.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SettingsPath = "$env:LOCALAPPDATA\Plaster\SecuredBuildSettings\$ProjectName.clixml"

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
}

###############################################################################
# Customize these tasks for performing operations before and/or after file staging.
###############################################################################

Task RemoveConditionnal -requiredVariables BuildConfiguration, ModuleOutDir{
#Traite les pseudo directives de parsing conditionnelle

 #bug scope/limit PSake ?
 # The first call works, but not the followings
 #-Force reload the ScriptToProcess
 Import-Module Template -Force

 try {
   $TempDirectory=New-TemporaryDirectory
   $ModuleOutDir="$OutDir\$ModuleName"

   Write-Verbose "Build with '$BuildConfiguration'"
   Get-ChildItem  "$SrcRootDir\$ModuleName.psm1","$SrcRootDir\$ModuleName.psd1"|
    Foreach-Object {
      $Source=$_
      $TempFileName="$TempDirectory\$($Source.Name)"
      Write-Verbose "Edit : $($Source.FullName)"
      Write-Verbose " to  : $TempFileName"
      if ($BuildConfiguration -eq 'Release')
      {

         #Transforme les directives %Scriptblock%
         $Lines=Get-Content -Path $Source -Encoding UTF8|
                 Edit-String -Setting $TemplateDefaultSettings|
                 Out-ArrayOfString

         #On supprime les lignes de code de Debug,
         #   supprime les lignes demandées,
         #   inclut les fichiers,
         #   nettoie toutes les directives restantes.

         ,$Lines|
           Edit-Template -ConditionnalsKeyWord 'DEBUG' -Include -Remove -Container $Source|
           Edit-Template -Clean|
           Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
      }
      elseif ($BuildConfiguration -eq 'Debug')
      {
         #On ne traite aucune directive et on ne supprime rien.
         #On inclut uniquement les fichiers.

         #'NODEBUG' est une directive inexistante et on ne supprime pas les directives
         #sinon cela génére trop de différences en cas de comparaison de fichier
         $Lines=Get-Content -Path $Source -Encoding UTF8|
                  Edit-String -Setting  $TemplateDefaultSettings|
                  Out-ArrayOfString

         ,$Lines|
           Edit-Template -ConditionnalsKeyWord 'NODEBUG' -Include -Container $Source|
           Set-Content -Path $TempFileName -Force -Encoding UTF8 -verbose:($VerbosePreference -eq 'Continue')
      }
      else
      { throw "Invalid configuration name '$BuildConfiguration'" }
     Copy-Item -Path $TempFileName -Destination $ModuleOutDir -Recurse -Verbose:($VerbosePreference -eq 'Continue') -EA Stop
    }#foreach
  } finally {
    if (Test-Path $TempDirectory)
    { Remove-Item $TempDirectory -Recurse -Force -Verbose:($VerbosePreference -eq 'Continue')  }
  }
}


# Executes before the StageFiles task.
Task BeforeStageFiles -Depends RemoveConditionnal{
}

#Verifying file encoding BEFORE generation
Task TestBOM -Precondition { $isTestBom } -requiredVariables SrcRootDir {
#La régle 'UseBOMForUnicodeEncodedFile' de PSScripAnalyzer s'assure que les fichiers qui
# ne sont pas encodés ASCII ont un BOM (cette régle est trop 'permissive' ici).
#On ne veut livrer que des fichiers UTF-8.

  Write-verbose "Validation de l'encodage des fichiers du répertoire : $SrcRootDir"

  Import-Module DTW.PS.FileSystem

  $InvalidFiles=Test-BOMFile -path $SrcRootDir
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
}

Task TestLocalizedData  {
    Import-module MeasureLocalizedData

    if ($null -eq $LocalizedDataFunctions)
    {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule }
    else
    {$Result = $CulturesLocalizedData|Measure-ImportLocalizedData -Primary $LocalizedDataModule -Secondary $LocalizedDataFunctions}
    if ($Result.Count -ne 0)
    {
      $Result
      throw 'One or more MeasureLocalizedData errors were found. Build cannot continue!'
    }
}

# Executes after the StageFiles task.
Task AfterStageFiles -Depends TestBOM, TestLocalizedData {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BeforeStageFiles phase of the Build task.
Task BeforeBuild {
}

# #Verifying file encoding AFTER generation
Task TestBOMAfterAll -Precondition { $isTestBom } -requiredVariables OutDir {
   Import-Module DTW.PS.FileSystem

  Write-Verbose  "Validation finale de l'encodage des fichiers du répertoire : $OutDir"
  $InvalidFiles=Test-BOMFile -path $OutDir
  if ($InvalidFiles.Count -ne 0)
  {
     $InvalidFiles |Format-List *
     Throw "Des fichiers ne sont pas encodés en UTF8 ou sont codés BigEndian."
  }
}

Task BeforeAnalyze -requiredVariables Projectname, OutDir, ModuleName{
  #Extract scriptmethod into release directory
  #So, PSScriptAnalyzer can treate this files.
    $TDpath="$OutDir\$ModuleName\TypeData"
    Get-ChildItem "$TDpath\*.ps1xml"|
     Export-ScriptMethod -TargetDirectory $TDpath >$null
}

Task AfterAnalyze {
    #see BeforePublish
    
}

# Executes after the Build task.
Task AfterBuild  -Depends TestBOMAfterAll {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the BuildHelp task.
Task BeforeBuildHelp {
}

# Executes after the BuildHelp task.
Task AfterBuildHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildUpdatableHelp.
###############################################################################

# Executes before the BuildUpdatableHelp task.
Task BeforeBuildUpdatableHelp {
}

# Executes after the BuildUpdatableHelp task.
Task AfterBuildUpdatableHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after GenerateFileCatalog.
###############################################################################

# Executes before the GenerateFileCatalog task.
Task BeforeGenerateFileCatalog {
}

# Executes after the GenerateFileCatalog task.
Task AfterGenerateFileCatalog {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the Install task.
Task BeforeInstall {
}

# Executes after the Install task.
Task AfterInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before the Publish task.
Task BeforePublish -requiredVariables Projectname, OutDir, ModuleName, PublishRepository, Dev_PublishRepository {
     #Suppresses unnecessary files created by BeforeAnalyze task
    Get-ChildItem "$OutDir\$ModuleName\TypeData\*.ps1"| Remove-item
   
    $ManifestPath="$OutDir\$ModuleName\$ModuleName.psd1"
    if ( (-not [string]::IsNullOrWhiteSpace($Dev_PublishRepository)) -and ($PublishRepository -eq $Dev_PublishRepository ))
    {
        #Increment  the module version for dev repository only
        Import-Module BuildHelpers
        $SourceLocation=(Get-PSRepository -Name $PublishRepository).SourceLocation
        "Get the latest version for '$ProjectName' in '$SourceLocation'"
        $Version = Get-NextNugetPackageVersion -Name $ProjectName -PackageSourceUrl $SourceLocation

        $ModuleVersion=(Test-ModuleManifest -path $ManifestPath).Version
        # If no version exists, take the current version
        $isGreater=$Version -gt $ModuleVersion
        "Update the module metadata '$ManifestPath' [$ModuleVersion] ? $isGreater "
        if ($isGreater)
        {
           "with the new version : $version"
           Update-Metadata -Path $ManifestPath  -PropertyName ModuleVersion -Value $Version
        }
    }

    $ModuleNames=Read-ModuleDependency $ManifestPath -AsHashTable
     #ExternalModuleDependencies
    if ($null -ne $ModuleNames)
    {
        $EMD=Find-ExternalModuleDependencies $ModuleNames -Repository $PublishRepository
        if ($null -ne $EMD)
        {
          "Update ExternalModuleDependencies with $($EMD.Name) in '$ManifestPath'"
          Update-ModuleManifest -path $ManifestPath -ExternalModuleDependencies $EMD
        }
    }
}

# Executes after the Publish task.
Task AfterPublish {
}
