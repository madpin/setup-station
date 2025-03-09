
install_tokentamer() {
  if ! command -v tokentamer &>/dev/null; then
    printf "tokentamer not found, installing...\n"
    curl -O https://nexus.indeed.tech/repository/pre-built-binaries/tokentamer/macos/latest/tokentamer
    chmod +x tokentamer
    printf "We're installing tokentamer, so sudo password is needed\n"
    sudo mv tokentamer /usr/local/bin

  fi
}

install_jq() {
  if ! command -v jq &>/dev/null; then
    echo "jq could not be found. Trying to install..."

    if command -v brew &>/dev/null; then
      # macOS with Homebrew
      brew install jq
    elif command -v apt-get &>/dev/null; then
      # Debian/Ubuntu
      sudo apt-get install -y jq
    elif command -v yum &>/dev/null; then
      # RHEL/CentOS/Fedora
      sudo yum install -y jq
    elif command -v dnf &>/dev/null; then
      # Modern Fedora
      sudo dnf install -y jq
    else
      printf "No supported package manager found (brew/apt-get/yum/dnf).\n"
      exit 1
    fi

    if ! command -v jq &>/dev/null; then
      printf "Failed to install jq.\n"
      exit 1
    fi

    echo "jq installed successfully."
  fi
}

install_fzf() {
  if ! command -v fzf &>/dev/null; then
    printf "fzf could not be found, attempting to install...\n"

    if command -v brew &>/dev/null; then
      # macOS with Homebrew
      brew install fzf
    elif command -v apt-get &>/dev/null; then
      # Debian/Ubuntu
      sudo apt-get install -y fzf
    elif command -v yum &>/dev/null; then
      # RHEL/CentOS/Fedora
      sudo yum install -y fzf
    elif command -v dnf &>/dev/null; then
      # Modern Fedora
      sudo dnf install -y fzf
    else
      printf "No supported package manager found (brew/apt-get/yum/dnf).\n"
      exit 1
    fi

    # check if fzf installation was successful
    if ! command -v fzf &>/dev/null; then
      printf "Failed to install fzf.\n"
      exit 1
    fi

    printf "fzf installed successfully.\n"
  fi
}