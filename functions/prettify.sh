function prettify() {
  local command

  if [ -z "$1" ]; then
    command="bunx prettier --write \"./**/*.{js,jsx,ts,tsx,json}\""
  else
    command="bunx prettier --write \"$1/**/*.{js,jsx,ts,tsx,json}\""
  fi

  eval "$command"
}