$ErrorActionPreference = "Stop"

$token = Get-Content -Path "C:\Users\Hp\.github_token.txt" -Raw
$token = $token.Trim()
$repo = "TaxFlowPro-Releases/TaxFlowPro-Releases"
$version = "1.8.7"
$tag = "v$version"
$releaseName = "Aggiornamento v$version"
$body = "Nuovo aggiornamento v$version con aggiunta del metodo di pagamento 'Carta'."

$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

# Delete existing release if it exists
try {
    $existingRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/tags/$tag" -Headers $headers -ErrorAction Stop
    Write-Host "Release $tag already exists (ID: $($existingRelease.id)). Deleting it..."
    Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/$($existingRelease.id)" -Method Delete -Headers $headers
    
    # Wait a bit
    Start-Sleep -Seconds 2
    
    # Delete tag
    Write-Host "Deleting tag $tag..."
    Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/git/refs/tags/$tag" -Method Delete -Headers $headers -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} catch {
    Write-Host "No existing release $tag found. Proceeding..."
}

# Creazione Release GitHub
Write-Host "Creating GitHub Release $tag..."
$releaseBody = @{
    tag_name = $tag
    name = $releaseName
    body = $body
    draft = $false
    prerelease = $false
} | ConvertTo-Json

$releaseResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Method Post -Headers $headers -Body $releaseBody -ContentType "application/json"
$releaseId = $releaseResponse.id
Write-Host "Created release with ID: $releaseId"

# Local paths
$apkDest = "C:\Users\Hp\Desktop\TaxFlowPro\TaxFlowPro_v$($version)_update.apk"
$zipDest = "C:\Users\Hp\Desktop\TaxFlowPro\TaxFlowPro_v$($version)_update.zip"

# Upload Assets
function Upload-Asset {
    param(
        [string]$FilePath,
        [string]$FileName,
        [string]$ContentType
    )
    Write-Host "Uploading $FileName..."
    $uploadUri = "https://uploads.github.com/repos/$repo/releases/$releaseId/assets?name=$FileName"
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
    Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $headers -Body $fileBytes -ContentType $ContentType
    Write-Host "$FileName uploaded successfully!"
}

Upload-Asset -FilePath $apkDest -FileName "TaxFlowPro_update.apk" -ContentType "application/vnd.android.package-archive"
Upload-Asset -FilePath $zipDest -FileName "TaxFlowPro_PC_Portable.zip" -ContentType "application/zip"

Write-Host "Tutto completato! L'aggiornamento è stato pubblicato."
