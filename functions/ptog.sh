ptog() {
  if pm2 list | grep -q online; then
    pm2 stop all
  else
    pm2 start all
  fi
}