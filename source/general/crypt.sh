#!/bin/bash

# Function to encrypt a file using openssl
# @param filepath The path to the file to encrypt.
# @param password The password to use for encryption.
encrypt() {
  local filepath="$1"
  local password="$2"

  if [ -z "$filepath" ]; then
    echo "Usage: encrypt <filepath> [password]" >&2
    return 1
  fi

  if [ ! -f "$filepath" ]; then
    echo "File not found: $filepath" >&2
    return 1
  fi

  if [ -e "$filepath.enc" ]; then
    echo -n "Output file already exists. Overwrite? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Encryption aborted." >&2
      return 1
    fi
  fi

  if [ -z "$password" ]; then
    password=$(get_password "Enter encryption password: ")
    local password_verify=$(get_password "Verify password: ")
    
    if [[ "$password" != "$password_verify" ]]; then
      echo "Passwords do not match. Encryption aborted." >&2
      return 1
    fi
  fi

  openssl aes-256-cbc -pbkdf2 -salt -in "$filepath" -out "$filepath.enc" -k "$password"

  if [ $? -eq 0 ]; then
    echo "File encrypted: $filepath.enc"
  else
    echo "Encryption failed." >&2
    return 1
  fi
}

# Function to decrypt a file using openssl
# @param filepath The path to the encrypted file.
# @param password The password to use for decryption.
decrypt() {
  local filepath="$1"
  local password="$2"
  local output_filepath="${filepath%.enc}"

  if [ -z "$filepath" ]; then
    echo "Usage: decrypt <filepath> [password]" >&2
    return 1
  fi

  if [ ! -f "$filepath" ]; then
    echo "File not found: $filepath" >&2
    return 1
  fi
  
  if [[ "$filepath" != *.enc ]]; then
    echo "File does not have a .enc extension" >&2
    return 1
  fi

  if [ -e "$output_filepath" ]; then
    echo -n "Output file already exists. Overwrite? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Decryption aborted." >&2
      return 1
    fi
  fi

  if [ -z "$password" ]; then
    password=$(get_password "Enter decryption password: ")
  fi

  openssl aes-256-cbc -pbkdf2 -d -salt -in "$filepath" -out "$output_filepath" -k "$password"

  if [ $? -eq 0 ]; then
    echo "File decrypted: $output_filepath"
  else
    echo "Decryption failed." >&2
    return 1
  fi
}

# Example usage (you would typically call these functions from another script or the command line)
#   encrypt "my_secrets.txt" "MySuperSecretPassword"
#   decrypt "my_secrets.txt.enc" "MySuperSecretPassword"

# --- Helper functions to prompt for password securely ---

# Prompts for a password, ensuring it's not echoed to the terminal.
# Returns the password via stdout.
get_password() {
    local prompt="${1:-Enter password: }"  # Use provided prompt or default
    local password

    if [[ "$OSTYPE" == darwin* ]]; then
        # macOS uses osascript for secure password entry
        password=$(osascript -e "display dialog \"$prompt\" default answer \"\" with hidden answer" -e 'text returned of result' 2>/dev/null)
        echo  # Add a newline after the password input
    else
        # Use stty for other systems
        # Turn off echoing
        stty -echo

        echo -n "$prompt"
        read -r password
        echo # Add a newline after the password input

        # Turn echoing back on
        stty echo
    fi

    printf "%s" "$password" # return the password, no final newline
}

# Encrypt using a prompted password.
encrypt_file_prompt() {
    local filepath="$1"
    if [ -z "$filepath" ]; then
        echo "Usage: encrypt_file_prompt <filepath>" >&2
        return 1
    fi
    
    encrypt "$filepath" ""  # Empty password will trigger the prompt inside encrypt()
    
    # No need to handle password here since encrypt() now handles it
}

# Decrypt a file, prompting for the password.
decrypt_file_prompt() {
    local filepath="$1"
    if [ -z "$filepath" ]; then
        echo "Usage: decrypt_file_prompt <filepath>" >&2
        return 1
    fi
    
    decrypt "$filepath" ""  # Empty password will trigger the prompt inside decrypt()
    
    # No need to handle password here since decrypt() now handles it
}

# --- Examples using the prompted password ---
# encrypt_file_prompt my_credentials.txt
# decrypt_file_prompt my_credentials.txt.enc