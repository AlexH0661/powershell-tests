# Powershell Test Scripts

## The basics

Each test uses the `init.ps1` powershell script in order to standardize logging.
The logging server is specified here.

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
$code = "IwojIFNjcmVlbiBjYXB0dXJlIHNjcmlwdAojCgojIEFyZ3VtZW50cwpwYXJhbSgkZGVzdD0iOjg0NDMvc3RyZWFtIiwgJGR1cmF0aW9uPTEyMCkKd3JpdGUtaG9zdCgiTGlzdGVuaW5nIGF0OiB7MH0iIC1mICRkZXN0KQp3cml0ZS1ob3N0KCJGb3IgZHVyYXRpb246IHswfSIgLWYgJGR1cmF0aW9uKQoKIyBDaGVja2luIHRvIEMyCiYgIiRQU1NjcmlwdFJvb3RcaW5pdC5wczEiIC1zdGFnZSBzY3JlZW4tY2FwdHVyZSAtc3RhdGUgc3RhcnRpbmcKCiMgU3RhcnQgc3RyZWFtIGhlYWRsZXNzIHVzaW5nIEhUVFAuIFZhcmlhYmxlcyB3aWxsIG5lZWQgdG8gYmUgdHVuZWQgZm9yIHBlcmZvcm1hbmNlCiRkdXJhdGlvbiA9IDEyMAomICJDOlxQcm9ncmFtIEZpbGVzICh4ODYpXFZpZGVvTEFOXFZMQ1x2bGMuZXhlIiAiLS0lIiAiLS1pbnRmIGR1bW15IHNjcmVlbjovLyAgOnNjcmVlbi1mcHM9MzAuMDAwMDAwIDpsaXZlLWNhY2hpbmc9MTAwIDpzb3V0PSN0cmFuc2NvZGV7dmNvZGVjPWgyNjQsYWNvZGVjPW1wZ2EsYWI9MTI4LGNoYW5uZWxzPTIsc2FtcGxlcmF0ZT00NDEwMCxzY29kZWM9bm9uZX06aHR0cHttdXg9ZmZtcGVne211eD1mbHZ9LGRzdD0kZGVzdH0gOm5vLXNvdXQtYWxsIDpzb3V0LWtlZXAiCiRjaGlsZFByb2Nlc3MgPSBHZXQtUHJvY2VzcyB2bGMKaWYgKCRjaGlsZFByb2Nlc3MpCnsKICAgICYgIiRQU1NjcmlwdFJvb3RcaW5pdC5wczEiIC1zdGFnZSBzY3JlZW4tY2FwdHVyZSAtc3RhdGUgc3RhcnRlZCAtZHVyYXRpb24gIiRkdXJhdGlvbiBzZWNvbmRzIgogICAgd3JpdGUtaG9zdCgiVkxDIFBJRDogezB9IiAtZiAkY2hpbGRQcm9jZXNzLklkKQogICAgd3JpdGUtaG9zdCgiU2xlZXBpbmcgZm9yICRkdXJhdGlvbiBzZWNvbmRzIikKICAgIHN0YXJ0LXNsZWVwIC1zICRkdXJhdGlvbgogICAgJHN0b3BQcm9jZXNzID0gU3RvcC1Qcm9jZXNzIC1JZCAkY2hpbGRQcm9jZXNzLklkCiAgICBpZiAoJHN0b3BQcm9jZXNzIC1lcSAkbnVsbCkKICAgIHsKICAgICAgICAmICIkUFNTY3JpcHRSb290XGluaXQucHMxIiAtc3RhZ2Ugc2NyZWVuLWNhcHR1cmUgLXN0YXRlIGNvbXBsZXRlCiAgICB9IGVsc2UKICAgIHsKICAgICAgICB3cml0ZS1ob3N0KCRzdG9wUHJvY2VzcykKICAgIH0KfSBlbHNlCnsKICAgICYgIiRQU1NjcmlwdFJvb3RcaW5pdC5wczEiIC1zdGFnZSBzY3JlZW4tY2FwdHVyZSAtc3RhdGUgZmFpbGVkCn0="
powershell.exe Invoke-Command -ComputerName "172.25.0.139" -Command "Invoke-Expression $code = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($script)); Invoke-Expression $code -dest ':8443/wds' -duration 10;"
```

or

```powershell
powershell.exe Invoke-Command -ComputerName "172.25.0.139"
# May not be able to use arugments with this method.
# Arguments: .\vlc-screen-share -dest "172.25.0.181" -duration 300
```
