#!/bin/zsh

# Directory containing zsh function files
ZSH_FUNCTION_DIR=~/.ezsh/functions

# Detect the operating system
OS_TYPE=$(uname)

# Source the .env file if it exists
if [ -f ~/.ezsh/.env ]; then
  source ~/.ezsh/.env
fi

# Source the .config file if it exists (for module loading control)
if [ -f ~/.ezsh/.config ]; then
  source ~/.ezsh/.config
else
  # Default to loading everything if no config file exists
  LOAD_GIT_FUNCTIONS=true
  LOAD_COMPILER_FUNCTIONS=true
  LOAD_DOCKER_FUNCTIONS=true
  LOAD_PSQL_FUNCTIONS=true
  LOAD_SSH_FUNCTIONS=true
  LOAD_TSC_FUNCTIONS=true
  LOAD_CODE_FUNCTIONS=true
  LOAD_COMMON_FUNCTIONS=true
  LOAD_MAC_FUNCTIONS=true
  LOAD_DYNAMIC_DNS=false
  LOAD_LPU_AUTOLOGIN=false
  LOAD_WIFINAME=true
  LOAD_MAC_UTILITIES=true
  LOAD_ASARAPP=true
  LOAD_CHECKSIZE=true
  LOAD_COMPARE_FOLDERS=true
  LOAD_MCODE=true
  LOAD_PRETTIERCONFIG=true
  LOAD_PRETTIFY=true
  LOAD_PTOG=true
  LOAD_RECUR=true
  LOAD_RUN=true
  VERBOSE_LOADING=false
  FAIL_SILENTLY=true
fi

# Helper function to check if a module should be loaded
should_load() {
  local category="$1"
  local file_path="$2"
  
  # Check category-based loading
  case "$category" in
    git)
      [[ "$LOAD_GIT_FUNCTIONS" == "true" ]] || return 1
      ;;
    compiler)
      [[ "$LOAD_COMPILER_FUNCTIONS" == "true" ]] || return 1
      ;;
    docker)
      [[ "$LOAD_DOCKER_FUNCTIONS" == "true" ]] || return 1
      ;;
    psql)
      [[ "$LOAD_PSQL_FUNCTIONS" == "true" ]] || return 1
      ;;
    ssh)
      [[ "$LOAD_SSH_FUNCTIONS" == "true" ]] || return 1
      ;;
    tsc)
      [[ "$LOAD_TSC_FUNCTIONS" == "true" ]] || return 1
      ;;
    code)
      [[ "$LOAD_CODE_FUNCTIONS" == "true" ]] || return 1
      ;;
    common)
      [[ "$LOAD_COMMON_FUNCTIONS" == "true" ]] || return 1
      ;;
    mac)
      # Mac has special handling for intrusive services
      [[ "$LOAD_MAC_FUNCTIONS" == "true" ]] || return 1
      
      # Check for intrusive services
      if [[ "$file_path" == *"dynamic_dns.sh" ]] && [[ "$LOAD_DYNAMIC_DNS" != "true" ]]; then
        return 1
      fi
      if [[ "$file_path" == *"lpu_captive_login.sh" ]] && [[ "$LOAD_LPU_AUTOLOGIN" != "true" ]]; then
        return 1
      fi
      if [[ "$file_path" == *"wifiname.sh" ]] && [[ "$LOAD_WIFINAME" != "true" ]]; then
        return 1
      fi
      # Other mac utilities
      if [[ "$file_path" == *"/mac/"* ]] && [[ "$LOAD_MAC_UTILITIES" != "true" ]]; then
        # Allow specific files even if utilities disabled
        if [[ "$file_path" != *"dynamic_dns.sh" ]] && \
           [[ "$file_path" != *"lpu_captive_login.sh" ]] && \
           [[ "$file_path" != *"wifiname.sh" ]]; then
          return 1
        fi
      fi
      ;;
  esac
  
  # Check individual file loading flags
  local basename=$(basename "$file_path" .sh)
  case "$basename" in
    asarapp)
      [[ "$LOAD_ASARAPP" == "true" ]] || return 1
      ;;
    checksize)
      [[ "$LOAD_CHECKSIZE" == "true" ]] || return 1
      ;;
    compare_folders)
      [[ "$LOAD_COMPARE_FOLDERS" == "true" ]] || return 1
      ;;
    mcode)
      [[ "$LOAD_MCODE" == "true" ]] || return 1
      ;;
    prettierconfig)
      [[ "$LOAD_PRETTIERCONFIG" == "true" ]] || return 1
      ;;
    prettify)
      [[ "$LOAD_PRETTIFY" == "true" ]] || return 1
      ;;
    ptog)
      [[ "$LOAD_PTOG" == "true" ]] || return 1
      ;;
    recur)
      [[ "$LOAD_RECUR" == "true" ]] || return 1
      ;;
    run)
      [[ "$LOAD_RUN" == "true" ]] || return 1
      ;;
  esac
  
  return 0
}

# Source all .sh files in the directory and its subdirectories
find $ZSH_FUNCTION_DIR -type f -name '*.sh' | while read file; do
  # Check if file is in a platform-specific folder
  if [[ "$file" == */mac/* && "$OS_TYPE" != "Darwin" ]]; then
    # Skip if file is in mac-specific folder but not on macOS
    continue
  elif [[ "$file" == */windows/* && "$OS_TYPE" != CYGWIN* && "$OS_TYPE" != MINGW* && "$OS_TYPE" != MSYS* ]]; then
    # Skip if file is in windows-specific folder but not on Windows
    continue
  fi
  
  # Determine category from path
  category=""
  if [[ "$file" == */git/* ]]; then
    category="git"
  elif [[ "$file" == */compiler/* ]]; then
    category="compiler"
  elif [[ "$file" == */docker/* ]]; then
    category="docker"
  elif [[ "$file" == */psql/* ]]; then
    category="psql"
  elif [[ "$file" == */ssh/* ]]; then
    category="ssh"
  elif [[ "$file" == */tsc/* ]]; then
    category="tsc"
  elif [[ "$file" == */code/* ]]; then
    category="code"
  elif [[ "$file" == */common/* ]]; then
    category="common"
  elif [[ "$file" == */mac/* ]]; then
    category="mac"
  fi
  
  # Check if we should load this file
  if should_load "$category" "$file"; then
    if [[ "$VERBOSE_LOADING" == "true" ]]; then
      echo "Loading: $file"
    fi
    
    if [[ "$FAIL_SILENTLY" == "true" ]]; then
      source "$file" 2>/dev/null || true
    else
      source "$file"
    fi
  elif [[ "$VERBOSE_LOADING" == "true" ]]; then
    echo "Skipping: $file"
  fi
done
