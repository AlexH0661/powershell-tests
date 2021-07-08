#
# logging_server.ps1 - Responsible for parsing and logging messages
#

Function Receive-TCPMessage {
    Param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [int] $Port
    ) 
    Process {
        Try {
            write-host("Started!") -ForegroundColor Green
                # Set up endpoint and start listening
                $listener = new-object System.Net.Sockets.TcpListener $port
                $listener.start() 

            while($true) {
                if ($listener.Pending()) {
                    # Wait for an incoming connection 
                    $data = $listener.AcceptTcpClient()
                    # Stream setup
                    $stream = $data.GetStream() 
                    $bytes = New-Object System.Byte[] 1024

                    # Read data from stream and write it to host
                    while (($i = $stream.Read($bytes,0,$bytes.Length)) -ne 0){
                        $EncodedText = New-Object System.Text.ASCIIEncoding
                        $data = $EncodedText.GetString($bytes,0, $i)
                        write-host($data)
                        $data | Out-File -FilePath metrics.txt -Append

                        # Uncomment if you want to output as JSON and hashtables
                        #$jsonObj = $data | ConvertTo-Json | ConvertFrom-Json
                        #write-host($jsonObj)
                        #$jsonObj | Out-File -FilePath metrics.json -Append
                    }
                    $stream.close()
                }
                start-sleep -m 500
                }
            }
        Catch {
            write-host("Receive Message failed with: {0}" -f $Error[0]) -ForegroundColor Red
            $listener.stop()
        }
        Finally {
            write-host("Caught CTRL+C")
            write-host("Stopping") -ForegroundColor Yellow
            $listener.stop()
        }
    }
}

write-host("Starting log server")
Receive-TCPMessage -Port 8443
