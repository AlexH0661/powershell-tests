$server = "172.25.0.139"
$cred = Get-Credential

$scriptblock = { & "C:\Users\user\Desktop\scripts\vlc-screen-share.ps1" }
Invoke-Command -ComputerName $server -Credential $cred -ScriptBlock $scriptblock