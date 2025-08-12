run() {
  local package_manager="bun"
  local file_arg="$1"
  local choice=""

  # Handle direct file execution if a file argument is provided
  if [ -n "$file_arg" ] && [ -f "$file_arg" ]; then
    local file_ext="${file_arg##*.}"
    
    # Run based on file extension
    case "$file_ext" in
      js)
        eval "node $file_arg"
        return 0
        ;;
      ts)
        eval "ts-node $file_arg"
        return 0
        ;;
      php)
        eval "php -S localhost:9999 $file_arg"
        return 0
        ;;
      json)
        # Set appropriate choice based on json file type
        if [[ "$file_arg" == *"package.json" ]]; then
          choice="p"
        elif [[ "$file_arg" == *"composer.json" ]]; then
          choice="c"
        else
          echo "Unsupported JSON file: $file_arg"
          return 1
        fi
        ;;
      js|cjs|mjs)
        # Check for ecosystem config file
        if [[ "$file_arg" == *"ecosystem.config."* ]]; then
          choice="e"
        else
          # Handle as a regular JavaScript file
          eval "node $file_arg"
          return 0
        fi
        ;;
      *)
        echo "Unsupported file type: $file_ext"
        return 1
        ;;
    esac
  fi

  # Determine which configuration to use if not already set
  if [ -z "$choice" ]; then
    # Check for ecosystem config files
    local ecosystem_file=""
    [ -f "ecosystem.config.js" ] && ecosystem_file="ecosystem.config.js"
    [ -f "ecosystem.config.cjs" ] && ecosystem_file="ecosystem.config.cjs"
    [ -f "ecosystem.config.mjs" ] && ecosystem_file="ecosystem.config.mjs"
    
    if [ -n "$ecosystem_file" ]; then
      if [ -f "package.json" ] || [ -f "composer.json" ] || [ -f ".turbo" ] || [ -f "turbo.json" ]; then
        # Build options list for user selection
        options=()
        [ -f "package.json" ] && options+=("package.json (p)")
        [ -f "composer.json" ] && options+=("composer.json (c)")
        ([ -f ".turbo" ] || [ -f "turbo.json" ]) && options+=(".turbo/turbo.json (t)")
        options+=("$ecosystem_file (e)")
        
        choice=$(gum choose "${options[@]}")
        choice=${choice:0:1}  # Get the first character of the choice
      else
        echo "$ecosystem_file is present. Do you want to run it? (y/n, default: y): "
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
  fi

  # Execute based on the determined choice
  case "$choice" in
    p)
      # Run package.json scripts
      if [ -f "package.json" ]; then
        for script in "dev" "start"; do
          if [ "$(jq -r ".scripts.$script != null" package.json)" = "true" ]; then
            eval "$package_manager $script"
            return 0
          fi
        done
      fi
      return 1
      ;;
    e) 
      # Run ecosystem config
      local ecosystem_file=""
      [ -f "ecosystem.config.js" ] && ecosystem_file="ecosystem.config.js"
      [ -f "ecosystem.config.cjs" ] && ecosystem_file="ecosystem.config.cjs"
      [ -f "ecosystem.config.mjs" ] && ecosystem_file="ecosystem.config.mjs"
      [ -n "$file_arg" ] && ecosystem_file="$file_arg"
      eval "pm2 start $ecosystem_file" 
      ;;
    t)
      # Run turbo build
      if [ -f ".turbo" ] || [ -f "turbo.json" ]; then
        eval "turbo run build"
        return 0
      fi
      return 1
      ;;
    c)
      # Run PHP Composer projects
      if [ -f "composer.json" ]; then
        # Try scripts in priority order
        for script in "serve" "start" "dev"; do
          if [ "$(jq -r ".scripts.$script != null" composer.json)" = "true" ]; then
            eval "composer $script"
            return 0
          fi
        done
        
        # Fallbacks if no scripts found
        if [ -f "artisan" ]; then
          eval "php artisan serve"
        else
          eval "php -S localhost:9999"
        fi
        return 0
      fi
      return 1
      ;;
    n)
      echo "Skipping running ecosystem.config.js"
      ;;
    *)
      echo "Invalid choice. Please select a valid option."
      return 1
      ;;
  esac
}