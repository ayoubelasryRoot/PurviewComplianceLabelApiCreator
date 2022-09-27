using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$label = $Request.Body.Name
$time = $Request.Body.Time
$stages = $Request.Body.stages | ConvertTo-Json -Compress -Depth 99

$isconnected = (Get-PSSession).Count -gt 0
if ($isconnected -eq $false) {
    $User = $ENV:email
    $password = ConvertTo-SecureString -String $ENV:password -AsPlainText -Force
    $UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $password
    Connect-IPPSSession -Credential $UserCredential
}

$body = "The label was created"
$status = [HttpStatusCode]::OK

Try {
    New-ComplianceTag -Name $label -RetentionAction Keep -RetentionDuration $time -RetentionType CreationAgeInDays -IsRecordLabel $true -MultiStageReviewProperty  $stages
}
Catch {
    $body = "Error while creating label. Please make sure the name doesn't exist."
    $status = [HttpStatusCode]::BadRequest
}
Finally {
    Disconnect-ExchangeOnline -Confirm:$false
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body = $body
    })
}
