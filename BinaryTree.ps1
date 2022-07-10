
$apiKey = "<api key created in service>"

Connect-BTSession -ApiKey (ConvertTo-SecureString $apiKey -AsPlainText -Force)

#Get Users Associated to a Wave
$WaveUsers = Get-BTUser #–Wave ‘i.e. Sales Wave 1’

$data = @()

foreach($user in $WaveUsers)
{
    $ErrorLogs = Get-BTSync -User $user | Select-Object -First 1 | Get-BTLog -Levels Error 
    foreach($log in $ErrorLogs)
    {
        $item = New-Object System.Object
        $item | Add-Member -MemberType NoteProperty -Value $user.NewUserPrincipalName -Name "User"
        $item | Add-Member -MemberType NoteProperty -Value $log.message.ToString() -Name "Message"
        $item | Add-Member -MemberType NoteProperty -Value $log.Level -Name "Level"
        $item | Add-Member -MemberType NoteProperty -Value $log.exception -Name "exception"
        $item | Add-Member -MemberType NoteProperty -Value $log.loggerName -Name "loggerName"
        $item | Add-Member -MemberType NoteProperty -Value $user.wavename -Name "Wave"
        $data += $item
    }
    $data | select User,Message,Level,exception,loggerName | Export-Csv –Path "C:\BTLogWaveCutover.csv" -NoTypeInformation #-Append
}
$WaveUsers | select NewUserPrincipalName, MigrationState, WaveName | Export-Csv –Path "C:\BTLogWaveUserStatus.csv"

#disconnect at end
Disconnect-BTSession


