psql_setup() {
  local user="" pass="" db="" conn="" host="localhost" port="5432"

  usage(){ echo "Usage: psql_setup [-u user -p password -d database [-c connstring]]"; }

  if [[ $# -eq 0 ]]; then
    echo "This will create a new Postgres user + database."
    echo "You can cancel anytime with Ctrl-C."
    echo

    echo -n "Username: "; read user
    echo -n "Password: "; read -s pass; echo
    echo -n "Database name: "; read db
    echo -n "Connection string (postgresql://host[:port] or leave blank for localhost:5432): "; read conn
  else
    while getopts "u:p:d:c:" opt; do
      case "$opt" in
        u) user="$OPTARG" ;;
        p) pass="$OPTARG" ;;
        d) db="$OPTARG" ;;
        c) conn="$OPTARG" ;;
        *) usage >&2; return 1 ;;
      esac
    done
  fi

  if [[ -z "$user" || -z "$pass" || -z "$db" ]]; then
    usage >&2
    return 1
  fi

  if [[ -z "$conn" ]]; then
    conn=""
    host="localhost"
    port="5432"
  fi

  conn="postgresql://${user}:${pass}@${host}:${port}/${db}"

  # Colors
  local GREEN_BOLD="\033[1;32m"
  local RESET="\033[0m"

  # Separate prefix from details and color only details
  local prefix="postgresql://"
  local details="${user}:${pass}@${host}:${port}/${db}"

  echo -e "Connection string for new DB: ${GREEN_BOLD}${prefix}${details}${RESET}" >&2

  cat <<EOF
CREATE USER $user WITH PASSWORD '$pass';
CREATE DATABASE $db OWNER $user;
GRANT ALL PRIVILEGES ON DATABASE $db TO $user;
EOF
}
