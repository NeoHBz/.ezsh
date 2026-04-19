#!/bin/zsh

inject_load_script() {
  local ZSHRC_FILE="$HOME/.zshrc"
  local LOAD_SCRIPT_LINE='source ~/.ezsh/load.sh'
  local tmp_file=""

  # Display the command to be added
  echo "The following line will be added to $ZSHRC_FILE:"
  echo "$LOAD_SCRIPT_LINE"
  
  # Prompt for confirmation
  printf "Confirm adding this line? (y/n): "
  local confirm
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    # Atomic write: stage changes in a temporary file, then move into place.
    tmp_file=$(mktemp "${ZSHRC_FILE}.XXXXXX") || {
      echo "Failed to create temporary file."
      return 1
    }

    if [ -f "$ZSHRC_FILE" ]; then
      cp "$ZSHRC_FILE" "$tmp_file" || {
        rm -f "$tmp_file"
        echo "Failed to prepare staged .zshrc update."
        return 1
      }
    fi

    # Check if the line is already in the .zshrc file
    if ! grep -Fxq "$LOAD_SCRIPT_LINE" "$tmp_file" 2>/dev/null; then
      # Append to staged file, then commit the file atomically.
      printf "\n%s\n\n" "$LOAD_SCRIPT_LINE" >> "$tmp_file"
      if mv "$tmp_file" "$ZSHRC_FILE"; then
        tmp_file=""
      else
        rm -f "$tmp_file"
        echo "Failed to commit .zshrc update."
        return 1
      fi
      echo "Added line to $ZSHRC_FILE"
    else
      local line_number
      line_number=$(grep -nFx "$LOAD_SCRIPT_LINE" "$tmp_file" | head -n1 | cut -d: -f1)
      rm -f "$tmp_file"
      echo "Line already present in $ZSHRC_FILE at line $line_number"
    fi
  else
    echo "Operation cancelled by user"
  fi
}

# Call the function
inject_load_script
