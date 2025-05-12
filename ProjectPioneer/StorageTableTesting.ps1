$stracct = Get-AzStorageAccount -Name jlrdpioneer -ResourceGroupName ProjectPioneer

$strTable = Get-AzStorageTable -Context $stracct.Context -Name primestate

$CloudTable = $strTable.CloudTable

Add-AzTableRow -Table $CloudTable -PartitionKey 'Server1' -RowKey 'hello.exe' -property @{"type"="process";"id"="148"}
Add-AzTableRow -Table $CloudTable -PartitionKey 'Server2' -RowKey 'hello.exe' -property @{"type"="process";"id"="222"}
Add-AzTableRow -Table $CloudTable -PartitionKey 'Server2' -RowKey 'term.exe' -property @{"type"="subprocess";"id"="4777"}

#[string]$filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("type",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::NotEqual,"subprocess")

$proc = Get-AzTableRow -Table $CloudTable -CustomFilter "(id eq 222)"
$proc.type = 'childprocess'
$proc | Update-AzTableRow -Table $CloudTable






