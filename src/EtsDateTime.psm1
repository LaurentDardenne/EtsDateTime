
Function Get-EtsDatetimeMethod{
# .ExternalHelp EtsDateTime-help.xml
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
  {
    $Result=@{}
    foreach($TypeName in 'Datetime','DateTimeOffset','Int32','Int64','String','Double','FluentDate.FluentTimeSpan')
    {
      $td=Get-TypeData -TypeName $TypeName
      $KeyName=$td.TypeName
      $Result.$KeyName=$td.Members.Keys
    }
    return ,$Result
  }
}

Export-ModuleMember -Function 'Get-EtsDatetimeMethod'