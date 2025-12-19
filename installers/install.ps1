# cmdop CLI Installer (Windows)
# Downloads and installs the cmdop command-line tool
#
# Usage:
#   iwr https://api.cmdop.com/media/cmdop_cli/install.ps1 -UseBasicParsing | iex
#
# Or with custom installation directory:
#   $env:CMDOP_INSTALL_DIR="C:\Tools"; iwr https://api.cmdop.com/media/cmdop_cli/install.ps1 -UseBasicParsing | iex

$ErrorActionPreference = "Stop"

$BINARY_NAME = "cmdop"
$BASE_URL = "https://api.cmdop.com/media/cmdop_cli"

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

# Create installation directory
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

# Download binary
$binaryPath = Join-Path $INSTALL_DIR "$BINARY_NAME.exe"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $binaryPath -UseBasicParsing
} catch {
    Write-Host "❌ Failed to download cmdop" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Try downloading manually:" -ForegroundColor Yellow
    Write-Host "   Invoke-WebRequest -Uri $downloadUrl -OutFile cmdop.exe"
    Write-Host "   Move-Item cmdop.exe $INSTALL_DIR\"
    exit 1
}

Write-Host "📦 Installing to: $binaryPath" -ForegroundColor Blue

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
    Write-Host "📚 Quick Start:" -ForegroundColor Blue
    Write-Host ""
    Write-Host "1. Interactive Mode (one-time connection):" -ForegroundColor Yellow
    Write-Host "   PS> cmdop connect"
    Write-Host ""
    Write-Host "2. Daemon Mode (persistent background service):" -ForegroundColor Yellow
    Write-Host "   PS> cmdop daemon start --mode prod"
    Write-Host "   PS> cmdop daemon status"
    Write-Host "   PS> cmdop daemon logs -f"
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
