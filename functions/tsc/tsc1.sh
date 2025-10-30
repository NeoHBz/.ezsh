tsc1 () {
  local file=$1 
  [[ -z "$file" ]] && {
    echo "Usage: tsc1 <path-to-file>"
    return 1
  }

  local project_root="$HOME/Workspace/manifest_unified_prisma/manifest-mobile-app"
  local tmpfile
  tmpfile=$(mktemp "$project_root/tsconfig.single.XXXXXX.json")

  # Use absolute path so tsc can find the file
  jq --arg f "$(realpath "$file")" '.include = [$f]' "$project_root/tsconfig.json" > "$tmpfile"

  bunx tsc -p "$tmpfile"
  rm -f "$tmpfile"
}
