param (
  [Parameter(Mandatory=$true)]
  [string] $Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Writing pfx..."
[System.Convert]::FromBase64String("$env:WIN_SIGN_PFX") | Set-Content -Path conduktor.pfx -Encoding Byte

$SignTool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\signtool.exe"
Try
{
  Write-Host "Signing .exe"
  #& $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /f conduktor.pfx /p "$env:WIN_SIGN_PFX_KEY" /t "http://timestamp.comodoca.com" /fd sha1 "Conduktor-$Version.exe}"
  #Start-Sleep -s 15
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /f conduktor.pfx /p "$env:WIN_SIGN_PFX_KEY" /tr "http://timestamp.comodoca.com?td=sha256" /fd sha256 /td sha256 /as "Conduktor-$Version.exe"
  Start-Sleep -s 15

  Write-Host "Signing .msi"
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /f conduktor.pfx /p "$env:WIN_SIGN_PFX_KEY" /tr "http://timestamp.comodoca.com?td=sha256" /fd sha256 /td sha256 "Conduktor-$Version.msi"
  Start-Sleep -s 15
  
  Write-Host "Signing .msi Single User"
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /f conduktor.pfx /p "$env:WIN_SIGN_PFX_KEY" /tr "http://timestamp.comodoca.com?td=sha256" /fd sha256 /td sha256 "Conduktor-$Version-single-user.msi"
}
Catch {
  Write-Host "An error occurred:"
  Write-Host $_
  exit 1
}
Finally {
  Write-Host "Removing pfx..."
  Remove-Item conduktor.pfx
}
