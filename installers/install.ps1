# cmdop CLI Installer (Windows)
# Downloads and installs the cmdop command-line tool
#
# Usage:
#   iwr -useb https://cdn.jsdelivr.net/gh/commandoperator/cmdop-agent@main/installers/install.ps1 | iex
#
# Or with custom installation directory:
#   $env:CMDOP_INSTALL_DIR="C:\Tools"; iwr -useb https://cdn.jsdelivr.net/gh/commandoperator/cmdop-agent@main/installers/install.ps1 | iex

$ErrorActionPreference = "Stop"

$BINARY_NAME = "cmdop"
$GITHUB_REPO = "commandoperator/cmdop-agent"
$BASE_URL = "https://github.com/$GITHUB_REPO/releases/latest/download"

# Default installation directory
$INSTALL_DIR = $env:CMDOP_INSTALL_DIR
if (-not $INSTALL_DIR) {
    $INSTALL_DIR = "$env:LOCALAPPDATA\cmdop\bin"
}

Write-Host "🚀 cmdop CLI Installer" -ForegroundColor Cyan
Write-Host ""

# Detect Architecture
$arch = "amd64"
if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    $arch = "arm64"
}

Write-Host "💻 Detected: Windows/$arch" -ForegroundColor Blue

# Construct Download URL
$binaryFile = "$BINARY_NAME-windows-$arch.exe"
$downloadUrl = "$BASE_URL/$binaryFile"

Write-Host "⬇️  Downloading from: $downloadUrl" -ForegroundColor Blue
Write-Host ""

# Create temporary directory for download
$tempDir = Join-Path $env:TEMP "cmdop-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$tempBinary = Join-Path $tempDir "$BINARY_NAME.exe"

try {
    # Show download progress
    $ProgressPreference = 'Continue'

    # Try BITS transfer first (shows native Windows progress)
    if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
        Start-BitsTransfer -Source $downloadUrl -Destination $tempBinary -Description "Downloading cmdop..."
    } else {
        # Fallback to Invoke-WebRequest with progress
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempBinary -UseBasicParsing
    }
} catch {
    Write-Host "❌ Failed to download cmdop" -ForegroundColor Red
    Write-Host ""
    
    # Check if it's a network error
    if ($_.Exception.Message -match "504|timeout|connection") {
        Write-Host "💡 Network error (timeout or connection issue)" -ForegroundColor Yellow
        Write-Host "   Please check your internet connection and try again" -ForegroundColor Yellow
    } else {
        Write-Host "💡 Try downloading manually to a writable directory:" -ForegroundColor Yellow
        Write-Host "   cd ~\Downloads" -ForegroundColor White
        Write-Host "   Invoke-WebRequest -Uri $downloadUrl -OutFile cmdop.exe" -ForegroundColor White
        Write-Host "   Move-Item cmdop.exe $INSTALL_DIR\" -ForegroundColor White
    }
    
    # Cleanup temp directory
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Create installation directory
Write-Host "📦 Installing to: $INSTALL_DIR" -ForegroundColor Blue
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

# Move binary to installation directory
$binaryPath = Join-Path $INSTALL_DIR "$BINARY_NAME.exe"
Move-Item -Path $tempBinary -Destination $binaryPath -Force

# Cleanup temp directory
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Check if directory is in PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$needsPathUpdate = $currentPath -notlike "*$INSTALL_DIR*"

if ($needsPathUpdate) {
    Write-Host ""
    Write-Host "⚙️  Adding to PATH..." -ForegroundColor Yellow

    try {
        # Add to user PATH
        $newPath = "$currentPath;$INSTALL_DIR"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

        # Also update current session
        $env:Path = "$env:Path;$INSTALL_DIR"

        Write-Host "✓ Added $INSTALL_DIR to PATH" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not automatically update PATH" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Add manually via System Settings or run:" -ForegroundColor Yellow
        Write-Host "  `$env:Path += `";$INSTALL_DIR`"" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "✅ cmdop CLI installed successfully!" -ForegroundColor Green
Write-Host ""

# Verify installation
try {
    $version = & "$binaryPath" version 2>$null | Select-Object -First 1
    Write-Host "📦 Version: $version" -ForegroundColor Blue
    Write-Host ""
    Write-Host "🎉 cmdop installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Quick Start:" -ForegroundColor Blue
    Write-Host ""
    Write-Host "   cmdop login          Login to your account" -ForegroundColor Green
    Write-Host "   cmdop agent start    Run agent in background" -ForegroundColor Green
    Write-Host "   cmdop connect        Start terminal session" -ForegroundColor Green
    Write-Host "   cmdop --help         Show all commands" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚙️  Configuration:" -ForegroundColor Blue
    Write-Host "   Config: %APPDATA%\cmdop\config.yaml"
    Write-Host "   Edit to set server, TLS, and other options"
    Write-Host ""
    Write-Host "🔗 Documentation:" -ForegroundColor Blue
    Write-Host "   PS> cmdop --help"
    Write-Host "   PS> cmdop daemon --help"
} catch {
    Write-Host "⚠️  cmdop was installed but could not verify" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Try running:" -ForegroundColor Yellow
    Write-Host "   PS> cmdop version"
}

Write-Host ""

# Note about restarting terminal
if ($needsPathUpdate) {
    Write-Host "💡 Tip: You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Cyan
    Write-Host ""
}
