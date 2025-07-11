#!/bin/bash
#
# Provides an interactive CLI to select an AWS account and IAM role,
# and then assumes that role using tokentamer.
#
# Prerequisites:
#   - fzf: For interactive selection (https://github.com/junegunn/fzf)
#   - jq: For JSON parsing (https://stedolan.github.io/jq/)
#   - tokentamer: For AWS role assumption (ensure it's in your PATH)
#   - Python 3: For updating .env and AWS credentials files

ttt() {
  # --- Configuration ---
  # Consider moving PROJECTS_JSON to an external file, e.g., ~/.config/ttt/projects.json
  # local projects_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/ttt/projects.json"
  # if [[ ! -f "$projects_config_file" ]]; then
  #   echo "Error: Projects configuration file not found at $projects_config_file" >&2
  #   echo "Please create it with your project definitions." >&2
  #   # You could offer to create a template here
  #   return 1
  # fi
  # local PROJECTS_JSON
  # PROJECTS_JSON=$(cat "$projects_config_file")
  # if ! jq -e . >/dev/null 2>&1 <<<"$PROJECTS_JSON"; then
  #   echo "Error: Invalid JSON in $projects_config_file" >&2
  #   return 1
  # fi

  # For simplicity, keeping it inline as per the original script
  local PROJECTS_JSON='[
    {
        "project_name": "evo-prod",
        "account_id": "337454644840",
        "role": "ct-evo-prod-admin"
    },
    {
        "project_name": "evo-qa",
        "account_id": "169325123174",
        "role": "ct-evo-wsb-admin"
    },
    {
        "project_name": "magna-prod",
        "account_id": "903880652457",
        "role": "ct-eda-myriad-magna-prod-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/1716/accounts"
    },
    {
        "project_name": "magna-qa",
        "account_id": "060425291414",
        "role": "ct-eda-myriad-magna-qa-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/1717/accounts"
    },
    {
        "project_name": "ent-manager-prod",
        "account_id": "864065747549",
        "role": "ct-eda-ent-manager-prod-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2033/accounts"
    },
    {
        "project_name": "ent-manager-qa",
        "account_id": "698164960551",
        "role": "ct-eda-ent-manager-qa-admin",
        "kion": "dummy"
    },
    {
        "project_name": "client-hub-prod",
        "account_id": "398543333626",
        "role": "ct-eda-client-hub-prod-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2317/accounts"
    },
    {
        "project_name": "client-hub-qa",
        "account_id": "994279948497",
        "role": "ct-eda-client-hub-qa-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2318/accounts"
    },
    {
        "project_name": "sbs-api-prod",
        "account_id": "166634873234",
        "role": "ct-eda-sbs-api-prod-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2344/accounts"
    },
    {
        "project_name": "sbs-api-qa",
        "account_id": "916352463284",
        "role": "ct-eda-sbs-api-qa-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2345/accounts"
    },
    {
        "project_name": "nba-dca-qa",
        "account_id": "113394075316",
        "role": "ct-eda-nba-dca-qa-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2683/accounts"
    },
    {
        "project_name": "nba-dca-prod",
        "account_id": "962371531581",
        "role": "ct-eda-nba-dca-prod-admin",
        "kion": "https://cloudops-prod.indeed.tech/portal/project/2684/accounts"
    },
    {
        "project_name": "dummy",
        "account_id": "dummy",
        "role": "dummy",
        "kion": "dummy"
    }
  ]'

  # --- Helper Functions ---
  _ttt_cleanup() {
    # Add any cleanup actions here if needed in the future
    # e.g., rm -f "$FZF_TMP_FILE" if we were still using it
    : # No-op
  }

  _ttt_ctrl_c() {
    printf "\n** Trapped CTRL-C. Exiting.\n" >&2
    _ttt_cleanup
    # Return a non-zero exit code to indicate interruption if sourced
    # If script is run directly, exit
    [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 1 || exit 1
  }

  # Check for required commands
  _ttt_check_command() {
    if ! command -v "$1" &>/dev/null; then
      printf "Error: Required command '%s' not found.\n" "$1" >&2
      printf "Please install it and ensure it's in your PATH.\n" >&2
      return 1
    fi
    return 0
  }

  # --- Main Logic ---
  trap _ttt_ctrl_c INT SIGINT
  trap _ttt_cleanup EXIT # General cleanup on exit

  for cmd in fzf jq tokentamer; do
    _ttt_check_command "$cmd" || return 1
  done
  # Ensure python3 or python is available
  local python_executable
  if command -v python3 &>/dev/null; then
    python_executable="python3"
  elif command -v python &>/dev/null; then
    python_executable="python"
  else
    echo "Error: Python (python3 or python) is not installed." >&2
    return 1
  fi

  # Select project using fzf
  local PROJECT_NAME
  PROJECT_NAME=$(printf "%s" "$PROJECTS_JSON" | jq -r '.[].project_name' | fzf --prompt="Select AWS Project: ")
  local FZF_EXIT_CODE=$?

  if [[ $FZF_EXIT_CODE -ne 0 ]]; then
    printf "fzf selection was cancelled or failed (exit code: %s). Exiting.\n" "$FZF_EXIT_CODE" >&2
    return 1
  fi

  if [[ -z "$PROJECT_NAME" ]]; then
    printf "No project selected. Exiting.\n" >&2
    return 1
  fi

  # Get account_id and role for the selected project
  local SELECTED_PROJECT_DETAILS
  SELECTED_PROJECT_DETAILS=$(printf "%s" "$PROJECTS_JSON" | jq -r --arg pn "$PROJECT_NAME" '.[] | select(.project_name == $pn) | "\(.account_id)\n\(.role)"')

  if [[ -z "$SELECTED_PROJECT_DETAILS" ]]; then
      printf "Error: Could not find details for project '%s'. Check your JSON configuration.\n" "$PROJECT_NAME" >&2
      return 1
  fi

  local ACCOUNT_ID ROLE
  # Read the two lines of output from jq into respective variables
  read -r ACCOUNT_ID <<< "$(echo "$SELECTED_PROJECT_DETAILS" | sed -n '1p')"
  read -r ROLE <<< "$(echo "$SELECTED_PROJECT_DETAILS" | sed -n '2p')"


  if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "null" || -z "$ROLE" || "$ROLE" == "null" ]]; then
      printf "Error: Extracted ACCOUNT_ID or ROLE is empty for project '%s'.\n" "$PROJECT_NAME" >&2
      return 1
  fi

  printf "You selected: %s\n" "$PROJECT_NAME"
  printf "Assuming role '%s' in account '%s'...\n" "$ROLE" "$ACCOUNT_ID"

  # Assume the role using tokentamer
  local TOKENTAMER_OUTPUT
  # Use process substitution and mapfile (Bash 4+) to read lines safely
  # Or use a temporary file if older Bash or for wider compatibility
  TOKENTAMER_OUTPUT=$(tokentamer setenv --iam-role="$ROLE" --account="$ACCOUNT_ID" 2>&1)
  local TOKENTAMER_EXIT_CODE=$?

  if [[ $TOKENTAMER_EXIT_CODE -ne 0 ]]; then
    printf "Error: tokentamer failed (exit code: %s).\nOutput:\n%s\n" "$TOKENTAMER_EXIT_CODE" "$TOKENTAMER_OUTPUT" >&2
    return 1
  fi

  if [[ -z "$TOKENTAMER_OUTPUT" ]]; then
    printf "Error: tokentamer produced no output. Cannot set environment variables.\n" >&2
    return 1
  fi
  
  # Evaluate the tokentamer output to set environment variables in the current shell
  eval "$TOKENTAMER_OUTPUT"

  # Check if core AWS variables were set by tokentamer
  if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$AWS_SESSION_TOKEN" ]]; then
      printf "Warning: tokentamer output was processed, but one or more core AWS environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN) are not set. Check tokentamer's output.\n" >&2
      # Depending on strictness, you might want to return 1 here
  fi
  
  # Use AWS_REGION if set by tokentamer, otherwise AWS_DEFAULT_REGION or a default
  local REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}" # Default to us-east-1 if neither is set


  printf "\n=================================================\n"
  printf "AWS credentials set for project: %s\n" "$PROJECT_NAME"
  printf "Account ID: %s\n" "$ACCOUNT_ID"
  printf "Role: %s\n" "$ROLE"
  printf "Run these commands in another terminal if needed:\n"
  printf "===\n%s\n===\n\n" "$TOKENTAMER_OUTPUT"


  # --- Python code generation for os.environ ---
  # This is much cleaner if done within the Python script itself,
  # by parsing the TOKENTAMER_OUTPUT.
  local python_env_code
  python_env_code=$($python_executable -c \
'import os, sys
print("import os")
for line in sys.stdin.read().splitlines():
    line = line.strip()
    if line.startswith("export "):
        line = line.split(" ", 1)[1]
    if "=" in line:
        key, value = line.split("=", 1)
        # Ensure proper quoting for string literals in Python
        # This handles existing quotes in the value if any (though AWS creds usually dont have them)
        value_escaped = value.replace("\\", "\\\\").replace("\"", "\\\"")
        print(f"os.environ[\"{key}\"] = \"{value_escaped}\"")
' <<< "$TOKENTAMER_OUTPUT")

  printf "=================================================\n"
  printf "Python code snippet to set environment variables:\n"
  printf "===\n%s\n===\n\n" "$python_env_code"


  # --- .env File Update Block ---
  local LOCAL_ENV_FILE="./.env"
  if [ -f "$LOCAL_ENV_FILE" ]; then
    printf "Updating .env file at %s...\n" "$LOCAL_ENV_FILE"
    # Pass necessary variables directly to Python
    # Note: AWS_DEFAULT_REGION might not be what you want if AWS_REGION is set
    # We use the 'REGION' variable determined earlier
    "$python_executable" - "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_SESSION_TOKEN" "$REGION" <<END_PYTHON_ENV
import os
import sys
from datetime import datetime, timezone

aws_access_key_id = sys.argv[1]
aws_secret_access_key = sys.argv[2]
aws_session_token = sys.argv[3]
aws_region = sys.argv[4] # This is the REGION variable we passed

new_values = {
    'AWS_ACCESS_KEY_ID': aws_access_key_id,
    'AWS_SECRET_ACCESS_KEY': aws_secret_access_key,
    'AWS_SESSION_TOKEN': aws_session_token,
    'AWS_REGION': aws_region, # Use AWS_REGION or AWS_DEFAULT_REGION as preferred
    'AWS_UPDATED_AT': datetime.now(timezone.utc).isoformat()
}

env_file = './.env' # Already checked that it exists
existing_keys = set()
updated_lines = []
content_changed = False

try:
    with open(env_file, 'r') as f:
        lines = f.readlines()

    # Process existing lines and identify keys
    new_file_content = []
    for line in lines:
        stripped_line = line.strip()
        if not stripped_line or stripped_line.startswith('#'):
            new_file_content.append(line)
            continue
        if '=' in stripped_line:
            key = stripped_line.split('=', 1)[0].strip()
            existing_keys.add(key)
            if key in new_values:
                new_line = f"{key}={new_values[key]}\n"
                if new_line != line:
                    content_changed = True
                new_file_content.append(new_line)
                del new_values[key] # Mark as updated
            else:
                new_file_content.append(line)
        else:
            new_file_content.append(line) # Keep lines without '='

    # Add any new keys that weren't in the file
    if new_values: # If there are any remaining new_values to add
        content_changed = True
        if new_file_content and new_file_content[-1].strip() != "":
            new_file_content.append("\n") # Add a newline if last line wasn't empty
        for k, v in new_values.items():
            new_file_content.append(f"{k}={v}\n")

    if content_changed:
        with open(env_file, 'w') as f:
            f.writelines(new_file_content)
        print(f"Updated {env_file}")
    else:
        print(f"{env_file} is already up to date.")

except Exception as e:
    print(f"Error updating {env_file}: {e}", file=sys.stderr)
    sys.exit(1)
END_PYTHON_ENV
  fi


  # --- AWS Credential File Update Block ---
  local INI_KEY="${ACCOUNT_ID}_${ROLE}"
  local AWS_CRED_FILE="${HOME}/.aws/credentials"
  printf "Updating AWS credentials file at %s for profile [%s]...\n" "$AWS_CRED_FILE" "$INI_KEY"

  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$AWS_CRED_FILE")"

  "$python_executable" - "$AWS_CRED_FILE" "$INI_KEY" "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_SESSION_TOKEN" "$REGION" <<END_PYTHON_AWS
import configparser
import os
import sys

aws_cred_file = sys.argv[1]
ini_key = sys.argv[2]
aws_access_key_id = sys.argv[3]
aws_secret_access_key = sys.argv[4]
aws_session_token = sys.argv[5]
aws_region = sys.argv[6]

config = configparser.ConfigParser()

# Read existing credentials if file exists
if os.path.exists(aws_cred_file):
    config.read(aws_cred_file)

# Update or add the section for the assumed role
# For temporary credentials, it's generally fine to overwrite.
# If you had a mix of long-term and temp creds under the same profile name (unlikely for this script),
# the original logic 'aws_session_token' in config[ini_key] would be relevant.
config[ini_key] = {
    'aws_access_key_id': aws_access_key_id,
    'aws_secret_access_key': aws_secret_access_key,
    'aws_session_token': aws_session_token,
    'region': aws_region # Store region as well
}

try:
    with open(aws_cred_file, 'w') as configfile:
        config.write(configfile)
    print(f"Updated AWS credentials file: {aws_cred_file} with profile [{ini_key}]")
except Exception as e:
    print(f"Error writing to {aws_cred_file}: {e}", file=sys.stderr)
    sys.exit(1)

END_PYTHON_AWS

  printf "\nCredentials successfully set and updated.\n"
  printf "Current AWS Identity: "
  aws sts get-caller-identity --output text --query 'Arn' || printf "(aws cli not found or error)\n"
  
  trap - INT SIGINT EXIT # Clear traps
  return 0
}

# If you want to run this script directly for testing (e.g. ./ttt.sh)
# you can add:
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   ttt
# fi
# Otherwise, source it: . ttt.sh