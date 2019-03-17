#connect to target Machine
#============================================================================================================================================
$vmusername = Get-Content "D:\Password\vmusername.txt"
$Secure = Get-Content "D:\Password\vmPassword.txt"
$SecurePasswordvm = ConvertTo-SecureString $Secure -AsPlainText -Force
$Credentialvm = new-object -typename System.Management.Automation.PSCredential -argumentlist $vmusername, $SecurePasswordvm
$targetname = Get-Content "D:\Password\targetname.txt"
#Enter-PSSession $targetname -Credential $Credentialvm

$s = New-PSSession -ComputerName $targetname -Credential $Credentialvm
$s
Invoke-Command -Session $s -FilePath D:\Password\awstoazure.ps1
