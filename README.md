# .ezsh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Custom zsh functions and utilities for productivity and automation on macOS.

## Features

- 🚀 **Git helpers** - Quick navigation and branch management
- 🐳 **Docker utilities** - Remote Docker connections and management
- 💻 **Development tools** - TypeScript compilation, code formatting, and more
- 🌐 **Network automation** - Dynamic DNS switching and captive portal auto-login
- 🔧 **macOS utilities** - Brightness control, WiFi detection, and system management
- 📦 **Database tools** - PostgreSQL setup and management helpers

## Installation

### Prerequisites

- macOS (required for macOS-specific features)
- Zsh shell
- Git

### Quick Install

```bash
# Clone the repository
git clone https://github.com/NeoHBz/.ezsh.git ~/.ezsh

# Run the installation script
cd ~/.ezsh
chmod +x install.sh
./install.sh

# Reload your shell
source ~/.zshrc
```

### Manual Installation

1. Clone the repository to `~/.ezsh`
2. Add to your `~/.zshrc`:
   ```bash
   source ~/.ezsh/load.sh
   ```
3. Copy and configure environment files:
   ```bash
   cp ~/.ezsh/.env.sample ~/.ezsh/.env
   cp ~/.ezsh/.config.sample ~/.ezsh/.config
   ```
4. Edit `~/.ezsh/.env` and `~/.ezsh/.config` with your settings

## Configuration

### Environment Variables (`.env`)

Copy `.env.sample` to `.env` and configure:

```bash
cp ~/.ezsh/.env.sample ~/.ezsh/.env
```

Key configuration options:
- **Docker** - Remote Docker host settings
- **PostgreSQL** - Database connection details
- **DNS** - Custom DNS server configuration
- **LPU Portal** - Captive portal settings (if applicable)
- **WiFi Networks** - Network-specific automation triggers

See [CONFIGURATION.md](CONFIGURATION.md) for detailed documentation.

### Service Control (`.config`)

Services are **disabled by default** for non-intrusive operation. To enable services:

1. Copy `.config.sample` to `.config`:
   ```bash
   cp ~/.ezsh/.config.sample ~/.ezsh/.config
   ```

2. Edit `.config` and enable desired services:
   ```bash
   # Enable services by listing them (comma-separated)
   ENABLED_SERVICES="dynamic_dns_service,lpu_auto_login"
   ```

Available services:
- `dynamic_dns_service` - Auto-switch DNS based on WiFi network
- `lpu_auto_login` - Auto-login to LPU captive portal

## Available Functions

### Git Functions
- `gcd` - Switch to dev branch
- `gcm` - Switch to main/master branch
- `gpo <branch>` - Pull from origin
- `gitrefresh` - Clean up merged branches
- `gitnuke` - Delete all branches except main/dev/current

### Docker Functions
- `remote` - Connect to remote Docker host

### Development Functions
- `tsc1 <file>` - Type-check a single TypeScript file
- `prettify` - Format code with Prettier
- `mcode` - Open VS Code with specific settings

### macOS Functions
- `bright <level>` - Set screen brightness (0-100)
- `cleardock` - Reset macOS Dock to defaults
- `touchidsudo` - Enable Touch ID for sudo
- `wifiname` - Get current WiFi network name

### PostgreSQL Functions
- `psql_setup` - Initialize PostgreSQL environment
- `psql_teardown` - Clean up PostgreSQL environment

And many more! Browse the `functions/` directory for all available utilities.

## Usage Examples

```bash
# Quick git branch switching
gcm              # Switch to main/master
gcd              # Switch to dev

# Git operations
gpo main         # Pull from origin main
gitrefresh       # Clean merged branches

# Docker remote connection
remote           # Connect to configured Docker host

# TypeScript type checking
tsc1 src/app.ts  # Check single file

# macOS utilities
bright 50        # Set brightness to 50%
wifiname         # Show current WiFi network
```

## LaunchAgent Services (Optional)

For automated services (WiFi-based DNS switching, captive portal login):

1. Enable services in `~/.ezsh/.config`
2. Install LaunchAgents:
   ```bash
   # Dynamic DNS service
   cp services/mac/wifi/dynamic_dns.plist ~/Library/LaunchAgents/com.ezsh.dynamic_dns.plist
   launchctl load ~/Library/LaunchAgents/com.ezsh.dynamic_dns.plist

   # LPU auto-login service
   cp services/mac/wifi/lpu_auto_login.plist ~/Library/LaunchAgents/com.ezsh.lpu.autologin.plist
   launchctl load ~/Library/LaunchAgents/com.ezsh.lpu.autologin.plist
   ```

3. View logs:
   ```bash
   tail -f ~/.ezsh/logs/dynamic_dns.log
   tail -f ~/.ezsh/logs/lpu_auto_login.log
   ```

## Project Structure

```
.ezsh/
├── functions/           # Function definitions
│   ├── git/            # Git utilities
│   ├── docker/         # Docker helpers
│   ├── mac/            # macOS-specific tools
│   ├── psql/           # PostgreSQL tools
│   ├── tsc/            # TypeScript utilities
│   └── ...
├── services/           # LaunchAgent services
│   └── mac/wifi/       # WiFi-based automation
├── logs/               # Service logs
├── load.sh             # Main loader script
├── install.sh          # Installation script
├── .env.sample         # Environment template
├── .config.sample      # Service config template
└── README.md           # This file
```

## Migrating from Previous Versions

If you're upgrading from an older version with hardcoded values, see [MIGRATION.md](MIGRATION.md) for step-by-step migration instructions.

## Security Best Practices

- ⚠️ **Never commit** `.env` or `.config` files (already in `.gitignore`)
- 🔒 Set proper permissions: `chmod 600 ~/.ezsh/.env`
- 🔑 Rotate credentials regularly
- 📝 Use `.env.sample` as a template, not the actual config

## Troubleshooting

### Functions not loading
```bash
# Check if load.sh is sourced in ~/.zshrc
grep "load.sh" ~/.zshrc

# Manually reload
source ~/.ezsh/load.sh
```

### Services not working
```bash
# Check if service is enabled in .config
cat ~/.ezsh/.config | grep ENABLED_SERVICES

# Check service logs
tail -f ~/.ezsh/logs/dynamic_dns.log
```

### Environment variables not set
```bash
# Ensure .env exists and is sourced
ls -la ~/.ezsh/.env
source ~/.ezsh/.env
```

## Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Contribution Guidelines

- Follow existing code style and structure
- Test your changes thoroughly
- Update documentation as needed
- Use descriptive commit messages
- Add comments for complex logic

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**NeoHBz**
- GitHub: [@NeoHBz](https://github.com/NeoHBz)

## Acknowledgments

- Built for productivity and automation
- Inspired by the need for streamlined development workflows
- Community contributions and feedback

## Support

If you find this project helpful, please ⭐ star the repository!

For issues, questions, or feature requests, please [open an issue](https://github.com/NeoHBz/.ezsh/issues).

---

**Note**: This project is primarily designed for macOS. Some features may not work on other operating systems.