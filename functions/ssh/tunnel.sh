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
  eval "$ssh_command"

  echo "Tunnel '$name' created: $local_part -> $remote_host:$remote_port"
}


# Kill tunnel function
kill_tunnel() {
  local name=$1
  if [[ -z "$name" ]]; then
    echo "Usage: kill_tunnel <name>"
    return 1
  fi

  # Kill the SSH tunnel using the unique ControlPath file for the tunnel
  if [[ -e "~/.ssh/sockets/tunnel_${name}" ]]; then
    ssh -O exit -o ControlPath="~/.ssh/sockets/tunnel_${name}" "$remote_host"
    echo "Tunnel '$name' has been killed."
  else
    echo "No active tunnel found with the name '$name'."
  fi
}

# Usage example
# create_tunnel my_tunnel 32400 32400
# kill_tunnel my_tunnel
