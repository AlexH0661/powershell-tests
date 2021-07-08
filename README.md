# Powershell Test Scripts

## The basics

Each test uses the `init.ps1` powershell script in order to standardize logging.
The logging server is specified here.

### Misc notes
The disk encryption module requires a GPO to be modified to enable BitLocker full disk encryption if there is no TPM present

## Ensure PSRemoting is enabled on endpoints
```powershell
powershell.exe Enable-PSRemoting
```
```powershell
powershell.exe Set-Item wsman:\localhost\Client\TrustedHosts -Value "172.25.0.139"
```
**Note:**
1. This requires an elevated powershell terminal to run
2. The network profile will also need to be either `domain` or `private`
3. Trusted host might need to be added

## Test Parameters

### Screen Share
```
:param str: dest
    format: :<listening-port>/<endpoint>
    example: :8443/stream
:param int: duration
    format: X (in seconds)
    example: 120
```
### UDP Stream
```
:param str: dest
    format: "<destination-socket>"
    example: "172.25.0.16:1234"
:param str: file
    format: "C:\path\to\file.extension"
    example: "C:\Users\user\Downloads\Rick%20Astley%20-%20Never%20Gonna%20Give%20You%20Up.mp4"
:param int: duration
    format: X (in seconds)
    example: 120
```
### Terminate Processes
```
:param list: services
    format: "item1,item2,item3"
    example: "excel,winword,outlook,chrome,msedge"
:param int: minDelay
    format: x (in seconds)
    example: 20
:param int: maxDelay
    format: X (in seconds)
    example: 120
:param int: iterations
    format: x
    example: 10
```
### Key Logger
```
:param int: duration
    format: X (in seconds)
    example: 120
```

## Run a test
**Note:**
The keylogger test will be flagged by any running antimalware/antivirus.
This is by design and should be accounted for when running that test.

### Screen Share test

#### Using script locally
```powershell
powershell.exe .\vlc-screen-share.ps1  -dest ":8443/wds" -duration 10
```

#### Using script remotely
```powershell
Invoke-Command -ComputerName "172.25.0.139" -Command C:\Users\user\Desktop\vlc-screen-share.ps1 -dest ":8443/wds"
```

or

```powershell
powershell.exe Invoke-Command -ComputerName "172.25.0.139"
# May not be able to use arugments with this method.
# Arguments: .\vlc-screen-share -dest "172.25.0.181" -duration 300
```
