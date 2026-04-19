#!/bin/zsh

# Directory containing zsh function files
ZSH_FUNCTION_DIR=~/.ezsh/functions

# Detect the operating system
OS_TYPE=$(uname)

is_supported_platform_file() {
  local file="$1"

  if [[ "$file" == */mac/* && "$OS_TYPE" != "Darwin" ]]; then
    return 1
  fi

  if [[ "$file" == */windows/* && "$OS_TYPE" != CYGWIN* && "$OS_TYPE" != MINGW* && "$OS_TYPE" != MSYS* ]]; then
    return 1
  fi

  return 0
}

# Source the .env file if it exists
if [ -f ~/.ezsh/.env ]; then
  source ~/.ezsh/.env
fi

# Source the .config file if it exists (for service control only)
if [ -f ~/.ezsh/.config ]; then
  source ~/.ezsh/.config
fi

typeset -a source_files
typeset -a preflight_errors

# Build deterministic file list first.
while IFS= read -r file; do
  if is_supported_platform_file "$file"; then
    source_files+=("$file")
  fi
done < <(find "$ZSH_FUNCTION_DIR" -type f -name '*.sh' | sort)

# Preflight phase: validate syntax first, so sourcing starts only if all files pass.
for file in "${source_files[@]}"; do
  if ! zsh -n "$file" >/dev/null 2>&1; then
    preflight_errors+=("$file")
  fi
done

if (( ${#preflight_errors[@]} > 0 )); then
  echo "load.sh preflight failed; no function files were sourced:" >&2
  for file in "${preflight_errors[@]}"; do
    echo "  - $file" >&2
  done
  return 1
fi

# Apply phase: source files now that preflight succeeded.
for file in "${source_files[@]}"; do
  source "$file" 2>/dev/null || true
done
