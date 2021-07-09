#
# init.ps1 is a common Powershell script that is used to gather initial details
#

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
