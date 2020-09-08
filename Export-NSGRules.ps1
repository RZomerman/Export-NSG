param(
    [Parameter(Mandatory=$true)][string]$CsvPathToSave,
    [Parameter(Mandatory=$false)][string]$ResourceGroup,
    [Parameter(Mandatory=$false)][string]$Login,
    [Parameter(Mandatory=$False)][boolean]$SelectSubscription
)



#Importing the functions module and primary modules for AAD and AD
If ((Get-Module).name -contains "Export-NSGRules") {
    write-host "reloading module"
    Remove-Module "Export-NSGRules"
}

Import-Module .\Export-NSGRules.psm1

write-host ""
write-host ""

#Cosmetic stuff
write-host ""
write-host ""
write-host "                               _____        __                                " -ForegroundColor Green
write-host "     /\                       |_   _|      / _|                               " -ForegroundColor Yellow
write-host "    /  \    _____   _ _ __ ___  | |  _ __ | |_ _ __ __ _   ___ ___  _ __ ___  " -ForegroundColor Red
write-host "   / /\ \  |_  / | | | '__/ _ \ | | | '_ \|  _| '__/ _' | / __/ _ \| '_ ' _ \ " -ForegroundColor Cyan
write-host "  / ____ \  / /| |_| | | |  __/_| |_| | | | | | | | (_| || (_| (_) | | | | | |" -ForegroundColor DarkCyan
write-host " /_/    \_\/___|\__,_|_|  \___|_____|_| |_|_| |_|  \__,_(_)___\___/|_| |_| |_|" -ForegroundColor Magenta
write-host "     "
write-host " This script dumps all NSG rules in a CSV" -ForegroundColor "Green"

If (!((LoadModule -name Az.Network))){
    Write-host "Az.Network Module was not found - cannot continue - please install the module using install-module AZ"
    Exit
}

##Setting Global Paramaters##
$ErrorActionPreference = "Stop"
$date = Get-Date -UFormat "%Y-%m-%d-%H-%M"
$workfolder = Split-Path $script:MyInvocation.MyCommand.Path
$logFile = $workfolder+'\ExportNSG'+$date+'.log'
write-host ""
write-host ""
Write-Output "Steps will be tracked on the log file : [ $logFile ]" 

##Login to Azure##
If ($Login) {
    $Description = "Connecting to Azure"
    $Command = {LogintoAzure}
    $AzureAccount = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile -Color "Green"
}


##Select the Subscription##
##Login to Azure##
If ($SelectSubscription) {
    $Description = "Selecting the Subscription : $Subscription"
    $Command = {Get-AZSubscription | Out-GridView -PassThru | Select-AZSubscription}
    RunLog-Command -Description $Description -Command $Command -LogFile $LogFile -Color "Green"
}

If ($ResourceGroup) {
    [array]$NSGArray=Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup
}else {
    [array]$NSGArray=Get-AzNetworkSecurityGroup 
}

ForEach ($NSG in $NSGArray){
    write-host ("exporting configuration for: " + $nsg.name)
    $CsvPathToSaveFile = ($CsvPathToSave + "\" + $NSG.Name + ".csv")
    write-host (" to: " + $CsvPathToSaveFile)
    $NSGRules=GetNSGDetails -NsgName $NSG.name
    $NSGRules | export-csv -Path $CsvPathToSaveFile
}
#$1=GetNSGDetails -CsvPathToSave $CsvPathToSave -NsgName AZDATAGW01-nsg

#$1 | export-csv -Path "$($CsvPathToSave).csv"