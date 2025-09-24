psql_teardown() {
  local user="" pass="" db=""

  usage(){ echo "Usage: psql_teardown -u user -p password -d database"; }

  while getopts "u:p:d:" opt; do
    case "$opt" in
      u) user="$OPTARG" ;;
      p) pass="$OPTARG" ;; # accepted but not used
      d) db="$OPTARG" ;;
      *) usage >&2; return 1 ;;
    esac
  done

  if [[ -z "$user" || -z "$db" ]]; then
    usage >&2
    return 1
  fi

  cat <<EOF
DROP DATABASE IF EXISTS $db;
DROP USER IF EXISTS $user;

-- Connection string:
-- postgresql://$user:[password]@localhost:5432/$db
EOF
}
