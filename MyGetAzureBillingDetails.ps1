# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
##My Code
#Set Access to Azure Table Storage for cleaning (3 months and older entries)
#My table name
$tblName='CHANGE-TO-YOUR-TABLE-NAME'
#My Shared Access Signature #e.g. ?sv=2020-08-04&ss=...... 
$tblSAS='CHANGE-TO-YOUR-SAS'
#Table Storage Account FQDN e.g. https://arrowsphereapi.table.core.windows.net/ 
$storAcc = 'CHANGE-TO-YOUR-StorageAccountName'

#My HTTP Trigger URL
$TriggerURL = 'CHANGE-TO-YOUR-Trigger-URL'

#Set delay if Process function gets overloaded
$throttleSec = 3
#Azure Legacy
#$SKU = 'MS-AZR-0145P'
#Azure Plan !!Change Billing Dates to first of month!!
$SKU = 'DZH318Z0BPS6:0001'
#Set up authentication headers
$headers = @{
'Content-Type' = 'application/json'
'apikey' = 'CHANGE-TO-YOUR-APIKEY'
'Accept' = 'application/json'
}

    #Create billing range
    $curMonth = get-date -Format yyyy-MM
    $lastMonth = $curMonth.split('-')[0] + '-' + "{0:D2}" -f ($curMonth.split('-')[1]-1)
    Write-Host "Using month" $lastMonth -ForegroundColor Yellow

    #Azure legacy
    #$billStartMonth = $curMonth.split('-')[0] + '-' + "{0:D2}" -f ($curMonth.split('-')[1]-2)
    #$billStartDay=$billStartMonth + "-28"
    #$billStopDay=$lastMonth + "-27"

    #Azure Plan
    $billStartMonth = $lastMonth
    $billStartDay=$billStartMonth + "-01"
    $billStopDay=$curMonth + "-01"

    Write-Host "Using range from" $billStartDay "to" $billStopDay

#create array to write out to table storage
[PSObject []] $tableStorageItems = @()

#Get all customers from ArrowSphere
$URI = 'https://xsp.arrow.com/index.php/api/customers'
try{
    $myCustomers = Invoke-RestMethod -Method 'Get' -Uri $URI -Headers $headers
} catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
}

#Loop all customers
foreach($customer in $myCustomers.data.customers){
    #Find customer with Azure licenses
    $custREF = $customer.Reference
    $URI = 'https://xsp.arrow.com/index.php/api/customers/'+$custREF+'/licenses?sku=' + $SKU
    try{
        $azureLicenses = Invoke-RestMethod -Method 'Get' -Uri $URI -Headers $headers
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
    }
    if($azureLicenses.data.licenses -ne ""){
        $customerName = $customer.CompanyName
        Write-Host "Customer Name:" $customerName -ForegroundColor Yellow
        Write-Host "XSP Reference:" $custREF -ForegroundColor Yellow
        #request billing details for each Azure license
        foreach($azLic in $azureLicenses.data.licenses){
            
            Write-Host "Azure License Id:" $azLic.license_id
            #create request body
            $jsonObject = [PSCustomObject]@{
                customer     = $custREF
                licenseRef   = $azLic.license_id
                dateStart    = $billStartDay
                dateEnd      = $billStopDay
                columns      = @('Usage Start date','Meter Category','Meter Sub-Category','Region','Resource Name','Subscription Friendly Name','Customer Xsp Ref','Customer Name','Vendor Name','Vendor Billing Start Date','Vendor Billing End Date','Vendor Ressource SKU','Vendor Product Name','Vendor Meter Category','Vendor Meter Sub-Category','Resource Group','Name','Cost Center','Project','Application','Environment','Custom Tag','UOM','Level Chargeable Quantity','Country currency code','Country reseller unit','Country reseller total','Country customer unit','Country customer total')
                callbackURL  = $TriggerURL
                }
            $jsonBody = $jsonObject | ConvertTo-Json
            $URI = 'https://xsp.arrow.com/index.php/api/consumption/downloadRequest'
            try{
                $billingRequestReference = Invoke-RestMethod -Method 'Post' -Uri $URI -Headers $headers -Body $jsonBody
            } catch {
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
            }
            Write-Host "Sleeping for" $throttleSec "seconds..."
            Start-Sleep -seconds $throttleSec
            $billingRef = $billingRequestReference.ref
            Write-host "Billign Request Reference:" $billingRef
            
            #get billing period consumption
            $URI = 'https://xsp.arrow.com/index.php/api/consumption/license/' + $azLic.license_id + '/monthly?billingMonthStart=' + $lastMonth
            try{
                $azureConsumptionTotal = Invoke-RestMethod -Method 'Get' -Uri $URI -Headers $headers
            } catch {
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
            }
            foreach($billingData in $azureConsumptionTotal.data.customer.dataProvider){
                if(($billStartDay + " to " + $billStopDay) -eq $billingData.billingPeriod){
                    $Consumed = $billingData.consumed
                    Write-Host "Total consumption:" $billingData.month $Consumed
                }
            }
        ##Write to referense table
        if($billingRequestReference.ref -eq $null){
            $billingRef = -join ((65..90) + (97..122) | Get-Random -Count 64 | % {[char]$_})
        }
        if($Consumed -eq $null){
            $Consumed = 0
        }
        $tableStorageItems += [PSObject]@{
            PartitionKey = "p1"
            RowKey = $billingRef
            Customer = $custREF
            CustomerName = $customerName
            License = $azLic.license_id
            Consumed = $Consumed
        }
        ## 
        #reset values
        $azureConsumptionTotal = $null
        $billingData = $null
        $billingRequestReference = $null
        $Consumed = $null
        }
    }
}

#cleanup Table storage over 90 days old entries
$headers = @{
'Content-Type' = 'application/json'
'Accept' = 'application/json'
}
$myCleanupDate = [DateTime]::UtcNow | get-date
$myCleanupDate = $myCleanupDate.AddDays(-90)
$myDateString = "'" + ($myCleanupDate.ToString("yyyy-MM-ddTHH:mm:ssZ")) +"'"
$myDateString = $myDateString.Replace('.',':')

$URI = $storAcc + $tblName + '()' + $tblSAS + '&$filter=Timestamp%20lt%20datetime'+ $myDateString

$tablerows = Invoke-RestMethod -Method 'Get' -Uri $URI -Headers $headers

foreach($row in $tablerows.value){
    $GMTTime=(Get-Date).ToUniversalTime().toString('R')
    $headers = @{
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
    'x-ms-date' = $GMTTime
    'If-Match' = '*'
    }
    $URI = $storAcc + $tblName + "(PartitionKey='" + $row.PartitionKey + "', RowKey='" + $row.RowKey +"')" + $tblSAS
    write-host $URI
    $resp = Invoke-RestMethod -Method 'Delete' -Uri $URI -Headers $headers
}

#write to table storage
$tableJSON = $tableStorageItems | Convertto-Json
Push-OutputBinding -name outputToTable -value $tableJSON
Write-Host $tableJSON