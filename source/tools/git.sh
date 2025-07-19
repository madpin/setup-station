#!/bin/bash

# Function: madrebase
# Purpose: Detects the primary branch (main or master), fetches its latest changes,
#          rebases the current branch onto it, and optionally force pushes the changes.
#          This script prevents rebasing the primary branch onto itself and gracefully
#          handles merge conflicts during rebase.
# Usage: Run 'madrebase' in your git repository's root directory.
#        Use 'madrebase --force' to automatically resolve conflicts by accepting the
#        primary branch version (will show conflicted files and ask for confirmation).
# Return: 0 if successful, 1 if operation fails, user aborts, or primary branch not found.
#
# Performance: Performance is primarily constrained by git command speed (`Workspace`, `rebase`, `push`).
#
# Resource Usage: Minimal system resources used (mostly calls git).
madrebase() {
  # --- Argument Parsing ---
  local force_mode=0
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --force)
        force_mode=1
        shift
        ;;
      *)
        log_message "Unknown argument: $1" error
        log_message "Usage: madrebase [--force]" error
        return 1
        ;;
    esac
  done

  # --- Initialization & Logging ---

  # Set script debug mode flag (set to 1 externally if needed)
  declare -i debug_mode=${madrebase_debug_mode:-0} # Allow setting via environment variable

  # Color codes for terminal output
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local BLUE='\033[0;34m'
  local PURPLE='\033[0;35m'
  local CYAN='\033[0;36m'
  local GRAY='\033[0;90m'
  local BOLD='\033[1m'
  local NC='\033[0m' # No Color

  # Function to print messages based on the debugging mode
  log_message() {
      local message="$1"
      local level="${2:-info}" # Default log level is info

      if [[ "$level" == "debug" ]]; then
          if [[ "$debug_mode" -eq 1 ]]; then
            # Use printf for better control and consistency
            printf "${GRAY}[madrebase - DEBUG]${NC} %s\n" "$message"
          fi
      elif [[ "$level" == "error" ]]; then
        # Print errors to stderr
        printf "${RED}[madrebase - ERROR]${NC} %s\n" "$message" >&2
      elif [[ "$level" == "success" ]]; then
        # Print success messages in green
        printf "${GREEN}[madrebase - SUCCESS]${NC} %s\n" "$message"
      elif [[ "$level" == "warning" ]]; then
        # Print warnings in yellow
        printf "${YELLOW}[madrebase - WARNING]${NC} %s\n" "$message"
      elif [[ "$level" == "force" ]]; then
        # Print force mode messages in purple/magenta
        printf "${PURPLE}[madrebase - FORCE]${NC} %s\n" "$message"
      else # info is default
          # Print info messages in blue
          printf "${CYAN}[madrebase - INFO]${NC} %s\n" "$message"
      fi
  }

  # Helper function to read a single character (bash and zsh compatible)
  read_one_char() {
    # $1: name of variable to set
    local __resultvar=$1
    local char
    if [ -n "$ZSH_VERSION" ]; then
      # zsh: use -k 1 to read a single character
      read -k 1 char
    else
      # bash: use -n 1 -r
      read -n 1 -r char
    fi
    # move to new line
    echo
    # assign to variable
    eval $__resultvar="\$char"
  }

  # Function to handle conflict resolution in force mode
  handle_force_resolution() {
    local primary_branch="$1"
    
    # Check if we're in a rebase state with conflicts
    if ! git status --porcelain | grep -q "^UU\|^AA\|^DD\|^AU\|^UA\|^DU\|^UD"; then
      log_message "No merge conflicts detected in current state." debug
      return 1
    fi
    
    # Get list of conflicted files
    local conflicted_files
    conflicted_files=$(git status --porcelain | grep "^UU\|^AA\|^DD\|^AU\|^UA\|^DU\|^UD" | cut -c4-)
    
    if [[ -z "$conflicted_files" ]]; then
      log_message "No conflicted files found." debug
      return 1
    fi
    
    log_message "The following files have conflicts and would be overwritten with the $primary_branch version:" force
    echo "$conflicted_files" | while IFS= read -r file; do
      printf "  - %s\n" "$file"
    done
    
    printf "${PURPLE}[madrebase - FORCE]${NC} Accept %s version for ALL conflicted files? (y/N) " "$primary_branch"
    local user_input
    read_one_char user_input
    
    log_message "User input for force resolution: '$user_input'" debug
    
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
      log_message "Resolving conflicts by accepting $primary_branch version..." debug
      
      # Resolve conflicts by accepting theirs (the primary branch version)
      while IFS= read -r file; do
        if [[ -z "$file" ]]; then
          continue
        fi
        if ! git checkout --theirs "$file"; then
          log_message "Failed to resolve conflict for file: $file" error
          return 1
        fi
        if ! git add "$file"; then
          log_message "Failed to stage resolved file: $file" error
          return 1
        fi
        log_message "Resolved conflict for: $file (accepted $primary_branch version)" debug
      done <<< "$conflicted_files"
      
      log_message "All conflicts resolved. Continuing rebase..."
      if ! git rebase --continue; then
        log_message "Failed to continue rebase after conflict resolution." error
        return 1
      fi
      
      log_message "Force resolution completed successfully!" success
      return 0
    else
      log_message "Force resolution aborted by user."
      return 1
    fi
  }

  # --- Pre-checks ---
  # Check that we are running in a git repo first
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_message "Not inside a git working tree. Aborting." error
    return 1
  fi

  # --- Determine Primary Branch (main or master) ---
  local primary_branch=""
  # Check for 'main' first (newer convention)
  if git show-ref --verify --quiet refs/remotes/origin/main; then
      primary_branch="main"
      log_message "Detected primary remote branch: main" debug
  # Fallback to check for 'master'
  elif git show-ref --verify --quiet refs/remotes/origin/master; then
      primary_branch="master"
      log_message "Detected primary remote branch: master" debug
  else
      log_message "Could not determine primary branch. Neither origin/main nor origin/master found remotely." error
      log_message "Please ensure your remote 'origin' is configured correctly and has a 'main' or 'master' branch." error
      return 1
  fi
  log_message "Using '$primary_branch' as the primary branch."

  # --- Get Current Branch ---
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ -z "$current_branch" ]] || [[ "$current_branch" == "HEAD" ]]; then
      log_message "Could not determine current branch name or in detached HEAD state. Aborting." error
      return 1
  fi
  log_message "Starting madrebase on branch: $current_branch (rebasing onto $primary_branch)" debug

  # --- Validation ---
  # Check if the current branch is the primary branch and abort
  if [[ "$current_branch" == "$primary_branch" ]]; then
    log_message "Current branch is '$primary_branch'. Cannot rebase '$primary_branch' onto itself. Aborting." error
    return 1
  fi

  # --- Fetching Latest Primary Branch ---
  log_message "Fetching the latest changes from origin/$primary_branch..." debug
  # Fetch directly into the local primary branch ref for efficiency
  if ! git fetch origin "$primary_branch":"$primary_branch"; then
    log_message "Failed to fetch from origin/$primary_branch. Check connection and permissions. Aborting." error
    return 1
  fi
  log_message "Successfully fetched the latest changes for '$primary_branch'." success

  # --- Rebase Operations ---
  log_message "Attempting to rebase '$current_branch' onto '$primary_branch'..." debug
  # Attempt interactive rebase using GIT_SEQUENCE_EDITOR to skip editor launch when no conflicts
  # Using 'true' instead of ':' might be slightly more portable/readable, though ':' works widely.
  if GIT_SEQUENCE_EDITOR=true git rebase -i "$primary_branch"; then
      # --- Rebase Successful ---
      log_message "Rebase successful!" success

      # --- Prompt for force push ---
      local REPLY
      # Use -n 1 to read only one character, -r for raw input
      printf "${CYAN}[madrebase - INFO]${NC} Rebase successful. Force push '%s' to origin? (y/N) " "$current_branch"
      read_one_char REPLY
      echo # Move to a new line after read

      log_message "User input for push: '$REPLY'" debug

      # force push if 'y' or 'Y'
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
          log_message "Force pushing changes to origin/$current_branch..." debug
          # Force push with lease for safety
          if ! git push origin "$current_branch" --force-with-lease; then
              log_message "Force push failed. The remote branch may have changed. Fetch and try again. Aborting push." error
              # Note: Rebase was successful, but push failed. Consider the return code.
              # Returning 1 indicates the *overall operation* wasn't fully completed as requested.
              return 1
          fi
                                     log_message "Force push successful!" success
      else
          log_message "Push aborted by user."
          # Return success because the rebase worked, even if push was skipped.
          # Or return 1 if skipping the push should be considered an 'aborted operation'. Let's stick to 0 for successful rebase.
      fi
  else
      # --- Rebase Failed (likely conflicts) ---
      local rebase_exit_code=$?
      log_message "Rebase failed (exit code: $rebase_exit_code). Potential conflicts detected." error
      
      # Check if force mode is enabled and try to resolve conflicts
      if [[ "$force_mode" -eq 1 ]]; then
          log_message "Force mode enabled. Attempting to resolve conflicts..." debug
          
          if handle_force_resolution "$primary_branch"; then
              # Force resolution was successful, continue with the rest of the function
              log_message "Conflicts resolved using force mode. Continuing..." debug
              
                             # --- Prompt for force push after successful force resolution ---
               local REPLY
               printf "${CYAN}[madrebase - INFO]${NC} Rebase completed with force resolution. Force push '%s' to origin? (y/N) " "$current_branch"
               read_one_char REPLY
              echo # Move to a new line after read

              log_message "User input for push: '$REPLY'" debug

              # force push if 'y' or 'Y'
              if [[ "$REPLY" =~ ^[Yy]$ ]]; then
                  log_message "Force pushing changes to origin/$current_branch..." debug
                  if ! git push origin "$current_branch" --force-with-lease; then
                      log_message "Force push failed. The remote branch may have changed. Fetch and try again. Aborting push." error
                      return 1
                  fi
                  log_message "Force push successful!"
              else
                  log_message "Push aborted by user."
              fi
          else
              log_message "Force resolution failed or was aborted. Attempting to abort the rebase..." error
              
              # Attempt to abort rebase
              if ! git rebase --abort; then
                  log_message "CRITICAL: Failed to automatically abort rebase." error
                  log_message "Your repository might be in a mid-rebase state. Please resolve manually (e.g., 'git rebase --abort' or resolve conflicts and 'git rebase --continue')." error
              else
                  log_message "Rebase aborted successfully. Changes reverted to state before rebase attempt." warning
              fi
              return 1 # Indicate failure
          fi
      else
          log_message "Attempting to abort the rebase..." error
          log_message "Tip: Use 'madrebase --force' to automatically resolve conflicts by accepting the $primary_branch version." warning 

          # Attempt to abort rebase
          if ! git rebase --abort; then
              log_message "CRITICAL: Failed to automatically abort rebase." error
              log_message "Your repository might be in a mid-rebase state. Please resolve manually (e.g., 'git rebase --abort' or resolve conflicts and 'git rebase --continue')." error
          else
              log_message "Rebase aborted successfully. Changes reverted to state before rebase attempt." warning
          fi
          return 1 # Indicate failure
      fi
  fi

  log_message "madrebase completed on branch '$current_branch'." success
  return 0 # Indicate success
}

# --- Example Usage ---
# To call normally:
# madrebase

# To automatically resolve conflicts by accepting the primary branch version:
# madrebase --force

# To enable debug mode for a single run:
# madrebase_debug_mode=1 madrebase

# To combine debug mode with force mode:
# madrebase_debug_mode=1 madrebase --force

# Note: The madpush function from the original script remains unchanged
# and would need separate adaptation if it should also detect the primary branch,
# although its current simple purpose might not require that.
madpush() {
  # Color codes for terminal output
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local CYAN='\033[0;36m'
  local NC='\033[0m' # No Color

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ -z "$current_branch" ]] || [[ "$current_branch" == "HEAD" ]]; then
      printf "${RED}[madpush - ERROR]${NC} Could not determine current branch name or in detached HEAD state. Aborting.\n" >&2
      return 1
  fi
  printf "${CYAN}[madpush - INFO]${NC} Force-pushing (with lease) branch '%s' to origin...\n" "$current_branch"
  if ! git push origin "$current_branch" --force-with-lease; then
      printf "${RED}[madpush - ERROR]${NC} Force push failed. Remote may have changed. Fetch and retry.\n" >&2
      return 1
  fi
   printf "${GREEN}[madpush - SUCCESS]${NC} Force push successful for branch '%s'.\n" "$current_branch"
   return 0
}