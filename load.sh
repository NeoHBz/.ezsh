#!/bin/zsh

# Directory containing zsh function files
ZSH_FUNCTION_DIR=~/.ezsh/functions

# Detect the operating system
OS_TYPE=$(uname)

# Source the .env file if it exists
if [ -f ~/.ezsh/.env ]; then
  source ~/.ezsh/.env
fi

# Source the .config file if it exists (for service control only)
if [ -f ~/.ezsh/.config ]; then
  source ~/.ezsh/.config
fi

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
  
  # Source the file (fail silently by default)
  source "$file" 2>/dev/null || true
done
