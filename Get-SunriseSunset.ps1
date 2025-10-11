<#
.SYNOPSIS
    Calculates sunrise and sunset times for a given location and date.

.DESCRIPTION
    Uses NOAA Solar Calculator algorithms to compute accurate sunrise and sunset times
    based on latitude, longitude, and date. Accounts for timezone offset.

.PARAMETER Latitude
    Latitude in decimal degrees (positive for North, negative for South)

.PARAMETER Longitude
    Longitude in decimal degrees (positive for East, negative for West)

.PARAMETER Date
    Date for which to calculate sunrise/sunset. Defaults to today.

.PARAMETER TimezoneOffset
    Timezone offset from UTC in hours. Defaults to system timezone.

.EXAMPLE
    Get-SunriseSunset -Latitude 40.7128 -Longitude -74.0060
    Calculates sunrise/sunset for New York City today.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
    Based on NOAA Solar Calculator algorithms
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [double]$Latitude,
    
    [Parameter(Mandatory = $true)]
    [double]$Longitude,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$Date = (Get-Date),
    
    [Parameter(Mandatory = $false)]
    [Nullable[double]]$TimezoneOffset = $null
)

# Get timezone offset if not provided
if ($null -eq $TimezoneOffset) {
    $TimezoneOffset = [TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalHours
}

# Helper function: Convert degrees to radians
function ConvertTo-Radians {
    param([double]$Degrees)
    return $Degrees * [Math]::PI / 180.0
}

# Helper function: Convert radians to degrees
function ConvertTo-Degrees {
    param([double]$Radians)
    return $Radians * 180.0 / [Math]::PI
}

# Calculate Julian Day
function Get-JulianDay {
    param([DateTime]$Date)
    
    $year = $Date.Year
    $month = $Date.Month
    $day = $Date.Day
    
    if ($month -le 2) {
        $year -= 1
        $month += 12
    }
    
    $a = [Math]::Floor($year / 100.0)
    $b = 2 - $a + [Math]::Floor($a / 4.0)
    
    $jd = [Math]::Floor(365.25 * ($year + 4716)) + 
          [Math]::Floor(30.6001 * ($month + 1)) + 
          $day + $b - 1524.5
    
    return $jd
}

# Calculate Julian Century
function Get-JulianCentury {
    param([double]$JulianDay)
    return ($JulianDay - 2451545.0) / 36525.0
}

# Calculate Geometric Mean Longitude of Sun
function Get-GeomMeanLongSun {
    param([double]$JulianCentury)
    $l0 = 280.46646 + $JulianCentury * (36000.76983 + $JulianCentury * 0.0003032)
    while ($l0 -gt 360.0) { $l0 -= 360.0 }
    while ($l0 -lt 0.0) { $l0 += 360.0 }
    return $l0
}

# Calculate Geometric Mean Anomaly of Sun
function Get-GeomMeanAnomalySun {
    param([double]$JulianCentury)
    return 357.52911 + $JulianCentury * (35999.05029 - 0.0001537 * $JulianCentury)
}

# Calculate Eccentricity of Earth's Orbit
function Get-EccentricityEarthOrbit {
    param([double]$JulianCentury)
    return 0.016708634 - $JulianCentury * (0.000042037 + 0.0000001267 * $JulianCentury)
}

# Calculate Sun Equation of Center
function Get-SunEqOfCenter {
    param([double]$JulianCentury)
    $m = Get-GeomMeanAnomalySun -JulianCentury $JulianCentury
    $mrad = ConvertTo-Radians -Degrees $m
    $sinm = [Math]::Sin($mrad)
    $sin2m = [Math]::Sin(2.0 * $mrad)
    $sin3m = [Math]::Sin(3.0 * $mrad)
    
    return $sinm * (1.914602 - $JulianCentury * (0.004817 + 0.000014 * $JulianCentury)) + 
           $sin2m * (0.019993 - 0.000101 * $JulianCentury) + 
           $sin3m * 0.000289
}

# Calculate Sun True Longitude
function Get-SunTrueLong {
    param([double]$JulianCentury)
    $l0 = Get-GeomMeanLongSun -JulianCentury $JulianCentury
    $c = Get-SunEqOfCenter -JulianCentury $JulianCentury
    return $l0 + $c
}

# Calculate Sun Apparent Longitude
function Get-SunApparentLong {
    param([double]$JulianCentury)
    $o = Get-SunTrueLong -JulianCentury $JulianCentury
    $omega = 125.04 - 1934.136 * $JulianCentury
    return $o - 0.00569 - 0.00478 * [Math]::Sin((ConvertTo-Radians -Degrees $omega))
}

# Calculate Mean Obliquity of Ecliptic
function Get-MeanObliquityOfEcliptic {
    param([double]$JulianCentury)
    $seconds = 21.448 - $JulianCentury * (46.8150 + $JulianCentury * (0.00059 - $JulianCentury * 0.001813))
    return 23.0 + (26.0 + ($seconds / 60.0)) / 60.0
}

# Calculate Obliquity Correction
function Get-ObliquityCorrection {
    param([double]$JulianCentury)
    $e0 = Get-MeanObliquityOfEcliptic -JulianCentury $JulianCentury
    $omega = 125.04 - 1934.136 * $JulianCentury
    return $e0 + 0.00256 * [Math]::Cos((ConvertTo-Radians -Degrees $omega))
}

# Calculate Sun Declination
function Get-SunDeclination {
    param([double]$JulianCentury)
    $e = Get-ObliquityCorrection -JulianCentury $JulianCentury
    $lambda = Get-SunApparentLong -JulianCentury $JulianCentury
    $sint = [Math]::Sin((ConvertTo-Radians -Degrees $e)) * [Math]::Sin((ConvertTo-Radians -Degrees $lambda))
    return ConvertTo-Degrees -Radians ([Math]::Asin($sint))
}

# Calculate Equation of Time
function Get-EquationOfTime {
    param([double]$JulianCentury)
    $epsilon = Get-ObliquityCorrection -JulianCentury $JulianCentury
    $l0 = Get-GeomMeanLongSun -JulianCentury $JulianCentury
    $e = Get-EccentricityEarthOrbit -JulianCentury $JulianCentury
    $m = Get-GeomMeanAnomalySun -JulianCentury $JulianCentury
    
    $y = [Math]::Tan((ConvertTo-Radians -Degrees ($epsilon / 2.0)))
    $y = $y * $y
    
    $sin2l0 = [Math]::Sin(2.0 * (ConvertTo-Radians -Degrees $l0))
    $sinm = [Math]::Sin((ConvertTo-Radians -Degrees $m))
    $cos2l0 = [Math]::Cos(2.0 * (ConvertTo-Radians -Degrees $l0))
    $sin4l0 = [Math]::Sin(4.0 * (ConvertTo-Radians -Degrees $l0))
    $sin2m = [Math]::Sin(2.0 * (ConvertTo-Radians -Degrees $m))
    
    $etime = $y * $sin2l0 - 2.0 * $e * $sinm + 4.0 * $e * $y * $sinm * $cos2l0 - 
             0.5 * $y * $y * $sin4l0 - 1.25 * $e * $e * $sin2m
    
    return ConvertTo-Degrees -Radians $etime * 4.0
}

# Calculate Hour Angle for Sunrise/Sunset
function Get-HourAngleSunrise {
    param(
        [double]$Latitude,
        [double]$SolarDec
    )
    
    $latRad = ConvertTo-Radians -Degrees $Latitude
    $sdRad = ConvertTo-Radians -Degrees $SolarDec
    
    $ha = [Math]::Acos(([Math]::Cos((ConvertTo-Radians -Degrees 90.833)) / 
                       ([Math]::Cos($latRad) * [Math]::Cos($sdRad)) - 
                       [Math]::Tan($latRad) * [Math]::Tan($sdRad)))
    
    return ConvertTo-Degrees -Radians $ha
}

# Main calculation
try {
    $jd = Get-JulianDay -Date $Date
    $t = Get-JulianCentury -JulianDay $jd
    
    $eqTime = Get-EquationOfTime -JulianCentury $t
    $solarDec = Get-SunDeclination -JulianCentury $t
    $hourAngle = Get-HourAngleSunrise -Latitude $Latitude -SolarDec $solarDec
    
    # Calculate sunrise and sunset in minutes from midnight UTC
    $sunriseUTC = 720 - 4 * $Longitude - $eqTime - 4 * $hourAngle
    $sunsetUTC = 720 - 4 * $Longitude - $eqTime + 4 * $hourAngle
    
    # Convert to local time
    $sunriseLocal = $sunriseUTC + ($TimezoneOffset * 60)
    $sunsetLocal = $sunsetUTC + ($TimezoneOffset * 60)
    
    # Convert minutes to DateTime
    $sunriseHour = [Math]::Floor($sunriseLocal / 60)
    $sunriseMin = [Math]::Floor($sunriseLocal % 60)
    $sunsetHour = [Math]::Floor($sunsetLocal / 60)
    $sunsetMin = [Math]::Floor($sunsetLocal % 60)
    
    # Handle day overflow
    if ($sunriseHour -ge 24) { $sunriseHour -= 24 }
    if ($sunsetHour -ge 24) { $sunsetHour -= 24 }
    if ($sunriseHour -lt 0) { $sunriseHour += 24 }
    if ($sunsetHour -lt 0) { $sunsetHour += 24 }
    
    $sunrise = Get-Date -Year $Date.Year -Month $Date.Month -Day $Date.Day `
                        -Hour $sunriseHour -Minute $sunriseMin -Second 0
    
    $sunset = Get-Date -Year $Date.Year -Month $Date.Month -Day $Date.Day `
                       -Hour $sunsetHour -Minute $sunsetMin -Second 0
    
    return [PSCustomObject]@{
        Date = $Date.Date
        Sunrise = $sunrise
        Sunset = $sunset
        Latitude = $Latitude
        Longitude = $Longitude
        TimezoneOffset = $TimezoneOffset
    }
}
catch {
    Write-Error "Failed to calculate sunrise/sunset: $_"
    
    # Return default times (7 AM / 7 PM) as fallback
    return [PSCustomObject]@{
        Date = $Date.Date
        Sunrise = Get-Date -Year $Date.Year -Month $Date.Month -Day $Date.Day -Hour 7 -Minute 0 -Second 0
        Sunset = Get-Date -Year $Date.Year -Month $Date.Month -Day $Date.Day -Hour 19 -Minute 0 -Second 0
        Latitude = $Latitude
        Longitude = $Longitude
        TimezoneOffset = $TimezoneOffset
        Error = "Calculation failed, using default times"
    }
}
