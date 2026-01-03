#!/bin/bash
# =============================================================================
#
#   ███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗███████╗██████╗ ██████╗  ██████╗ ████████╗
#   ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝
#   ███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║█████╗  ██████╔╝██████╔╝██║   ██║   ██║
#   ╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██╗██║   ██║   ██║
#   ███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║███████╗██║  ██║██████╔╝╚██████╔╝   ██║
#   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝
#
#   ScreenerBot VPS Manager - Installation, Update & Management Tool
#   https://screenerbot.io
#
#   Automated Solana DeFi Trading Bot
#   Copyright © 2025 ScreenerBot. All rights reserved.
#
# =============================================================================
#
# USAGE:
#   curl -fsSL https://screenerbot.io/install.sh | bash
#   OR
#   bash <(curl -fsSL https://raw.githubusercontent.com/screenerbotio/ScreenerBot-Public/main/screenerbot.sh)
#   OR
#   wget -qO- https://screenerbot.io/install.sh | bash
#
# FEATURES:
#   • Install/Update/Uninstall ScreenerBot
#   • Systemd service management
#   • Backup and restore data
#   • Auto-update notifications via Telegram
#   • Version selection with API integration
#   • Architecture auto-detection (x64/arm64)
#
# =============================================================================

set -e

# =============================================================================
# Configuration & Constants
# =============================================================================

readonly SCRIPT_VERSION="1.0.0"
readonly API_BASE="https://screenerbot.io/api"
readonly GITHUB_RAW="https://raw.githubusercontent.com/screenerbotio/ScreenerBot-Public/main"
readonly INSTALL_DIR="/opt/screenerbot"
readonly SYMLINK_PATH="/usr/local/bin/screenerbot"
readonly SERVICE_NAME="screenerbot"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
readonly UPDATE_TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}-update.timer"
readonly UPDATE_SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}-update.service"

# Data directory detection (follows XDG spec)
get_data_dir() {
    local user="${SUDO_USER:-$USER}"
    local home_dir
    if [ -n "$SUDO_USER" ]; then
        home_dir=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        home_dir="$HOME"
    fi
    
    if [ -n "${XDG_DATA_HOME:-}" ]; then
        echo "${XDG_DATA_HOME}/ScreenerBot"
    else
        echo "${home_dir}/.local/share/ScreenerBot"
    fi
}

# =============================================================================
# Colors & Formatting
# =============================================================================

# Check if terminal supports colors
if [ -t 1 ] && command -v tput &>/dev/null; then
    readonly RED=$(tput setaf 1)
    readonly GREEN=$(tput setaf 2)
    readonly YELLOW=$(tput setaf 3)
    readonly BLUE=$(tput setaf 4)
    readonly MAGENTA=$(tput setaf 5)
    readonly CYAN=$(tput setaf 6)
    readonly WHITE=$(tput setaf 7)
    readonly BOLD=$(tput bold)
    readonly DIM=$(tput dim)
    readonly RESET=$(tput sgr0)
else
    readonly RED=""
    readonly GREEN=""
    readonly YELLOW=""
    readonly BLUE=""
    readonly MAGENTA=""
    readonly CYAN=""
    readonly WHITE=""
    readonly BOLD=""
    readonly DIM=""
    readonly RESET=""
fi

# Icons (ASCII for maximum compatibility)
readonly ICON_CHECK="[+]"
readonly ICON_CROSS="[x]"
readonly ICON_ARROW="->"
readonly ICON_BULLET="*"
readonly ICON_INFO="[i]"
readonly ICON_WARN="[!]"
readonly ICON_ROCKET="*"
readonly ICON_PACKAGE="[+]"
readonly ICON_DOWNLOAD="[-]"
readonly ICON_UPDATE="[~]"
readonly ICON_TRASH="[x]"
readonly ICON_BACKUP="[S]"
readonly ICON_RESTORE="[R]"
readonly ICON_SERVICE="[=]"
readonly ICON_STATUS="[i]"
readonly ICON_BELL="[!]"
readonly ICON_HELP="[?]"
readonly ICON_EXIT="[Q]"
readonly ICON_BACK="<-"
readonly ICON_START=">"
readonly ICON_STOP="#"
readonly ICON_RESTART="~"
readonly ICON_LOGS="[L]"
readonly ICON_TELEGRAM="[T]"

# =============================================================================
# Logging & UI Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}${ICON_INFO}${RESET} $1"
}

log_success() {
    echo -e "${GREEN}${ICON_CHECK}${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}${ICON_WARN}${RESET} $1"
}

log_error() {
    echo -e "${RED}${ICON_CROSS}${RESET} $1" >&2
}

log_step() {
    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}${BOLD}▶ $1${RESET}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Spinner animation for long-running tasks
spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spinchars='|/-\\'
    local i=0
    
    # Hide cursor if possible
    tput civis 2>/dev/null || true
    
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spinchars:$i:1}"
        printf "\r${CYAN}%s${RESET} %s" "$char" "$message"
        i=$(( (i + 1) % ${#spinchars} ))
        sleep 0.1
    done
    printf "\r\033[K"  # Clear line
    
    # Show cursor
    tput cnorm 2>/dev/null || true
}

# Progress bar animation
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r  ["
    printf "%${filled}s" '' | tr ' ' '█'
    printf "%${empty}s" '' | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

# Interactive menu with arrow key navigation
# Uses pure ANSI escape codes for maximum compatibility (no tput)
# Usage: select_menu "option1" "option2" "option3"
# Returns: selected index (0-based) in $MENU_RESULT
select_menu() {
    local options=("$@")
    local count=${#options[@]}
    local selected=0
    
    # Ensure we have a terminal for input
    if [ ! -r /dev/tty ]; then
        echo "Error: No terminal available for interactive menu" >&2
        MENU_RESULT=0
        return 1
    fi
    
    # Save terminal settings and ensure proper restoration
    local saved_tty_settings
    saved_tty_settings=$(stty -g < /dev/tty 2>/dev/null) || true
    
    # Cleanup function
    cleanup_menu() {
        printf "\033[?25h"  # Show cursor
        [ -n "$saved_tty_settings" ] && stty "$saved_tty_settings" < /dev/tty 2>/dev/null || true
    }
    trap cleanup_menu EXIT INT TERM
    
    # ANSI escape sequences (work everywhere, no tput needed)
    local ESC=$'\033'
    local CURSOR_UP="${ESC}[A"
    local CLEAR_LINE="${ESC}[2K"
    local CURSOR_HIDE="${ESC}[?25l"
    local CURSOR_SHOW="${ESC}[?25h"
    local REVERSE="${ESC}[7m"
    local NORMAL="${ESC}[27m"
    local RESET_ALL="${ESC}[0m"
    local COLOR_CYAN="${ESC}[36m"
    local COLOR_DIM="${ESC}[2m"
    local COLOR_BOLD="${ESC}[1m"
    
    # Hide cursor
    printf "%s" "$CURSOR_HIDE"
    
    # Print navigation hint
    echo ""
    printf "  %sUp/Down: Navigate  |  Enter: Select  |  Q: Quit%s\n" "$COLOR_DIM" "$RESET_ALL"
    echo ""
    
    # Function to print menu
    print_menu() {
        local sel=$1
        for i in "${!options[@]}"; do
            printf "%s" "$CLEAR_LINE"
            if [ "$i" -eq "$sel" ]; then
                printf "  %s%s%s> %s%s\n" "$COLOR_CYAN" "$COLOR_BOLD" "$REVERSE" "${options[$i]}" "$RESET_ALL"
            else
                printf "    %s%s%s\n" "$COLOR_DIM" "${options[$i]}" "$RESET_ALL"
            fi
        done
    }
    
    # Print initial menu
    print_menu $selected
    
    # Flush input buffer to prevent auto-selection
    while read -r -t 0 -n 1 2>/dev/null; do read -r -n 1 2>/dev/null; done < /dev/tty
    
    # Main input loop
    while true; do
        # Read key input from /dev/tty
        local key=""
        local read_result=0
        
        # Use a block to ensure we read from tty
        {
            IFS= read -rsn1 key 2>/dev/null || read_result=$?
        } < /dev/tty
        
        # If read failed (no terminal or EOF), exit gracefully
        if [ $read_result -ne 0 ]; then
            sleep 0.1
            continue
        fi
        
        # Check for escape sequence (arrow keys start with ESC)
        if [[ "$key" == $'\033' ]]; then
            # Read the rest of the escape sequence
            local rest=""
            {
                IFS= read -rsn2 -t 0.1 rest 2>/dev/null || true
            } < /dev/tty
            key="${key}${rest}"
        fi
        
        # Process key
        case "$key" in
            $'\033[A')  # Up arrow
                if [ $selected -gt 0 ]; then
                    ((selected--))
                fi
                ;;
            $'\033[B')  # Down arrow
                if [ $selected -lt $((count - 1)) ]; then
                    ((selected++))
                fi
                ;;
            ''|$'\n')  # Enter key (empty or newline)
                break
                ;;
            q|Q)  # Quit
                selected=-1
                break
                ;;
            k|K)  # Vim-style up
                if [ $selected -gt 0 ]; then
                    ((selected--))
                fi
                ;;
            j|J)  # Vim-style down
                if [ $selected -lt $((count - 1)) ]; then
                    ((selected++))
                fi
                ;;
        esac
        
        # Move cursor up to redraw menu (using ANSI escape)
        printf "%s" "${ESC}[${count}A"
        
        # Redraw menu
        print_menu $selected
    done
    
    # Cleanup: show cursor and restore terminal
    printf "%s" "$CURSOR_SHOW"
    trap - EXIT INT TERM  # Remove trap
    [ -n "$saved_tty_settings" ] && stty "$saved_tty_settings" < /dev/tty 2>/dev/null || true
    
    echo ""
    MENU_RESULT=$selected
}

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╔══════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                                          ║
    ║   ███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗███████╗██████╗ ██████╗  ██████╗ ████████╗           ║
    ║   ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝           ║
    ║   ███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║█████╗  ██████╔╝██████╔╝██║   ██║   ██║              ║
    ║   ╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██╗██║   ██║   ██║              ║
    ║   ███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║███████╗██║  ██║██████╔╝╚██████╔╝   ██║              ║
    ║   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝              ║
    ║                                                                                                          ║
    ║                            Automated Solana DeFi Trading Bot                                             ║
    ║                                  VPS Management Tool v1.0.0                                              ║
    ║                                                                                                          ║
    ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${RESET}"
    echo -e "${DIM}                     https://screenerbot.io  •  Telegram: @screenerbotio${RESET}"
    echo ""
}

print_separator() {
    echo -e "${DIM}─────────────────────────────────────────────────────────────────────────────────${RESET}"
}

confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    local yn_prompt
    if [ "$default" = "y" ]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi
    
    echo -en "${YELLOW}${ICON_WARN}${RESET} ${prompt} ${yn_prompt}: "
    read -r response < /dev/tty
    
    if [ -z "$response" ]; then
        response="$default"
    fi
    
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

press_enter() {
    echo ""
    echo -en "${DIM}Press Enter to continue...${RESET}"
    read -r < /dev/tty
}

# =============================================================================
# System Detection & Validation
# =============================================================================

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "x64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo ""
            ;;
    esac
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

get_glibc_version() {
    if command -v ldd &>/dev/null; then
        ldd --version 2>&1 | head -1 | grep -oP '\d+\.\d+' | head -1
    else
        echo "0.0"
    fi
}

check_requirements() {
    log_step "Checking System Requirements"
    
    local errors=0
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        log_warn "This script requires root privileges for installation"
        log_info "Please run with: sudo screenerbot"
        echo ""
        if ! confirm "Continue anyway? (some features may not work)"; then
            exit 1
        fi
    fi
    
    # Check architecture
    local arch
    arch=$(detect_arch)
    if [ -z "$arch" ]; then
        log_error "Unsupported architecture: $(uname -m)"
        log_info "ScreenerBot supports x86_64 (Intel/AMD) and aarch64 (ARM64)"
        errors=$((errors + 1))
    else
        log_success "Architecture: ${BOLD}$(uname -m)${RESET} (${arch})"
    fi
    
    # Check GLIBC version
    local glibc_version
    glibc_version=$(get_glibc_version)
    if [ -n "$glibc_version" ]; then
        local required_glibc="2.29"
        if printf '%s\n%s\n' "$required_glibc" "$glibc_version" | sort -V -C; then
            log_success "GLIBC version: ${BOLD}${glibc_version}${RESET} (≥${required_glibc} required)"
        else
            log_error "GLIBC version ${glibc_version} is too old (≥${required_glibc} required)"
            log_info "Please upgrade your system or use a newer distribution"
            errors=$((errors + 1))
        fi
    fi
    
    # Check available memory
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    if [ "$total_mem_gb" -lt 3 ]; then
        log_warn "RAM: ${BOLD}${total_mem_gb}GB${RESET} (4GB+ recommended)"
    else
        log_success "RAM: ${BOLD}${total_mem_gb}GB${RESET}"
    fi
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 4 ]; then
        log_warn "CPU cores: ${BOLD}${cpu_cores}${RESET} (4+ recommended)"
    else
        log_success "CPU cores: ${BOLD}${cpu_cores}${RESET}"
    fi
    
    # Check disk space
    local free_space_gb
    free_space_gb=$(df -BG "${INSTALL_DIR%/*}" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
    if [ -n "$free_space_gb" ] && [ "$free_space_gb" -lt 5 ]; then
        log_warn "Free disk space: ${BOLD}${free_space_gb}GB${RESET} (5GB+ recommended)"
    elif [ -n "$free_space_gb" ]; then
        log_success "Free disk space: ${BOLD}${free_space_gb}GB${RESET}"
    fi
    
    # Check required commands
    local required_cmds=("curl" "tar" "systemctl")
    for cmd in "${required_cmds[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_success "Required command: ${BOLD}${cmd}${RESET}"
        else
            log_error "Missing required command: ${BOLD}${cmd}${RESET}"
            errors=$((errors + 1))
        fi
    done
    
    # Check optional commands
    local optional_cmds=("jq")
    for cmd in "${optional_cmds[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_success "Optional command: ${BOLD}${cmd}${RESET}"
        else
            log_info "Optional command not found: ${BOLD}${cmd}${RESET} (will use fallback)"
        fi
    done
    
    echo ""
    if [ $errors -gt 0 ]; then
        log_error "System check failed with $errors error(s)"
        return 1
    else
        log_success "All system requirements met!"
        return 0
    fi
}

# =============================================================================
# API Functions
# =============================================================================

# Fetch JSON from API with error handling (with spinner)
api_fetch() {
    local endpoint="$1"
    local url="${API_BASE}${endpoint}"
    local response
    local temp_file
    temp_file=$(mktemp)
    
    # Run curl in background with spinner
    curl -fsSL --connect-timeout 10 --max-time 30 "$url" > "$temp_file" 2>&1 &
    local curl_pid=$!
    spinner "$curl_pid" "Connecting to API..."
    wait "$curl_pid"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        rm -f "$temp_file"
        return 1
    fi
    
    response=$(cat "$temp_file")
    rm -f "$temp_file"
    echo "$response"
}

# Parse JSON (with jq or fallback)
json_get() {
    local json="$1"
    local key="$2"
    
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r "$key" 2>/dev/null
    else
        # Fallback: simple grep/sed parsing for basic keys
        echo "$json" | grep -oP "\"${key}\"\s*:\s*\"?\K[^,\"}]+" | head -1
    fi
}

# Get latest release info
get_latest_release() {
    local response
    if ! response=$(api_fetch "/releases/latest"); then
        return 1
    fi
    
    if command -v jq &>/dev/null; then
        local success
        success=$(echo "$response" | jq -r '.success' 2>/dev/null)
        if [ "$success" != "true" ]; then
            log_error "API returned error"
            return 1
        fi
    fi
    
    echo "$response"
}

# Check for updates
check_update_available() {
    local current_version="$1"
    local platform="$2"
    
    local response
    if ! response=$(api_fetch "/releases/check?version=${current_version}&platform=${platform}"); then
        return 1
    fi
    
    echo "$response"
}

# Get download URL for specific platform
get_download_url() {
    local version="$1"
    local platform="$2"
    
    echo "${API_BASE}/releases/download?version=${version}&platform=${platform}&mode=update"
}

# =============================================================================
# Version Management
# =============================================================================

get_installed_version() {
    if [ -x "${SYMLINK_PATH}" ] || [ -x "${INSTALL_DIR}/screenerbot" ]; then
        local binary="${SYMLINK_PATH}"
        if [ ! -x "$binary" ]; then
            binary="${INSTALL_DIR}/screenerbot"
        fi
        "$binary" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1
    else
        echo ""
    fi
}

compare_versions() {
    local v1="$1"
    local v2="$2"
    
    # Returns: 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2
    if [ "$v1" = "$v2" ]; then
        return 0
    fi
    
    local IFS='.'
    read -ra v1_parts <<< "$v1"
    read -ra v2_parts <<< "$v2"
    
    for i in 0 1 2; do
        local p1="${v1_parts[$i]:-0}"
        local p2="${v2_parts[$i]:-0}"
        
        if [ "$p1" -gt "$p2" ]; then
            return 1
        elif [ "$p1" -lt "$p2" ]; then
            return 2
        fi
    done
    
    return 0
}

# =============================================================================
# Installation Functions
# =============================================================================

download_and_install() {
    local version="$1"
    local arch
    arch=$(detect_arch)
    
    if [ -z "$arch" ]; then
        log_error "Could not detect system architecture"
        return 1
    fi
    
    local platform="linux-${arch}-headless"
    
    log_step "Installing ScreenerBot v${version}"
    
    log_info "Platform: ${BOLD}${platform}${RESET}"
    log_info "Target directory: ${BOLD}${INSTALL_DIR}${RESET}"
    
    # Create install directory
    if ! mkdir -p "${INSTALL_DIR}"; then
        log_error "Failed to create installation directory"
        return 1
    fi
    
    # Create temp directory for download
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '${temp_dir}'" EXIT
    
    local download_url
    download_url=$(get_download_url "$version" "$platform")
    local tarball="${temp_dir}/screenerbot.tar.gz"
    
    log_info "Downloading from: ${DIM}${download_url}${RESET}"
    
    # Download with progress
    echo ""
    if ! curl -fSL --connect-timeout 30 --max-time 300 \
        --progress-bar \
        -o "$tarball" \
        "$download_url"; then
        log_error "Download failed"
        return 1
    fi
    echo ""
    
    log_success "Download complete"
    
    # Verify tarball
    if [ ! -f "$tarball" ] || [ ! -s "$tarball" ]; then
        log_error "Downloaded file is empty or missing"
        return 1
    fi
    
    local file_size
    file_size=$(du -h "$tarball" | cut -f1)
    log_info "Downloaded: ${BOLD}${file_size}${RESET}"
    
    # Backup existing installation
    if [ -x "${INSTALL_DIR}/screenerbot" ]; then
        local old_version
        old_version=$(get_installed_version)
        log_info "Backing up existing installation (v${old_version})..."
        cp "${INSTALL_DIR}/screenerbot" "${INSTALL_DIR}/screenerbot.backup.${old_version}" 2>/dev/null || true
    fi
    
    # Extract
    log_info "Extracting..."
    if ! tar -xzf "$tarball" -C "${INSTALL_DIR}"; then
        log_error "Failed to extract tarball"
        return 1
    fi
    
    # Make executable
    chmod +x "${INSTALL_DIR}/screenerbot"
    
    # Create symlink
    if [ ! -L "${SYMLINK_PATH}" ] || [ "$(readlink -f "${SYMLINK_PATH}")" != "${INSTALL_DIR}/screenerbot" ]; then
        log_info "Creating symlink: ${SYMLINK_PATH} -> ${INSTALL_DIR}/screenerbot"
        ln -sf "${INSTALL_DIR}/screenerbot" "${SYMLINK_PATH}"
    fi
    
    # Verify installation
    local installed_version
    installed_version=$(get_installed_version)
    if [ -z "$installed_version" ]; then
        log_error "Installation verification failed"
        return 1
    fi
    
    log_success "ScreenerBot v${installed_version} installed successfully!"
    
    return 0
}

uninstall() {
    log_step "Uninstalling ScreenerBot"
    
    # Stop service if running
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        log_info "Stopping service..."
        systemctl stop "${SERVICE_NAME}"
    fi
    
    # Disable service
    if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
        log_info "Disabling service..."
        systemctl disable "${SERVICE_NAME}"
    fi
    
    # Remove service files
    if [ -f "${SERVICE_FILE}" ]; then
        log_info "Removing service file..."
        rm -f "${SERVICE_FILE}"
    fi
    
    if [ -f "${UPDATE_TIMER_FILE}" ]; then
        rm -f "${UPDATE_TIMER_FILE}"
    fi
    
    if [ -f "${UPDATE_SERVICE_FILE}" ]; then
        rm -f "${UPDATE_SERVICE_FILE}"
    fi
    
    systemctl daemon-reload 2>/dev/null || true
    
    # Remove symlink
    if [ -L "${SYMLINK_PATH}" ]; then
        log_info "Removing symlink..."
        rm -f "${SYMLINK_PATH}"
    fi
    
    # Remove installation directory
    if [ -d "${INSTALL_DIR}" ]; then
        log_info "Removing installation directory..."
        rm -rf "${INSTALL_DIR}"
    fi
    
    log_success "ScreenerBot uninstalled successfully!"
    
    # Ask about data directory
    local data_dir
    data_dir=$(get_data_dir)
    if [ -d "$data_dir" ]; then
        echo ""
        log_warn "Data directory still exists: ${data_dir}"
        if confirm "Remove data directory? (This will delete all configs and databases)"; then
            rm -rf "$data_dir"
            log_success "Data directory removed"
        else
            log_info "Data directory preserved at: ${data_dir}"
        fi
    fi
}

# =============================================================================
# Backup & Restore Functions
# =============================================================================

create_backup() {
    local data_dir
    data_dir=$(get_data_dir)
    
    if [ ! -d "$data_dir" ]; then
        log_error "Data directory not found: $data_dir"
        return 1
    fi
    
    log_step "Creating Backup"
    
    # Get the actual user's home directory (not root if using sudo)
    local user_home
    if [ -n "$SUDO_USER" ]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        user_home="$HOME"
    fi
    
    local backup_name="screenerbot-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    local backup_path="${user_home}/${backup_name}"
    
    log_info "Source: ${data_dir}"
    log_info "Backup: ${backup_path}"
    
    # Create backup
    if tar -czf "$backup_path" -C "$(dirname "$data_dir")" "$(basename "$data_dir")"; then
        local backup_size
        backup_size=$(du -h "$backup_path" | cut -f1)
        log_success "Backup created: ${BOLD}${backup_path}${RESET} (${backup_size})"
        
        # Fix ownership if created as root
        if [ -n "$SUDO_USER" ]; then
            chown "$SUDO_USER:$SUDO_USER" "$backup_path" 2>/dev/null || true
        fi
    else
        log_error "Failed to create backup"
        return 1
    fi
    
    return 0
}

restore_backup() {
    log_step "Restore Backup"
    
    # Get the actual user's home directory (not root if using sudo)
    local user_home
    if [ -n "$SUDO_USER" ]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        user_home="$HOME"
    fi
    
    # List available backups
    local backups=()
    while IFS= read -r -d '' file; do
        backups+=("$file")
    done < <(find "${user_home}" -maxdepth 1 -name "screenerbot-backup-*.tar.gz" -print0 2>/dev/null | sort -rz)
    
    if [ ${#backups[@]} -eq 0 ]; then
        log_warn "No backup files found in ${user_home}"
        echo ""
        echo -n "Enter path to backup file: "
        read -r backup_path < /dev/tty
        
        if [ ! -f "$backup_path" ]; then
            log_error "File not found: $backup_path"
            return 1
        fi
    else
        echo ""
        echo "Available backups:"
        echo ""
        local i=1
        for backup in "${backups[@]}"; do
            local size
            size=$(du -h "$backup" | cut -f1)
            local name
            name=$(basename "$backup")
            echo "  ${CYAN}[$i]${RESET} $name ${DIM}($size)${RESET}"
            ((i++))
        done
        echo ""
        echo -n "Select backup [1-${#backups[@]}]: "
        read -r selection < /dev/tty
        
        if [ -z "$selection" ] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups[@]} ]; then
            log_error "Invalid selection"
            return 1
        fi
        
        backup_path="${backups[$((selection-1))]}"
    fi
    
    local data_dir
    data_dir=$(get_data_dir)
    
    # Stop service if running
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        log_info "Stopping service before restore..."
        systemctl stop "${SERVICE_NAME}"
    fi
    
    # Backup current data if exists
    if [ -d "$data_dir" ]; then
        log_warn "Current data directory will be replaced"
        if confirm "Continue with restore?"; then
            local current_backup="${user_home}/screenerbot-pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
            log_info "Backing up current data to: $current_backup"
            tar -czf "$current_backup" -C "$(dirname "$data_dir")" "$(basename "$data_dir")"
            rm -rf "$data_dir"
        else
            log_info "Restore cancelled"
            return 1
        fi
    fi
    
    # Restore
    log_info "Restoring from: $backup_path"
    mkdir -p "$(dirname "$data_dir")"
    
    if tar -xzf "$backup_path" -C "$(dirname "$data_dir")"; then
        log_success "Backup restored successfully!"
    else
        log_error "Failed to restore backup"
        return 1
    fi
    
    return 0
}

# =============================================================================
# Service Management Functions
# =============================================================================

create_service() {
    log_step "Creating Systemd Service"
    
    local user="${SUDO_USER:-$USER}"
    local group="${SUDO_USER:-$USER}"
    local home_dir
    if [ -n "$SUDO_USER" ]; then
        home_dir=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        home_dir="$HOME"
    fi
    
    log_info "Service will run as user: ${BOLD}${user}${RESET}"
    log_info "Working directory: ${BOLD}${home_dir}${RESET}"
    
    cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=ScreenerBot - Automated Solana Trading Bot
Documentation=https://screenerbot.io/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${user}
Group=${group}
WorkingDirectory=${home_dir}
ExecStart=${SYMLINK_PATH}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true

# Environment
Environment="HOME=${home_dir}"
Environment="USER=${user}"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    
    log_success "Service file created: ${SERVICE_FILE}"
    
    echo ""
    if confirm "Enable service to start on boot?" "y"; then
        systemctl enable "${SERVICE_NAME}"
        log_success "Service enabled for auto-start"
    fi
    
    if confirm "Start service now?" "y"; then
        systemctl start "${SERVICE_NAME}"
        sleep 2
        if systemctl is-active --quiet "${SERVICE_NAME}"; then
            log_success "Service started successfully!"
            echo ""
            log_info "Dashboard available at: ${CYAN}http://localhost:8080${RESET}"
            log_info "For remote access, use SSH tunnel:"
            echo ""
            echo "  ${DIM}ssh -L 8080:localhost:8080 ${user}@your-server-ip${RESET}"
        else
            log_error "Service failed to start"
            echo ""
            log_info "Check logs with: ${CYAN}journalctl -u ${SERVICE_NAME} -f${RESET}"
        fi
    fi
}

service_status() {
    echo ""
    echo "${BOLD}Service Status:${RESET}"
    echo ""
    
    if ! systemctl list-unit-files | grep -q "${SERVICE_NAME}"; then
        echo "  ${DIM}Service not installed${RESET}"
        return
    fi
    
    local status
    status=$(systemctl is-active "${SERVICE_NAME}" 2>/dev/null || echo "inactive")
    local enabled
    enabled=$(systemctl is-enabled "${SERVICE_NAME}" 2>/dev/null || echo "disabled")
    
    local status_color
    case "$status" in
        active)
            status_color="${GREEN}"
            ;;
        inactive)
            status_color="${YELLOW}"
            ;;
        failed)
            status_color="${RED}"
            ;;
        *)
            status_color="${DIM}"
            ;;
    esac
    
    echo "  Status:      ${status_color}${BOLD}${status}${RESET}"
    echo "  Auto-start:  ${enabled}"
    
    if [ "$status" = "active" ]; then
        local pid
        pid=$(systemctl show "${SERVICE_NAME}" --property=MainPID --value)
        local uptime
        uptime=$(systemctl show "${SERVICE_NAME}" --property=ActiveEnterTimestamp --value)
        local mem
        mem=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print int($1/1024)"MB"}')
        
        echo "  PID:         ${pid}"
        echo "  Memory:      ${mem:-unknown}"
        echo "  Started:     ${uptime:-unknown}"
    fi
    echo ""
}

service_menu() {
    while true; do
        print_banner
        echo "${BOLD}  ${ICON_SERVICE}  Service Management${RESET}"
        echo ""
        
        service_status
        
        local options=(
            "${ICON_START} Start Service"
            "${ICON_STOP} Stop Service"
            "${ICON_RESTART} Restart Service"
            "${ICON_LOGS} View Logs"
            "${GREEN}+${RESET} Enable Auto-Start"
            "${RED}-${RESET} Disable Auto-Start"
            "${ICON_SERVICE} Create/Recreate Service"
            "${ICON_BACK} Back to Main Menu"
        )
        
        select_menu "${options[@]}"
        local choice=$MENU_RESULT
        
        case "$choice" in
            0)
                if systemctl start "${SERVICE_NAME}" 2>/dev/null; then
                    log_success "Service started"
                else
                    log_error "Failed to start service"
                fi
                press_enter
                ;;
            1)
                if systemctl stop "${SERVICE_NAME}" 2>/dev/null; then
                    log_success "Service stopped"
                else
                    log_error "Failed to stop service"
                fi
                press_enter
                ;;
            2)
                if systemctl restart "${SERVICE_NAME}" 2>/dev/null; then
                    log_success "Service restarted"
                else
                    log_error "Failed to restart service"
                fi
                press_enter
                ;;
            3)
                echo ""
                log_info "Showing last 50 log lines (Ctrl+C to exit live view)..."
                echo ""
                journalctl -u "${SERVICE_NAME}" -n 50 -f 2>/dev/null || log_error "Failed to get logs"
                ;;
            4)
                if systemctl enable "${SERVICE_NAME}" 2>/dev/null; then
                    log_success "Auto-start enabled"
                else
                    log_error "Failed to enable auto-start"
                fi
                press_enter
                ;;
            5)
                if systemctl disable "${SERVICE_NAME}" 2>/dev/null; then
                    log_success "Auto-start disabled"
                else
                    log_error "Failed to disable auto-start"
                fi
                press_enter
                ;;
            6)
                create_service
                press_enter
                ;;
            7|-1)
                break
                ;;
        esac
    done
}

# =============================================================================
# Telegram Notification Functions
# =============================================================================

get_telegram_config() {
    local data_dir
    data_dir=$(get_data_dir)
    local config_file="${data_dir}/data/config.toml"
    
    if [ ! -f "$config_file" ]; then
        echo ""
        return 1
    fi
    
    local bot_token
    local chat_id
    
    # Parse TOML for telegram settings
    bot_token=$(grep -A 20 '^\[telegram\]' "$config_file" 2>/dev/null | grep '^bot_token' | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
    chat_id=$(grep -A 20 '^\[telegram\]' "$config_file" 2>/dev/null | grep '^chat_id' | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
    
    if [ -n "$bot_token" ] && [ -n "$chat_id" ]; then
        echo "${bot_token}:${chat_id}"
        return 0
    fi
    
    echo ""
    return 1
}

send_telegram_message() {
    local message="$1"
    local config
    config=$(get_telegram_config)
    
    if [ -z "$config" ]; then
        return 1
    fi
    
    local bot_token="${config%%:*}"
    local chat_id="${config#*:}"
    
    curl -fsSL -X POST \
        "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -d "chat_id=${chat_id}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" \
        &>/dev/null
}

setup_update_notifications() {
    log_step "Setup Auto-Update Notifications"
    
    local config
    config=$(get_telegram_config)
    
    if [ -z "$config" ]; then
        log_warn "Telegram not configured in ScreenerBot"
        log_info "Please configure Telegram in the ScreenerBot dashboard first:"
        log_info "  Settings → Telegram → Configure bot token and chat ID"
        press_enter
        return 1
    fi
    
    log_success "Telegram configuration found"
    
    # Test notification
    if confirm "Send test notification?"; then
        if send_telegram_message "🤖 <b>ScreenerBot VPS Manager</b>%0A%0ATest notification from your VPS! Auto-update notifications are working."; then
            log_success "Test message sent!"
        else
            log_error "Failed to send test message"
            return 1
        fi
    fi
    
    # Create update check service
    log_info "Creating update check timer..."
    
    local arch
    arch=$(detect_arch)
    local platform="linux-${arch}-headless"
    
    # Resolve home directory for the actual user (not root if using sudo)
    local user="${SUDO_USER:-$USER}"
    local user_home
    if [ -n "$SUDO_USER" ]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        user_home="$HOME"
    fi
    local config_path="${user_home}/.local/share/ScreenerBot/data/config.toml"
    
    # Use non-quoted heredoc to allow variable substitution for config path
    cat > "${UPDATE_SERVICE_FILE}" << EOF
[Unit]
Description=ScreenerBot Update Checker
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '\\
    CURRENT=\$(/usr/local/bin/screenerbot --version 2>/dev/null | grep -oP "\\\\d+\\\\.\\\\d+\\\\.\\\\d+" | head -1); \\
    if [ -z "\$CURRENT" ]; then exit 0; fi; \\
    ARCH=\$(uname -m | sed "s/x86_64/x64/;s/aarch64/arm64/;s/amd64/x64/"); \\
    RESPONSE=\$(curl -fsSL "https://screenerbot.io/api/releases/check?version=\${CURRENT}&platform=linux-\${ARCH}-headless" 2>/dev/null); \\
    UPDATE=\$(echo "\$RESPONSE" | grep -o "updateAvailable.*true" | head -1); \\
    if [ -n "\$UPDATE" ]; then \\
        LATEST=\$(echo "\$RESPONSE" | grep -oP "latestVersion\\":\\"\\\\K[^\\"]+"); \\
        CONFIG_FILE="${config_path}"; \\
        if [ -f "\$CONFIG_FILE" ]; then \\
            BOT_TOKEN=\$(grep -A 20 "^\\\\[telegram\\\\]" "\$CONFIG_FILE" | grep "^bot_token" | head -1 | sed "s/.*= *\\"\\\\([^\\"]*\\\\)\\".*/\\\\1/"); \\
            CHAT_ID=\$(grep -A 20 "^\\\\[telegram\\\\]" "\$CONFIG_FILE" | grep "^chat_id" | head -1 | sed "s/.*= *\\"\\\\([^\\"]*\\\\)\\".*/\\\\1/"); \\
            if [ -n "\$BOT_TOKEN" ] && [ -n "\$CHAT_ID" ]; then \\
                MSG="🔄 <b>ScreenerBot Update Available</b>%0A%0ACurrent: v\${CURRENT}%0ALatest: v\${LATEST}%0A%0ARun: <code>sudo screenerbot</code> to update"; \\
                curl -fsSL -X POST "https://api.telegram.org/bot\${BOT_TOKEN}/sendMessage" -d "chat_id=\${CHAT_ID}" -d "text=\${MSG}" -d "parse_mode=HTML" &>/dev/null; \\
            fi; \\
        fi; \\
    fi'
EOF

    cat > "${UPDATE_TIMER_FILE}" << EOF
[Unit]
Description=ScreenerBot Update Checker Timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}-update.timer"
    systemctl start "${SERVICE_NAME}-update.timer"
    
    log_success "Update notifications configured!"
    log_info "Checks for updates every 6 hours"
    log_info "Sends Telegram notification when update available"
    
    press_enter
}

# =============================================================================
# Status & Info Functions
# =============================================================================

show_status() {
    print_banner
    echo "${BOLD}  ${ICON_STATUS}  ScreenerBot Status${RESET}"
    echo ""
    print_separator
    
    # Installation status
    echo ""
    echo "${BOLD}Installation:${RESET}"
    echo ""
    
    local installed_version
    installed_version=$(get_installed_version)
    
    if [ -n "$installed_version" ]; then
        echo "  Version:     ${GREEN}${BOLD}v${installed_version}${RESET}"
        echo "  Binary:      ${INSTALL_DIR}/screenerbot"
        echo "  Symlink:     ${SYMLINK_PATH}"
    else
        echo "  ${DIM}ScreenerBot is not installed${RESET}"
    fi
    
    # Data directory
    local data_dir
    data_dir=$(get_data_dir)
    echo ""
    echo "${BOLD}Data Directory:${RESET}"
    echo ""
    if [ -d "$data_dir" ]; then
        local data_size
        data_size=$(du -sh "$data_dir" 2>/dev/null | cut -f1)
        echo "  Path:        ${data_dir}"
        echo "  Size:        ${data_size:-unknown}"
        
        if [ -f "${data_dir}/data/config.toml" ]; then
            echo "  Config:      ${GREEN}${ICON_CHECK} Found${RESET}"
        else
            echo "  Config:      ${YELLOW}${ICON_WARN} Not configured${RESET}"
        fi
    else
        echo "  ${DIM}Data directory not created yet${RESET}"
    fi
    
    # Service status
    service_status
    
    # Latest version check
    echo "${BOLD}Latest Version:${RESET}"
    echo ""
    local latest_response
    latest_response=$(get_latest_release 2>/dev/null)
    if [ -n "$latest_response" ]; then
        local latest_version
        if command -v jq &>/dev/null; then
            latest_version=$(echo "$latest_response" | jq -r '.data.version' 2>/dev/null)
        else
            latest_version=$(echo "$latest_response" | grep -oP '"version"\s*:\s*"\K[^"]+' | head -1)
        fi
        
        if [ -n "$latest_version" ]; then
            echo "  Available:   v${latest_version}"
            
            if [ -n "$installed_version" ]; then
                if compare_versions "$installed_version" "$latest_version"; then
                    case $? in
                        0) echo "  Status:      ${GREEN}Up to date${RESET}" ;;
                        2) echo "  Status:      ${YELLOW}Update available!${RESET}" ;;
                    esac
                fi
            fi
        fi
    else
        echo "  ${DIM}Could not fetch latest version${RESET}"
    fi
    
    echo ""
    print_separator
    press_enter
}

# =============================================================================
# Help & Tips
# =============================================================================

show_help() {
    print_banner
    echo "${BOLD}  ${ICON_HELP}  Help & Tips${RESET}"
    echo ""
    print_separator
    echo ""
    
    echo "${BOLD}${CYAN}Quick Start:${RESET}"
    echo ""
    echo "  1. Install ScreenerBot using option [1]"
    echo "  2. Configure your wallet and RPC in the dashboard"
    echo "  3. Access dashboard at http://localhost:8080"
    echo "  4. Enable auto-start with option [6]"
    echo ""
    
    echo "${BOLD}${CYAN}Remote Dashboard Access:${RESET}"
    echo ""
    echo "  The safest way to access your dashboard remotely is via SSH tunnel:"
    echo ""
    echo "  ${DIM}ssh -L 8080:localhost:8080 user@your-server-ip${RESET}"
    echo ""
    echo "  Then open http://localhost:8080 in your local browser."
    echo ""
    
    echo "${BOLD}${CYAN}Useful Commands:${RESET}"
    echo ""
    echo "  View logs:          ${DIM}journalctl -u screenerbot -f${RESET}"
    echo "  Restart service:    ${DIM}sudo systemctl restart screenerbot${RESET}"
    echo "  Check status:       ${DIM}sudo systemctl status screenerbot${RESET}"
    echo "  Edit config:        ${DIM}nano ~/.local/share/ScreenerBot/data/config.toml${RESET}"
    echo ""
    
    echo "${BOLD}${CYAN}Security Tips:${RESET}"
    echo ""
    echo "  • Never expose port 8080 to the public internet"
    echo "  • Use SSH tunnel or VPN for remote access"
    echo "  • Keep your system and ScreenerBot updated"
    echo "  • Enable Telegram notifications for monitoring"
    echo "  • Regularly backup your data directory"
    echo ""
    
    echo "${BOLD}${CYAN}Resources:${RESET}"
    echo ""
    echo "  Documentation:      ${CYAN}https://screenerbot.io/docs${RESET}"
    echo "  Support:            ${CYAN}https://screenerbot.io/support${RESET}"
    echo "  Telegram:           ${CYAN}https://t.me/screenerbotio${RESET}"
    echo "  Twitter/X:          ${CYAN}https://x.com/screenerbotio${RESET}"
    echo ""
    
    print_separator
    press_enter
}

# =============================================================================
# Main Menu
# =============================================================================

main_menu() {
    while true; do
        print_banner
        
        # Show current status
        local installed_version
        installed_version=$(get_installed_version)
        
        if [ -n "$installed_version" ]; then
            echo "  ${GREEN}${ICON_CHECK}${RESET} Installed: ${BOLD}v${installed_version}${RESET}"
        else
            echo "  ${DIM}Not installed${RESET}"
        fi
        
        local service_status_text
        if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
            service_status_text="${GREEN}● Running${RESET}"
        elif systemctl list-unit-files | grep -q "${SERVICE_NAME}" 2>/dev/null; then
            service_status_text="${YELLOW}○ Stopped${RESET}"
        else
            service_status_text="${DIM}○ No service${RESET}"
        fi
        echo "  Service: ${service_status_text}"
        
        echo ""
        
        local options=(
            "${ICON_PACKAGE} Install ScreenerBot"
            "${ICON_UPDATE} Update ScreenerBot"
            "${ICON_TRASH} Uninstall ScreenerBot"
            "${ICON_BACKUP} Backup Data"
            "${ICON_RESTORE} Restore Data"
            "${ICON_SERVICE} Manage Service"
            "${ICON_STATUS} Status & Info"
            "${ICON_TELEGRAM} Setup Update Notifications"
            "${ICON_HELP} Help & Tips"
            "${ICON_EXIT} Exit"
        )
        
        select_menu "${options[@]}"
        local choice=$MENU_RESULT
        
        case "$choice" in
            0)
                # Install
                if [ -n "$installed_version" ]; then
                    log_warn "ScreenerBot is already installed (v${installed_version})"
                    if ! confirm "Reinstall?"; then
                        continue
                    fi
                fi
                
                if check_requirements; then
                    echo ""
                    # Get latest version
                    local latest_response
                    latest_response=$(get_latest_release)
                    local latest_version
                    
                    if [ -n "$latest_response" ] && command -v jq &>/dev/null; then
                        latest_version=$(echo "$latest_response" | jq -r '.data.version' 2>/dev/null)
                    elif [ -n "$latest_response" ]; then
                        latest_version=$(echo "$latest_response" | grep -oP '"version"\s*:\s*"\K[^"]+' | head -1)
                    fi
                    
                    if [ -z "$latest_version" ]; then
                        log_error "Failed to get latest version"
                        press_enter
                        continue
                    fi
                    
                    echo ""
                    log_info "Latest version: ${BOLD}v${latest_version}${RESET}"
                    echo ""
                    echo -n "Install version [${latest_version}]: "
                    read -r user_version < /dev/tty
                    
                    if [ -z "$user_version" ]; then
                        user_version="$latest_version"
                    fi
                    
                    if download_and_install "$user_version"; then
                        echo ""
                        if confirm "Create systemd service for auto-start?" "y"; then
                            create_service
                        fi
                    fi
                fi
                press_enter
                ;;
            1)
                # Update
                if [ -z "$installed_version" ]; then
                    log_error "ScreenerBot is not installed"
                    press_enter
                    continue
                fi
                
                local arch
                arch=$(detect_arch)
                local platform="linux-${arch}-headless"
                
                log_info "Checking for updates..."
                local check_response
                check_response=$(check_update_available "$installed_version" "$platform")
                
                local update_available="false"
                local latest_version=""
                
                if [ -n "$check_response" ]; then
                    if command -v jq &>/dev/null; then
                        update_available=$(echo "$check_response" | jq -r '.data.updateAvailable' 2>/dev/null)
                        latest_version=$(echo "$check_response" | jq -r '.data.latestVersion' 2>/dev/null)
                    else
                        update_available=$(echo "$check_response" | grep -o '"updateAvailable":true' | head -1)
                        [ -n "$update_available" ] && update_available="true"
                        latest_version=$(echo "$check_response" | grep -oP '"latestVersion"\s*:\s*"\K[^"]+' | head -1)
                    fi
                fi
                
                if [ "$update_available" = "true" ] && [ -n "$latest_version" ]; then
                    echo ""
                    log_success "Update available!"
                    echo ""
                    echo "  Current: v${installed_version}"
                    echo "  Latest:  v${latest_version}"
                    echo ""
                    
                    if confirm "Download and install update?"; then
                        if download_and_install "$latest_version"; then
                            if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
                                log_info "Restarting service..."
                                systemctl restart "${SERVICE_NAME}"
                                log_success "Service restarted with new version!"
                            fi
                        fi
                    fi
                else
                    log_success "You're running the latest version (v${installed_version})"
                fi
                press_enter
                ;;
            2)
                # Uninstall
                if [ -z "$installed_version" ]; then
                    log_warn "ScreenerBot is not installed"
                    press_enter
                    continue
                fi
                
                echo ""
                log_warn "This will remove ScreenerBot from your system"
                if confirm "Are you sure you want to uninstall?"; then
                    uninstall
                fi
                press_enter
                ;;
            3)
                # Backup
                create_backup
                press_enter
                ;;
            4)
                # Restore
                restore_backup
                press_enter
                ;;
            5)
                # Service menu
                service_menu
                ;;
            6)
                # Status
                show_status
                ;;
            7)
                # Telegram notifications
                setup_update_notifications
                ;;
            8)
                # Help
                show_help
                ;;
            9|-1)
                echo ""
                log_info "Thanks for using ScreenerBot! ${ICON_ROCKET}"
                echo ""
                exit 0
                ;;
        esac
    done
}

# =============================================================================
# Command Line Arguments
# =============================================================================

show_usage() {
    echo "ScreenerBot VPS Manager v${SCRIPT_VERSION}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install [version]    Install ScreenerBot (latest if version not specified)"
    echo "  update               Check and install updates"
    echo "  uninstall            Remove ScreenerBot"
    echo "  status               Show installation status"
    echo "  backup               Create backup of data directory"
    echo "  restore [file]       Restore from backup"
    echo "  start                Start the service"
    echo "  stop                 Stop the service"
    echo "  restart              Restart the service"
    echo "  logs                 View service logs"
    echo "  help                 Show this help message"
    echo ""
    echo "Without arguments, starts interactive menu mode."
    echo ""
    echo "Examples:"
    echo "  $0                   # Interactive menu"
    echo "  $0 install           # Install latest version"
    echo "  $0 install 0.1.107   # Install specific version"
    echo "  $0 update            # Check and install updates"
    echo "  $0 status            # Show status"
    echo ""
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    # Handle command line arguments
    case "${1:-}" in
        install)
            check_requirements || exit 1
            local version="${2:-}"
            if [ -z "$version" ]; then
                local response
                response=$(get_latest_release)
                if command -v jq &>/dev/null; then
                    version=$(echo "$response" | jq -r '.data.version' 2>/dev/null)
                else
                    version=$(echo "$response" | grep -oP '"version"\s*:\s*"\K[^"]+' | head -1)
                fi
            fi
            if [ -z "$version" ]; then
                log_error "Failed to determine version"
                exit 1
            fi
            download_and_install "$version"
            ;;
        update)
            local installed_version
            installed_version=$(get_installed_version)
            if [ -z "$installed_version" ]; then
                log_error "ScreenerBot is not installed"
                exit 1
            fi
            
            local arch
            arch=$(detect_arch)
            local check_response
            check_response=$(check_update_available "$installed_version" "linux-${arch}-headless")
            
            local update_available="false"
            local latest_version=""
            
            if command -v jq &>/dev/null; then
                update_available=$(echo "$check_response" | jq -r '.data.updateAvailable' 2>/dev/null)
                latest_version=$(echo "$check_response" | jq -r '.data.latestVersion' 2>/dev/null)
            fi
            
            if [ "$update_available" = "true" ] && [ -n "$latest_version" ]; then
                log_info "Update available: v${installed_version} → v${latest_version}"
                download_and_install "$latest_version"
                if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
                    systemctl restart "${SERVICE_NAME}"
                    log_success "Service restarted"
                fi
            else
                log_success "Already up to date (v${installed_version})"
            fi
            ;;
        uninstall)
            uninstall
            ;;
        status)
            local version
            version=$(get_installed_version)
            if [ -n "$version" ]; then
                echo "Installed: v${version}"
                echo "Binary: ${INSTALL_DIR}/screenerbot"
            else
                echo "Not installed"
            fi
            
            if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
                echo "Service: running"
            elif systemctl list-unit-files | grep -q "${SERVICE_NAME}" 2>/dev/null; then
                echo "Service: stopped"
            else
                echo "Service: not configured"
            fi
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "$2"
            ;;
        start)
            systemctl start "${SERVICE_NAME}"
            log_success "Service started"
            ;;
        stop)
            systemctl stop "${SERVICE_NAME}"
            log_success "Service stopped"
            ;;
        restart)
            systemctl restart "${SERVICE_NAME}"
            log_success "Service restarted"
            ;;
        logs)
            journalctl -u "${SERVICE_NAME}" -f
            ;;
        help|--help|-h)
            show_usage
            ;;
        "")
            # No arguments - start interactive menu
            main_menu
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
