#
# c2_server.ps1 - Responsible for parsing messages
#

$socket = New-Object System.Net.Sockets.TcpListener('0.0.0.0', 8443)
if ($socket -eq $null)
{
    exit 1;
}
$socket.Start()
try
{
    $client = $socket.AcceptTcpClient()
    write-host("New connection: {0}" -f $client.Client.RemoteEndPoint)
    $data = ""
    $stream = $client.GetStream()
    $buffer = New-Object System.Byte[] 2048
    $encoding = New-Object System.Text.ASCIIEncoding
    while ($stream.DataAvailable)
    {
        $read = $stream.Read($buffer, 0, 2048)
        write-host -n ($encoding.GetString($buffer,0, $read))
    }
    $stream.Close()
    $client.Close()
}
finally
{
    #$reader.Close()
    $client.Close()
    $socket.Stop()
}