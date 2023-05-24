Import-Module Sharegate
$csvFile = "C:\Temp\ShareGateMappingFile.csv"
$table = Import-CSV $csvFile -Delimiter ","
$mappingSettings = New-MappingSettings
foreach ($row in $table) {
    $results = Set-UserAndGroupMapping -MappingSettings $mappingSettings -Source $row.SourceValue -Destination $row.DestinationValue
    $row.sourcevalue
}
Export-UserAndGroupMapping -MappingSettings $mappingSettings -Path "C:\Temp\MappingFile.sgum"