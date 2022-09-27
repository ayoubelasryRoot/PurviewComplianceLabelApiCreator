# Create an API for Purview (Compliance Portal) with PowerShell

## Objective
I wanted to create compliance labels in Purview using an API approche. For example the user can create a compliance label by making the below Http Post request.
``` json
{
    "name": "azure 0103",
    "time": 1400,
    "stages": {
        "MultiStageReviewSettings": [
            {
                "StageName": "Stage1",
                "Reviewers": [
                    "asayedl@tds237rdspc.onmicrosoft.com"
                ]
            }
        ]
    }
}
```
## Current Solution
Purview doesn't support such API. 

## My Solution
I create an Azure Function that is HttpTrigger with two secrets **email** and **password** as environement variables which represents the credential for my App User.  
  This App User need to have the neccessary access to the record management role which can be done on the Compliance Portal:
1. Permissions
2. Click on Roles under Microsoft Purview Solutions
3. Search Records Management in Role groups for Microsoft Purview solutions
4. Add your user to the role

## Code
With the following script you can create a Label Policy by providing the name, rentetion time and review stages. Feel free to add your own attribute that you want to send from the API
``` shell
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

```
