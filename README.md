# cmdop - Remote Terminal Control

![cmdop demo](https://raw.githubusercontent.com/markolofsen/cmdop-client/refs/heads/main/static/demo.gif)

**cmdop** is a powerful CLI tool that enables secure remote terminal access and management. Control your computer from anywhere with real-time terminal sessions and file operations.

## 🚀 Quick Installation

### macOS / Linux

```bash
curl -sSL https://cmdop.com/install.sh | bash
```

Or install to custom directory:

```bash
curl -sSL https://cmdop.com/install.sh | bash -s -- --prefix=$HOME/.local/bin
```

### Windows (PowerShell)

```powershell
iwr -useb https://cmdop.com/install.ps1 | iex
```

Or with custom installation directory:

```powershell
$env:CMDOP_INSTALL_DIR="C:\Tools"; iwr -useb https://cmdop.com/install.ps1 | iex
```

## 📦 Getting Started

After installation, run these commands:

```bash
# Login to your account
cmdop auth login

# Start the agent in background
cmdop agent start

# Connect to a terminal session
cmdop connect

# View all available commands
cmdop --help
```

## ⚙️ Configuration

Configuration file location:
- **macOS/Linux**: `~/.config/cmdop/config.yaml`
- **Windows**: `%APPDATA%\cmdop\config.yaml`

## 🔧 Features

- ✅ Real-time terminal access from anywhere
- ✅ Secure encrypted connections
- ✅ File operations (read, write, list, delete, move, copy)
- ✅ Session management and history
- ✅ Cross-platform support (Linux, macOS, Windows)
- ✅ Background daemon mode

## 📚 Documentation

Visit [cmdop.com](https://cmdop.com) for full documentation and guides.

## 📄 License

MIT License - see LICENSE file for details
