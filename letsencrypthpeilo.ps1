Import-Module -Name HPEiLOCmdlets

$hpIloHost = "<ILO HOST NAME>"
$hpIloUsername="<ADMIN USER>"
$hpIloPassword="<ADMIN PASSWORD>"

$certificate = @{
    Country = "<COUNTRY>";
    State = "<STATE>";
    City = "<CITY>";
    Organization = "<ORGANIZATION>";
    OrgUnit = "<ORGUNIT>";
};

if ($false){ # Soon I'll add the prompt
if (!$hpIloHost -and !$hpIloIp){
    $hpIloHost = Read-Host -Prompt "HP iLO Host:"
}

if (!$hpIloUsername){
    $hpIloUsername = Read-Host -Prompt "Username:"
}

if (!$hpIloPassword){
    $hpIloPassword = Read-Host -Prompt "Password:" -MaskInput
}
}

$hpIloIp = @(Resolve-DnsName $hpIloHost).IpAddress

Write-Host "Connecting to iLO $hpIloHost ($hpIloIp) as $hpIloUsername"

try {
    $iloConnection = Connect-HPEiLO -Address $hpIloHost -Username $hpIloUsername -Password $hpIloPassword -DisableCertificateAuthentication -Force
    $global:connection = $iloConnection
    Write-Host "Connected $iloConnection"

    Write-Host
    Write-Host "Requesting certificate for $hpIloHost..."
    $iloCertificateRequestOperation = Start-HPEiLOCertificateSigningRequest -Connection $iloConnection `
                                          -Country $certificate.Country `
                                          -State $certificate.State `
                                          -Locality $certificate.City `
                                          -Organization $certificate.Organization `
                                          -OrganizationalUnit $certificate.OrgUnit `
                                          -CommonName $hpIloHost

    $global:certRequest = $iloCertificateRequestOperation

    Write-Host
    Write-Host "Trying to Obtainin CSR..."
    do {
        Start-Sleep 5
        $iloCsr = Get-HPEiLOCertificateSigningRequest -Connection $iloConnection

        if ($iloCsr.CertificateSigningRequest.Length -gt 0){
            Write-Host "Obtained CSR for $($iloCsr.Hostname)"
            Write-Host $iloCsr.CertificateSigningRequest
            Out-File -FilePath "$($iloCsr.Hostname).csr" -Encoding utf8 -Force -InputObject $iloCsr.CertificateSigningRequest
        }

        
    } until ((Test-Path "$($iloCsr.Hostname).csr"))
    
    Write-Host
    Write-Host "Written CSR into $($iloCsr.Hostname).csr"

    Write-Host "Now run the following Certbot command. This script will wait until $hpIloHost.crt is available"
    Write-Host
    Write-Host
    Write-Host "certbot certonly --csr .\$hpIloHost.csr -d $hpIloHost --manual --preferred-challenges dns --cert-path $hpIloHost.crt"
    Write-Host
    Write-Host "During Certbot operation, use GoDaddy.ps1 to update DNS"

    while ((!(Test-Path "$hpIloHost.crt"))) {
        Start-Sleep 5
    }

    Write-Host "The certificate file was found! Uploading to HPE iLO"
    Write-Host

    Import-HPEiLOCertificate -Connection $iloConnection `
                             -Certificate (Get-Content -Raw "$hpIloHost.crt", "*.pem")

    Write-Host "Success!!!"
    Write-Host "Now cleaning up the mess"
}
catch {
    Write-Error "Error connecting"
    
    $hpIloIp = $null;
    $hpIloHost = $null;
    $hpIloUsername = $null;
    $hpIloPassword = $null;
}
finally {
    if (Test-Path "$hpIloHost.csr") {
        Remove-Item "$hpIloHost.csr"
    }
    if (Test-Path "$hpIloHost.crt") {
        Remove-Item -Force "$hpIloHost.crt"
    }
    if (Test-Path "*.pem") {
        Remove-Item -Force "*.pem"
    }
}

#$hpIloIp = $null;
#$hpIloHost = $null;
#$hpIloUsername = $null;
#$hpIloPassword = $null;
#66F8TC9F