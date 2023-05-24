Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

Write-Host "Location for csv file:"
$filepath = Read-Host

$webs = (Get-SPSite -Limit all | Get-SPWeb -Limit all)
#$output = ""
$stuff = @()

    $permNone =    [Microsoft.SharePoint.SPBasePermissions]::EmptyMask

    $permRead =    [Microsoft.SharePoint.SPBasePermissions]::ViewListItems -bor
                   [Microsoft.SharePoint.SPBasePermissions]::OpenItems -bor
                   [Microsoft.SharePoint.SPBasePermissions]::Open -bor
                   [Microsoft.SharePoint.SPBasePermissions]::ViewPages
            
    $permWrite =   [Microsoft.SharePoint.SPBasePermissions]::AddListItems -bor
                   [Microsoft.SharePoint.SPBasePermissions]::EditListItems -bor
                   [Microsoft.SharePoint.SPBasePermissions]::BrowseDirectories -bor
                   [Microsoft.SharePoint.SPBasePermissions]::AddDelPrivateWebParts -bor
                   [Microsoft.SharePoint.SPBasePermissions]::EditMyUserInfo -bor
                   [Microsoft.SharePoint.SPBasePermissions]::UpdatePersonalWebParts

    $permDelete =  [Microsoft.SharePoint.SPBasePermissions]::DeleteListItems -bor
                   [Microsoft.SharePoint.SPBasePermissions]::DeleteVersions
              
    $permLimited = [Microsoft.SharePoint.SPBasePermissions]::Open -bor
                   [Microsoft.SharePoint.SPBasePermissions]::BrowseUserInfo -bor
                   [Microsoft.SharePoint.SPBasePermissions]::UseClientIntegration


foreach( $web in $webs)
{
    #get all lists with broken inheritance
    $lists = $web.Lists
    Write-Host "In Site $($web.Url)" -ForegroundColor Green
    $groups = $web.SiteUsers | where {$_.isDomainGroup -eq $true} #| select DisplayName
    Write-Host "$($groups.Count) Found" -ForegroundColor DarkYellow
    foreach($group in $groups)
    {
        $account = New-Object System.Object
        $account | Add-Member -MemberType NoteProperty -Value $group.DisplayName -Name DisplayName
        $account | Add-Member -MemberType NoteProperty -Value $web.url -Name Site
        if($group.DisplayName -ne "Everyone" -or $group.DisplayName -ne "NT AUTHORITY\Authenticated Users")
        {
            $roles = ""
            foreach($role in $group.Roles)
            {
                if($role.name -ne "Limited Access")
                {
                    $roles += $role.name + "; "
                }
            }
            $roles = $roles.TrimEnd()
            $account | Add-Member -MemberType NoteProperty -Value $roles -Name Roles
            if($roles -ne "")
            {
                $stuff += $account
            }
        }
     
    
        foreach($list in $lists)
        {
            if($list.HasUniqueRoleAssignments -and $list.Hidden -eq $false)
            {
                #$list.DoesUserHavePermissions($group.DisplayName)
                try
                {
                    
                    $perms = $list.GetUserEffectivePermissions($group.DisplayName)
                    if($perms -ne "EmptyMask")
                    {
                        write-host $perms

                        
        if ($list.GetUserEffectivePermissions($group.DisplayName) -eq $permNone)
        {
            $none = ""
        }
        else
        {
            if ($list.DoesUserHavePermissions($group, $permLimited) -and
                $list.DoesUserHavePermissions($group, $permRead) -eq $false)
            {
                $roles += "Limited"
            }
            else
            {
                $limited = ""
                if ($list.DoesUserHavePermissions($group, $permRead))
                {
                    $roles += "Read"
                }
                
                if ($list.DoesUserHavePermissions($group, $permWrite))
                {
                    $roles += "Write"
                }
                
                if ($list.DoesUserHavePermissions($group, $permDelete))
                {
                    $roles += "Delete"
                }
            }
        }

         $account = New-Object System.Object
        $account | Add-Member -MemberType NoteProperty -Value $group.DisplayName -Name DisplayName
        $account | Add-Member -MemberType NoteProperty -Value $list.ParentWeb.Site.MakeFullUrl($list.RootFolder.ServerRelativeUrl) -Name Site
        $account | Add-Member -MemberType NoteProperty -Value $roles -Name Roles
        $stuff += $account

                    }
                }
                catch
                {

                }

            }
        }
        }
}

$stuff | select Site,DisplayName,Roles | Export-Csv -Path $filepath -NoTypeInformation