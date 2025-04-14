run() {
  local package_manager="bun"
  local script_name="start"
  local choice

  # Helper function to run package.json scripts
  run_package_json() {
    if [ -f "package.json" ]; then
      local dev_script=$(jq -r '.scripts.dev // empty' package.json)
      
      if [ -n "$dev_script" ]; then
        script_name="dev"
      fi
      
      eval "$package_manager $script_name"
      return 0
    fi
    return 1
  }

  # Helper function to run turbo build
  run_turbo() {
    if [ -f ".turbo" ] || [ -f "turbo.json" ]; then
      eval "turbo run build"
      return 0
    fi
    return 1
  }

  # Determine which configuration to use
  if [ -f "ecosystem.config.js" ]; then
    if [ -f "package.json" ]; then
      choice=$(gum choose "package.json (p)" "ecosystem.config.js (e)" ".turbo/turbo.json (t)")
      choice=${choice:0:1}  # Get the first character of the choice
    else
      echo "ecosystem.config.js is present. Do you want to run it? (y/n, default: y): "
      choice=$(gum confirm && echo "e" || echo "n")
    fi
  elif [ -f "package.json" ]; then
    if run_turbo; then
      choice="t"
    else
      choice="p"
    fi
  elif [ -f ".turbo" ] || [ -f "turbo.json" ]; then
    choice="t"
  else
    echo "Neither package.json, ecosystem.config.js, nor turbo configuration found in the current directory."
    return 1
  fi

  case "$choice" in
    p) run_package_json ;;
    e) eval "pm2 start ecosystem.config.js" ;;
    t) run_turbo ;;
    n) echo "Skipping running ecosystem.config.js" ;;
    *)
      echo "Invalid choice. Please enter 'e' for ecosystem.config.js, 'p' for package.json, or 't' for turbo configuration."
      return 1
      ;;
  esac
}