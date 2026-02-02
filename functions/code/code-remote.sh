code-remote() {
    # Configuration file path
    local config_file="$HOME/.ezsh/.temp/.code-remote-config.json"
    local default_base_dir="/home"

    # Ensure the config file exists
    if [[ ! -f "$config_file" ]]; then
        mkdir -p "$(dirname "$config_file")"
        cat <<'EOF' > "$config_file"
{"last_host": null, "folders": {}}
EOF
    fi

    # Helper: Load values from JSON
    local last_host=$(jq -r '.last_host // empty' "$config_file")

    # Initialize variables
    local host=""
    local folder_override=""

    # Help message
    local help_msg="code-remote: Open VS Code in a remote SSH host
  
  Usage:
  code-remote                 - Display list of SSH hosts to choose from
  code-remote -H <host>       - Open VS Code for the specified remote host
  code-remote -f <folder>     - Override the base directory for the host
  code-remote -l              - Connect to the last used host
  code-remote -h              - Display this help message"

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -H) shift; host="$1" ;;             # Specify host
            -f) shift; folder_override="$1" ;;  # Override base directory
            -l) host="$last_host" ;;             # Connect to last used host
            -h) echo "$help_msg"; return ;;     # Display help message
            *) echo "Invalid argument: $1"; echo "$help_msg"; return 1 ;;
        esac
        shift
    done

    # If no host is specified, display a menu of SSH hosts
    if [[ -z "$host" ]]; then
        local hosts=$(awk '/^Host / {print $2}' ~/.ssh/config | grep -v '\*')
        if [[ -z "$hosts" ]]; then
            echo "No SSH hosts found in ~/.ssh/config."
            return 1
        fi
        host=$(echo "$hosts" | gum choose --no-show-help --header="Choose host:")
        if [[ -z "$host" ]]; then
            echo "No host selected."
            return 1
        fi
    fi

    # Retrieve or default to base directory
    if [[ -n "$folder_override" ]]; then
        base_dir="$folder_override"
    else
        base_dir=$(jq -r --arg host "$host" --arg default "$default_base_dir" '.folders[$host] // $default' "$config_file")
    fi

    # Save selected host and folder to the config file
    jq --arg host "$host" --arg base "$base_dir" '.last_host = $host | .folders[$host] = $base' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"

    # Open VS Code with the selected host and directory
    if [[ -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc"
    fi
    local vscode_cli=""
    for tool in code code-insiders; do
        local tool_path
        tool_path=$(whence -p "$tool" 2>/dev/null)
        if [[ -n "$tool_path" ]]; then
            vscode_cli="$tool_path"
            if [[ "$tool" == "code-insiders" ]]; then
                echo "Opening with code-insiders because the stable CLI was not found."
            fi
            break
        fi
    done
    if [[ -z "$vscode_cli" ]]; then
        echo "The VS Code CLI (code or code-insiders) is not installed or not in PATH."
        echo "Install it from VS Code (Command Palette → Shell Command: Install 'code' command in PATH)"
        return 127
    fi
    "$vscode_cli" --folder-uri "vscode-remote://ssh-remote+$host${base_dir}"
}
