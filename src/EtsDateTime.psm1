
Function Get-EtsDatetimeMethod {
  param([switch] $help)

  if ($help)
  {
    if (Get-Command 'hh.exe' -ErrorAction SilentlyContinue)
     {
       hh.exe $PSScriptRoot\docs\DateTimeExtensions.chm
       hh.exe $PSScriptRoot\docs\FluentDateTime.chm
     }
     else
     { Write-Warning "Program not found : 'hh.exe'" }
  }
  else
  {  (Get-TypeData -TypeName Datetime).Members.Keys }
}

Export-ModuleMember -Function 'Get-EtsDatetimeMethod'