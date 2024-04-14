param (
  [Parameter(Mandatory=$true)]
  [string] $Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SignTool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
Try
{
  cd windows

  # SIGNING EXE IS FAILING FOR UNKNOWN REASONS
  # exactly this: https://stackoverflow.com/questions/77965240/failing-to-sign-jpackage-exe-installer
  # But we actually don't expose it to our users so let's not bother
  #Write-Host "Signing .exe"
  #& $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /tr "http://timestamp.digicert.com" /fd sha256 /td sha256 /n "Conduktor, Inc" "Conduktor-$Version.exe"
  #Start-Sleep -s 15

  Write-Host "Signing .msi"
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /tr "http://timestamp.digicert.com" /fd sha256 /td sha256 /n "Conduktor, Inc" "Conduktor-$Version.msi"
  Start-Sleep -s 15
  
  Write-Host "Signing .msi Single User"
  & $SignTool sign /v /d "Conduktor Desktop v$Version" /du "https://www.conduktor.io" /tr "http://timestamp.digicert.com" /fd sha256 /td sha256 /n "Conduktor, Inc" "Conduktor-$Version-single-user.msi"
}
Catch {
  Write-Host "An error occurred:"
  Write-Host $_
  exit 1
}
