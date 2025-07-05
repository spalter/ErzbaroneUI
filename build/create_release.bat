@echo off
setlocal enabledelayedexpansion

echo Creating release zip file...

REM Check if zip command is available
where zip >nul 2>&1
if %errorlevel% neq 0 (
    echo Zip command not found, using PowerShell with .NET compression...
    powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $source = Get-Location; $destination = Join-Path $source 'build/release.zip'; if (Test-Path $destination) { Remove-Item $destination }; $zipFile = [System.IO.Compression.ZipFile]::Open($destination, 'Create'); Get-ChildItem -Path . -Recurse -File | Where-Object { $_.FullName -notmatch '\.git' -and $_.FullName -notmatch '\.github' -and $_.FullName -notmatch 'node_modules' -and $_.FullName -notmatch 'build' -and $_.FullName -notmatch '\.vscode' -and $_.FullName -notmatch 'docs' -and $_.Name -ne '.DS_Store' -and $_.Name -ne 'release.zip' } | ForEach-Object { $relativePath = $_.FullName.Substring($source.Path.Length + 1); [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipFile, $_.FullName, $relativePath) }; $zipFile.Dispose()"
) else (
    echo Using zip command...
    zip -r release.zip . -x "*.git*" "*.github*" "node_modules/*" "build/*" ".vscode/*" "docs/*" "*.DS_Store" "release.zip"
)

if exist release.zip (
    echo Zip file created successfully
    dir release.zip
) else (
    echo Failed to create zip file
    exit /b 1
)

echo Done!