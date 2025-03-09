#!/bin/bash

# Find the most recent Obsidian vault using config files (much faster than filesystem search)



# Function to parse Obsidian's vault list config
get_vaults_from_config() {
  local config_file="$1"
  if [[ ! -f "$config_file" ]]; then
    return 1
  fi

  # Check if jq is available (for robust parsing)
  if command -v jq &>/dev/null; then
    # Extract all vault paths and last-open timestamps
    jq -r '.vaults | to_entries[] | "\(.value.path)|\(.value.ts)"' "$config_file" 2>/dev/null || return 1
  else
    # Fallback using grep/awk/sed - less reliable but works without jq
    grep -o '"path":"[^"]*","ts":[0-9]*' "$config_file" 2>/dev/null | 
      sed 's/"path":"//g' | 
      sed 's/","ts":/|/g' || return 1
  fi
}

# Function to check if a path is a valid Obsidian vault
is_valid_vault() {
  local path="$1"
  # Basic validation: directory exists and contains .obsidian subdirectory
  [[ -d "$path" && -d "$path/.obsidian" ]]
}

# Find config directory based on OS
get_config_dir() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "$HOME/Library/Application Support/obsidian"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -n "$XDG_CONFIG_HOME" && -d "$XDG_CONFIG_HOME/obsidian" ]]; then
      echo "$XDG_CONFIG_HOME/obsidian"
    else
      echo "$HOME/.config/obsidian" 
    fi
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    if [[ -d "$APPDATA/Obsidian" ]]; then
      echo "$APPDATA/Obsidian"
    else
      echo "$HOME/AppData/Roaming/Obsidian"
    fi
  fi
}

# Main function to find most recent vault
find_most_recent_vault() {
  local config_dir
  config_dir=$(get_config_dir)
  
  # Check if config directory exists
  if [[ ! -d "$config_dir" ]]; then
    echo "Obsidian config directory not found at: $config_dir" >&2
    return 1
  fi
  
  # Find the main obsidian config file
  local config_file="$config_dir/obsidian.json"
  if [[ ! -f "$config_file" ]]; then
    # Try common alternatives
    for alt_file in "$config_dir/app.json" "$config_dir/core.json"; do
      if [[ -f "$alt_file" ]]; then
        config_file=$alt_file
        break
      fi
    done
  fi
  
  if [[ ! -f "$config_file" ]]; then
    echo "Obsidian config file not found in: $config_dir" >&2
    return 1
  fi
  
  # Get vaults and sort by timestamp (most recent first)
  local most_recent_vault=""
  local latest_ts=0
  
  while IFS="|" read -r vault_path ts; do
    # Normalize path (expand ~ if present)
    vault_path="${vault_path/#\~/$HOME}"
    
    # Remove any surrounding quotes if present
    vault_path="${vault_path%\"}"
    vault_path="${vault_path#\"}"
    
    # Verify it's a valid vault
    if is_valid_vault "$vault_path"; then
      # If this is more recent than our current most recent
      if (( ts > latest_ts )); then
        most_recent_vault="$vault_path"
        latest_ts=$ts
      fi
    fi
  done < <(get_vaults_from_config "$config_file")
  
  # Return the most recent vault
  if [[ -n "$most_recent_vault" ]]; then
    echo "$most_recent_vault"
    return 0
  else
    echo "No valid Obsidian vaults found in config." >&2
    return 1
  fi
}

# Execute and print the result
find_most_recent_vault