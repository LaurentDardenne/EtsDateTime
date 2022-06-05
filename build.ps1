#Requires -Modules InvokeBuild

[CmdletBinding(DefaultParameterSetName = "Debug")]
Param(
    [Parameter(ParameterSetName="Release")]
  [switch] $Release,

  [ValidateRange('Dev','Prod')]
  [string] $Environnement='Dev'
)

Write-Host "Build the delivery for the EtsDatetime module."
$local:Verbose=$PSBoundParameters.ContainsKey('Verbose')
$local:Debug=$($PSBoundParameters.ContainsKey('Debug'))
Invoke-Build -File "$PSScriptRoot\EtsDatetime.build.ps1" -Configuration $PsCmdlet.ParameterSetName -Environnement $Environnement -Verbose:$Verbose -Debug:$Debug
