#!/bin/bash

# Shell Environment Management Framework
# This script must be sourced, not executed directly

# --- Core Initialization ---

# Check proper usage - script must be sourced
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && { echo "Error: This script must be sourced, not executed directly."; exit 1; }

# Set up debug mode if needed
[[ -n "$DEBUG" ]] && set -x

# --- Path Resolution ---

# Determine the base directory containing configuration files
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
elif [[ -n "${ZSH_NAME}" ]]; then
    BASE_DIR="$( cd "$( dirname "${(%):-%x}" )" && pwd )"
else
    BASE_DIR="$( cd "$( dirname "$0" )" && pwd )"
fi

# --- Logging Functions ---

log() {
    local level="$1"
    local message="$2"

    # Only show debug messages when DEBUG is enabled
    if [[ "$level" == "DEBUG" && -n "$DEBUG" ]] || [[ "$level" != "DEBUG" ]]; then
        echo "[$(date +%H:%M:%S)] [$level] $message" >&2
    fi
}

# --- Utility Functions ---

# Check for command existence
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Source all valid files from a directory
source_files_from_dir() {
    local dir="$1"
    local context="${2:-}"

    [[ -n "$DEBUG" ]] && log "DEBUG" "Looking for configurations in: $dir ${context:+($context)}"

    # Check for direct .sh file first
    local sh_file="${dir}.sh"
    if [[ -f "$sh_file" && -r "$sh_file" ]]; then
        [[ -n "$DEBUG" ]] && log "DEBUG" "Sourcing: $(basename "$sh_file")"
        source "$sh_file"
    fi

    # Then check directory
    if [[ -d "$dir" ]]; then
        for file in "$dir"/*; do
            if [[ -f "$file" && -r "$file" ]]; then
                [[ -n "$DEBUG" ]] && log "DEBUG" "Sourcing: $(basename "$file")"
                source "$file"
            fi
        done
    else
        [[ -n "$DEBUG" ]] && log "DEBUG" "Directory not found: $dir"
    fi
}
# User-facing greeting function (example utility)
greeting() {
    local name="${1:-$(whoami)}"
    echo "Hello $name, welcome to your shell environment"
    cmd_exists python && echo "Python is available at: $(which python)"
}

# --- Environment Detection (Automatic) ---

# Detect operating system
OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Darwin)
        IS_MACOS=true
        ;;
    Linux)
        IS_LINUX=true
        ;;
    *)
        IS_UNKNOWN_OS=true
        ;;
esac

# Hardware and hostname information
HOSTNAME="$(hostname)"
CPU_CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 'unknown')"

# Get Memory
get_memory() {
  if [[ "$IS_MACOS" == true ]]; then
    local memsize=$(sysctl -n hw.memsize 2>/dev/null)
    # Check if memsize is a positive integer
    if [[ "$memsize" =~ ^[0-9]+$ ]] && [[ "$memsize" -gt 0 ]]; then
      MEMORY_GB=$(( memsize / 1024 / 1024 / 1024 ))
    else
      MEMORY_GB="unknown"  # Set to "unknown" if sysctl fails or output is invalid
    fi
  elif [[ "$IS_LINUX" == true ]]; then
      MEMORY_GB="$(( $(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0) / 1024 / 1024 ))"
  else
      MEMORY_GB="unknown"
  fi

}

get_memory # Call the function to set MEMORY_GB
# Default personal/work detection
IS_PERSONAL_MACHINE=true  # Default assumption

# Check for Indeed-specific markers
if cmd_exists indeed-entrypoint || [[ -d "/opt/indeed" || -d "/etc/indeed" ]]; then
    IS_INDEED_ENV=true
    IS_WORK_MACHINE=true
    IS_PERSONAL_MACHINE=false
    log "INFO" "Indeed environment detected"
fi

# Check for Indeed VPN client (Warp)
if [[ -d "/Applications/Cloudflare Warp.app" ]] || ( cmd_exists warp-cli && [[ $? -eq 0 ]] ); then
    HAS_WARP_VPN=true
    # If Warp is installed, it's likely a work machine for Indeed.
    if [[ "$IS_INDEED_ENV" != true ]]; then
        log "INFO" "Indeed VPN client (Warp) detected"
        IS_WORK_MACHINE=true
        IS_PERSONAL_MACHINE=false
        IS_INDEED_ENV=true
    fi
fi

# Additional environment detection
if [[ "$IS_MACOS" == true ]]; then
    # Check for signs of *additional* 'general' work environment on Mac (beyond Indeed)
    if [[ "$HOSTNAME" == *"IT-IRL"* || "$HOSTNAME" == *"work"* ||
          -d "/Applications/Company VPN.app" || -e "/Library/Management" ]]; then

        # Only set to work if it's not *already* detected as Indeed.  Indeed takes precedence.
        if [[ "$IS_INDEED_ENV" != true ]]; then
             IS_WORK_MACHINE=true
             IS_PERSONAL_MACHINE=false
        fi
    fi

    # Detect Mac model
    if cmd_exists system_profiler; then
        MAC_MODEL=$(system_profiler SPHardwareDataType | grep 'Model Name' | cut -d ':' -f2 | xargs)
        [[ "$MAC_MODEL" == *"MacBook"* ]] && IS_LAPTOP=true
    fi

elif [[ "$IS_LINUX" == true ]]; then
    # Detect if this is a server or desktop Linux
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$XDG_CURRENT_DESKTOP" == "" ]]; then
        # No GUI environment suggests server
        IS_SERVER=true

        # Check for cloud providers
        if grep -q "Amazon EC2" /sys/devices/virtual/dmi/id/bios_version 2>/dev/null || \
           grep -q "amazon" /sys/devices/virtual/dmi/id/product_name 2>/dev/null || \
           [[ -f /sys/hypervisor/uuid && $(cat /sys/hypervisor/uuid | cut -c1-3) == "ec2" ]] || \
           [[ $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | tr '[:upper:]' '[:lower:]') == *"amazon"* ]]; then
            IS_AWS=true
            IS_VPS=true
        elif [[ -f /etc/google_cloud ]]; then
            IS_GCP=true
            IS_VPS=true
        elif [[ -f /etc/digitalocean ]]; then
            IS_DIGITALOCEAN=true
            IS_VPS=true
        elif [[ "$HOSTNAME" == *"linode"* ]]; then
            IS_LINODE=true
            IS_VPS=true
        elif [[ -d "/etc/oracle-cloud-agent" ]]; then
            IS_ORACLE_CLOUD=true
            IS_VPS=true
        fi

        # If not specifically identified as cloud, assume it's a VPS/server
        IS_VPS=true
    else
        IS_DESKTOP=true
        # Look for signs of a *general* work machine, but only set if NOT already Indeed.
        if [[ "$IS_INDEED_ENV" != true ]]; then
          if [[ -d "/opt/company" || "$HOSTNAME" == *"work"* || -f "/etc/company/config" ]]; then
              IS_WORK_MACHINE=true
              IS_PERSONAL_MACHINE=false
          fi
        fi
        # Try to detect if this is a laptop
        if [[ -d "/sys/class/power_supply" && -n "$(find /sys/class/power_supply -name "BAT*" 2>/dev/null)" ]]; then
            IS_LAPTOP=true
        fi
    fi

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            "ubuntu") CONFIG_SOURCES+=("$BASE_DIR/linux/ubuntu") ;;
            "debian") CONFIG_SOURCES+=("$BASE_DIR/linux/debian") ;;
            "centos") CONFIG_SOURCES+=("$BASE_DIR/linux/centos") ;;
            "fedora") CONFIG_SOURCES+=("$BASE_DIR/linux/fedora") ;;
            "amzn")   CONFIG_SOURCES+=("$BASE_DIR/linux/amazon") ;;
            *)        CONFIG_SOURCES+=("$BASE_DIR/linux/other") ;;
        esac
    fi
fi

# Detect shell type
if [[ -n "$ZSH_NAME" ]]; then
    IS_ZSH=true
    SHELL_TYPE="zsh"
elif [[ -n "$BASH" ]]; then
    IS_BASH=true
    SHELL_TYPE="bash"
elif [[ -n "$FISH_VERSION" ]]; then
    IS_FISH=true
    SHELL_TYPE="fish"
else
    SHELL_TYPE="unknown"
fi

# Detect if this is a remote SSH session
if [[ -n "$SSH_CLIENT" || -n "$SSH_CONNECTION" || -n "$SSH_TTY" ]]; then
    IS_SSH_SESSION=true
fi

# Detect if working at home (a reasonable guess)
  #Consider that this is a personal machine
if [[ "$IS_WORK_MACHINE" == true && "$IS_SSH_SESSION" != true && "$HOSTNAME" == *"home"* ]]; then
   # IS_WORK_AT_HOME=true  <- Removing this.  Overly specific.
    IS_PERSONAL_MACHINE=true
    IS_WORK_MACHINE=false
fi

# Detect development environment indicators
if cmd_exists git && cmd_exists npm; then
    IS_DEV_MACHINE=true
fi
if cmd_exists docker || cmd_exists podman; then
    HAS_CONTAINERS=true
fi
if cmd_exists python3 || cmd_exists python; then
    HAS_PYTHON=true
fi

# Detect company environments through commands or paths  (besides Indeed)
[[ -d "/opt/google" || -d "/google" ]] && IS_GOOGLE_ENV=true
[[ -d "/opt/amazon" || -d "/amazon" ]] && IS_AMAZON_ENV=true

# --- Allow user overrides of detected environment ---
[[ -f "$HOME/.shell_env_overrides" ]] && source "$HOME/.shell_env_overrides"

# --- Log detected environment ---

log "INFO" "Detected environment: $OS_TYPE ($(uname -r))"
log "INFO" "Host: $HOSTNAME, CPU cores: $CPU_CORES, Memory: ${MEMORY_GB}GB"
[[ "$IS_WORK_MACHINE" == true ]] && log "INFO" "Work machine detected"
[[ "$IS_PERSONAL_MACHINE" == true ]] && log "INFO" "Personal machine detected"
[[ "$IS_SERVER" == true ]] && log "INFO" "Server environment detected"
[[ "$IS_DESKTOP" == true ]] && log "INFO" "Desktop environment detected"
[[ "$IS_LAPTOP" == true ]] && log "INFO" "Laptop detected"
[[ "$IS_SSH_SESSION" == true ]] && log "INFO" "SSH session detected"

# --- Configuration Loading Logic ---

# Create an array of configuration sources to load in order
CONFIG_SOURCES=(
    # 1. Base/general configurations
    "$BASE_DIR/general"
)

# 2. OS-specific configurations
if [[ "$IS_MACOS" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/macos")
elif [[ "$IS_LINUX" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/linux")
fi

# 3. Machine type configurations
[[ "$IS_LAPTOP" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/laptop")
[[ "$IS_DESKTOP" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/desktop")
[[ "$IS_SERVER" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/server")
[[ "$IS_VPS" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/vps")

# 4. Environment-specific configurations
if [[ "$IS_WORK_MACHINE" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/work")
    [[ "$IS_MACOS" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/work/macos")
    [[ "$IS_LINUX" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/work/linux")
fi


if [[ "$IS_PERSONAL_MACHINE" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/personal")
    [[ "$IS_MACOS" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/personal/macos")
    [[ "$IS_LINUX" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/personal/linux")
fi

# 5. Shell-specific configurations
CONFIG_SOURCES+=("$BASE_DIR/$SHELL_TYPE")

# 6. Tool-specific configurations
cmd_exists code && CONFIG_SOURCES+=("$BASE_DIR/tools/vscode")
cmd_exists git && CONFIG_SOURCES+=("$BASE_DIR/tools/git")
cmd_exists docker && CONFIG_SOURCES+=("$BASE_DIR/tools/docker")
cmd_exists npm && CONFIG_SOURCES+=("$BASE_DIR/tools/node")
cmd_exists python3 && CONFIG_SOURCES+=("$BASE_DIR/tools/python")
CONFIG_SOURCES+=("$BASE_DIR/tools/general")

# 7. Special purpose configurations
[[ "$IS_DEV_MACHINE" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/development")
#[[ "$IS_WORK_AT_HOME" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/work_at_home")   <- Removing.  Overly narrow.
[[ "$IS_SSH_SESSION" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/ssh")

# 8. Company-specific configurations - Indeed prioritized
if [[ "$IS_INDEED_ENV" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/indeed")
    # Load Indeed-specific OS configs if they exist
    [[ "$IS_MACOS" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/indeed/macos")
    [[ "$IS_LINUX" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/indeed/linux")
    # VPN specific configurations
    [[ "$HAS_WARP_VPN" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/indeed/warp")
elif [[ "$IS_GOOGLE_ENV" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/companies/google")
elif [[ "$IS_AMAZON_ENV" == true ]]; then
    CONFIG_SOURCES+=("$BASE_DIR/companies/amazon")
fi

# 9. Cloud provider-specific configurations
[[ "$IS_AWS" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/cloud/aws")
[[ "$IS_GCP" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/cloud/gcp")
[[ "$IS_DIGITALOCEAN" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/cloud/digitalocean")
[[ "$IS_LINODE" == true ]] && CONFIG_SOURCES+=("$BASE_DIR/cloud/linode")

# --- Load all configurations ---
for config_source in "${CONFIG_SOURCES[@]}"; do
    source_files_from_dir "$config_source"
done

# --- Finalization ---

# Load user-specific function overrides (last to ensure they take precedence)
[[ -f "$BASE_DIR/user_functions.sh" ]] && source "$BASE_DIR/user_functions.sh"
[[ -f "$HOME/.local_profile" ]] && source "$HOME/.local_profile"

# Turn off debug mode if it was enabled
[[ -n "$DEBUG" ]] && set +x

log "INFO" "Environment setup complete"


# Log all sourced directories
log "DEBUG" "Sourced configuration directories:"
for config_source in "${CONFIG_SOURCES[@]}"; do
    log "DEBUG" "  - $config_source"
done
