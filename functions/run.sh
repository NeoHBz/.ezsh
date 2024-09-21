run() {
  local package_manager="bun"
  local script_name="start"
  local choice

  # Helper function to check for scripts in package.json
  run_package_json() {
    local dev_script=$(jq -r '.scripts.dev // empty' package.json)
    local start_script=$(jq -r '.scripts.start // empty' package.json)

    if [ -n "$dev_script" ]; then
      script_name="dev"
    fi
    eval "$package_manager $script_name"
  }

  if [ -f "ecosystem.config.js" ]; then
    if [ -f "package.json" ]; then
      choice=$(gum choose "package.json (p)" "ecosystem.config.js (e)")
      choice=${choice:0:1}  # Get the first character of the choice
    else
      echo "ecosystem.config.js is present. Do you want to run it? (y/n, default: y): "
      choice=$(gum confirm && echo "e" || echo "n")
    fi
  elif [ -f "package.json" ]; then
    choice="p"
  else
    echo "Neither package.json nor ecosystem.config.js found in the current directory."
    return 1
  fi

  case "$choice" in
    p)
      run_package_json
      ;;
    e)
      eval "pm2 start ecosystem.config.js"
      ;;
    n)
      echo "Skipping running ecosystem.config.js"
      ;;
    *)
      echo "Invalid choice. Please enter 'e' for ecosystem.config.js or 'p' for package.json."
      return 1
      ;;
  esac
}
