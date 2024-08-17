function gcm () {
  if git show-ref --verify --quiet refs/heads/master; then
    git checkout master
  else
    git checkout main
  fi
}