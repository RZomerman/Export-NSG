
#Functions
Function RunLog-Command([string]$Description, [ScriptBlock]$Command, [string]$LogFile, [string]$Color){
    If (!($Color)) {$Color="Yellow"}
    Try{
        $Output = $Description+'  ... '
        Write-Host $Output -ForegroundColor $Color
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        $Result = Invoke-Command -ScriptBlock $Command 
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $Output = 'Error '+$ErrorMessage
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        $Result = ""
    }
    Finally {
        if ($ErrorMessage -eq $null) {
            $Output = "[Completed]  $Description  ... "} else {$Output = "[Failed]  $Description  ... "
        }
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
    }
    Return $Result
}


Function WriteLog([string]$Description, [string]$LogFile, [string]$Color){
    If (!($Color)) {$Color="Yellow"}
    Try{
        $Output = $Description+'  ... '
        Write-Host $Output -ForegroundColor $Color
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        #$Result = Invoke-Command -ScriptBlock $Command 
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $Output = 'Error '+$ErrorMessage
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        $Result = ""
    }
    Finally {
        if ($ErrorMessage -eq $null) {
            $Output = "[Completed]  $Description  ... "} else {$Output = "[Failed]  $Description  ... "
        }
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
    }
    Return $Result
}
    
    
Function LogintoAzure(){
    $Error_WrongCredentials = $True
    $AzureAccount = $null
    while ($Error_WrongCredentials) {
        Try {
            Write-Host "Info : Please, Enter the credentials of an Admin account of Azure" -ForegroundColor Cyan
            #$AzureCredentials = Get-Credential -Message "Please, Enter the credentials of an Admin account of your subscription"      
            $AzureAccount = Add-AzAccount

            if ($AzureAccount.Context.Tenant -eq $null) 
                        {
                        $Error_WrongCredentials = $True
                        $Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
                        Write-Host $Output -BackgroundColor Red -ForegroundColor Yellow
                        } 
                        else
                        {$Error_WrongCredentials = $false ; return $AzureAccount}
            }

        Catch {
            $Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
            Write-Host $Output -BackgroundColor Red -ForegroundColor Yellow
            Generate-LogVerbose -Output $logFile -Message  $Output 
            }

        Finally {
                }
    }
    return $AzureAccount

}
    
Function Select-Subscription ($SubscriptionName, $AzureAccount){
            Select-AzSubscription -SubscriptionName $SubscriptionName -TenantId $AzureAccount.Context.Tenant.TenantId
}

Function AreJobsRunning ($LogFile){
    $Description = "  -Validating existing jobs"
    WriteLog -Description $Description -LogFile $LogFile -Color 'Yellow'
    Write-host "     " -NoNewline
    [array]$Jobs=Get-Job -ErrorAction SilentlyContinue
    Do {
        write-host "." -NoNewline -ForegroundColor Red
        Start-Sleep 5
        [array]$Jobs=Get-Job -ErrorAction SilentlyContinue
    }
    While ($Jobs.State -contains "Running")
    write-host "." -ForegroundColor Green
    #clearing jobs
    $void=get-job | remove-job
}
Function MonitorJobs ($OperationName, $LogFile){
    Start-sleep 3
    $Running=$true

    [array]$Jobs=Get-Job
    Write-host "     " -NoNewline
    Do {
        ForEach ($Job in $Jobs) {
            If ($Job.State -eq 'Completed') {
                $JobID=$job.id
                $Description = " job $JobID done"
                WriteLog -Description $Description -LogFile $LogFile -Color 'Green'

                $void=Get-Job -id $Job.id | remove-job
                Write-host "     " -NoNewline
            }elseif ($Job.state -eq 'Failed') {
                #Need to remove VM from return set
                #Long Running Operation for 'Remove-AzVM' on resource 'BLABLA'
                $JobID=$job.Name
                $Description = " job $JobID Failed " 
                WriteLog -Description $Description -LogFile $LogFile -Color 'Red'
                If ($job.output){
                    ForEach ($line in $job.output) {
                        WriteLog -Description $line -LogFile $LogFile -Color 'Red'
                    }
                }
                #write-host $job.Output
                $void=Get-Job -id $Job.id | remove-job
                Write-host "     " -NoNewline
            }elseif ($Job.state -eq 'Running'){
                #do nothing - job still running
                Write-host . -NoNewline -ForegroundColor Yellow
                Start-Sleep 2
                
            }else{
                $status=Get-Job
                write-host $status
                Write-host "something went wrong - or starting"
                Write-host . -NoNewline -ForegroundColor Red
                Start-Sleep 2
            }
        }
        [array]$Jobs=Get-Job
    }
    While ($Jobs.count -ne 0) {}

}

Function LoadModule{
    param (
        [parameter(Mandatory = $true)][string] $name
    )
    $retVal = $true
    if (!(Get-Module -Name $name)){
        $retVal = Get-Module -ListAvailable | where { $_.Name -eq $name }
        if ($retVal) {
            try {
                Import-Module $name -ErrorAction SilentlyContinue
            }
            catch {
                $retVal = $false
            }
        }
    }
    return $retVal
}

Function GetNSGDetails {
    param(
        [Parameter(Mandatory=$true)][string]$NsgName
        #[Parameter(Mandatory=$true)][string]$CsvPathToSave
    )

    $nsg = Get-AzNetworkSecurityGroup -Name $NsgName | Get-AzNetworkSecurityRuleConfig

    $NsgRuleSet = @()

    foreach ($rule in $nsg) {

        $ASGGroupNameSource = $rule.SourceApplicationSecurityGroups.id -replace '.*/'
        $ASGGroupNameDestination = $rule.DestinationApplicationSecurityGroups.id -replace '.*/'
        
        $NsgRuleSet += (

            [pscustomobject]@{ 
                            RuleName =  $rule.Name; 
                            Priority = $rule.Priority; 
                            DestinationPortRange = "$($rule.DestinationPortRange -join ",")"; 
                            Protocol = $rule.Protocol;
                            SourceAddressPrefix = "$($rule.SourceAddressPrefix -join ", ")";
                            SourceApplicationSecurityGroups = $ASGGroupNameSource;
                            DestinationAddressPrefix = "$($rule.DestinationAddressPrefix -join ",")";
                            DestinationApplicationSecurityGroups = $ASGGroupNameDestination;
                            Direction = $rule.Direction;
                            Access = $rule.Access;
                            }

        )
    } 
    return $NsgRuleSet
}