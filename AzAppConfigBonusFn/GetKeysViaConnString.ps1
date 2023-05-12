<#
- https://stackoverflow.com/questions/62884532/get-key-value-pairs-from-azure-app-configuration-with-powershell
- Keys can contain slash characters, so they need to be URL-encoded using [System.Net.WebUtility]::UrlEncode($Key) when building a $RequestUri.
#>
function Invoke-AppConfigRequest {
    param(
        [Parameter(Mandatory = $true)] [string] $ConnectionString, # 'Endpoint=...;Id=...;Secret=...'
        [Parameter(Mandatory = $true)] [string] $RequestUri, # '/kv?api-version=1.0&key=some-url-encoded-key&label=*'
        [Parameter(Mandatory = $false)] [string] $Method = 'GET', # 'GET', 'POST'
        [Parameter(Mandatory = $false)] [object] $Body = $null      # Accepts [object] to avoid implicit conversion of $null to empty string
    )

    $ConnectionStringValues = $ConnectionString -split ';' | ForEach-Object { $Tokens = $_ -split '=', 2; @{ Key = $Tokens[0]; Value = $Tokens[1] } }
    $Endpoint = ($ConnectionStringValues | Where-Object { $_.Key -eq 'Endpoint' }).Value
    $Credential = ($ConnectionStringValues | Where-Object { $_.Key -eq 'Id' }).Value
    $Secret = ($ConnectionStringValues | Where-Object { $_.Key -eq 'Secret' }).Value
    if ([string]::IsNullOrWhitespace($Endpoint) -or [string]::IsNullOrWhitespace($Credential) -or [string]::IsNullOrWhitespace($Secret)) {
        throw 'Invalid App Configuration connection string'
    }

    $UtcNow = (Get-Date).ToUniversalTime().ToString('ddd, d MMM yyyy HH:mm:ss \G\M\T')
    $EndpointHost = $Endpoint -replace '^https?://(.*)$', '$1'
    $ContentHash = [Convert]::ToBase64String(
        [System.Security.Cryptography.HashAlgorithm]::Create('sha256').ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($(if ($Body -ne $null) { "$Body" } else { '' }))
        )
    )
    $StringToSign = "$Method`n$RequestUri`n$UtcNow;$EndpointHost;$ContentHash"

    $HmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
    $HmacSha256.Key = [Convert]::FromBase64String($Secret)
    $Signature = [Convert]::ToBase64String(
        $HmacSha256.ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($StringToSign)
        )
    )

    $Headers = @{
        'Host'                = $EndpointHost;
        'x-ms-date'           = $UtcNow;
        'x-ms-content-sha256' = $ContentHash;
        'Accept'              = 'application/vnd.microsoft.appconfig.kv+json, application/json, application/problem+json';
        'Authorization'       = "HMAC-SHA256 Credential=$Credential&SignedHeaders=x-ms-date;host;x-ms-content-sha256&Signature=$Signature";
    }

    $Uri = "$Endpoint$RequestUri"
    $Response = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $Headers -Body $Body
    if ($Response.StatusCode -eq 200) {
        [System.Text.Encoding]::UTF8.GetString($Response.Content) | ConvertFrom-Json
    }
}


function Get-AppConfigKeyValue {
    param(
        [Parameter(Mandatory = $true)] [string] $ConnectionString,
        [Parameter(Mandatory = $true)] [string] $Key,
        [Parameter(Mandatory = $false)] [string] $Label = ''
    )

    $UrlEncodedKey = [System.Net.WebUtility]::UrlEncode($Key)
    $UrlEncodedLabel = [System.Net.WebUtility]::UrlEncode($Label)

    # https://learn.microsoft.com/azure/azure-app-configuration/rest-api-key-value
    $Method = 'GET'
    $ApiVersion = '1.0'
    $RequestUri = '/kv'
    #if (![string]::IsNullOrWhitespace($UrlEncodedKey)) {
    #    $RequestUri += "/$UrlEncodedKey"  # Strict key/label matching, no support for wildcards like *.
    #}
    $RequestUri += "?api-version=$ApiVersion"
    if (![string]::IsNullOrWhitespace($UrlEncodedKey)) {
        $RequestUri += "&key=$UrlEncodedKey"  # Key filter, accepts "*" to match all keys.
    }
    if (![string]::IsNullOrWhitespace($UrlEncodedLabel)) {
        $RequestUri += "&label=$UrlEncodedLabel"  # Label filter, accepts "*" to match all labels.
    }
    else {
        $RequestUri += '&label=%00'  # Matches KV without a label.
    }

    (Invoke-AppConfigRequest -ConnectionString $ConnectionString -RequestUri $RequestUri).items
}