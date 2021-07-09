#
# Kill common user processes at random intervals for a set duration
#

# Arguments
param($services="excel,winword,outlook,chrome,msedge", $minDelay=5, $maxDelay=30 , $iterations=10)
write-host("Targeting services: {0}" -f $services)
write-host("For duriation: {0}" -f $duration)

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
Send-Message -stage terminate-services -state starting

$services = $services.Split(",")
$count = 0
while ($count -lt $iterations)
{
    $delay = Get-Random -Minimum $minDelay -Maximum $maxDelay
    $count += 1
    $service = Get-Random -InputObject $services
    Send-Message -stage terminate-service -state started -comment "{service: $service, delay: $delay seconds, iteration: $count/$iterations}"
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
            Send-Message -stage terminate-service -state complete -comment "{service: $service}"
        } else
        {
            write-host($stopProcError)
            $errorMsg = "Get-Process: {0}, Stop-Process: {1}" -f $getProcError, $stopProcError
            Send-Message -stage terminate-service -state failed -comment $errorMsg
        }
    }
    catch
    {
        $errorMsg = "Get-Process: {0}" -f $getProcError
        Send-Message -stage terminate-service -state failed -comment $errorMsg
    }
}
