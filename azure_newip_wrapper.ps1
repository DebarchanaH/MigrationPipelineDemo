#connect to target Machine
#============================================================================================================================================
$vmusername = Get-Content "D:\Password\vmusername.txt"
$Secure = Get-Content "D:\Password\vmPassword.txt"
$SecurePasswordvm = ConvertTo-SecureString $Secure -AsPlainText -Force
$Credentialvm = new-object -typename System.Management.Automation.PSCredential -argumentlist $vmusername, $SecurePasswordvm
$targetname = Get-Content "D:\Password\targetname.txt"
#Enter-PSSession $targetname -Credential $Credentialvm

$g = New-PSSession -ComputerName $targetname -Credential $Credentialvm
$g
Invoke-Command -Session $g -FilePath D:\Password\ip_of_new_vm.ps1
