#
# Disk encryption
#

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