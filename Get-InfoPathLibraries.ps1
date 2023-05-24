$mySiteHost = "Alliant Energy MySites"

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
    $outFile = "$($pwd.Path)\$hostName-InfoPath.csv"
    $sites = Get-SiteCollections $a.Url
    
    #Write the CSV header
    "Site Collection`t Site`t List Name`t List Url`t Docs Count`t Last Modified`t WF Count`t Live WF`t Live WF Names`t Form Template" > $outFile
 
    #Loop through all site collections of the web app
    foreach ($site in $sites) {
        foreach ($web in $site.AllWebs) {
            write-host "Scanning Site" $web.title "@" $web.URL
            foreach ($list in $web.lists) {
                if ( $list.BaseType -eq "DocumentLibrary" -and $list.BaseTemplate -eq "XMLForm") {
                    $listModDate = $list.LastItemModifiedDate.ToShortDateString()
                    $listTemplate = $list.ServerRelativeDocumentTemplateUrl
                    $listWorkflowCount = $list.WorkflowAssociations.Count
                    $listLiveWorkflowCount = 0
                    $listLiveWorkflows = ""
                    Write-Host $list.title -ForegroundColor Yellow
                    foreach ($wf in $list.WorkflowAssociations) {
                        if ($wf.Enabled) {
                            $listLiveWorkflowCount++
                            if ($listLiveWorkflows.Length -gt 0) {
                                $listLiveWorkflows = "$listLiveWorkflows, $($wf.Name)"
                            }
                            else {
                                $listLiveWorkflows = $wf.Name
                            }
                        }
                    }
                    #Write data to CSV File
                    $site.RootWeb.Title + "`t" + $web.Title + "`t" + $list.title + "`t" + $Web.Url + "/" + $List.RootFolder.Url + "`t" + $list.ItemCount + "`t" + $listModDate + "`t" + $listWorkflowCount + "`t" + $listLiveWorkflowCount + "`t" + $listLiveWorkflows + "`t" + $listTemplate >> $outFile
                }
            }
        }
    }
}
Write-host  "Report Generated at $outFile" -foregroundcolor green
