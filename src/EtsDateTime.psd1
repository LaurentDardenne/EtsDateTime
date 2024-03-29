﻿#
# Manifeste de module pour le module "EtsDateTime"
#
# Généré le : 03/06/2017

@{
  RootModule="EtsDateTime.psm1"

  Author="Laurent Dardenne. FluentDateTime authors : Slobodan Pavkov, Tom Pester, Simon Cropp. DateTimeExtensions author : Joao Matos Silva"
  Copyright="http://www.apache.org/licenses/LICENSE-2.0.html"
  Description="A set of C# extension methods for easier and more natural DateTime handling and operations in Powershell."
  CLRVersion="4.0"
  GUID = 'a4b6fb6e-b8fd-448d-ba62-630eaf075bde'
  ModuleVersion="1.0.0"
  PowerShellVersion="5.1"
  TypesToProcess = @(
     '.\TypeData\FluentDateTime.Extensions.Types.ps1xml',
     '.\TypeData\DateTimeExtensions.Types.ps1xml',
     '.\TypeData\System.String.Types.ps1xml'
  )

  RequiredAssemblies=@(
    '.\lib\FluentDateTime.dll',
    '.\lib\DateTimeExtensions\DateTimeExtensions.dll'
  )

 FunctionsToExport=@( 'Get-EtsDatetimeMethod' )

 CompatiblePSEditions = 'Desktop'

 PrivateData = @{

  PSData = @{

      Tags = @('PSEdition_Desktop','.ps1xml','Types','XML','typeextension','typedata')

      LicenseUri = 'https://creativecommons.org/licenses/by-nc-sa/4.0'

      ProjectUri = 'https://github.com/LaurentDardenne/EtsDateTime'

      ReleaseNotes = 'Initial version.'
  }
 }
}
