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

$Repositories.$($PsCmdlet.ParameterSetName)
# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList Publish -parameters @{"RepositoryName"=$Repositories.$($PsCmdlet.ParameterSetName)}
