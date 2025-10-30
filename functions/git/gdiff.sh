gdiff() {
  git --no-pager diff "$@"
  git ls-files --others --exclude-standard | while read -r file; do
    echo "\n# Untracked: $file"
    git --no-pager diff --no-index /dev/null "$file"
  done
}
