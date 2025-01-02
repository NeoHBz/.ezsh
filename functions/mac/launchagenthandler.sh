launchagenthandler() {
    local base_dir="$HOME/.zsh/services/mac"
    local launch_agents_dir="$HOME/Library/LaunchAgents"
    case "$1" in
        loadall)
            # Load all plist files from ./services/mac
            echo "Loading all services..."
            for service_dir in "$base_dir"/*; do
                if [[ -d "$service_dir" ]]; then
                    local service_name=$(basename "$service_dir")
                    local plist_source="$service_dir/$service_name.plist"
                    local plist_target="$launch_agents_dir/com.ezsh.$service_name.plist"
                    echo -n "Loading $service_name..."
                    if [[ -f "$plist_source" ]]; then
                        cp "$plist_source" "$plist_target"
                        launchctl load "$plist_target"
                        echo "Loaded $plist_target"
                    else
                        echo "Plist file not found for $service_name"
                    fi
                fi
            done
            ;;

        unloadall)
            # Unload and remove all com.ezsh.*.plist files
            for plist_file in "$launch_agents_dir"/com.ezsh.*.plist; do
                if [[ -f "$plist_file" ]]; then
                    launchctl unload "$plist_file"
                    rm "$plist_file"
                    echo "Unloaded and removed $plist_file"
                fi
            done
            ;;

        load)
            # Load a single plist file
            local service_name="$2"
            local plist_source="$base_dir/$service_name/$service_name.plist"
            local plist_target="$launch_agents_dir/com.ezsh.$service_name.plist"

            if [[ -f "$plist_source" ]]; then
                cp "$plist_source" "$plist_target"
                launchctl load "$plist_target"
                echo "Loaded $plist_target"
            else
                echo "Plist file not found for $service_name"
            fi
            ;;

        unload)
            # Unload a single plist file
            local service_name="$2"
            local plist_target="$launch_agents_dir/com.ezsh.$service_name.plist"

            if [[ -f "$plist_target" ]]; then
                launchctl unload "$plist_target"
                rm "$plist_target"
                echo "Unloaded and removed $plist_target"
            else
                echo "Plist file not found for $service_name"
            fi
            ;;

        list)
            # List all plist files in the LaunchAgents directory
            echo "Listing all plist files in $launch_agents_dir:"
            ls -1 "$launch_agents_dir"/*.plist 2>/dev/null || echo "No plist files found."
            ;;

        active)
            # List locations of all active plist files
            echo "Listing all active plist files:"
            launchctl list | awk '{print $3}' | grep -E '\.plist$' || echo "No active plist files found."
            ;;

        *)
            echo "Usage: launchagenthandler {loadall|unloadall|load <filename>|unload <filename>}"
            ;;
    esac
}
