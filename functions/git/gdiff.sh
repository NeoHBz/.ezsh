gdiff() {
  # Verify inside git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository." >&2
    return 1
  fi

  local args=()
  local exceptions=()
  local parsing_exceptions=false

  for arg in "$@"; do
    if [[ "$arg" == "--except" ]]; then
      parsing_exceptions=true
    elif $parsing_exceptions; then
      exceptions+=("$arg")
    else
      args+=("$arg")
    fi
  done

  # Build exclusion pathspecs for tracked files
  local pathspecs=("--diff-filter=d" "--")
  for ex in "${exceptions[@]}"; do
    pathspecs+=(":!$ex")
  done

  # Single clean diff for tracked files
  git --no-pager diff "${args[@]}" "${pathspecs[@]}"

  # Untracked files (excluding exceptions)
  git ls-files --others --exclude-standard | while read -r file; do
    [[ -z "$file" ]] && continue
    
    # Skip files modified in the last 2 seconds that contain "diff --git" 
    # (likely output redirection of this command)
    if [[ -f "$file" ]]; then
      local file_age=$(($(date +%s) - $(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)))
      if [[ $file_age -lt 2 ]] && grep -q "^diff --git" "$file" 2>/dev/null; then
        continue
      fi
    fi
    
    for ex in "${exceptions[@]}"; do
      [[ "$file" == "$ex" ]] && continue 2
    done
    echo
    echo "# Untracked: $file"
    git --no-pager diff --no-index /dev/null "$file"
  done
}
