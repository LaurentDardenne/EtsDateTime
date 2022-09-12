
Import-Module "$PSScriptRoot\..\Release\EtsDatetime\EtsDatetime.psd1"

Describe 'Ets Get-TypeData' {
    Beforeall {
      $EtsDatetimeMethod=Get-EtsDatetimeMethod
      $EtsDatetimeMethod >$null
    }

    Context "Checks loaded type files." {
      it "counts the number of extended types." {
        $EtsDatetimeMethod.Keys.Count| Should -Be 7
      }
    }

    Context "counts the number of extended methods by types."{
        It "counts the number of extended methods for the type 'System.Int32'"{
          $EtsDatetimeMethod.'System.Int32'.Count | Should -Be 10
        }

        It "counts the number of extended methods for the type 'System.String'" {
          $EtsDatetimeMethod.'System.String'.Count | Should -Be 2
        }

        It "counts the number of extended methods for the type 'System.DateTimeOffset'"{
          $EtsDatetimeMethod.'System.DateTimeOffset'.Count | Should -Be 52
        }

        It "counts the number of extended methods for the type 'FluentDate.FluentTimeSpan'"{
          $EtsDatetimeMethod.'FluentDate.FluentTimeSpan'.Count | Should -Be 6
        }

        It "counts the number of extended methods for the type 'System.Int64'"{
          $EtsDatetimeMethod.'System.Int64'.Count | Should -Be 1
        }

        It "counts the number of extended methods for the type 'System.DateTime'"{
          $EtsDatetimeMethod.'System.DateTime'.Count | Should -Be 69
        }

        It "counts the number of extended methods for the type 'System.Double'"{
          $EtsDatetimeMethod.'System.Double'.Count | Should -Be 6
        }
    }
}