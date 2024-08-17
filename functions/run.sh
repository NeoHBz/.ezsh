run() {
  local package_manager="bun"
  local script_name="start"
  local choice

  if [ -f "ecosystem.config.js" ]; then
    if [ -f "package.json" ]; then
      echo "Both ecosystem.config.js and package.json are present. Which one do you want to run?"
      choice=$(gum choose {p,e})
    else
      echo "ecosystem.config.js is present. Do you want to run it? (y/n, default: y): "
    
      if gum confirm; then
        choice="e"
      else
        choice="n"
      fi
    fi
  elif [ -f "package.json" ]; then
    choice="p"
  else
    echo "Neither package.json nor ecosystem.config.js found in the current directory."
    return 1
  fi

  if [ "$choice" = "p" ]; then
    if [ -f "package.json" ]; then
      local dev_script_exists=$(jq -r '.scripts.dev' package.json)
      local start_script_exists=$(jq -r '.scripts.start' package.json)

      if [ "$dev_script_exists" != "null" ]; then
        script_name="dev"
      fi

      local command="$package_manager $script_name"
      eval "$command"
    else
      echo "package.json not found in the current directory."
      return 1
    fi
  elif [ "$choice" = "e" ]; then
    eval "pm2 start ecosystem.config.js"
  elif [ "$choice" = "n" ]; then
    echo "Skipping running ecosystem.config.js"
  else
    echo "Invalid choice. Please enter 'e' for ecosystem.config.js or 'p' for package.json."
    return 1
  fi
}