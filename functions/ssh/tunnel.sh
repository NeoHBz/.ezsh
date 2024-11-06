# Create tunnel function
create_tunnel() {
  local name=$1
  local remote_port=$2
  local host_port=$3
  local remote_host="oracle"  # Replace with your actual remote host alias from ~/.ssh/config

  if [[ -z "$name" || -z "$remote_port" || -z "$host_port" ]]; then
    echo "Usage: create_tunnel <name> <remote_port> <host_port>"
    return 1
  fi

  # Check if the local port is already in use
  if lsof -i :$host_port &>/dev/null; then
    echo "Port $host_port is already in use on the local host."
    return 1
  fi

  # Ensure the tunnel socket directory exists
  mkdir -p ~/.ssh/sockets

  # Split the -L argument into substrings
  local local_part="localhost:$host_port"
  local remote_part="localhost:$remote_port"

  # Concatenate the components to form the full SSH command
  local ssh_command="ssh -f -N -L $local_part:$remote_part $remote_host -o ControlPath=~/.ssh/sockets/tunnel_${name}"

  # Echo the command for verification
  echo "About to execute the following SSH command:"
  echo "$ssh_command"
  
  # Wait for user input to continue
  echo "Press Enter to execute the command or Ctrl+C to cancel..."
  read

  # Execute the SSH command
  eval "$ssh_command" &>/dev/null

  echo "Tunnel '$name' created: $local_part -> $remote_host:$remote_port"
}


# Kill tunnel function
kill_tunnel() {
  local name=$1
  local remote_host="oracle"  # Use the same host name you defined in ~/.ssh/config

  if [[ -z "$name" ]]; then
    echo "Usage: kill_tunnel <name>"
    return 1
  fi

  # Define the control path with full expansion
  local control_path="$HOME/.ssh/sockets/tunnel_${name}"
  echo $control_path
  # Check if the control path (socket) exists
  if [[ ! -S $control_path ]]; then
    echo "No active tunnel found with the name '$name'."
    return 1
  fi

  # Send the exit command to the SSH session
#   ssh -O exit -o ControlPath="$control_path" "$remote_host"
  local ssh_command="ssh -O exit -o ControlPath=$control_path $remote_host"

  # Echo the command for verification
  echo "About to execute the following SSH command:"
  echo "$ssh_command"
  
  # Wait for user input to continue
  echo "Press Enter to execute the command or Ctrl+C to cancel..."
  read

  # Execute the SSH command
  eval "$ssh_command" &>/dev/null
  # Confirm tunnel termination and clean up
  if [[ $? -eq 0 ]]; then
    echo "Tunnel '$name' terminated successfully."
    rm -f "$control_path"
  else
    echo "Failed to terminate the tunnel '$name'."
  fi
}
