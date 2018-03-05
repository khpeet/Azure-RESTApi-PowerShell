# Get root path of this script.
$CurrentDirPath = Split-Path $MyInvocation.MyCommand.Path

# Import Utility Module
Import-Module -Name "$CurrentDirPath\Module\Utility" -Verbose -DisableNameChecking

# Variables
$TenantId = ""
$ClientId = ""
$ClientSecret = ""
$Resource = "https://management.core.windows.net/"
$ApiUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$SubscriptionId = ""

# Functions
Function New-AccessToken
{
    $Response = Get-AccessToken -GrantType client_credentials -ClientId $ClientId `
            -ClientSecret $ClientSecret -Resource $Resource -ApiUri $ApiUri
    $Token | ConvertTo-Json | Out-File "token.json" -Force
    Write-Output "New token generated."
    return $Response
}

# Get Access Token
if (!(Test-Path -Path "$CurrentDirPath\token.json"))
{
    Write-Output "Getting new token."
    $Token = New-AccessToken
}
else 
{
    $Token = Get-Content -Raw -Path "$CurrentDirPath\token.json" | ConvertFrom-Json
    # Check if token is expired.
    $epoch = [datetime]"1/1/1970"
    $ExpiresOn = $epoch.AddSeconds($Token.expires_on)
    if ($ExpiresOn -lt [datetime]::Now)
    {
        Write-Output "Token has expired and will be reviewed."
        $Token = New-AccessToken
    }
    else
    {
        Write-Output "Token is valid and ready to be used."
    }
}
# Get Azure Resource Groups
$ResourceGroupApiUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups?api-version=2017-05-10"

$Headers = @{}

$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")

$ResourceGroups = Invoke-RestMethod -Method Get -Uri $ResourceGroupApiUri -Headers $Headers

Write-Output $ResourceGroups