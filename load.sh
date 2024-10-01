#!/bin/zsh

# Directory containing zsh function files
ZSH_FUNCTION_DIR=~/.zsh/functions
# ZSH_FUNCTION_DIR=~/.zsh/sandbox

OS_TYPE=$(uname)

if [ -f ~/.zsh/.env ]; then
  source ~/.zsh/.env
fi

find $ZSH_FUNCTION_DIR -type f \( -name '*.sh' -o -name '*.zsh' \) | while read file; do
  if [[ "$file" == */mac/* && "$OS_TYPE" != "Darwin" ]]; then
    continue
  elif [[ "$file" == */windows/* && "$OS_TYPE" != CYGWIN* && "$OS_TYPE" != MINGW* && "$OS_TYPE" != MSYS* ]]; then
    continue
  fi

  # Get the relative path from the function directory
  relative_path="${file#$ZSH_FUNCTION_DIR/}"

  if [[ "$relative_path" == */* ]]; then
    prefix_path="${relative_path#*/}"
    prefix_path="${prefix_path%/*}"
    prefix=$(echo "$prefix_path" | tr '/' '_')

    source "$file"

    function_name=$(basename "$file" .sh)

    # Check if the file contains a function
    if grep -q "^$function_name() {" "$file"; then
      # Read the entire file content
      function_body=$(<"$file")

      # Extract the content inside the function (removing the function definition)
      function_body=$(echo "$function_body" | sed -n "/^$function_name() {/,/^}/p" | sed '1d;$d')

      # Construct the prefixed function to directly execute the body
      eval "${prefix}${function_name}() { $function_body }"

      unset -f "${function_name}"
    else
      # For non-function files (aliases, variables), source them directly
      source "$file"
    fi
  else
    source "$file"
  fi
done
