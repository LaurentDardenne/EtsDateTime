$Configuration=New-PesterConfiguration

#$Configuration.filter.Tag=('SetCulture')
#$Configuration.filter.Tag=('UseCulture')
#$Configuration.filter.Tag=('UseCultureHC')

$Configuration.filter.Tag=('Job')

$Configuration.Output.Verbosity=('Detailed')

Invoke-Pester -Configuration $Configuration
