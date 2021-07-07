#
# UDP stream script
#

# Define arguments
param($dest="127.0.0.1:1234", $file="C:\Users\user\Downloads\Rick%20Astley%20-%20Never%20Gonna%20Give%20You%20Up.mp4", $duration=120)
write-host("Targeting: {0}" -f $dest)
write-host("Using file: {0}" -f $file)
write-host("For duration: {0}" -f $duration)

# Checkin to C2
& "$PSScriptRoot\init.ps1" -stage udp-stream -state starting

# Start stream headless using UDP. Variables will need to be tuned for performance
& "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" "--%" "--intf dummy file:///$file :file-caching=100 :sout=#transcode{vcodec=h264,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=none}:udp{dst=$dest} :no-sout-all :sout-keep"
$childProcess = Get-Process vlc
if ($childProcess)
{
    & "$PSScriptRoot\init.ps1" -stage udp-stream -state started -duration "$duration seconds"
    write-host("VLC PID: {0}" -f $childProcess.Id)
    write-host("Sleeping for $duration seconds")
    start-sleep -s $duration
    $stopProcess = Stop-Process -Id $childProcess.Id
    if ($stopProcess -eq $null)
    {
        & "$PSScriptRoot\init.ps1" -stage udp-stream -state complete
    } else
    {
        write-host($stopProcess)
    }
} else
{
    & "$PSScriptRoot\init.ps1" -stage udp-stream -state failed
}
