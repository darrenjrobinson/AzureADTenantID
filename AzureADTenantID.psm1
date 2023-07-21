$CommandsToExport = @()

function Get-AzureADTenantId {
    <#
    .SYNOPSIS
        Lookup Azure AD OIDC AuthZ Endpoint using Domain Name and return the TenantID.

    .DESCRIPTION
        Lookup the OIDC Well-Known AuthZ endpoint using a domain name. If it exists return the TenantID. 
        
    .EXAMPLE
        Get-AzureADTenantId -domain 'microsoft.com'
        Get-EntraIDTenantId -domain 'microsoft.com'
        Retrives the tenant ID for the domain name microsoft.com.

    .EXAMPLE
        'microsoft.com' | Get-AzureADTenantId  
        'microsoft.com' | Get-EntraIDTenantId  
        Retrives the tenant ID for the domain name microsoft.com.
    #>

    [CmdletBinding()]
    [alias("Get-EntraIDTenantId")]
    param(
        # Tenant domain name to lookup and if it exists return the ID for
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$domain
    )

    try {
        Write-Verbose "Looking up the tenant ID for Domain: '$($domain)'"
        $result = $null 
        $result = Invoke-RestMethod -Method Get "https://login.microsoftonline.com/$($domain)/v2.0/.well-known/openid-configuration" -ErrorAction SilentlyContinue
        $tenantID = ($result.authorization_endpoint.split("/"))[3]

        Write-Verbose "TenantID for '$($domain)': '$($tenantID)'"
        return $tenantID
    } 
    catch { 
        Write-Warning "'$($domain)' not found" 
    } 
}   

$CommandsToExport += 'Get-AzureADTenantId'

function Get-AzureADCustomDomains {
    <#
    .SYNOPSIS
        Query ExchangeOnline for Registered Domains.

    .DESCRIPTION
        Query EXO using AutoDiscover to get a list of configured domain names
        
    .EXAMPLE
        Get-AzureADCustomDomains -domain 'microsoft.com'
        Get-EntraIDCustomDomains -domain 'microsoft.com'
        Retrives a list of custom domains for an EXO Org.

    .EXAMPLE
        Get-AzureADCustomDomains -domain 'microsoft.com' -GCCH
        Get-EntraIDCustomDomains -domain 'microsoft.com' -GCCH
        Retrives a list of custom domains for an EXO Org.

    .EXAMPLE
        'microsoft.com' | Get-AzureADCustomDomains  
        Retrives a list of custom domains for an EXO Org.
    #>

    [cmdletbinding()]
    [alias("Get-EntraIDCustomDomains")]
    Param(
        # EXO Org domain name to lookup and return any associated domain names
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$domain,
        # EXO Org in GCC-H
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [switch]$GCCH = $false
    )

    Try {
        # Create the body
        if ($GCCH) {
            $autoDiscoverURI = "https://autodiscover-s.office365.us/autodiscover/autodiscover.svc"
        }
        else {
            $autoDiscoverURI = "https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc"
        }
        
        $query = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:exm="http://schemas.microsoft.com/exchange/services/2006/messages" xmlns:ext="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<soap:Header>
    <a:Action soap:mustUnderstand="1">http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetFederationInformation</a:Action>
    <a:To soap:mustUnderstand="1">https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc</a:To>
    <a:ReplyTo>
        <a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address>
    </a:ReplyTo>
</soap:Header>
<soap:Body>
    <GetFederationInformationRequestMessage xmlns="http://schemas.microsoft.com/exchange/2010/Autodiscover">
        <Request>
            <Domain>$domain</Domain>
        </Request>
    </GetFederationInformationRequestMessage>
</soap:Body>
</soap:Envelope>
"@

        $headers = @{
            "Content-Type" = "text/xml; charset=utf-8"
            "SOAPAction"   = '"http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetFederationInformation"'
            "User-Agent"   = "AutodiscoverClient"
        }
        $response = Invoke-RestMethod -UseBasicParsing -Method Post -uri $autoDiscoverURI -Body $query -Headers $headers
        $response.Envelope.body.GetFederationInformationResponseMessage.response.Domains.Domain | Sort-Object
    }
    catch {
        if ($GCCH) {
            Write-Warning "'$($domain)' not found in GCC-H. Maybe check the WW Cloud by ommitting the -GCCH switch." 
        }
        else {
            Write-Warning "'$($domain)' not found in the WW Cloud. Maybe check GCC-H by including the -GCCH switch. e.g Get-AzureADCustomDomains -domain '$($domain)' -GCCH" 
        }
    }
}

$CommandsToExport += 'Get-AzureADCustomDomains'

# SIG # Begin signature block
# MIIoKQYJKoZIhvcNAQcCoIIoGjCCKBYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA39jLL0Z9QJFl3
# vKa44hjkzQTOHgtXQ0skHkzT1XJQKqCCISwwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# sDCCBJigAwIBAgIQCK1AsmDSnEyfXs2pvZOu2TANBgkqhkiG9w0BAQwFADBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# HhcNMjEwNDI5MDAwMDAwWhcNMzYwNDI4MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1bQvQtAorXi3XdU5WRuxiEL1M4zr
# PYGXcMW7xIUmMJ+kjmjYXPXrNCQH4UtP03hD9BfXHtr50tVnGlJPDqFX/IiZwZHM
# gQM+TXAkZLON4gh9NH1MgFcSa0OamfLFOx/y78tHWhOmTLMBICXzENOLsvsI8Irg
# nQnAZaf6mIBJNYc9URnokCF4RS6hnyzhGMIazMXuk0lwQjKP+8bqHPNlaJGiTUyC
# EUhSaN4QvRRXXegYE2XFf7JPhSxIpFaENdb5LpyqABXRN/4aBpTCfMjqGzLmysL0
# p6MDDnSlrzm2q2AS4+jWufcx4dyt5Big2MEjR0ezoQ9uo6ttmAaDG7dqZy3SvUQa
# khCBj7A7CdfHmzJawv9qYFSLScGT7eG0XOBv6yb5jNWy+TgQ5urOkfW+0/tvk2E0
# XLyTRSiDNipmKF+wc86LJiUGsoPUXPYVGUztYuBeM/Lo6OwKp7ADK5GyNnm+960I
# HnWmZcy740hQ83eRGv7bUKJGyGFYmPV8AhY8gyitOYbs1LcNU9D4R+Z1MI3sMJN2
# FKZbS110YU0/EpF23r9Yy3IQKUHw1cVtJnZoEUETWJrcJisB9IlNWdt4z4FKPkBH
# X8mBUHOFECMhWWCKZFTBzCEa6DgZfGYczXg4RTCZT/9jT0y7qg0IU0F8WD1Hs/q2
# 7IwyCQLMbDwMVhECAwEAAaOCAVkwggFVMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYD
# VR0OBBYEFGg34Ou2O/hfEYb7/mF7CIhl9E5CMB8GA1UdIwQYMBaAFOzX44LScV1k
# TN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# AzB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmww
# HAYDVR0gBBUwEzAHBgVngQwBAzAIBgZngQwBBAEwDQYJKoZIhvcNAQEMBQADggIB
# ADojRD2NCHbuj7w6mdNW4AIapfhINPMstuZ0ZveUcrEAyq9sMCcTEp6QRJ9L/Z6j
# fCbVN7w6XUhtldU/SfQnuxaBRVD9nL22heB2fjdxyyL3WqqQz/WTauPrINHVUHmI
# moqKwba9oUgYftzYgBoRGRjNYZmBVvbJ43bnxOQbX0P4PpT/djk9ntSZz0rdKOtf
# JqGVWEjVGv7XJz/9kNF2ht0csGBc8w2o7uCJob054ThO2m67Np375SFTWsPK6Wrx
# oj7bQ7gzyE84FJKZ9d3OVG3ZXQIUH0AzfAPilbLCIXVzUstG2MQ0HKKlS43Nb3Y3
# LIU/Gs4m6Ri+kAewQ3+ViCCCcPDMyu/9KTVcH4k4Vfc3iosJocsL6TEa/y4ZXDlx
# 4b6cpwoG1iZnt5LmTl/eeqxJzy6kdJKt2zyknIYf48FWGysj/4+16oh7cGvmoLr9
# Oj9FpsToFpFSi0HASIRLlk2rREDjjfAVKM7t8RhWByovEMQMCGQ8M4+uKIw8y4+I
# Cw2/O/TOHnuO77Xry7fwdxPm5yg/rBKupS8ibEH5glwVZsxsDsrFhsP2JjMMB0ug
# 0wcCampAMEhLNKhRILutG4UI4lkNbcoFUCvqShyepf2gpx8GdOfy1lKQ/a+FSCH5
# Vzu0nAPthkX0tGFuv2jiJmCG6sivqf6UHedjGzqGVnhOMIIGwDCCBKigAwIBAgIQ
# DE1pckuU+jwqSj0pB4A9WjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIyMDkyMTAw
# MDAwMFoXDTMzMTEyMTIzNTk1OVowRjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERp
# Z2lDZXJ0MSQwIgYDVQQDExtEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMiAtIDIwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDP7KUmOsap8mu7jcENmtuh6BSF
# dDMaJqzQHFUeHjZtvJJVDGH0nQl3PRWWCC9rZKT9BoMW15GSOBwxApb7crGXOlWv
# M+xhiummKNuQY1y9iVPgOi2Mh0KuJqTku3h4uXoW4VbGwLpkU7sqFudQSLuIaQyI
# xvG+4C99O7HKU41Agx7ny3JJKB5MgB6FVueF7fJhvKo6B332q27lZt3iXPUv7Y3U
# TZWEaOOAy2p50dIQkUYp6z4m8rSMzUy5Zsi7qlA4DeWMlF0ZWr/1e0BubxaompyV
# R4aFeT4MXmaMGgokvpyq0py2909ueMQoP6McD1AGN7oI2TWmtR7aeFgdOej4TJEQ
# ln5N4d3CraV++C0bH+wrRhijGfY59/XBT3EuiQMRoku7mL/6T+R7Nu8GRORV/zbq
# 5Xwx5/PCUsTmFntafqUlc9vAapkhLWPlWfVNL5AfJ7fSqxTlOGaHUQhr+1NDOdBk
# +lbP4PQK5hRtZHi7mP2Uw3Mh8y/CLiDXgazT8QfU4b3ZXUtuMZQpi+ZBpGWUwFjl
# 5S4pkKa3YWT62SBsGFFguqaBDwklU/G/O+mrBw5qBzliGcnWhX8T2Y15z2LF7OF7
# ucxnEweawXjtxojIsG4yeccLWYONxu71LHx7jstkifGxxLjnU15fVdJ9GSlZA076
# XepFcxyEftfO4tQ6dwIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1Ud
# EwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZn
# gQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCP
# nshvMB0GA1UdDgQWBBRiit7QYfyPMRTtlwvNPSqUFN9SnDBaBgNVHR8EUzBRME+g
# TaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRS
# U0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCB
# gDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUF
# BzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUA
# A4ICAQBVqioa80bzeFc3MPx140/WhSPx/PmVOZsl5vdyipjDd9Rk/BX7NsJJUSx4
# iGNVCUY5APxp1MqbKfujP8DJAJsTHbCYidx48s18hc1Tna9i4mFmoxQqRYdKmEIr
# UPwbtZ4IMAn65C3XCYl5+QnmiM59G7hqopvBU2AJ6KO4ndetHxy47JhB8PYOgPvk
# /9+dEKfrALpfSo8aOlK06r8JSRU1NlmaD1TSsht/fl4JrXZUinRtytIFZyt26/+Y
# siaVOBmIRBTlClmia+ciPkQh0j8cwJvtfEiy2JIMkU88ZpSvXQJT657inuTTH4YB
# ZJwAwuladHUNPeF5iL8cAZfJGSOA1zZaX5YWsWMMxkZAO85dNdRZPkOaGK7DycvD
# +5sTX2q1x+DzBcNZ3ydiK95ByVO5/zQQZ/YmMph7/lxClIGUgp2sCovGSxVK05iQ
# RWAzgOAj3vgDpPZFR+XOuANCR+hBNnF3rf2i6Jd0Ti7aHh2MWsgemtXC8MYiqE+b
# vdgcmlHEL5r2X6cnl7qWLoVXwGDneFZ/au/ClZpLEQLIgpzJGgV8unG1TnqZbPTo
# ntRamMifv427GFxD9dAq6OJi7ngE273R+1sKqHB+8JeEeOMIA11HLGOoJTiXAdI/
# Otrl5fbmm9x+LMz/F0xNAKLY1gEOuIvu5uByVYksJxlh9ncBjDCCB20wggVVoAMC
# AQICEAnI7Fw0fQcgWcyoNeinb/gwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBU
# cnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMTAe
# Fw0yMzAzMjkwMDAwMDBaFw0yNjA2MjIyMzU5NTlaMHUxCzAJBgNVBAYTAkFVMRgw
# FgYDVQQIEw9OZXcgU291dGggV2FsZXMxFDASBgNVBAcTC0NoZXJyeWJyb29rMRow
# GAYDVQQKExFEYXJyZW4gSiBSb2JpbnNvbjEaMBgGA1UEAxMRRGFycmVuIEogUm9i
# aW5zb24wggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDHrKfntVGeXaDp
# 6S/nqZuiKuhmIqivGTXM9VwXuzO3gV8FcuLWD+QciGujTkWBLHpVViPV5jtTPnD0
# uo0TK6WW/cbVB/jaSmTvnkrYYEwLZxDtXVmgCumOwB/2VY5oDk1mVwVYm4wBPyUC
# iH2cseB5uRTh+oat27JQPkVEKaNzUMTb9gLs3JCkMG1uwKFyDbnY9HbmAog2LIZ/
# /Zh884C9FaTWEaZoBGu1loHNSR9e1fkmJWn+qjFqWKFrjg8Lg5bUh9qee6gCNv+C
# eq1GBL57O0GfbICFHRpVK+fen6dGOI7sqclRhO0a9GvD7Qci1lLqcle2eZCj6/zE
# Y3q1wJgZ3+gHYSN5GOho89+en2ZDwOPVLgiFxYMk2U/OAKOipcPtEaie9CQ7eOPV
# JMu4XWvofIdj4lHX+610Gplee5mOufpRwJnOPlIE7lrJ6cJ07jZZG2cUZwsNg/lt
# 6raNmgYQ3m3Iimc4r34gFpVn03B7QqcveoDOS/jgeOXsw6VOigB9YcEUozkVJVuc
# qBU11Gz1AUX5VNztm2dMHQCXslGGh1gGsjaMhX7ina5gi7SMe9ujtOnc/SoPnCX/
# tWXSeynFL2YEdnfBdfRVeRtQlTJzs4TGUdnZyHieYdBIHDijR5d4TChXVUceJYVv
# LXK0EDeGU9hIBnyPXwXNItxl0xQNMQIDAQABo4ICAzCCAf8wHwYDVR0jBBgwFoAU
# aDfg67Y7+F8Rhvv+YXsIiGX0TkIwHQYDVR0OBBYEFAUxVql07mJzafndN3rNijPS
# XRlIMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0f
# BIGtMIGqMFOgUaBPhk1odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGg
# T4ZNaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29k
# ZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcmwwPgYDVR0gBDcwNTAzBgZn
# gQwBBAEwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MIGUBggrBgEFBQcBAQSBhzCBhDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMFwGCCsGAQUFBzAChlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIx
# Q0ExLmNydDAJBgNVHRMEAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQBYQAlozzK3Gn8A
# 32eZnv51K5L+MmICIud+XHXTwJv9rMBg07s0lQVRyDAafC1i5s1zwNRm8QTpgOC/
# L7w4IxKUBfSPT4eTDWIGIYNMUqQCKffygKHODkJ8JckRjzfgo2smONMcU8+P4R6I
# VoOK5yTCLlRI5DLSpzHU26Z6lPOcO/AEJXw+/b/4FkNnS9U959fBzhI07fFUrq8Z
# BIUOSN0h/Aq/WIVL/eDm1iFGzilLeUhu5v3fstpn5CkUjpkZbi0qGCz1m8d+aQK7
# GJGj6Y3+WJeY4iT2NxkMxFP0kVVtK68AwG7SkjdIClrWcYozw27PGkFGAooxX43u
# jlhheEZ5j0kIdBX/AMsz0HMfS40P/Fu4FBC7BOiBblz+W49ouoHi8uuS0XuOkGZW
# A6v2zGs1KGUE5Y3v4bOqZDi+H9Sr+7WyWZjBDVVVESTZng0Xo7zZYh2mhhAL/4hd
# GaO6ar4+MAgghht4/7DUeVkkWJ8X+cUOK/YvYGapOMo8JPwyQltq5ijQlKMTSGVo
# dhCJTEg88NwzCpNspWXYmPywIuRpmwshi7erE8/yBNcNTWMK6f8+r+CPdZQ4HV4P
# n05IYcbeO4VpozDg92WFUhc0JoPGpdYkP/ukWCoH7MMOuLSJMvCTjmV/97LP7ocS
# lIzycWCZDsEMFMqAGM43LvwBOwctKzGCBlMwggZPAgEBMH0waTELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBU
# cnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQ
# CcjsXDR9ByBZzKg16Kdv+DANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCBMQw46nWFAqi6R
# 28QdNeMjZr+N0VmkUEDyJkzJlnTYzTANBgkqhkiG9w0BAQEFAASCAgBAHHi5sRwn
# c2UenzGmAJEhQNjgTCZj3l3SjHSgfa+6Kft2xzILUOJlQNwkoGCUuUgxK4/aEPSv
# uGMnCTCa1XgrBwggKRIM9sdrSKWhsijdTTF2GTPQhNo50BDeHKAXuQaaYnBVbNR5
# /C/sVdFMt2m4SaO1KMmQm7K01GlB7Breg3l4RixLxDv4DjW6W9AMF8nyLr9nMhJW
# 82gkLJphBvUXfFtqGJbR0eHtI+S8ANe01XiZq+SFH6j6Ig8kyow1y56rhkpVCDrf
# 9R/angNczG+GPjfI0iXdDGXZs8+2Rcf0KHKcMeJPqRv6T5bLSh5AIlySZQZ66zsf
# vlEYNtpfjhjL1yP66c0nchle6NQm18QwXyc3nhG5myAfzpkrnR9soiMBMEq2XDGm
# 2ELGjlv+VflMv9ujkB4PEMIMdUCjOBfa1tvbLm65OUL36opIvjGIsB5lMZINKp65
# MMcvz6g1B0w0Kben1YC9XjVulGtkVVILg0yK7/df+OMdPKsmMEfgXfUs1m1TIdgE
# CHbpfWwg6NGwEamIMJKiKC8aMznvjBNs7SyKerrwoWIVWiAIwR7+3Tv0kKD+HNhD
# 438CIw+Qa8qOHAj8GzDQHEgCyxJGUzWLYmtyqwJk2DWlzPyKqQkqGKlnV8GnCe/R
# 3IHkg+/k3naM9TMNxnJIklWQ/SMQzYzeKKGCAyAwggMcBgkqhkiG9w0BCQYxggMN
# MIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBU
# aW1lU3RhbXBpbmcgQ0ECEAxNaXJLlPo8Kko9KQeAPVowDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzA3
# MjEwMDA3MTZaMC8GCSqGSIb3DQEJBDEiBCCiUTL5JmO7NmUUlW339oXtH4GWM8S8
# JrLC6z+ri/pNXDANBgkqhkiG9w0BAQEFAASCAgBuPSHfRREBFa3CnaacrEk6meyv
# HNcdokmg8WeEGksiC4DK+A8UNTSUgUVERONJsjF5DMLPNUlGHiHXQ9QjHJrTlWYl
# mAY6riwtL3yW3R2dU52gZQsxJFjEvRxj1mhASmj5/gq8ak634vwQMhSPv/e4CPgg
# T9LqFaklVGTPAHNcdjs8IkJHS2NtVF/RKxiJh2d2Y0kQ3YgZ7OMoCUnQjDa/7q5o
# zGh4pS7dmnTgdo1uq/DmC+VDlEv6sAN3OdhAeZOjYO9AtLJ2NQnmf8VaZ7zAQBSe
# xTs1EfGybAcaZqnLPDRsB9HVtVK1kDpwUASb0FmZi1/lE+weam8I9lKqRlwvZxK5
# 7eaZmZSncdxz5XCj4CXyd7n/lVYop4zBGoZ2D0gX6IeX44WGrYtz0KhVKy4mB5Q4
# 4DZJ76bp+4ePufKIwwNnv2v9ZwUcqMdko92G7ahP9FMDgLgyARDsqQiOIM7oDXLZ
# Yb+2s5GhKA86E7kb0m8Oxmb3oa+vWYURJIpUhgi596YeeugBQdRwu2YIfoowm7zu
# A1SSrjylOOYnCCszpBvHBiHsLpZ3ePnFq5wjXPmXo1P3LrnB0N4BVXj39Spya0aS
# 3N1rxp5UPsN3MV2puweGRpQVVX6URUsYKpVyf6lJtuWrsgPdsPVV0FL7b5Pid0cw
# QLieEcD27j+qGOVWXg==
# SIG # End signature block
