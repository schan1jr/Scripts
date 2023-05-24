############################################################
#
#   Description: Site Provisioning Script
#
#   Author: Jeffrey Schantz, Concurrency Inc.
#
#   Date: 8/8/2019
#
############################################################

$teamSiteUrl = "<SiteURL>"

$credentials = get-credential "<AccountName>" 

#Connect to SPO site
Connect-PnPOnline $teamSiteUrl -Credentials $credentials

# Now we have access on the SharePoint site for any operations
$context = Get-PnPContext
$web = Get-PnPWeb
$context.Load($web, $web.WebTemplate)
Invoke-PnPQuery


#Connect Site to a New Office Group
Connect-SPOService -Url "<SP Admin Center URL>" -Credential $credentials 
$site = Get-SPOSite -Identity $teamSiteUrl
Set-SPOSiteOffice365Group -Site $site -DisplayName $web.Title -Alias $web.Title -IsPublic $false
Disconnect-SPOService

#Apply Provisioning Template
write-host "Applying Provisioning Template" -ForegroundColor Green
Apply-PnPProvisioningTemplate -Path "Filename.xml" -Web $web #Team Site


#Set Theme
write-host "Setting Theme" -ForegroundColor Green
$design = Get-PnPSiteDesign -Identity "<Theme Name>"
Invoke-PnPSiteDesign -Identity $design -WebUrl $web.Url

Disconnect-PnPOnline