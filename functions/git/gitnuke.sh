function gitnuke() {
  # Get the name of the current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  # Delete all branches except the current branch, main, and dev
  # WARNING: THIS IS FATAL AND NON-REVERSIBLE, DATA LOSS IS POSSIBLE
  git branch | grep -v 'dev\|main\|'"$current_branch" | xargs git branch -D
}
