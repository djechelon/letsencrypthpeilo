$goDaddyApi="<APIKEY>"
$goDaddySecret="<APISECRET>"
$hpIloHost = "<ILO HOST>"

$dnsChallenge = "<REPLACE DNS CHALLENGE FROM CERTBOT>"

$domainSegments = $hpIloHost.Split('.')
$domainSecondPart = "$($domainSegments[$domainSegments.Length-2]).$($domainSegments[$domainSegments.Length-1])"
$domainFirstPart = "";
for ($i=0; $i -lt $domainSegments.Length-2; $i++){
    $domainFirstPart += $domainSegments[$i];
    if ($i -ne $domainSegments.Length-3){
        $domainFirstPart+="."
    }
}



$goDaddyDnsBody=@(
   @{
        "data"= $dnsChallenge;
        "port"= 1;
        "priority"= 0;
        "ttl"= 600;
        "weight"= 0    
    }
)

Write-Host "Calling GoDaddy!"
#Write-Host "Calling https://api.godaddy.com/v1/domains/$domainSecondPart/records/TXT/_acme-challenge.$domainFirstPart"
Write-Host ($goDaddyDnsBody |ConvertTo-Json -AsArray)
Invoke-RestMethod -Method Put -Uri "https://api.godaddy.com/v1/domains/$domainSecondPart/records/TXT/_acme-challenge.$domainFirstPart" `
                  -Headers @{"Authorization"= "sso-key $($goDaddyApi):$goDaddySecret"} `
                  -ContentType "application/json" `
                  -Body ($goDaddyDnsBody | ConvertTo-Json -AsArray)

Write-Host "Success!"