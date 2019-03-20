#connect to Azure New VM Machine and install chrome
#============================================================================================================================================
$vmusername = Get-Content "D:\Password\vmusername.txt"
$Secure = Get-Content "D:\Password\vmPassword.txt"
$SecurePasswordvm = ConvertTo-SecureString $Secure -AsPlainText -Force
$Credentialvm = new-object -typename System.Management.Automation.PSCredential -argumentlist $vmusername, $SecurePasswordvm
$targetname = Get-Content "D:\Password\azurenewip.txt"
#Enter-PSSession $targetname -Credential $Credentialvm

$w = New-PSSession -ComputerName $targetname -Credential $Credentialvm

echo "104.42.169.124    chefserver.qge32fcktqruhfmbsu3nb0f0xg.dx.internal.cloudapp.net" >> C:\Windows\System32\drivers\etc\hosts

#Invoke-Command -Session $w -FilePath D:\Password\install_chrome_azure.ps1
Exit-PSSession

knife bootstrap windows winrm $targetname -x '.\demouser1' -P 'TCS@#1234'  -N Testnode

