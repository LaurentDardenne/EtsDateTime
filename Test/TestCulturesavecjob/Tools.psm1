#Module Tools

$script:CultureInfoFR=[System.Globalization.CultureInfo]::GetCultureInfo("fr-FR")
<#
Formats de date Fr autorisés lors d'une recherche :
-              Deux chaines représentant des dates séparées par un espace : 'dd/MM/yyyy dd/MM/yyyy' (sans les guillemets)
-              Une chaine représentant une date : 'dd/MM/yyyy'
-              Une chaine représentant un mois et une année : 'MM/yyyy'
-              Une chaine représentant une année : 'yyyy'
#>

$script:LongDateFormatFR='dd/MM/yyyy'
$script:LongDateFormatUS='MM/dd/yyyy'
[string[]] $script:AllowedShortFormatsDeliveryDate=@('dd/MM','MM/yyyy','yyyy')
[string[]] $script:AllowedFormatsDeliveryDate=$script:AllowedShortFormatsDeliveryDate+$script:LongDateFormatFR

[string] $script:DeliveryDateInvalidMsg=@"
The date format is invalid for the string '{0}'
Only the following formats are allowed:
'dd/MM','MM/yyyy','yyyy','dd/MM/yyyy','dd/MM/yyyy dd/MM/yyyy'
"@

$Culture=Get-Culture
$Script:isFrenchCulture=$Culture.Name -eq 'fr-FR'
$Script:isEnglishCulture=$Culture.TwoLetterISOLanguageName -eq 'en'
Remove-Variable -Name 'Culture'

Function ConvertTo-Datetime {
  [CmdletBinding()]
  [OutputType([Datetime])]
#Renvoi un datetime formaté à partir d'une chaîne représentant une date formatée en Français.
#La plupart des requêtes TSQL construisent des PSobjets ayant des propriétés contenant
# du texte représentant une date au format dd/mm/yyyy.
param(
    [Parameter(Mandatory=$True)]
    [AllowEmptyString()]
   [string] $Date
)
   #Pour la démo Pester
   Write-Warning "$(Get-Culture)"
   Write-Warning "UI culture $([System.Threading.Thread]::CurrentThread.CurrentUICulture)"
   Write-Warning "culture $([System.Threading.Thread]::CurrentThread.CurrentCulture)"
   if ( [string]::IsNullOrEmpty($Date))
   {
      #L'appelant décide si, à la place de null, on utilise la date du jour.
      Write-Debug 'Return Null. Date is null or empty'
      return $null
   }

   if ($script:isEnglishCulture)
   {
      Write-Debug 'Return an English date with Fr culture'
      #On transforme la date récupérée en base avec le format Français et pas celui de la culture courante
      return [DateTime]::Parse($Date, $script:CultureInfoFR)
   }
   else #tente un formatage Fr si la culture est Fr, It,GB,ES,SP sinon échoue sur une exception.
   {
      Write-Debug 'Return an French date with current culture'
      return (Get-Date $Date)
   }
}

Export-ModuleMember -Variable * -Function *
