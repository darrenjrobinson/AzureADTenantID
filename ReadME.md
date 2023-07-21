# Find an Azure Active Directory Tenant ID and/or Custom Domains using a registered Domain Name

[![PSGallery Version](https://img.shields.io/powershellgallery/v/AzureADTenantID.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/AzureADTenantID) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/AzureADTenantID.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/AzureADTenantID)

## Description
Signed PowerShell module to 
- lookup a domain name and return the associated Entra ID (Azure Active Directory) Tenant ID
- query ExchangeOnline for Registered Domains


## Features
- Queries the 'Well-Known' Entra ID (Azure AD) Open ID Connect (OIDC) Authorization Endpoint using a domain name and returns the TenantId
- Queries the Exchange Online Autodiscovery service using a domain name and returns all other registered domains. 
- Aliases for new Entra ID naming Get-AzureADTenantId == Get-EntraIDTenantId AND Get-AzureADCustomDomains == Get-EntraIDCustomDomains
- Works with Windows PowerShell and PowerShell (6.x+)

## Installation
Install from the PowerShell Gallery on Windows PowerShell 5.1+ or PowerShell Core 6.x or PowerShell.

```
Install-Module -name AzureADTenantID
```

## How to use

### Entra ID (AAD) Tenant ID
```
Get-AzureADTenantId -domain 'microsoft.com'
or
Get-EntraIDTenantId -domain 'microsoft.com'
```

or

```
'microsoft.com' | Get-AzureADTenantId
or
'microsoft.com' | Get-EntraIDTenantId
```

### Exchange Online Domains (which usually infers EntraID (AAD) custom domains so that email and UPN matches for users.)

Defaults to WW Cloud

```
Get-AzureADCustomDomains -domain 'microsoft.com'
or
Get-EntraIDCustomDomains -domain 'microsoft.com'
```

For GCC-H use the -GCCH switch

```
Get-AzureADCustomDomains -domain 'microsoft.com' -GCCH
or
Get-EntraIDCustomDomains -domain 'microsoft.com' -GCCH
```

or 

```
'microsoft.com' | Get-AzureADCustomDomains  
or
'microsoft.com' | Get-EntraIDCustomDomains  
```

## Keep up to date
* [Visit my blog](https://blog.darrenjrobinson.com)
* ![](http://twitter.com/favicon.ico) [Follow darrenjrobinson](https://twitter.com/darrenjrobinson)