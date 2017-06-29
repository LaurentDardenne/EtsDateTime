#Heure d'ouverture

# Fermé Dimanche et Lundi
# Fermé les jours férié français (par défaut, pas par département). Date fixe et mobile
# Mardi..Vendredi :  HeureDebut="8:00:00" HeureFin="20:00:00" Samedi HeureDebut="8:00:00" HeureFin="14:00:00"

# I'm trying to understand how to schedule 20 hours of work.

# I've use CalendarDateAdd to find the start and the end time assuming working hours of 8-16 Monday-Friday. So far so good.

# My question, is how can I figure out the scheduled periods?
# - 1 day, 8 hours (8-16)
# - 1 day, 8 hours (8-16)
# - 1 day, 4 hours (8-12)

# I tried the CalendarPeriodCollector, however it returns 3 days of 8 hours...
# There a three steps to calculate the scheduled periods:
# 1. calculate the scheduling end moment using CalendarDateAdd: result is DateTime
# 2. determine the scheduling days using CalendarPeriodCollector: ITimePeriodCollection
# 3. determine the scheduling days using TimePeriodIntersector: ITimePeriodCollection


Function CalendarPeriodCollectorSample{
  $start = [Itenso.TimePeriod.Now]::Week([DayOfWeek]::Monday)
  $Collector = GetCollector $start ([TimeSpan]::FromHours(20))
  $periods = GetSchedulingPeriods $Collector
  foreach ($period in $periods)
  {
    "Period: " + $period
  }
} 
Function CalendarPeriodCollectorSample2{
  param([int]$hours=20)
  $start = [Itenso.TimePeriod.Now]::Week([DayOfWeek]::Monday)
  $Collector = GetCollector $start ([TimeSpan]::FromHours($Hours))
  $periods = GetSchedulingPeriods $Collector
  foreach ($period in $periods)
  {
    "Period: " + $period
  }
} 
 
function GetCollector([DateTime] $start, [TimeSpan] $offset)
{
  #const 
  [int] $workDayStart = 8
  [int] $workDayEnd = 16

  $calendar = new-object Itenso.TimePeriod.TimeCalendar(
    (New-Object Itenso.TimePeriod.TimeCalendarConfig -Property @{'EndOffset' = [TimeSpan]::Zero})
  )
 
  # calculate schedule end time
  $calendarDateAdd = New-Object Itenso.TimePeriod.CalendarDateAdd($calendar)
  $calendarDateAdd.AddWorkingWeekDays()
  $calendarDateAdd.WorkingDayHours.Add((New-Object Itenso.TimePeriod.DayHourRange([DayOfWeek]::Monday, $workDayStart, $workDayEnd)))
  $calendarDateAdd.WorkingDayHours.Add((New-Object Itenso.TimePeriod.DayHourRange([DayOfWeek]::Tuesday, $workDayStart, $workDayEnd)))
  $calendarDateAdd.WorkingDayHours.Add((New-Object Itenso.TimePeriod.DayHourRange([DayOfWeek]::Wednesday, $workDayStart,$workDayEnd)))
  $calendarDateAdd.WorkingDayHours.Add((New-Object Itenso.TimePeriod.DayHourRange([DayOfWeek]::Thursday, $workDayStart, $workDayEnd)))
  $calendarDateAdd.WorkingDayHours.Add((New-Object Itenso.TimePeriod.DayHourRange([DayOfWeek]::Friday, $workDayStart, $workDayEnd)))  #DateTime? 
  $end = $calendarDateAdd.Add($start, $offset,[Itenso.TimePeriod.SeekBoundaryMode]::Next )
  if ($null -eq $end)
  {
    return $null
  }
 
  #get scheduling days
  $filter = New-Object Itenso.TimePeriod.CalendarPeriodCollectorFilter
  $filter.AddWorkingWeekDays()
  $filter.CollectingHours.Add((New-Object Itenso.TimePeriod.HourRange($workDayStart, $workDayEnd)))
  $schedulePeriod = New-Object Itenso.TimePeriod.CalendarTimeRange($start, $end.AddDays(1));
  $collector = New-Object Itenso.TimePeriod.CalendarPeriodCollector($filter, $schedulePeriod, [Itenso.TimePeriod.SeekDirection]::Forward, $calendar)
  $collector.CollectHours()
  $collector.Periods.Add((New-Object Itenso.TimePeriod.TimeRange($start, $end)))
  return $collector
} 
function GetSchedulingPeriods([ Itenso.TimePeriod.CalendarPeriodCollector]$Collector)
{
  #get scheduling hours
  $periodIntersector = New-Object 'Itenso.TimePeriod.TimePeriodIntersector[Itenso.TimePeriod.TimeRange]'
  return $periodIntersector.IntersectPeriods($collector.Periods)
} 


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

#todo Exclusion basé sur Itenso.TimePeriod, quelle classe ?