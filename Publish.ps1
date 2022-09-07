#Requires -Modules psake
 [CmdletBinding(DefaultParameterSetName = 'Dev')]
 Param(
      #see appveyor.yml
     [Parameter(ParameterSetName='Myget')]
    [switch] $MyGet,

     [Parameter(ParameterSetName='Dev')]
    [switch] $Dev,

     [Parameter(ParameterSetName='PowershellGallery')]
    [switch] $PSGallery
 )
$Repositories=@{
 'PowershellGallery'='PSGallery'
 'MyGet'='OttoMatt'
 'Dev'='DevOttoMatt'
}

$Repositories.$($PsCmdlet.ParameterSetName)
# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList Publish -parameters @{"RepositoryName"=$Repositories.$($PsCmdlet.ParameterSetName)}

<#
# Executes before the Publish task.
Task BeforePublish -requiredVariables Projectname, OutDir, ModuleName, PublishRepository, Dev_PublishRepository {
    $ManifestPath="$OutDir\$ModuleName\$ModuleName.psd1"
    if ( (-not [string]::IsNullOrWhiteSpace($Dev_PublishRepository)) -and ($PublishRepository -eq $Dev_PublishRepository ))
    {
        #Increment the module version for dev repository only
        Import-Module BuildHelpers
        $SourceLocation=(Get-PSRepository -Name $PublishRepository).SourceLocation
        Write-host "Get the latest version for '$ProjectName' in '$SourceLocation'"
        $Version = Get-NextNugetPackageVersion -Name $ProjectName -PackageSourceUrl $SourceLocation

        $ModuleVersion=(Test-ModuleManifest -path $ManifestPath).Version
        # If no version exists, take the current version
        $isGreater=$Version -gt $ModuleVersion
        Write-host "Update the module metadata '$ManifestPath' [$ModuleVersion] ? $isGreater "
        if ($isGreater)
        {
           "with the new version : $version"
           Update-Metadata -Path $ManifestPath  -PropertyName ModuleVersion -Value $Version
        }
    }
}
#>