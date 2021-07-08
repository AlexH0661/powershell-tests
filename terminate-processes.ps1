#
# Kill common user processes at random intervals for a set duration
#

# Arguments
param($services="excel,winword,outlook,chrome,msedge", $minDelay=5, $maxDelay=30 , $iterations=10)
write-host("Targeting services: {0}" -f $services)
write-host("For duriation: {0}" -f $duration)

# Checkin to logging server
& "$PSScriptRoot\init.ps1" -stage terminate-services -state starting

$services = $services.Split(",")
$count = 0
while ($count -lt $iterations)
{
    $delay = Get-Random -Minimum $minDelay -Maximum $maxDelay
    $count += 1
    $service = Get-Random -InputObject $services
    & "$PSScriptRoot\init.ps1" -stage terminate-service -state started -comment "{service: $service, delay: $delay seconds, iteration: $count/$iterations}"
    # The reason the sleep statement is at the start is so that a process doesn't die as soon as the script starts off.
    # This will seem more 'random' to the user.
    Start-Sleep -Seconds $delay
    try
    {
        $processObj = Get-Process $service -ErrorVariable getProcError -ErrorAction SilentlyContinue
        $getProcError = $getProcError[0].Exception | Out-String
        Stop-Process -Id $processObj.Id -ErrorVariable stopProcError -ErrorAction SilentlyContinue
        $stopProcError = $stopProcError[0].Exception | Out-String
        if ($stopProcError -ne $null)
        {
            & "$PSScriptRoot\init.ps1" -stage terminate-service -state complete -comment "{service: $service}"
        } else
        {
            write-host($stopProcError)
            $errorMsg = "Get-Process: {0}, Stop-Process: {1}" -f $getProcError, $stopProcError
            & "$PSScriptRoot\init.ps1" -stage terminate-service -state failed -comment $errorMsg
        }
    }
    catch
    {
        $errorMsg = "Get-Process: {0}" -f $getProcError
        & "$PSScriptRoot\init.ps1" -stage terminate-service -state failed -comment $errorMsg
    }
}
