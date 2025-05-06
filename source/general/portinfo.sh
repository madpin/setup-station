# ~/.zshrc

# Function to get detailed info about the process listening on a specific TCP port
# Attempts to run without sudo first, falling back to sudo if necessary.
# Includes kill command suggestions and context hints.
portinfo() {
  # Check if port argument is provided
  if [[ -z "$1" ]]; then
    echo "Usage: portinfo <port_number>"
    echo "Example: portinfo 8091"
    return 1
  fi

  local port=$1
  local pid user command_name address full_command cwd process_info
  local sudo_used_lsof=0
  local sudo_used_cwd=0

  echo "🔎 Checking TCP Port: $port (attempting without sudo first)"
  echo "---------------------------------------"

  # --- Find Listening Process ---
  # Try lsof without sudo first
  process_info=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | tail -n +2 | head -n 1)

  # If not found by current user, try with sudo
  if [[ -z "$process_info" ]]; then
    echo "ℹ️ Process not found as current user. Trying with sudo..."
    process_info=$(sudo lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | tail -n +2 | head -n 1)
    if [[ -n "$process_info" ]]; then
      sudo_used_lsof=1
    fi
  fi

  # Check if any process was found even with sudo
  if [[ -z "$process_info" ]]; then
    echo "❌ No process found listening on TCP port $port (even with sudo)."
    echo "---------------------------------------"
    # Add hints for common non-process holders
    echo "💡 Common non-process checks:"
    echo "   - Docker: Check if a container is publishing the port:"
    echo "     \`docker ps --filter publish=$port\`"
    echo "   - VS Code Remote/Forwarding: Check your VS Code 'Ports' tab or settings."
    echo "   - System Services/LaunchDaemons: Less common for high ports, but possible."
    echo "---------------------------------------"
    return 0
  fi

  # --- Extract Basic Info ---
  pid=$(echo "$process_info" | awk '{print $2}')
  user=$(echo "$process_info" | awk '{print $3}')
  command_name=$(echo "$process_info" | awk '{print $1}')
  address=$(echo "$process_info" | awk '{print $9}')

  echo "✅ Process Found Listening!"
  [ $sudo_used_lsof -eq 1 ] && echo "   (sudo was required to initially find the process)"
  echo "---------------------------------------"
  echo " PID             : $pid"
  echo " User            : $user"
  echo " Command (lsof)  : $command_name"
  echo " Listening Addr  : $address"

  # --- Added Kill Commands ---
  echo "---------------------------------------"
  echo " Kill Commands (use with caution!):"
  # Suggest sudo for kill, as it's often needed if the process belongs to another user or root
  echo "   Graceful stop : \`sudo kill $pid\`"
  echo "   Force stop    : \`sudo kill -9 $pid\`"
  echo "---------------------------------------"

  # --- Get Full Command ---
  # ps usually doesn't require sudo for this part if the process exists
  full_command=$(ps -ww -o command= -p "$pid" 2>/dev/null)
  if [[ -n "$full_command" ]]; then
    echo " Full Command (ps): $full_command"
  else
     echo " Full Command (ps): (Could not retrieve)"
     full_command="" # Ensure it's empty for later checks
  fi

  # --- Get Current Working Directory (CWD) ---
  # Try lsof first without sudo
  cwd=$(lsof -p "$pid" -a -d cwd -Fn 2>/dev/null | grep '^n' | cut -c2-)

  # If lsof failed, try ps without sudo
  if [[ -z "$cwd" ]]; then
    cwd=$(ps -o pwd= -p "$pid" 2>/dev/null | tail -n 1 | awk '{$1=$1};1') # awk trims whitespace
    [[ "$cwd" == "-" ]] && cwd="" # Reset if ps returns "-"
  fi

  # If still no CWD, try lsof with sudo
  if [[ -z "$cwd" ]]; then
    echo "ℹ️ Could not get CWD as current user. Trying with sudo..."
    cwd=$(sudo lsof -p "$pid" -a -d cwd -Fn 2>/dev/null | grep '^n' | cut -c2-)
     if [[ -n "$cwd" ]]; then
       sudo_used_cwd=1
     fi
  fi

  # If still no CWD, try ps with sudo
  if [[ -z "$cwd" ]]; then
     cwd=$(sudo ps -o pwd= -p "$pid" 2>/dev/null | tail -n 1 | awk '{$1=$1};1')
     if [[ -n "$cwd" && "$cwd" != "-" ]]; then
         sudo_used_cwd=1
     else
         cwd="" # Ensure CWD is empty if not found
     fi
  fi

  # Print CWD result
  if [[ -n "$cwd" ]]; then
    echo -n " Working Dir (CWD): $cwd"
    [ $sudo_used_cwd -eq 1 ] && echo " (sudo required for CWD)" || echo ""
  else
    echo " Working Dir (CWD): (Could not retrieve or N/A)"
  fi

  echo "---------------------------------------"

  # --- Added Hints based on command ---
  if [[ -n "$full_command" ]]; then
    echo "💡 Hints based on command:"
    # Use case-insensitive matching (requires Zsh options or explicit conversion)
    setopt localoptions extendedglob # Apply option only to this function's scope
    local lower_full_command=${full_command:l} # Convert to lowercase for matching

    if [[ "$lower_full_command" =~ "docker" || "$command_name" =~ "docker" || "$command_name" == (#i)com.docker* ]]; then
        echo "   - Command suggests Docker. It might be a container process or Docker Desktop itself."
        echo "     Check running containers: \`docker ps\`"
        echo "     Inspect container ports: \`docker port <container_id_or_name>\`"
    elif [[ "$lower_full_command" =~ "(code|vscode)" || ("$lower_full_command" =~ "node" && "$lower_full_command" =~ "--remote") ]]; then
        echo "   - Command suggests VS Code or a related process (like Node.js used by extensions)."
        echo "     Check VS Code's 'Ports' tab (View > Ports) or Remote Explorer if using remote dev."
        echo "     Port forwarding might be active."
    elif [[ "$lower_full_command" =~ "^(/usr/bin/|/usr/local/bin/)?python([3-9](\.[0-9]+)?)?" ]]; then
        echo "   - Python script detected. The 'Full Command' likely shows the script path."
    elif [[ "$lower_full_command" =~ "^(/usr/bin/|/usr/lib/jvm/|/opt/)?java($| )" ]]; then
       echo "   - Java application detected. Could be a web server (Tomcat, Jetty), app, etc."
    elif [[ "$lower_full_command" =~ "^(/usr/bin/|/usr/local/bin/)?node($| )" && ! "$lower_full_command" =~ "--remote" ]]; then # Exclude vscode remote case handled above
        echo "   - Node.js process detected. Could be a web server, build tool, or script."
    fi
      echo "   - Check the 'Full Command' and 'Working Dir' above for more context."
    echo "---------------------------------------"
    # extendedglob restored automatically by localoptions
  fi

  return 0
}