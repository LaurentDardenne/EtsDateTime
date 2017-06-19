Import-Module "..\Release\EtsDatetime\EtsDatetime.psd1"

Describe 'Exported variable IsoCountiesFR' {
    It "must contains 128 counties" {
        $IsoCountiesFR.Count|Should Be 128
    }
    
    It "return 'FR-GF' with 'Guyane (française)'" {
        $IsoCountiesFR.'Guyane (francaise)'|Should Be 'FR-GF'
    }
}

Describe "Get-PublicHolidayFR" {
    It "return all french public holiday" {
        $Ph=Get-PublicHolidayFR 2017
        $Ph.Count|Should Be 24
    }
    
    It "return all specific french public holiday for a county (La Martinique)" {
        $Ph=Get-PublicHolidayFR 2017
        $Ph.SpecificPublicHoliday($IsoCountiesFR.Martinique).Count|Should Be 4
    }
    
    It "return all shared french public holiday" {
        $Ph=Get-PublicHolidayFR 2017
        $Ph.SharedPublicHoliday().Count|Should Be 11
    }

   It "return all french public holiday by county (La Martinique)" {
        $Ph=Get-PublicHolidayFR 2017
        $Ph.PublicHolidayByCounty($IsoCountiesFR.Martinique).Count|Should Be (11+4)
    }

   It "return false for a day('20/12/2017' Abolition de l'esclavage) that is not a shared french public holiday" {
        $Ph=Get-PublicHolidayFR 2017
        $searchDay='20/12/2017' -as [datetime]
        $Ph.isHoliday($searchday)|Should be $false
   }

   It "return true for a day ('11/11/2017') that is a shared french public holiday" {
        $Ph=Get-PublicHolidayFR 2017
        $searchDay='11/11/2017' -as [datetime]
        $Ph.isHoliday($searchday)|Should be $true
   }
   
   It "return true for a day ('11/11/2017') that is a french public holiday and a specific county (La Réunion)" {
        $Ph=Get-PublicHolidayFR 2017
        $searchDay='11/11/2017' -as [datetime]
        $SpecificCounty='FR-RE'
        $Ph.isHoliday($searchday,$SpecificCounty)|Should be $true
   }

   It "return false for a day ('20/12/2017') that is not a specific french public holiday (La Martinique)" {
        $Ph=Get-PublicHolidayFR 2017
        $searchDay='20/12/2017' -as [datetime]
        $SpecificCounty='FR-MQ'
        $Ph.isHoliday($searchday,$SpecificCounty)|Should be $false
   }

   It "return true for a day ('20/12/2017' Abolition de l'esclavage) that is a specific french public holiday (La Réunion)" {
        $Ph=Get-PublicHolidayFR 2017
        $searchDay='20/12/2017' -as [datetime]
        $SpecificCounty='FR-RE'
        $Ph.isHoliday($searchday,$SpecificCounty)|Should be $true
   }

   It "return false for a day ('21/12/2017' ) that is not a specific french public holiday (La Réunion)" {
        $Ph=Get-PublicHolidayFR 2017
        $searchDay='21/12/2017' -as [datetime]
        $SpecificCounty='FR-RE'
        $Ph.isHoliday($searchday,$SpecificCounty)|Should be $false
   }
}
Describe "Get-PublicHolidayFR with error" {
  #Impossible to calc EasterSunday with 0 or -1
  # [Nager.Date.PublicHolidays.FranceProvider]::EasterSunday(0)
    It "- Year -1 throw an exception" {
        {Get-PublicHolidayFR -Year -1} | Should Throw
    }
    
    It "- Year 0 throw an exception" {
        {Get-PublicHolidayFR -Year 0} | Should Throw
    }
}
