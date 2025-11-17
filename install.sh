#!/bin/zsh

inject_load_script() {
  ZSHRC_FILE="$HOME/.zshrc"
  LOAD_SCRIPT_LINE='source ~/.ezsh/load.sh'

  # Display the command to be added
  echo "The following line will be added to $ZSHRC_FILE:"
  echo "$LOAD_SCRIPT_LINE"
  
  # Prompt for confirmation
  read -p "Confirm adding this line? (y/n): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    # Check if the line is already in the .zshrc file
    if ! grep -Fxq "$LOAD_SCRIPT_LINE" "$ZSHRC_FILE"; then
      # Append the line to .zshrc
      echo "" >> "$ZSHRC_FILE"
      echo "$LOAD_SCRIPT_LINE" >> "$ZSHRC_FILE"
      echo "" >> "$ZSHRC_FILE"
      echo "Added line to $ZSHRC_FILE"
    else
        grep -nFx "$LOAD_SCRIPT_LINE" "$ZSHRC_FILE" | awk -F: '{print "Line already present in $ZSHRC_FILE at line " $1}'
    fi
  else
    echo "Operation cancelled by user"
  fi
}

# Call the function
inject_load_script
