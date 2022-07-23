param(
    [Parameter(Mandatory)][string]$DefaultName = 'thr-core',
    [Parameter(Mandatory)][string]$ReleaseName,
    [hashtable]$DefaultTags = @{},
    [Parameter(Mandatory)][string]$AzureStorageAccountName,
    [Parameter(Mandatory)][string]$AzureStorageContainerName,
    
    [Parameter(Mandatory)]
    [Parameter(Mandatory)][string]$MetadataLocation,
    [Parameter(Mandatory)][string]$PrimaryLocation,
    [Parameter(Mandatory)][string]$SecondaryLocation,

    [Parameter(Mandatory)][string]$OwnerPrincipalId,
    [Parameter(Mandatory)][string]$ContributorPrincipalId,
    [Parameter(Mandatory)][string]$ReaderPrincipalId,

    [Parameter(Mandatory)][string]$ImageGalleryId
)

$ErrorActionPreference = "Stop"

$pkg = "thr-azure-devops-images.$DefaultName"
$url = "https://$AzureStorageAccountName.blob.core.windows.net/$AzureStorageContainerName/$pkg"
$src = $PSScriptRoot

# stage files into Azure storage
Write-Host "Copying deployment from '$src' to '$url'."
$ctx = New-AzStorageContext -StorageAccountName $AzureStorageAccountName -UseConnectedAccount
$sas = Get-AzStorageContainer -Name $AzureStorageContainerName -Context $ctx | New-AzStorageContainerSASToken -Permission racwdl -ExpiryTime (Get-Date).AddDays(7)
az storage blob upload-batch --account-name $AzureStorageAccountName --sas-token ('"' + $sas + '"') -s "$src" -d $AzureStorageContainerName --destination-path $pkg
Write-Host "Done copying deployment from '$src' to '$url'."

$args = @{
    defaultName            = $DefaultName
    releaseName            = $ReleaseName
    defaultTags            = $DefaultTags

    metadataLocation       = $MetadataLocation
    primaryLocation        = $PrimaryLocation
    secondaryLocation      = $SecondaryLocation

    ownerPrincipalId       = $OwnerPrincipalId
    contributorPrincipalId = $ContributorPrincipalId
    readerPrincipalId      = $ReaderPrincipalId

    imageGalleryId         = $ImageGalleryId
}

New-AzResourceGroupDeployment `
    -Name "thr-azure-devops-images.$DefaultName" `
    -ResourceGroupName $DefaultName `
    -DeploymentDebugLogLevel All `
    -Verbose `
    -TemplateUri "$url/azuredeploy.json$sas" `
    -TemplateParameterObject $args
