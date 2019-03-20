$username = Get-Content "D:\Password\username.txt"
$Secure = Get-Content "D:\Password\Password.txt"
$SecurePassword = ConvertTo-SecureString $Secure -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $SecurePassword
Login-AzureRmAccount -Credential $Credential

$RGName = Get-Content "D:\Password\resourcegroupname.txt"
$RG = Get-AzureRmResourceGroup -Name $RGName

$ipName = Get-Content "D:\Password\pip.txt"
$publicIp = Get-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $RG.ResourceGroupName
$publicIp.IpAddress | Out-File -FilePath D:\Password\azurenewip.txt

$newname = Get-Content "D:\Password\azurenewip.txt"
