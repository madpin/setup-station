
# Function: madrebase
# Purpose: Rebase the current branch onto master and optionally force push the changes.
#          This script prevents rebasing the master branch onto itself, fetches latest
#          changes from master first and gracefully handles merge conflicts during rebase.
# Usage: Run 'madrebase' in your git repository's root directory.
# Return: 0 if successful, 1 if operation fails, or user aborts from a question.
#
# Performance: This script's performance is primarily constrained by the speed of the
#              git commands it executes. For large repositories, `git fetch`, `git rebase` and
#             `git push` could take time.
#
# Resource Usage: This script uses minimal system resources because it mostly calls git
#             and outputs to the console,  Memory usage is low.
madrebase() {
  # --- Initialization & Logging ---

  # Set script debug mode flag
  declare -i debug_mode=0
  # If you want to turn on debug mode, set debug_mode=1 before calling the function

  # Function to print messages based on the debugging mode
  # Parameter 1: Message to log
  # Parameter 2: (Optional) Log level [info (default)|debug|error]
  log_message() {
      local message="$1"
      local level="${2:-info}"
      
      if [[ "$level" == "debug" ]]; then
          if [[ "$debug_mode" -eq 1 ]]; then
            echo "[madrebase - DEBUG] $message"
          fi
      elif [[ "$level" == "error" ]]; then
        echo "[madrebase - ERROR] $message" >&2 # output to STDERR
      else # info is default
          echo "[madrebase - INFO] $message" # output to STDOUT
      fi
  }


  # Save the current branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  log_message "Starting madrebase on branch: $current_branch" debug
  
  # --- Validation ---

  # Check if the current branch is master and abort
  if [[ "$current_branch" = "master" ]]; then
    log_message "Cannot rebase master onto itself. Aborting." error
    return 1
  fi
  
  # check that we are running in a git repo
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_message "Not inside a git working tree. Aborting." error
    return 1
  fi

  # --- Fetching Latest Master ---

  log_message "Fetching the latest changes from origin/master..." debug
  if ! git fetch origin master:master; then
    log_message "Failed to fetch from origin. Aborting." error
    return 1
  fi
  log_message "Successfully fetched the latest changes from origin/master." debug
  
  # --- Rebase Operations ---
  
  log_message "Attempting to rebase $current_branch onto master..." debug
  # Attempt interactive rebase using GIT_SEQUENCE_EDITOR to skip editor launch
  GIT_SEQUENCE_EDITOR=":" git rebase -i master
    
  # Check if rebase was successful
  if [[ $? -eq 0 ]]
  then
      log_message "Rebase successful." debug    

    # --- Prompt for force push ---
    read -r -p "Rebase successful. Force push? (y/N) " REPLY
    log_message "User input: $REPLY" debug

    # force push if 'y/Y'
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      log_message "Force pushing changes to origin/$current_branch..." debug
      # Force push with lease for safety
      if ! git push origin "$current_branch" --force-with-lease; then
        log_message "Force push failed. Aborting." error
        return 1
      fi
        
      log_message "Force push successful!"
    else
        log_message "Aborted push."
    fi

  else
    
    log_message "Merge conflict detected. Reverting rebase..." error
    # Attempt to abort rebase
    if ! git rebase --abort; then
      log_message "Failed to abort rebase. You may need to resolve the conflicts manually." error
      
    fi
    log_message "Rebase aborted successfully. Changes reverted to state before rebase attempt."
    return 1

  fi
  
  log_message "madrebase completed successfully." 
  return 0
}


# Function: madpush
# Purpose: Push the current branch to the remote repository.
# Usage: Run 'madpush' in your git repository's root directory.
# Return: 0 if successful, 1 if operation fails.
madpush() {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  git push origin "$current_branch" --force-with-lease
}