log "INFO" "Sourcing VS Code configurations..."

fix-code() {
  socket=$(ls -1t /run/user/$UID/vscode-ipc-*.sock 2>/dev/null | head -1)
  export VSCODE_IPC_HOOK_CLI=${socket}
}

code-git-diff-master() {
  log "INFO" "Opening git diff in VS Code..."

  # Make sure we're inside a Git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Error" "Not inside a Git repository."
    return 1
  fi

  # Get main or master branch
  BRANCH=$(git branch --list main master | tr -d ' ' | head -n 1)
  if [ -z "$BRANCH" ]; then
    echo "No valid main or master branch found."
    return 1
  fi

  # Get current branch name and build diff
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  git diff "$BRANCH"..."$CURRENT_BRANCH" > /tmp/diff.txt

  # Check if diff is empty
  if [ ! -s /tmp/diff.txt ]; then
    echo "No changes to show."
    return 0
  fi

  code /tmp/diff.txt
}

code-git-diff-remote() {
  log "INFO" "Opening staged git diff with remote in VS Code..."

  # Check if we're inside a Git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Error" "Not inside a Git repository."
    return 1
  fi

  # Determine current branch and default remote branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  remote_branch="origin/$branch"
  default_branch=$([ -n "$(git rev-parse --verify --quiet origin/main)" ] && echo "origin/main" || echo "origin/master")

  git diff --staged $([ -n "$(git rev-parse --verify --quiet "$remote_branch")" ] && echo "$remote_branch" || echo "$default_branch") > /tmp/diff.txt

  # Check if diff is empty
  if [ ! -s /tmp/diff.txt ]; then
    echo "No staged changes to show."
    return 0
  fi

  code /tmp/diff.txt
}

