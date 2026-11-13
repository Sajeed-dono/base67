$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'Release build failed.' }
    New-Item -ItemType Directory -Force dist | Out-Null
    Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-release.apk -Destination 'dist/Base 67.apk'
    $apkHash = (Get-FileHash -LiteralPath 'dist/Base 67.apk' -Algorithm SHA256).Hash.ToLowerInvariant()
    "$apkHash  Base 67.apk" | Set-Content -LiteralPath 'dist/Base 67.apk.sha256' -Encoding ascii
    Get-Item -LiteralPath 'dist/Base 67.apk'
} finally {
    Pop-Location
}
