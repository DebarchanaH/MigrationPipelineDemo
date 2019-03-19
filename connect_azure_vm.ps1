#connect to Azure New VM Machine and install chrome
#============================================================================================================================================
$vmusername = Get-Content "D:\Password\vmusername.txt"
$Secure = Get-Content "D:\Password\vmPassword.txt"
$SecurePasswordvm = ConvertTo-SecureString $Secure -AsPlainText -Force
$Credentialvm = new-object -typename System.Management.Automation.PSCredential -argumentlist $vmusername, $SecurePasswordvm
$targetname = Get-Content "D:\Password\azurenewip.txt"
#Enter-PSSession $targetname -Credential $Credentialvm

$w = New-PSSession -ComputerName $targetname -Credential $Credentialvm
Invoke-Command -Session $w -FilePath D:\Password\install_chrome_azure.ps1

