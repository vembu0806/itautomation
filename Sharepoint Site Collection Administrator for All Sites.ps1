param(
    [Parameter(Mandatory)]
    [String]$tenant,
    [Parameter(Mandatory)]
    [String]$loginName
)
Connect-SPOService ("https://{0}-admin.sharepoint.com" -f $tenant) -Credential (Get-Credential)
Get-SPOSite -Limit All | select Template -unique | out-host
$siteType = Read-Host "Optional template to filter by (or just hit Enter to get all sites)"
$sites = Get-SPOSite -Limit All
if ($siteType -ne "")
{
    $sites = $sites | where { $_.Template -eq $siteType }
}
foreach ($site in $sites)
{
    $supress = Set-SPOUser -Site $site.Url -LoginName $loginName -IsSiteCollectionAdmin $true
    $obj = New-Object PSObject
    $obj | Add-Member "SiteUrl" $site.Url
    $obj | Add-Member "LoginName" $loginName
    $obj | Add-Member "IsSiteAdmin" (Get-SPOUser -Site $site.Url -LoginName $loginName | select IsSiteAdmin).IsSiteAdmin
    
    $obj   
}
Read-Host -Prompt "Press Enter to exit"