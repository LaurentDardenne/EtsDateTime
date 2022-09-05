#Install.psake.ps1

###############################################################################
# Dot source the user's customized properties and extension tasks.
###############################################################################
. $PSScriptRoot\Install.settings.ps1

Task default -Depends Install,Update

Task Install -Depends RegisterPSRepository -Precondition { $Mode -eq  'Install'}  {

  #Suppose : PowershellGet à jour
  #On précise le repository car Pester est également sur Nuget
  $PSGallery.Modules |ForEach-Object {
    Write-Host "PSGallery : Install module $_"
    PowershellGet\Install-Module -Name $_ -Repository PSGallery -Scope $InstallationScope  -SkipPublisherCheck -AllowClobber
  }

  $MyGet.Modules  |ForEach-Object {
    Write-Host "MyGet :Install module $_"
    PowershellGet\Install-Module -Name $_ -Repository OttoMatt -Scope $InstallationScope -AllowClobber
  }
}

Task RegisterPSRepository {
  Foreach ($Repository in $Repositories)
  {
    $Name=$Repository.Name
    try{
        $RepositoryNames.Add($Name) > $Null
        Get-PSRepository $Name -EA Stop >$null
    }catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound')
        { throw $_ }
        else
        {
          $Parameters=@{
              Name=$Name
              SourceLocation=$Repository.SourceLocation
              PublishLocation=$Repository.PublishLocation

              ScriptSourceLocation= "$($Repository.SourceLocation)\"
              ScriptPublishLocation=$Repository.SourceLocation

              InstallationPolicy='Trusted'
          }
          Write-Output "Register repository '$($Repository.Name)'"
          Register-PSRepository @Parameters
        }
    }
  }
}

Task Update -Precondition { $Mode -eq 'Update'}  {

  $sbUpdateOrInstallModule={
      $ModuleName=$_
      try {
        Write-Host "Update module $ModuleName"
         PowershellGet\Update-Module -name $ModuleName
      }
      catch [Microsoft.PowerShell.Commands.WriteErrorException]{
        if ($_.FullyQualifiedErrorId -match ('^ModuleNotInstalledOnThisMachine'))
        {
          Write-Host "`tInstall module $ModuleName"
          PowershellGet\Install-Module -Name $ModuleName -Repository $CurrentRepository -Scope $InstallationScope
        }
        else
        { throw $_ }
      }
  }

   $sbUpdateOrInstallScript={
      $ScriptName=$_
      try {
        Write-Host "Update script $ScriptName"
        PowershellGet\Update-Script -name $ScriptName
      }
      catch [Microsoft.PowerShell.Commands.WriteErrorException]{
        if ($_.FullyQualifiedErrorId -match ('^ScriptNotInstalledOnThisMachine'))
        {
          Write-Host "`tInstall script $ScriptName"
          PowershellGet\Install-Script -Name $ScriptName -Repository $CurrentRepository -Scope $InstallationScope
        }
        else
        { throw $_ }
      }
  }
  $CurrentRepository='PSGallery'
   $PSGallery.Modules|Foreach-Object $sbUpdateOrInstallModule
   $PSGallery.Scripts|Foreach-Object $sbUpdateOrInstallScript

  $CurrentRepository='OttoMatt'
   $MyGet.Modules|Foreach-Object $sbUpdateOrInstallModule
   $MyGet.Scripts|Foreach-Object $sbUpdateOrInstallScript
}

