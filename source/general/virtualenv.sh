
# Function: svenv (source virtual environment)
# Description: Searches for and activates a Python virtual environment in the current
#             directory or specified subdirectories.
#
# Usage: 
#   svenv                     # Searches in current directory
#   svenv subfolder          # Searches in ./subfolder
#   svenv subfolder1 subfolder2  # Searches in ./subfolder1/subfolder2
#
# Arguments:
#   $1 - First level subfolder (optional)
#   $2 - Second level subfolder (optional)
#
# Returns:
#   0 - Virtual environment activated successfully
#   1 - No virtual environment found or error occurred
svenv() {
    # Visual separator for output clarity
    local separator="=============================="
    echo "$separator"
    echo "Searching for virtual environment..."

    # Store arguments
    local subfolder="${1:-}"
    local ssubfolder="${2:-}"
    
    # Common virtual environment directory names
    local folders=("venv" ".venv" ".env" "env")
    local activate_script="bin/activate"

    # Construct base path based on provided arguments
    local base_path="${PWD}"
    if [ -n "$subfolder" ]; then
        base_path="${base_path}/${subfolder}"
        if [ -n "$ssubfolder" ]; then
            base_path="${base_path}/${ssubfolder}"
        fi
    fi

    # Search for virtual environment
    for folder in "${folders[@]}"; do
        local venv_path="${base_path}/${folder}"
        local activate_path="${venv_path}/${activate_script}"

        if [ -d "$venv_path" ] && [ -f "$activate_path" ]; then
            echo "Found virtual environment in: $venv_path"
            
            # Source the virtual environment
            # shellcheck disable=SC1090
            source "$activate_path"
            
            # Verify activation
            if [ $? -eq 0 ]; then
                echo "Successfully activated virtual environment!"
                echo "Python path: $(which python)"
                echo "Pip path: $(which pip)"
                echo "$separator"
                return 0
            else
                echo "Error: Failed to activate virtual environment"
                echo "$separator"
                return 1
            fi
        fi
    done

    # No virtual environment found
    echo "Error: No virtual environment found in specified path(s)"
    echo "Searched in: $base_path"
    echo "$separator"
    return 1
}


# Function: cvenv
# Description: Creates and activates a Python virtual environment with the latest
#              available Python version. Primarily uses indeed-python-next if 
#              available, otherwise falls back to system Python3.
#
# Usage:
#   cvenv                   # Creates venv in current directory
#   cvenv myproject        # Creates venv in ./myproject
#   cvenv myproject test   # Creates venv in ./myproject/test
#
# Arguments:
#   $1 - (Optional) Subfolder name
#   $2 - (Optional) Secondary subfolder name
#
# Returns:
#   0 - Success
#   1 - Error (Python not found or venv creation failed)
#
# Dependencies:
#   - virtualenv
#   - python3
#   - indeed-python-next (optional)
#   - svenv (optional)
#
cvenv() {
    echo "Creating virtual environment..."
    # Safely deactivate any active virtual environment
    type deactivate >/dev/null 2>&1 && deactivate

    # Set variables with defaults
    local subfolder="${1:-}"
    local ssubfolder="${2:-}"
    local env_path="${PWD}"
    
    # Build the path based on provided arguments
    [ -n "$subfolder" ] && env_path="${env_path}/${subfolder}"
    [ -n "$ssubfolder" ] && env_path="${env_path}/${ssubfolder}"
    env_path="${env_path}/venv"

    # Try to get Python path, first from indeed-python-next, then fallback to system
    local python_path
    if command -v indeed-python-next >/dev/null 2>&1; then
        python_path="$(indeed-python-next)"
    else
        # Find the latest Python 3 version available in the system
        python_path=$(which python3)
        if [ -z "$python_path" ]; then
            echo "Error: No Python installation found"
            return 1
        fi
        echo "Note: Using system Python: $python_path"
    fi

    # Create virtual environment
    if ! virtualenv --python="$python_path" "$env_path"; then
        echo "Error: Failed to create virtual environment at $env_path"
        return 1
    fi

    # Activate the new environment using svenv
    if command -v svenv >/dev/null 2>&1; then
        svenv "$subfolder" "$ssubfolder"
    else
        echo "Warning: svenv command not found. Manually activate the environment with:"
        echo "source $env_path/bin/activate"
    fi
}



# Function: ivenv (Install Virtual Environment Requirements)
#
# Description:
#   Installs Python package requirements from specified requirement files.
#   Searches for requirement files in the current directory and specified subfolders.
#   Uses a three-tier priority system for finding requirement files.
#
# Usage:
#   ivenv [subfolder] [sub-subfolder]
#
# Arguments:
#   $1 - First level subfolder (optional)
#   $2 - Second level subfolder (optional)
#
# Priority System:
#   Tier 1 (Frozen Requirements):
#     - requirements.test
#     - requirements.dev
#     - requirements.frozen
#     - requirements.base.frozen
#
#   Tier 2 (Input Requirements):
#     - requirements.in
#     - requirements.dev.in
#     - requirements.test.in
#
#   Tier 3 (Fallback):
#     - requirements.txt
#
# Example:
#   ivenv backend tests
#   ivenv src
#   ivenv
ivenv() {
    echo "Installing requirements..."
    local subfolder=$1
    local ssubfolder=$2

    # Define priority tiers
    local tier1=(
        "requirements.test"
        "requirements.dev"
        "requirements.frozen"
        "requirements.base.frozen"
    )

    local tier2=(
        "requirements.in"
        "requirements.dev.in"
        "requirements.test.in"
    )

    local tier3=(
        "requirements.txt"
    )

    # Update pip and pip-tools
    echo "Updating pip and pip-tools..."
    pip install -U pip >/dev/null
    pip install -U pip-tools >/dev/null

    # Define folders to search
    local folders=("$PWD")
    [[ -n "$subfolder" ]] && folders+=("${PWD}/$subfolder")
    [[ -n "$ssubfolder" ]] && folders+=("${PWD}/$subfolder/$ssubfolder")

    local requirements_found=false

    # Function to install requirements from a list of files
    install_requirements() {
        local folder=$1
        local files_ref=$2
        local found=false
        eval "local files=(\"\${$files_ref[@]}\")"

        for file in "${files[@]}"; do
            if [[ -f "$folder/$file" ]]; then
                echo "Installing packages from $folder/$file"
                pip install -r "$folder/$file" --quiet
                found=true
                requirements_found=true
            fi
        done

        echo "$found"
    }

    # Search through each folder
    for folder in "${folders[@]}"; do
        if [[ -d "$folder" ]]; then
            echo "Checking folder: $folder"
            
            # Try Tier 1 first
            local tier1_found
            tier1_found=$(install_requirements "$folder" "tier1")
            
            # If nothing found in Tier 1, try Tier 2
            if [[ "$tier1_found" == "false" ]]; then
                local tier2_found
                tier2_found=$(install_requirements "$folder" "tier2")
                
                # If nothing found in Tier 2, try Tier 3
                if [[ "$tier2_found" == "false" ]]; then
                    install_requirements "$folder" "tier3"
                fi
            fi
        else
            echo "Warning: Folder $folder does not exist"
        fi
    done

    # Provide feedback on the installation process
    if [[ "$requirements_found" == true ]]; then
        echo "Requirements installation completed successfully!"
    else
        echo "No requirement files found in any specified locations."
    fi
}
civenv() {
  # Calls cvenv and ivenv
  cvenv $1 $2
  ivenv $1 $2

}