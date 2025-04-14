run() {
  local package_manager="bun"
  local script_name="start"
  local choice

  # Helper function to run package.json scripts
  run_package_json() {
    if [ -f "package.json" ]; then
        local script_names=("dev" "start")
        for script in "${script_names[@]}"; do
        if [ "$(jq -r ".scripts.$script != null" package.json)" = "true" ]; then
            eval "$package_manager $script"
            return 0
        fi
        done
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

    # Helper function to run PHP Composer projects
    # Loop through script names in priority order
  run_composer() {
    if [ -f "composer.json" ]; then
        # Script names in priority order
        local script_names=("serve" "start" "dev")
        
        for script in "${script_names[@]}"; do
        if [ "$(jq -r ".scripts.$script != null" composer.json)" = "true" ]; then
            eval "composer $script"
            return 0
        fi
        done
        
        # Fallbacks if no scripts found
        if [ -f "artisan" ]; then
        eval "php artisan serve"
        else
        eval "php -S localhost:8000"
        fi
        return 0
    fi
    return 1
  }

  # Determine which configuration to use
  if [ -f "ecosystem.config.js" ]; then
    if [ -f "package.json" ] || [ -f "composer.json" ] || [ -f ".turbo" ] || [ -f "turbo.json" ]; then
      options=()
      [ -f "package.json" ] && options+=("package.json (p)")
      [ -f "composer.json" ] && options+=("composer.json (c)")
      [ -f ".turbo" ] || [ -f "turbo.json" ] && options+=(".turbo/turbo.json (t)")
      options+=("ecosystem.config.js (e)")
      
      choice=$(gum choose "${options[@]}")
      choice=${choice:0:1}  # Get the first character of the choice
    else
      echo "ecosystem.config.js is present. Do you want to run it? (y/n, default: y): "
      choice=$(gum confirm && echo "e" || echo "n")
    fi
  elif [ -f "composer.json" ]; then
    choice="c"
  elif [ -f "package.json" ]; then
    if [ -f ".turbo" ] || [ -f "turbo.json" ]; then
        choice="t"
    else
        choice="p"
    fi
  elif [ -f ".turbo" ] || [ -f "turbo.json" ]; then
    choice="t"
  else
    echo "No supported configuration files found in the current directory."
    return 1
  fi

  # Execute based on the determined choice
  case "$choice" in
    p) run_package_json ;;
    e) eval "pm2 start ecosystem.config.js" ;;
    t) run_turbo ;;
    c) run_composer ;;
    n) echo "Skipping running ecosystem.config.js" ;;
    *)
      echo "Invalid choice. Please select a valid option."
      return 1
      ;;
  esac
}