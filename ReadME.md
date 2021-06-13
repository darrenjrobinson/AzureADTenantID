# Find an Azure Active Directory Tenant ID using a registered Domain Name

[![PSGallery Version](https://img.shields.io/powershellgallery/v/AzureADTenantID.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/AzureADTenantID) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/AzureADTenantID.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/AzureADTenantID)

## Description
Signed PowerShell module to lookup a domain name and return the associated Azure Active Directory Tenant ID.

## Features
- Queries the 'Well-Known' Azure AD Open ID Connect (OIDC) Authorization Endpoint using a domain name and returns the TenantId
- Works with Windows PowerShell and PowerShell (6.x+)

## Installation
Install from the PowerShell Gallery on Windows PowerShell 5.1+ or PowerShell Core 6.x or PowerShell.

```
Install-Module -name AzureADTenantID
```

## How to use

```
Get-AzureADTenantId -domain 'microsoft.com'
```

or

```
'microsoft.com' | Get-AzureADTenantId
```

## Keep up to date
* [Visit my blog](https://blog.darrenjrobinson.com)
* ![](http://twitter.com/favicon.ico) [Follow darrenjrobinson](https://twitter.com/darrenjrobinson)