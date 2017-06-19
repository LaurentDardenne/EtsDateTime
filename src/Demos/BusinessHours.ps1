#Heure d'ouverture

# Fermé Dimanche et Lundi
# Fermé les jours férié français (par défaut, pas par département). Date fixe et mobile
# Mardi..Vendredi :  HeureDebut="8:00:00" HeureFin="20:00:00" Samedi HeureDebut="8:00:00" HeureFin="14:00:00"

#DateAddSample

$DateAdd = New-Object Itenso.TimePeriod.DateAdd

 $DateAdd.IncludePeriods.Add(
    (New-Object Itenso.TimePeriod.TimeRange(
         (New-Object DateTime( 2011, 3, 17 )),
         (New-Object DateTime( 2011, 4, 20 )))))

  #setup some periods to exclude
 $DateAdd.ExcludePeriods.Add( (New-Object Itenso.TimePeriod.TimeRange(
    (New-Object DateTime( 2011, 3, 22 )), 
    (New-Object DateTime( 2011, 3, 25 ) ) ) ))
 
 $DateAdd.ExcludePeriods.Add( (New-Object Itenso.TimePeriod.TimeRange(
    (New-Object DateTime( 2011, 4, 1 )), 
    (New-Object DateTime( 2011, 4, 7 ) ) )))
  $DateAdd.ExcludePeriods.Add( (New-Object Itenso.TimePeriod.TimeRange(
    (New-Object DateTime( 2011, 4, 15 )), 
    (New-Object DateTime( 2011, 4, 16 ) ) )))

 #positive
$dateDiffPositive = New-Object DateTime( 2011, 3, 19 )
$positive1 = $dateAdd.Add( $dateDiffPositive, [Itenso.TimePeriod.Duration]::Hours( 1 ) )
"DateAdd Positive1: {0}" -f $positive1

$positive2 = $dateAdd.Add( $dateDiffPositive, [Itenso.TimePeriod.Duration]::Days( 4 ) )
"DateAdd Positive2: {0}"  -f $positive2

$positive3 = $dateAdd.Add( $dateDiffPositive, [Itenso.TimePeriod.Duration]::Days( 17 ) )
"DateAdd Positive3: {0}" -F $positive3

$positive4 = $dateAdd.Add( $dateDiffPositive, [Itenso.TimePeriod.Duration]::Days( 20 ) )
"DateAdd Positive4: {0}" -F $positive4

 #negative
$dateDiffNegative = New-Object DateTime( 2011, 4, 18 )
$negative1 = $dateAdd.Add( $dateDiffNegative, [Itenso.TimePeriod.Duration]::Hours( -1 ) )
 "DateAdd Negative1: {0}" -f $negative1

$negative2 = $dateAdd.Add( $dateDiffNegative, [Itenso.TimePeriod.Duration]::Days( -4 ) )
"DateAdd Negative2: {0}" -f $negative2

$negative3 = $dateAdd.Add( $dateDiffNegative, [Itenso.TimePeriod.Duration]::Days( -17 ) )
"DateAdd Negative3: {0}" -f $negative3
$negative4 = $dateAdd.Add( $dateDiffNegative, [Itenso.TimePeriod.Duration]::Days( -20 ) )
"DateAdd Negative4: {0}" -f $negative4


#CalendarDateAddSample
$calendarDateAdd = New-Object Itenso.TimePeriod.CalendarDateAdd
  # weekdays
$calendarDateAdd.AddWorkingWeekDays()
  # holidays
$calendarDateAdd.ExcludePeriods.Add( (New-Object Itenso.TimePeriod.Day( 2011, 4, 5, $calendarDateAdd.Calendar)))
 # working hours
$calendarDateAdd.WorkingHours.Add( 
      (New-Object Itenso.TimePeriod.HourRange(
        (New-Object Itenso.TimePeriod.Time( 08, 30 )), 
        (New-Object Itenso.TimePeriod.Time( 12 )))))
 $calendarDateAdd.WorkingHours.Add( 
     (New-Object Itenso.TimePeriod.HourRange( 
        (New-Object Itenso.TimePeriod.Time( 13, 30 )), 
        (New-Object Itenso.TimePeriod.Time( 18 ) ) )))

$start = New-Object DateTime( 2011, 4, 1, 9, 0, 0 )
$offset = New-Object TimeSpan( 22, 0, 0 ) # 22 hours

$end = $calendarDateAdd.Add( $start, $offset )
"start: {0}" -F $start
"offset: {0}" -F $offset
"end: {0}" -F $end

#CalendarPeriodCollectorSample

$filter = New-Object Itenso.TimePeriod.CalendarPeriodCollectorFilter
$filter.Months.Add( [Itenso.TimePeriod.YearMonth]::January ) # only Januaries
$filter.WeekDays.Add( [System.DayOfWeek]::Friday ) # only Fridays
$filter.CollectingHours.Add((New-Object Itenso.TimePeriod.HourRange( 8, 18 ) )) #working hours

$testPeriod =New-Object Itenso.TimePeriod.CalendarTimeRange((new-Object DateTime( 2010, 1, 1 )), (New-Object DateTime( 2011, 12, 31 ) ))
"Calendar period collector of period: " + $testPeriod
$collector =New-Object Itenso.TimePeriod.CalendarPeriodCollector( $filter, $testPeriod )
$collector.CollectHours()

foreach ( $period in $collector.Periods )
{
  "Period: " + $period
}

$filter = New-Object Itenso.TimePeriod.CalendarPeriodCollectorFilter
$filter.Months.Add( [DateTime]::Now.ToString("MMMM", [CultureInfo]::InvariantCulture))
$filter.AddWorkingWeekDays()
$filter.WeekDays.Add([System.DayOfWeek]::Saturday)
$filter.WeekDays.Remove([System.DayOfWeek]::Monday) > $null

Exclusion basé sur Itenso.TimePeriod, quelle classe ?