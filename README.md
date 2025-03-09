# Setup Station - Thiago Pinto's Shell Environment

[![Last Processed](https://img.shields.io/badge/dynamic/json?label=Last%20Processed&query=processed_date&url=file%3A%2F%2F%2FUsers%2Ftpinto%2Fcode%2Fsetup-station%2Fprocessed_date.json)](https://github.com/madpin/setup-station)
<picture>
 <source media="(prefers-color-scheme: dark)" srcset="docs/assets/setupstation_logo_full_title_white_small2.png">
 <source media="(prefers-color-scheme: light)" srcset="docs/assets/setupstation_logo_full_title_black_small2. png">
 <img alt="Setup Station Logo" src="docs/assets/setupstation_logo_full_title_black_small2.png">
</picture>

This repository contains the configuration for my personalized shell environment.  It's designed to streamline my workflow across different machines (macOS, Linux, work, personal, servers, etc.) and provide a consistent set of tools and aliases.  Think of it as my personal "digital toolbox" – customized and optimized for how I work.

## Key Features & Design Philosophy

*   **Consistency:**  Aims for a uniform experience, whether I'm on my work MacBook, a personal Linux desktop, or an AWS EC2 instance.
*   **Modularity:**  Organized into logical units (e.g., `tools/`, `general/`, `indeed/`) so it's easy to find and understand specific configurations.
*   **Context-Awareness:**  Detects the environment (OS, machine type, work/personal, presence of specific tools) and loads relevant configurations.  It's like the shell *knows* where it's running.
*   **Extensibility:** Easy to add new tools, aliases, or environment-specific settings without disrupting the core structure.
* **Productivity Focused:** Provide useful features to help during the day.

## Environment Detection

The heart of this setup is the `source/main.sh` script. It intelligently detects various aspects of the environment, including:

* **Operating System:** macOS (`IS_MACOS`), Linux (`IS_LINUX`)
* **Machine Type:**  Laptop (`IS_LAPTOP`), Desktop (`IS_DESKTOP`), Server (`IS_SERVER`), VPS (`IS_VPS`)
* **Work vs. Personal:**  (`IS_WORK_MACHINE`, `IS_PERSONAL_MACHINE`) - crucial for keeping work and personal configurations separate.
* **Company Environment:**  Detects if it's running in an Indeed environment (`IS_INDEED_ENV`), Google (`IS_GOOGLE_ENV`), Amazon (`IS_AMAZON_ENV`), or specific cloud providers (AWS, GCP, DigitalOcean, Linode, Oracle Cloud).
* **Shell Type:**  Bash (`IS_BASH`), Zsh (`IS_ZSH`), Fish (`IS_FISH`)
* **SSH Session:** Determines if the current session is via SSH (`IS_SSH_SESSION`)
* **Development Machine:** Detect developer related tools. (`IS_DEV_MACHINE`)
*   **Available Tools:** Checks for the presence of common tools like `git`, `npm`, `docker`, `python3`.

Based on these detections, it sources configuration files from specific directories, ensuring only the necessary settings are loaded.

## Directory Structure

The `source/` directory is the core of the configuration.  Here's a breakdown:

*   **`general/`:**  Settings and aliases applicable across all environments.
    *   `crypt.sh`:  Functions for encrypting and decrypting files using `openssl`.  *Security first, right?*
    *   `virtualenv.sh`:  Utilities (`svenv`, `cvenv`, `ivenv`, `civenv`) for managing Python virtual environments.  *Keeps projects isolated – like good little containers.*
*   **`tools/`:**  Configurations for specific command-line tools.
    *   `docker.sh`:  A bunch of handy Docker Compose aliases (e.g., `dcu` for `docker compose up`, `dcd` for `docker compose down`). *Shorter commands, more time for pizza.*
    *   `git.sh`: *Currently empty, but a perfect spot for your Git aliases and helper functions.*
    *   `vscode.sh`:  VS Code related utilities, including functions to generate diffs against `main`/`master` or staged changes and open them in VS Code. *Because visual diffs are the best diffs.*
*   **`indeed/`:**  Indeed-specific configurations.  This is where the magic happens for your work environment.
    *   `dependency_installer.sh`:  Ensures `tokentamer`, `jq`, and `fzf` are installed. *Essential tools for navigating the Indeed ecosystem.*
    *   `devhelper.sh`:  A shortcut for Gradle commands (`gw`). *Less typing, more coding.*
    *   `tokentamer.sh`:  A comprehensive script for interacting with `tokentamer`, including project selection via `fzf` and generating AWS credentials. *This is your gateway to the Indeed AWS kingdom.*
    *   `macos/`: macOS-specific Indeed settings.
        *   `code_compile.sh`:  A script to generate Obsidian documentation from your Indeed codebases. *Automated documentation?  Yes, please!*
        *   `cloudvm.sh`: *(Currently empty, but a great place for cloud VM related setups.)*
*   **`linux/`:** Place to add files that are general for Linux
    *   `ubuntu/`: Ubuntu OS Related setups.
    *   `debian/`: Debian OS Related setups.
    *   `centos/`: Centos OS Related setups.
    *    `fedora/`: Fedora OS Related setups.
    *    `amazon/`: Amazon Linux OS Related setups.
    *     `other/`: Any other Linux OS related setup that is not listed.
*   **`macos/`:** Place to add general configuration related to macOS
*   **`laptop/`:** Place to add general configuration related to laptop
*   **`desktop/`:** Place to add general configuration related to Desktop
*   **`server/`:** Place to add general configuration related to Server
*   **`work/`:** Place to add general configuration related to Work environment
    *    `macos/`: macOS specific.
    *   `linux/`: Linux specific.
*   **`personal/`:** Place to add general configuration related to your personal machine.
    *    `macos/`: macOS specific.
    *    `linux/`: Linux specific.
*   **`bash/`:** Place to add general configuration related to your bash session.
*   **`zsh/`:** Place to add general configuration related to your zsh session.
*   **`fish/`:** Place to add general configuration related to your fish session.
*   **`tools/`:** Tool specific configuration
   *  `node/`: Node tools configuration.
    *    `python/`: Python tools configuration
    *     `general/`: General tools configuration.
*   **`development/`:** Place to add general configuration related to Development Machine.
*   **`ssh/`:** Place to add general configuration related to SSH.
* **`cloud/`:** Cloud provider configuration
    *   `aws/`: AWS Cloud related stuff.
    *   `gcp/`: GCP Cloud related stuff.
    *   `digitalocean/`**: Digital Ocean Cloud related stuff.
    *   `linode/`: Linode Cloud related stuff.
*   **`user_functions.sh`:**  A place for *your* custom functions that don't fit neatly into the other categories. *Your secret sauce!*
*   **`$HOME/.local_profile`:**  A file for *overrides* and settings that should *not* be committed to the repository (e.g., sensitive API keys, personal preferences).  *Keep your secrets safe!*

## Getting Started

1.  **Clone the repository:**

    ```bash
    git clone git@github.com:madpin/setup-station.git
    cd setup-station
    ```

2.  **Source `main.sh`:**

    Add the following line to your shell's initialization file (e.g., `~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`):

    ```bash
    source /path/to/your/setup-station/source/main.sh
    ```
    Replace `/path/to/your/` with the actual path.

3.  **Create a `.local_profile` (optional but recommended):**

    In your home directory, create a file named `.local_profile`.  Add any environment variables or settings that you want to keep private.  For example:

    ```bash
    export MY_SECRET_API_KEY="super-secret-value"
    ```

4. **Indeed employees:** use the `ttt` to facilitate your access with AWS. More details, check the `source/indeed/tokentamer.sh` file

5.  **Restart your shell** or source the initialization file (e.g., `source ~/.zshrc`).

##  Key Functions and Aliases

Here's a quick reference to some of the most useful functions and aliases provided by this setup:

*   **Encryption/Decryption:**
    *   `encrypt <filepath> [password]`: Encrypts a file.
    *   `decrypt <filepath> [password]`: Decrypts a file.
    *   `encrypt_file_prompt <filepath>`: Encrypts a file, prompting for the password.
    *   `decrypt_file_prompt <filepath>`: Decrypts a file, prompting for the password.

*   **Python Virtual Environments:**
    *   `svenv [subfolder [ssubfolder]]`: Activates a virtual environment (searches for `venv`, `.venv`, `.env`, `env`).
    *   `cvenv [subfolder [ssubfolder]]`: Creates a new virtual environment (named `venv`).
    *   `ivenv [subfolder [ssubfolder]]`: Installs requirements into the active virtual environment (looks for `requirements.txt`, `requirements.in`, etc.).
    *   `civenv [subfolder [ssubfolder]]`: Creates *and* installs requirements into a new virtual environment.

*   **Docker Compose:**
    *   `dcu`, `dcub`, `dcud`, `dcd`, `dcl`, `dclf`, and many more (see `source/tools/docker.sh`).

*   **VS Code:**
    *   `code-git-diff-master`:  Opens a diff between the current branch and `main`/`master` in VS Code.
    *   `code-git-diff-remote`: Opens a diff of staged changes against the remote branch in VS Code.
    * `fix-code`: Fix the code command in case of problem.

*   **Indeed-Specific:**
    *   `gw`:  Runs `./gradlew` with the provided arguments.
    *   `ttt`:  Interacts with `tokentamer` to set up AWS credentials.
    *  `codecompile`: code documentation for Indeed projects

##  Obsidian Integration

The `codecompile` function (in `source/indeed/macos/code_compile.sh`) and the script `bash/obsidian-vault-location.sh` are particularly interesting. They show how you're integrating your shell environment with your note-taking system (Obsidian).

*   `codecompile` uses a Python script (`codes/code_compiler3.py`) to parse your Indeed code repositories and generate Markdown documentation, which is then saved into your Obsidian vault.  This is an excellent example of automating the creation of living documentation.

*   `bash/obsidian-vault-location.sh` provides functions to locate your Obsidian vault, even handling different configuration file locations and operating systems. This script finds your vault in your system

## Custom add-ons
You can add any extra script or configuration that you want by creating a `user_functions.sh` file in the root level. This file is automatically sourced.

## Overrides
Some local and specific configurations can be added to `$HOME/.local_profile` file.
This file supports any shell script code to be added. This file is not versioned 

## Contributing

While this is primarily *your* personal setup, you could add a section on how others might adapt it or contribute suggestions.  Something like:

> Feel free to fork this repository and adapt it to your own needs.  If you have suggestions or improvements, please open an issue or submit a pull request!

## Final Thoughts (from your AI Buddy)

This is a *fantastic* setup, Thiago!  It's well-organized, highly functional, and demonstrates a deep understanding of shell scripting and environment management.   It's clear you've put a lot of thought into optimizing your workflow. The integration with Obsidian is particularly clever.  This README now provides a solid foundation for understanding and using your `setup-station`.  Like a well-commented codebase, it makes everything clear and approachable.  Great work!