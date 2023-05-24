####################################################################
#
#  Description: Grabs basic information about SharePoint farm and outputs to file
#
#  Author: Jeffrey Schantz, Concurrency
#
#  Date: May 3, 2019
#
#####################################################################

Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

#Initializing Variables
$totalDatabaseSize = 0
$DBOutput = @()
$WebOutput = @()
$DBfilepath = "C:\FarmDBInfo.csv"
$Webfilepath = "C:\FarmWebInfo.csv"
$Farmfilepath = "C:\FarmInfo.csv"

#farm level info
$farm = get-spfarm

#cycle through web applications getting all site info
$wa = get-spwebapplication

foreach($webApp in $wa)
{
    #get database information (name, size, etc)
    foreach($database in $webApp.ContentDatabases)
    {
        Write-Host "$($database.name)"
        $totalDatabaseSize += $database.DiskSizeRequired
        $DBObject = New-Object System.Object
        $DBObject | Add-Member -MemberType NoteProperty -Value $database.name -Name DatabaseName
        $DBObject | Add-Member -MemberType NoteProperty -Value $database.server -Name DatabaseServer
        $DBObject | Add-Member -MemberType NoteProperty -Value $database.DiskSizeRequired -Name Size
        $DBOutput += $DBObject
    }


    foreach($site in $webApp.sites)
    {

        #subsite info
        foreach($web in $site.AllWebs)
        {
            #$web.lists.count
            #$web.webtemplate
            $adminUsers = ""
            Write-Host "Processing site: $($web.title)"
            $OutObject = New-Object System.Object
            $OutObject | Add-Member -MemberType NoteProperty -Value $web.URL -Name URL
            $OutObject | Add-Member -MemberType NoteProperty -Value $web.Title -Name Title
            $OutObject | Add-Member -MemberType NoteProperty -Value $site.owner.DisplayName -Name Owner
            $OutObject | Add-Member -MemberType NoteProperty -Value $site.secondaryContact.DisplayName -Name SecondaryOwner
            $OutObject | Add-Member -MemberType NoteProperty -Value ($site.usage.storage/1gb) -Name SizeInGB
            $OutObject | Add-Member -MemberType NoteProperty -Value $site.LastContentModifiedDate -Name LastContentModified
            $OutObject | Add-Member -MemberType NoteProperty -Value $site.LastSecurityModifiedDate -Name LastSecurityModified
            $OutObject | Add-Member -MemberType NoteProperty -Value $web.LastItemModifiedDate -Name LastItemModified
            $OutObject | Add-Member -MemberType NoteProperty -Value $web.lists.count -Name ListCount
            $OutObject | Add-Member -MemberType NoteProperty -Value $web.webtemplate -Name SiteTemplate
            $OutObject | Add-Member -MemberType NoteProperty -Value $web.created -Name Created
            
            $adminGroup = $Web.Groups | ? {$_.Name -match "Administrators"}
            if($adminGroup -ne $null)
            {
                foreach($user in $adminGroup.users)
                {
                    $adminUsers += ($user.DisplayName + "; ")
                }
            }
            
            $OutObject | Add-Member -MemberType NoteProperty -Value $adminUsers -Name AdminUsers
            $WebOutput += $OutObject
            $adminUsers=""
        }
    }
}

$totalDatabaseSize = $totalDatabaseSize/1gb #convert bytes to GB

#Export of collected Info

$DBOutput | select DatabaseName,DatabaseServer,Size | Export-Csv -Path $DBfilepath -NoTypeInformation
$WebOutput | select URL,Title,Owner,SecondaryOwner,SizeInGB,LastContentModified,LastSecurityModified,LastItemModified,ListCount,SiteTemplate,Created,AdminUsers | Export-Csv -Path $Webfilepath -NoTypeInformation


#create farm level file

$FarmOutput = "Farm Output `n"
$FarmOutput += "Solutions: $($farm.solutions) `n"
$FarmOutput += "Total Content Database Size: $($totalDatabaseSize) GB `n"
$FarmOutput += "Current SharePoint version: $($farm.version) `n"

$FarmOutput | Out-File -FilePath $Farmfilepath