# Define your storage account and container
$storageAccountName = 'yourStorageAccountName'
$storageAccountKey = 'yourStorageAccountAccessKey'
$containerName = 'yourContainerName'

# Create a context using the access key
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# List blobs in the container
$blobs = Get-AzStorageBlob -Container $containerName -Context $context

# Display blob names
$blobs | ForEach-Object {
    Write-Output $_.Name
}
