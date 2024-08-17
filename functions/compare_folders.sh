function compare_folders() {
  local folder1="$1"
  local folder2="$2"

  if [[ ! -d "$folder1" || ! -d "$folder2" ]]; then
    echo "Both arguments must be directories"
    return 1
  fi

  # Create output directories
  mkdir -p output/"$folder1"/extra output/"$folder1"/missing output/"$folder2"/extra output/"$folder2"/missing

  # Get sorted lists of files in each folder
  local files1=$(find "$folder1" -type f | sed "s|^$folder1/||" | sort)
  local files2=$(find "$folder2" -type f | sed "s|^$folder2/||" | sort)

  # Compare the file lists
  local diff_output=$(diff <(echo "$files1") <(echo "$files2"))

  echo "Comparing $folder1 and $folder2"

  # Process diff output
  echo "$diff_output" | while read -r line; do
    case "$line" in
      "< "*)
        local file="${line#< }"
        echo "Extra file in $folder1: $file"
        mkdir -p "output/$folder1/extra/$(dirname "$file")"
        cp "$folder1/$file" "output/$folder1/extra/$file"
        ;;
      "> "*)
        local file="${line#> }"
        echo "Extra file in $folder2: $file"
        mkdir -p "output/$folder2/extra/$(dirname "$file")"
        cp "$folder2/$file" "output/$folder2/extra/$file"
        ;;
    esac
  done

  # For better readability, also list missing files explicitly
  echo "Missing files in $folder1 compared to $folder2:"
  echo "$files2" | while read -r file; do
    if ! echo "$files1" | grep -q "^$file$"; then
      echo "$file"
      mkdir -p "output/$folder1/missing/$(dirname "$file")"
      cp "$folder2/$file" "output/$folder1/missing/$file"
    fi
  done

  echo "Missing files in $folder2 compared to $folder1:"
  echo "$files1" | while read -r file; do
    if ! echo "$files2" | grep -q "^$file$"; then
      echo "$file"
      mkdir -p "output/$folder2/missing/$(dirname "$file")"
      cp "$folder1/$file" "output/$folder2/missing/$file"
    fi
  done
}