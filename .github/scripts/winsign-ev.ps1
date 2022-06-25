param (
  [Parameter(Mandatory=$true)]
  [string] $Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SignTool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
Try
{
  Write-Host "Signing .exe"

  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /tr "http://timestamp.digicert.com" /fd sha256 /td sha256 /a "Conduktor-$Version.exe"
  Start-Sleep -s 15

  Write-Host "Signing .msi"
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /tr "http://timestamp.digicert.com" /fd sha256 /td sha256 "Conduktor-$Version.msi"
  Start-Sleep -s 15
  
  Write-Host "Signing .msi Single User"
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /tr "http://timestamp.digicert.com" /fd sha256 /td sha256 "Conduktor-$Version-single-user.msi"
}
Catch {
  Write-Host "An error occurred:"
  Write-Host $_
  exit 1
}
