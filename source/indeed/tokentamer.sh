

ttt() {
  # Provides an interactive CLI to select an AWS account and IAM role, and then assumes that role.
  
  function ctrl_c() {
    printf "** Trapped CTRL-C\n"
    exit 1
  }

  # trap ctrl+c and call ctrl_c()
  trap ctrl_c INT
  trap ctrl_c SIGINT

  install_tokentamer
  install_fzf
  install_jq

  PROJECTS_JSON='[
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
  FZF_TMP_FILE=$(mktemp)

  # Execute fzf to select a project name and save the output to the temporary file
  printf "$PROJECTS_JSON" | jq -r '.[].project_name' | fzf >"$FZF_TMP_FILE"

  # Capture the exit code of fzf
  FZF_EXIT_CODE=$?

  # Read the selected project name from the temporary file
  PROJECT_NAME=$(cat "$FZF_TMP_FILE")

  # Remove the temporary file
  rm "$FZF_TMP_FILE"

  # Check if fzf was interrupted
  if [ $FZF_EXIT_CODE -ne 0 ]; then
    printf "fzf was interrupted, exiting...\n"
    return 1
  fi

  SELECTED_PROJECT=$(echo "$PROJECTS_JSON" | jq -r --arg pn "$PROJECT_NAME" '.[] | select(.project_name == $pn)')

  ACCOUNT_ID=$(echo "$SELECTED_PROJECT" | jq -r '.account_id')
  ROLE=$(echo "$SELECTED_PROJECT" | jq -r '.role')

  printf "You've selected: $PROJECT_NAME\n"
  printf "Running command with selected account id: $ACCOUNT_ID and role: $ROLE\n"

  OUTPUT=$(tokentamer setenv --iam-role="$ROLE" --account="$ACCOUNT_ID")
  eval $OUTPUT
  printf "=================================================\n"
  printf "Code to run in another terminal:\n"
  printf "===\n\n"
  printf "$OUTPUT\n\n"

  # Remove the first empty line, remove "export " prefix
  # replace = with =", and append " at the end
  OUTPUT=$(echo "$OUTPUT" | sed -e '/^$/d' -e 's/export //g' -e "s/=/='/" -e "s/$/\"/g")
  # Remove the first empty line, remove "export " prefix, replace only first "=" with "='", and append "'" at the end
  # OUTPUT=$(echo "$OUTPUT" | sed -e '/^$/d' -e 's/export //g' -e "s/=/'/" -e "s/$/\"/g")

  # Replace newlines with newlines + "os.environ["
  OUTPUT=$(echo "$OUTPUT" | awk '{print "os.environ[\""$0}')

  # Append "]" before "="
  OUTPUT=$(echo "$OUTPUT" | sed "s/='/\"]=\"/")

  # Add "import os" to the start of the string
  OUTPUT="import os"$'\n'"$OUTPUT"

  # Print the final output
  printf "=================================================\n"
  printf "Code to run in python:\n"
  printf "===\n\n"
  printf "$OUTPUT\n\n"
# AWS Credential Files Block >>>
  INI_KEY="${ACCOUNT_ID}_${ROLE}"

  AWS_CRED_FILE="$HOME/.aws/credentials"
python_code=$(
  cat <<END
import configparser
import os

config = configparser.ConfigParser()
config.read('$AWS_CRED_FILE')

# Check if the section already exists
if '$INI_KEY' not in config or 'aws_session_token' in config['$INI_KEY']:

    config['$INI_KEY'] = {
        'aws_access_key_id': '$AWS_ACCESS_KEY_ID',
        'aws_secret_access_key': '$AWS_SECRET_ACCESS_KEY',
        'aws_session_token': '$AWS_SESSION_TOKEN',
        'region': '$AWS_DEFAULT_REGION'
    }

    with open('$AWS_CRED_FILE', 'w') as configfile:
        config.write(configfile)
else:
    print(f"Section '$INI_KEY' already exists with long-term credentials. Skipping update.")

END
  )

  # Execute the python code
  if command -v python3 &>/dev/null; then
    python3 -c "$python_code"
  else
    python -c "$python_code"
  fi
# AWS Credential Files Block <<<
# .env Files Block >>>

  LOCAL_ENV_FILE="./.env"
  if [ -f "$LOCAL_ENV_FILE" ]; then
    python_code=$(
      cat <<END
import configparser

new_values = {
    'AWS_ACCESS_KEY_ID': '$AWS_ACCESS_KEY_ID',
    'AWS_SECRET_ACCESS_KEY': '$AWS_SECRET_ACCESS_KEY',
    'AWS_SESSION_TOKEN': '$AWS_SESSION_TOKEN',
    'REGION': '$AWS_DEFAULT_REGION'
}

# Read the existing .env file and update the values
with open('.env', 'r') as file:
    lines = file.readlines()

updated_lines = []
for line in lines:
    key_value = line.strip().split('=')
    key = key_value[0]
    if key in new_values:
        updated_lines.append(f"{key}={new_values[key]}\n")
    else:
        updated_lines.append(line)

# Write the updated values back to the .env file
with open('.env', 'w') as file:
    file.writelines(updated_lines)
END
    )

    # Execute the python code
    if command -v python3 &>/dev/null; then
      python3 -c "$python_code"
    else
      python -c "$python_code"
    fi
  fi
# .env Files Block <<<
}