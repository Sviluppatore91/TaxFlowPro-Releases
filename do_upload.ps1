$token = (Get-Content -Path "C:\Users\Hp\Documents\Sviluppo\Token di accesso\token.txt" -Raw).Trim()
$apkPath = "C:\Users\Hp\Desktop\TaxFlowPro\TaxFlowPro_v1.8.34_update.apk"
$releaseId = "375893889"
$url = "https://uploads.github.com/repos/TaxFlowPro-Releases/TaxFlowPro-Releases/releases/$releaseId/assets?name=TaxFlowPro_v1.8.34_update.apk"

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Authorization", "token $token")
$wc.Headers.Add("User-Agent", "PowerShell")
$wc.Headers.Add("Content-Type", "application/vnd.android.package-archive")
Write-Host "Uploading APK..."
$response = $wc.UploadFile($url, "POST", $apkPath)
Write-Host "Done!"
