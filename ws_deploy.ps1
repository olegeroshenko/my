powershell Set-ExecutionPolicy RemoteSigned
if ((Get-PSSnapin -Name VMWare.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null)
{ 
Add-PSSnapin VMWare.VimAutomation.Core
}


$EsxServer="ctd-vc01.cisco.com"
$EsxUser="cisco\oyeroshe"
$EsxPass="MJ23JORd"

$GuestUser="qadmin"
$GuestPassword="Cisco123"

$Template="Win7-template"

$MachineName="MyMachine"
$Folder="Attack"

$Cluster="PODS"

$IP="10.1.2.12"
$Netmask="255.255.255.0"
$Gateway="10.1.2.1"
$DNS="10.1.2.11"
#$DNS2="10.0.0.14"

#$NameofNetwork="SUT #0 - *SOC -*"

$Domain='POD'
$DomainPassword="Itoly0u!"
$DomainUsername="POD\administrator"


Connect-VIServer -Server $EsxServer -User $EsxUser -Password $EsxPass

$MyHost=Get-Cluster $Cluster|Get-VMHost -state connected|Get-Random

#create new vm 
$Task=New-VM -Name $MachineName -Template $Template -VMHost $MyHost -Location $Folder
Wait-Task -Task $Task

<#$NIC=Get-NetworkAdapter -VM $MachineName
Remove-NetworkAdapter -NetworkAdapter $NIC -Confirm:$false

$Network=Get-VirtualPortGroup -Name $Nameofnetwork

New-NetworkAdapter -vm $machineName -NetworkName $NetWork
#>


$Task=Start-VM -VM $MachineName
Wait-Task -Task $Task
Start-Sleep 90


#set ip, netmask, gateway
$ScriptText="netsh interface ip set address ""Local Area Connection"" static $IP $NetMask $GateWay"
Invoke-VMScript -ScriptText $ScriptText -VM $MachineName -GuestUser $GuestUser -GuestPassword $GuestPassword -ScriptType bat 

#set dns server
$ScriptText="netsh interface ip set dns ""Local Area Connection"" static $DNS"
Invoke-VMScript -ScriptText $ScriptText -VM $MachineName -GuestUser $GuestUser -GuestPassword $GuestPassword -ScriptType bat 

#rename machine name
$ScriptText=@'
$PC=Get-WmiObject -Class Win32_ComputerSystem
$PC.Rename("#MachineName#")
'@
$ScriptText=$ScriptText.Replace('#MachineName#',$MachineName)
Invoke-VMScript -ScriptText $ScriptText -VM $MachineName -GuestUser $GuestUser -GuestPassword $GuestPassword


$ScriptText=@'
ADD-Computer -WorkGroupName MyWorkGroup
'@
Invoke-VMScript -ScriptText $ScriptText -VM $MachineName -GuestUser $GuestUser -GuestPassword $GuestPassword
Restart-VMGuest -VM $MachineName
Start-Sleep 90

#join to domain
$ScriptText=@'
$comp = Get-WmiObject Win32_ComputerSystem
$comp.JoinDomainOrWorkgroup("#Domain#", "#DomainPassword#", "#DomainUsername#", $null, 3)
'@
$ScriptText=$ScriptText.Replace('#Domain#',$Domain).Replace('#DomainPassword#',$DomainPassword).Replace('#DomainUsername#',$DomainUsername)
Invoke-VMScript -ScriptText $ScriptText -VM $MachineName -GuestUser $GuestUser -GuestPassword $GuestPassword
Restart-VMGuest -VM $MachineName
Start-Sleep 90

Disconnect-VIServer -Confirm:$false
