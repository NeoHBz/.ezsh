#!/bin/zsh

set -u
set -o pipefail

log() {
  printf '[install_deps] %s\n' "$1"
}

warn() {
  printf '[install_deps][warn] %s\n' "$1" >&2
}

err() {
  printf '[install_deps][error] %s\n' "$1" >&2
}

print_error_report_and_exit() {
  local failures_count="$1"
  shift
  local -a failures=("$@")

  err "Installation failed with ${failures_count} error(s)."
  printf '\n[install_deps] Failure report:\n' >&2
  for failure in "${failures[@]}"; do
    printf '  - %s\n' "$failure" >&2
  done
  exit 1
}

run_with_error_capture() {
  local label="$1"
  shift

  local tmp_err
  tmp_err=$(mktemp)
  if "$@" 2>"$tmp_err"; then
    rm -f "$tmp_err"
    return 0
  fi

  local captured_err
  captured_err=$(tr '\n' ' ' < "$tmp_err" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')
  rm -f "$tmp_err"

  if [[ -z "$captured_err" ]]; then
    captured_err="command exited with non-zero status"
  fi

  LAST_ERROR="${label}: ${captured_err}"
  return 1
}

if [[ "$(uname)" != "Darwin" ]]; then
  warn "This installer currently targets macOS/Homebrew only."
  warn "Install dependencies manually on your platform."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew is required but not installed."
  warn "Install Homebrew from https://brew.sh and re-run this script."
  exit 1
fi

typeset -a failures
typeset -a brew_required_missing
typeset -a brew_optional_missing
typeset -a npm_global_missing
LAST_ERROR=""

# Commands used directly by scripts/aliases in this workspace.
brew_required=(
  git
  jq
  tree
  gum
  bun
  node
  composer
  php
)

# Useful extras detected in workspace usage (optional paths/features).
brew_optional=(
  docker
  parallel
  coreutils
)

log "Phase 1/3: Planning installation (no changes yet)..."

for pkg in "${brew_required[@]}"; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    log "Already installed: $pkg"
  else
    brew_required_missing+=("$pkg")
  fi
done

for pkg in "${brew_optional[@]}"; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    log "Already installed: $pkg"
  else
    brew_optional_missing+=("$pkg")
  fi
done

if command -v npm >/dev/null 2>&1; then
  npm_global_required=(
    pm2
    turbo
    ts-node
    typescript
  )

  for pkg in "${npm_global_required[@]}"; do
    if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
      log "Already installed globally: $pkg"
    else
      npm_global_missing+=("$pkg")
    fi
  done
else
  warn "npm not found. Skipping npm global packages (pm2, turbo, ts-node, typescript)."
fi

log "Updating Homebrew metadata..."
if ! run_with_error_capture "brew update" brew update; then
  failures+=("$LAST_ERROR")
  print_error_report_and_exit "${#failures[@]}" "${failures[@]}"
fi

log "Phase 2/3: Installing required dependencies atomically (fail-fast)..."
for pkg in "${brew_required_missing[@]}"; do
  log "Installing required package: $pkg"
  if ! run_with_error_capture "brew install $pkg" brew install "$pkg"; then
    failures+=("$LAST_ERROR")
    print_error_report_and_exit "${#failures[@]}" "${failures[@]}"
  fi
done

log "Phase 3/3: Installing optional dependencies and npm globals..."

for pkg in "${brew_optional_missing[@]}"; do
  log "Installing optional package: $pkg"
  if ! run_with_error_capture "brew install (optional) $pkg" brew install "$pkg"; then
    failures+=("$LAST_ERROR")
  fi
done

if command -v npm >/dev/null 2>&1; then
  log "Installing required npm global packages..."
  for pkg in "${npm_global_missing[@]}"; do
    log "Installing global npm package: $pkg"
    if ! run_with_error_capture "npm install -g $pkg" npm install -g "$pkg"; then
      failures+=("$LAST_ERROR")
    fi
  done
fi

if (( ${#failures[@]} > 0 )); then
  print_error_report_and_exit "${#failures[@]}" "${failures[@]}"
fi

log "Done."
log "Tip: if VS Code CLI is needed, ensure code/code-insiders is installed in PATH from VS Code shell command setup."
