# cmdop - Remote Terminal Control

![cmdop demo](https://raw.githubusercontent.com/markolofsen/cmdop-client/refs/heads/main/static/demo.gif)

**cmdop** is a CLI tool for secure remote terminal access. Control your machines from anywhere with real-time sessions and file operations.

## Installation

### Quick Install (macOS / Linux)

```bash
curl -sSL https://cmdop.com/install.sh | bash
```

### macOS App (with menu bar)

Download [CMDOP-macos.dmg](https://github.com/markolofsen/cmdop-client/releases/latest/download/CMDOP-macos.dmg) - includes system tray with quick access to connect/disconnect.

### Manual Download

**Linux x64:**
```bash
sudo curl -L https://github.com/markolofsen/cmdop-client/releases/latest/download/cmdop-linux-x64 -o /usr/local/bin/cmdop && sudo chmod +x /usr/local/bin/cmdop
```

**Linux ARM64:**
```bash
sudo curl -L https://github.com/markolofsen/cmdop-client/releases/latest/download/cmdop-linux-arm64 -o /usr/local/bin/cmdop && sudo chmod +x /usr/local/bin/cmdop
```

**macOS Intel:**
```bash
sudo curl -L https://github.com/markolofsen/cmdop-client/releases/latest/download/cmdop-macos-intel -o /usr/local/bin/cmdop && sudo chmod +x /usr/local/bin/cmdop
```

**macOS Silicon:**
```bash
sudo curl -L https://github.com/markolofsen/cmdop-client/releases/latest/download/cmdop-macos-silicon -o /usr/local/bin/cmdop && sudo chmod +x /usr/local/bin/cmdop
```

### Windows

Download `cmdop-windows-x64.exe` from [releases](https://github.com/markolofsen/cmdop-client/releases/latest).

## Quick Start

```bash
cmdop login          # Authenticate
cmdop agent start    # Start background agent (auto-updates on start)
cmdop connect        # Connect to terminal session
```

## Commands

### Main Commands

| Command | Description |
|---------|-------------|
| `cmdop login` | Login to CMDOP (device flow) |
| `cmdop logout` | Logout and clear credentials |
| `cmdop connect` | Connect to terminal session |
| `cmdop tray` | Start menu bar app (macOS) |
| `cmdop logs` | View daemon logs |
| `cmdop logs -f` | Follow logs in real-time |
| `cmdop monitor` | TUI dashboard (logs, metrics, gRPC) |
| `cmdop update` | Check and install updates (auto-restarts agent) |
| `cmdop version` | Show version |

### Agent Management

The agent runs in background and keeps your machine accessible.

| Command | Description |
|---------|-------------|
| `cmdop agent start` | Start background agent |
| `cmdop agent stop` | Stop agent |
| `cmdop agent restart` | Restart agent |
| `cmdop agent status` | Show agent status |
| `cmdop agent logs` | Show agent logs |

**Features:**
- Auto-updates on start (checks for new version)
- Auto-reconnects on connection loss
- Auto-start on boot (when installed as service)

### System Service

Install as auto-start service (survives reboots).

| Command | Description |
|---------|-------------|
| `cmdop service install` | Install user-level service |
| `sudo cmdop service install --system` | Install system-level service |
| `cmdop service status` | Show service status |
| `cmdop service uninstall` | Remove service |

### Session Management

| Command | Description |
|---------|-------------|
| `cmdop session list` | List all sessions |
| `cmdop session create` | Create new session |
| `cmdop session attach <id>` | Attach to session |
| `cmdop session destroy <id>` | Destroy session |

### Configuration

| Command | Description |
|---------|-------------|
| `cmdop config show` | Show current config |
| `cmdop config set-mode dev` | Switch to dev server |
| `cmdop auth status` | Check auth status |

## Monitor TUI

```bash
cmdop monitor
```

| Key | Action |
|-----|--------|
| `Tab` | Switch tabs (Logs/Metrics/gRPC) |
| `↑/↓` or `j/k` | Scroll |
| `a` | Toggle auto-scroll |
| `c` | Clear current tab |
| `q` | Quit |

## Config Location

- **macOS**: `~/.config/cmdop/config.yaml`
- **Linux**: `~/.config/cmdop/config.yaml`
- **Windows**: `%APPDATA%\cmdop\config.yaml`

## Log Location

- **macOS**: `~/Library/Logs/cmdop/cmdop.log`
- **Linux**: `~/.cmdop/logs/cmdop.log`
- **Windows**: `%PROGRAMDATA%\cmdop\logs\cmdop.log`

Use `cmdop logs --path` to see exact path.

## Global Flags

```
--debug              Enable debug mode
--log-level string   Log level (debug, info, warn, error)
--log-format string  Log format (json, console)
```

## Links

- Website: [cmdop.com](https://cmdop.com)
- Dashboard: [cmdop.com/dashboard](https://cmdop.com/dashboard)
- Releases: [GitHub Releases](https://github.com/markolofsen/cmdop-client/releases)

## License

MIT
