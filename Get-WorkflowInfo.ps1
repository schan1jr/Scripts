function Write-ToCsv($msg)
{
    $path = "workflowInfo.csv"
    
    $msg | Out-File $path -Append
}

function Get-WorkflowInfo()
{
    Write-ToCsv("Web;List;ContentType;WorkflowName;Status;Instances;SPD;Author")
    
    $webApps = Get-SPWebApplication -Identity "WebApp"
        
    foreach ($w in $webApps)
    {
        $siteScope = Start-SPAssignment
        
        foreach ($site in ($siteScope | Get-SPSite -WebApplication $w -Limit All))
        {
            $webScope = Start-SPAssignment
            
            foreach ($web in ($webScope | Get-SPWeb -Site $site -Limit All))
            {
                foreach ($list in $web.Lists)
                {
                    if ($list.WorkflowAssociations.Count -gt 0)
                    {
                        foreach ($wa in $list.WorkflowAssociations)
                        {
                            if ($wa.Enabled -eq $true)
                            {
                                $status = "Allowed"
                            } else {
                                $status = "No New Instances"
                            }
                            
                            $output = $web.Url + ";" + $list.Title + "; ;" + $wa.Name + ";" + $status + ";" + $wa.RunningInstances + ";" + $wa.IsDeclarative + ";" + $web.AllUsers.GetById($wa.Author).LoginName
                            Write-ToCsv($output)
                        }
                    }
                    
                    foreach ($ctype in $list.ContentTypes)
                    {
                        if ($ctype.WorkflowAssociations.Count -gt 0)
                        {
                            foreach ($wa in $ctype.WorkflowAssications)
                            {
                                if ($wa.Enabled -eq $true)
                                {
                                    $status = "Allowed"
                                } else {
                                    $status = "No New Instances"
                                }
                                
                                $output = $web.Url + ";" + $list.Title + ";" + $ctype.Name + ";" + $wa.Name + ";" + $status + ";" + $wa.RunningInstances + ";" + $wa.IsDeclarative + ";" + $web.AllUsers.GetById($wa.Author).LoginName
                                Write-ToCsv($output)
                            }
                        }
                    }
                }
            }
            
            Stop-SPAssignment $webScope
        }
        
        Stop-SPAssignment $siteScope
    }
}

Write-Host ""
Write-Host "Getting workflow information" -ForegroundColor Yellow
Get-WorkflowInfo