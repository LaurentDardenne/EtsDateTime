#Requires -Modules InvokeBuild

[CmdletBinding(DefaultParameterSetName = "Debug")]
Param(
    [Parameter(ParameterSetName="Release")]
  [switch] $Release,

  [switch] $Prod
 )


Write-Host "Build and publish the EtsDatetime module."
$Environnement='Dev'
if ($Prod)
{ $Environnement='Prod' }

$local:Verbose=$PSBoundParameters.ContainsKey('Verbose')
$local:Debug=$($PSBoundParameters.ContainsKey('Debug'))
Invoke-Build -File "$PSScriptRoot\EtsDatetime.build.ps1" -Task publish -Configuration $PsCmdlet.ParameterSetName -Environnement $Environnement -Verbose:$Verbose -Debug:$Debug
