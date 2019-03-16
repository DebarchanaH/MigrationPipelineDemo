#============================================================================================================================================
#Install the AzureRM PowerShell module
#============================================================================================================================================
#$PSVersionTable
#Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
#Install-Module AzureRM –Force -Scope CurrentUser
$PSVersionTable
#============================================================================================================================================
#Signing in to Azure 
#============================================================================================================================================
$username = Get-Content "D:\Password\username.txt"
$Secure = Get-Content "D:\Password\Password.txt"
$SecurePassword = ConvertTo-SecureString $Secure -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $SecurePassword
Login-AzureRmAccount -Credential $Credential

#============================================================================================================================================
#Specify the resource group 
#============================================================================================================================================
$RGName = Get-Content "D:\Password\resourcegroupname.txt"
$RG = Get-AzureRmResourceGroup -Name $RGName
#============================================================================================================================================
Specify the path to the Disk2VHD tool 
#============================================================================================================================================
$Path = Get-Content "D:\Password\disktovhdpath.txt"

#============================================================================================================================================
#Download the Disk2VHD tool
#============================================================================================================================================
$object = New-Object Net.WebClient
$Disk2VHDURL = 'https://download.sysinternals.com/files/Disk2vhd.zip'
$object.DownloadFile($Disk2VHDURL, "$Path\Disk2vhd.zip")

#============================================================================================================================================
#Extract the Disk2VHD tool
#============================================================================================================================================
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
Unzip "$Path\Disk2vhd.zip" $Path
Write-Host "Disk2VHD has been unzipped" 
cd $Path
#============================================================================================================================================
#Specify the path to the converted disks 
#============================================================================================================================================
$VHDPath = Get-Content "D:\Password\awsvhdpath.txt"

#============================================================================================================================================
#Specify the drives 
#============================================================================================================================================
$Drives = Get-Content "D:\Password\drives.txt"

#============================================================================================================================================
#Start the conversion 
#============================================================================================================================================
$cmd  = @"
"$ScriptDir.\disk2vhd.exe" $Drives $VHDPath\$env:computername.vhd /accepteula
"@
& cmd.exe /c $cmd


#============================================================================================================================================
#Specify the Storage Account
#============================================================================================================================================
$SAName = Get-Content "D:\Password\storageaccountname.txt"
$SA = Get-AzureRmStorageAccount -Name $SAName -ResourceGroupName $RG.ResourceGroupName
  
#============================================================================================================================================
#Create a storage container 
#============================================================================================================================================
$SAKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RG.ResourceGroupName  -Name $SA.StorageAccountName) | ? {$_.KeyName -eq "key1"}
$StorageContext = New-AzureStorageContext -StorageAccountName $SAName  -StorageAccountKey $SAKey.Value
$ContainerName = "migartedtoawsvhds"
$ContainerName = New-AzureStorageContainer -Name $ContainerName -Permission Blob  -Context $StorageContext

#============================================================================================================================================
#Upload the VHD 
#============================================================================================================================================
$urlOfUploadedImageVhd = ('https://' + $Sa.StorageAccountName + '.blob.core.windows.net/' + $ContainerName.Name + '/' + $env:computername)                      
$localpath = "$VHDPath\$env:computername.vhd"
Add-AzureRmVhd -ResourceGroupName $RG.ResourceGroupName -Destination $urlOfUploadedImageVhd -LocalFilePath $localpath

#============================================================================================================================================
#Create the OS disk 
#============================================================================================================================================
$osDiskName = $env:computername
$Result = "StandardSSD_LRS"
$osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk (New-AzureRmDiskConfig  -AccountType $Result -Location $RG.Location -CreateOption Import -SourceUri $urlOfUploadedImageVhd) -ResourceGroupName $RG.ResourceGroupName

#============================================================================================================================================
#Specify the virtual network and subnet
#============================================================================================================================================
$vnetName = Get-Content "D:\Password\vnetname.txt"
$subnetName = Get-Content "D:\Password\subnetname.txt"
$VNet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $RG.ResourceGroupName        
$Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $VNet

#============================================================================================================================================
#Create a network security group (NSG)
#============================================================================================================================================
$nsgName = Get-Content "D:\Password\nsgname.txt"
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name RDPRule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG.ResourceGroupName  -Location $RG.Location -Name $nsgName -SecurityRules $rdpRule

#============================================================================================================================================
#Create a network interface card (NIC)
#============================================================================================================================================
$ipName = Get-Content "D:\Password\pip.txt"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $RG.ResourceGroupName -Location $RG.Location -AllocationMethod Static

$nicName = Get-Content "D:\Password\nic.txt"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $RG.ResourceGroupName -Location $RG.Location -SubnetId $Subnet.Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

#============================================================================================================================================
#Select the VM size 
#============================================================================================================================================

$VMSize = Get-Content "D:\Password\vmsize.txt"

#============================================================================================================================================
#Create the VM on Azure
#============================================================================================================================================
$vmConfig = New-AzureRmVMConfig -VMName $env:computername -VMSize $VMSize
$vmName = "$env:computername"
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id
$vm = Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -StorageAccountType $Result -DiskSizeInGB 128 -CreateOption Attach -Windows
New-AzureRmVM -ResourceGroupName $RG.ResourceGroupName -Location $RG.Location -VM $vm

