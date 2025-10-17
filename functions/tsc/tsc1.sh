tsc1() {
  local file=$1
  [[ -z "$file" ]] && { echo "Usage: tsc1 <path-to-file>"; return 1; }

  # set project root here
  local project_root="$HOME/Workspace/manifest_unified_prisma/manifest-mobile-app"

  local tmpfile=$(mktemp "$project_root/tsconfig.single.XXXXXX.json")
  jq --arg f "$file" '.include = [$f]' "$project_root/tsconfig.json" > "$tmpfile" &&
    bunx tsc -p "$tmpfile"
  rm -f "$tmpfile"
}
