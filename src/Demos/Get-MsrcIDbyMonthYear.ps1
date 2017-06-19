Function Get-MsrcIDbyMonthYear {
#Elle permet de créer une chaîne de caractères de type "Année-MoisEnCours" pour intérroger l'API MSRC de Microsoft. 
    Param(
        [Parameter(Mandatory = $true)]
        [int]$Month,

        [Parameter(Mandatory = $true)]
        [int]$Year
    )
    #Variables
    $i = 1
    $TabMonth = @()

    #Generation du tableau des mois
    #Note : [0..11] car le tableau renferme un index 12 qui est vide.
    $Culture = [cultureinfo]::GetCultureInfo('en-US')
    $AbbreviatedMonth = $Culture.DateTimeFormat.AbbreviatedMonthNames[0..11]

    Foreach ($M in $AbbreviatedMonth){
        $TabMonth += [PSCustomObject]@{
            NumOfMonth = $i
            AbbreviatedMonthName = $M
        }
        $i++
    }

    #Generationd de l'ID en fonction de l'annee et du mois
    $AbbMonth = $TabMonth[$Month-1].AbbreviatedMonthName
    $ID = "$Year-$AbbMonth"

    Return $ID
}

Types {
    _Type System.String {
        ScriptMethod ToMsrcID {
         switch ($args.Count) {
           1 {        
                $Date=$args[0]
                 ($Date -as [datetime]).ToString("yyyy-MMM", [CultureInfo]::CreateSpecificCulture('En-US'))
              }
              
           default { throw "No overload for 'ToMsrcID' takes the specified number of parameters." }
         }             
        }
    }
}