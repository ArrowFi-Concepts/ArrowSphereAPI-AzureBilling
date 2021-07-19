using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$body = "This HTTP triggered function executed successfully."

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
##My Code
#Teams Webhook URL
$TeamsWebHookURL = 'CHANGE-TO-YOUR-WEB-HOOK-URL'

foreach($row in $inputTable){
    if($Request.Body.ref -eq $row.RowKey){
        $message += "Customer Name: " + $row.CustomerName + "<br>"
        $message += "Azure License: " + $row.License + "<br>"
        $message += "Azure Consumed: " + $row.Consumed + "<br>"
        $message += "Link to Details: " + $Request.Body.link + "<br>"
        $message += "Link Expiration: " + $Request.Body.linkExpirationDate + "<br>"
    }

}
#Send Message
$URI=$TeamsWebHookURL
$myObject = [PSCustomObject]@{
    '@context' = 'http://schema.org/extensions'
    '@type'    = 'MessageCard'
    themeColor = '0072C6'
    title      = 'ArrowSphere Automation'
    text       = $message
}
$myJSON = $myObject | ConvertTo-Json
#Write-Host $myJSON
$response = Invoke-RestMethod -Method 'Post' -Uri $URI -Headers $headers -Body $myJSON
