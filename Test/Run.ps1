$Configuration=New-PesterConfiguration

#$Configuration.filter.Tag=('Job')

$Configuration.Output.Verbosity=('Detailed')

Invoke-Pester -Configuration $Configuration
