#
# Disk encryption
#

# Checkin to logging server
& "$PSScriptRoot\init.ps1" -stage disk-encryption -state starting

# Check if TPM is present
$is_tpm = Get-WmiObject win32_tpm -Namespace root\cimv2\security\microsofttpm

if ($is_tpm -ne $null)
{
    $tpm = $true
} else
{
 $tpm = $false
}

write-host("TPM Present: {0}" -f $tpm)

& "$PSScriptRoot\init.ps1" -stage disk-encryption -state started -comment "{tpm_present: $tpm}"

$bitlocker_drive = Get-BitLockerVolume -MountPoint C:
$pass = ConvertTo-SecureString "knownPassword" -AsPlainText -Force
if ($bitlocker_drive.VolumeStatus -eq "FullyDecrypted")
{
    Enable-BitLocker -MountPoint C:\ -EncryptionMethod Aes128 -Password $pass -PasswordProtector -SkipHardwareTest -ErrorAction SilentlyContinue -ErrorVariable fde_error
    if ($fde_error){
        & "$PSScriptRoot\init.ps1" -stage disk-encryption -state failed -comment "{error:  $fde_error}"
    }
    else
    {
            & "$PSScriptRoot\init.ps1" -stage disk-encryption -state encrypting -comment "{status: initiated encryption}"
        $encryption_status = Get-BitLockerVolume -MountPoint C:
        while ($encryption_status.EncryptionPercentage -le 100)
        {
            & "$PSScriptRoot\init.ps1" -stage disk-encryption -state encrypting -comment "{status: encrypting, percent_complete: $encryption_status.EncryptionPercentage %}"
            start-sleep -seconds 30
        }
    }
}
else
{
    & "$PSScriptRoot\init.ps1" -stage disk-encryption -state failed -comment "Disk already encrypted. Aborting"
}
