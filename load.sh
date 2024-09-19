#!/bin/zsh

# Directory containing zsh function files
ZSH_FUNCTION_DIR=~/.zsh/functions

# Detect the operating system
OS_TYPE=$(uname)

# Source the .env file if it exists
if [ -f ~/.zsh/.env ]; then
  source ~/.zsh/.env
fi

# Source all .sh files in the directory and its subdirectories
for file in $(find $ZSH_FUNCTION_DIR -type f \( -name '*.sh' -o -name '*.zsh' \)); do
  # Check if file is in a platform-specific folder
  if [[ "$file" == *"/mac/" && "$OS_TYPE" != "Darwin" ]]; then
    # Skip if file is in mac-specific folder but not on macOS
    continue
  elif [[ "$file" == *"/windows/" && "$OS_TYPE" != *"CYGWIN"* && "$OS_TYPE" != *"MINGW"* && "$OS_TYPE" != "MSYS"* ]]; then
    # Skip if file is in windows-specific folder but not on Windows
    continue
  fi
  # Source the file
  source "$file"
done
