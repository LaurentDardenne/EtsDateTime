# EtsDateTime
Provides extensions to help manage DateTime types.

To install this module :
```Powershell
$PublishUri = 'https://www.myget.org/F/devottomatt/api/v2/package'
$SourceUri = 'https://www.myget.org/F/devottomatt/api/v2'

Register-PSRepository -Name DevOttoMatt -SourceLocation $SourceUri -PublishLocation $PublishUri #-InstallationPolicy Trusted
Install-Module EtsDateTime -Repository DevOttoMatt
```
[Demos](https://github.com/LaurentDardenne/EtsDateTime/blob/master/src/Demos/DateTime.ps1)
