#!/bin/zsh

# Directory containing zsh function files
ZSH_FUNCTION_DIR=~/.zsh/functions

# Source all .sh files in the directory and its subdirectories
for file in $(find $ZSH_FUNCTION_DIR -type f -name '*.sh' -o -name '*.zsh'); do
  source "$file"
done
