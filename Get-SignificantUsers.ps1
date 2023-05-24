$mySiteHost = "mysite.company.com"

function Get-SiteCollections([string] $webApp) {
    $sites = Get-SPSite -Limit ALL -WebApplication $webApp

    #Exclude the Office Viewing Service Cache
    $cacheUrl = $webApp + "sites/Office_Viewing_Service_Cache"

    return $sites | Where-Object {$_.Url -ne $cacheUrl}
}

$wa = Get-SPWebApplication | Where-Object {$_.Name -ne "ControlPoint" -and $_.Name -ne $mySiteHost}

foreach ($a in $wa) {
	$a
    $webAppUri = [System.Uri] $a.Url 
    $hostName = $webAppUri.Host 
    #$webAppUrl = $webAppUri.AbsoluteUri
    $outFile = "$($pwd.Path)\$hostName-SignificantFolks.csv"
    $sites = Get-SiteCollections $a.Url

    #Write the CSV header
    "Site Collection`t Web Title`t Web URL`t Is Root Web`t Owner Group`t Owners`t Request Access Email`t Has Unique Permissions" > $outFile
 
    #Loop through all site collections of the web app
    foreach ($site in $sites) {
        # Site Collection URL
        $siteCollection = $web.Site.Url
        # Site Collection Admins
        $siteCollectionAdmins = ""
        foreach ($u in $site.RootWeb.SiteAdministrators) {
            $sca = "$($u.DisplayName)($($u.Email))"
            if ($siteCollectionAdmins.Length -gt 0) {
                $siteCollectionAdmins = "$siteCollectionAdmins; $sca"
            }
            else {
                $siteCollectionAdmins = $sca
            }
        }
        foreach ($web in $site.AllWebs) {
            write-host "Scanning Site" $web.title "@" $web.URL
            # Title
            $title = $web.Title
            # URL
            $url = $web.Url
            # Is Root Web
            $isRoot = $web.IsRootWeb

            # Associated Owner Group
            $associatedOwnerGroup = $web.AssociatedOwnerGroup

            # Associated Owners (From Group)
            $associatedOwners = ""
            foreach ($u in $web.SiteGroups["$($web.AssociatedOwnerGroup)"].Users) {

                $o = "$($u.DisplayName)($($u.Email))"
                if ($associatedOwners.Length -gt 0) {
                    $associatedOwners = "$associatedOwners; $o"
                }
                else {
                    $associatedOwners = $o
                }
            }
            # Request Access Email
            $requestAccessEmail = $web.RequestAccessEmail

            # Inherited Permissions
            $uniquePermissions = $web.HasUniquePermissions

            #Write data to CSV File
            $siteCollection + "`t" + $title + "`t" + $url + "`t" + $isRoot + "`t" + $associatedOwnerGroup + "`t" + $associatedOwners + "`t" + $requestAccessEmail + "`t" + $uniquePermissions + "`t"  >> $outFile
        }
    }
}
Write-host  "Report Generated at $outFile" -foregroundcolor green
