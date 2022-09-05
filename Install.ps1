#Install.ps1
#Requires -Modules psake

#Install : new workstation
# CI (Action) use a cache

#or update the dependencies locally (Modules, scripts, binaries)
#The versions of the modules installed on the IC and those installed on the dev station
#may not match and break the build.


 [CmdletBinding(DefaultParameterSetName = "Install")]
 Param(
     [Parameter(ParameterSetName="Update")]
   [switch] $Update
 )
#By default we install, otherwise we update
Invoke-Psake ".\Install.psake.ps1" -parameters @{"Mode"="$($PsCmdlet.ParameterSetName)"} -nologo
