#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Installation paths
INSTALL_DIR="$HOME/.bugbounty-tools"
VENV_PATH="$INSTALL_DIR/venv"
TOOLS_DIR="$INSTALL_DIR/tools"
GO_TOOLS_DIR="$INSTALL_DIR/go/bin"

# Function to print banner
print_banner() {
   echo -e "${GREEN}"
   echo "    ____                      ____            "
   echo "   / __ \___  _________  ____/ __ )____  _  __"
   echo "  / /_/ / _ \/ ___/ __ \/ __  / __/ __ \| |/_/"
   echo " / _, _/  __/ /__/ /_/ / /_/ / /_/ /_/ />  <  "
   echo "/_/ |_|\___/\___/\____/\____/_____\____/_/|_|  "
   echo "                                               "
   echo "         [Bug Bounty Recon Tools]             "
   echo "           [By CodeSec Team]                  "
   echo -e "${NC}"
}

# Function to detect OS
detect_os() {
   if [ "$(uname)" == "Darwin" ]; then
       echo "macos"
   elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
       echo "linux"
   elif grep -q Microsoft /proc/version; then
       echo "wsl"
   else
       echo "unknown"
   fi
}

# Function to detect package manager
detect_pkg_manager() {
   if command -v apt-get &> /dev/null; then
       echo "apt"
   elif command -v brew &> /dev/null; then
       echo "brew"
   elif command -v dnf &> /dev/null; then
       echo "dnf"
   elif command -v yum &> /dev/null; then
       echo "yum"
   elif command -v pacman &> /dev/null; then
       echo "pacman"
   else
       echo "unknown"
   fi
}

# Function to install dependencies based on OS
install_dependencies() {
   local os=$(detect_os)
   local pkg_manager=$(detect_pkg_manager)

   echo -e "${GREEN}[+] Installing dependencies for $os using $pkg_manager${NC}"

   case $pkg_manager in
       apt)
           sudo apt-get update
           sudo apt-get install -y git golang python3 python3-pip python3-venv build-essential libssl-dev libffi-dev python3-dev
           ;;
       brew)
           brew update
           brew install git go python3
           ;;
       dnf|yum)
           sudo $pkg_manager update -y
           sudo $pkg_manager install -y git golang python3 python3-pip python3-devel gcc openssl-devel
           ;;
       pacman)
           sudo pacman -Syu --noconfirm
           sudo pacman -S --noconfirm git go python python-pip base-devel
           ;;
       *)
           echo -e "${RED}[!] Unsupported package manager. Please install dependencies manually:${NC}"
           echo "git, golang, python3, python3-pip"
           exit 1
           ;;
   esac
}

# Function to setup Python environment
setup_python_env() {
   echo -e "${GREEN}[+] Setting up Python virtual environment...${NC}"
   python3 -m venv $VENV_PATH
   source $VENV_PATH/bin/activate
   pip install --upgrade pip
}

# Function to setup Go environment
setup_go_env() {
   echo -e "${GREEN}[+] Setting up Go environment...${NC}"
   mkdir -p $GO_TOOLS_DIR
   export GOPATH="$INSTALL_DIR/go"
   export PATH="$PATH:$GO_TOOLS_DIR"
}

# Function to install tools
install_tools() {
   local arch=$1
   
   echo -e "${GREEN}[+] Installing tools for $arch...${NC}"
   
   # Setup environments
   setup_python_env
   setup_go_env

   # Install Go tools
   echo -e "${GREEN}[+] Installing Go tools...${NC}"
   go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
   go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
   go install github.com/OWASP/Amass/v3/...@latest
   go install github.com/ffuf/ffuf@latest
   go install github.com/tomnomnom/waybackurls@latest
   go install github.com/lc/gau/v2/cmd/gau@latest
   go install github.com/projectdiscovery/httpx/cmd/httpx@latest
   go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
   go install github.com/hahwul/dalfox/v2@latest
   go install github.com/projectdiscovery/notify/cmd/notify@latest

   # Install Python tools
   echo -e "${GREEN}[+] Installing Python tools...${NC}"
   pip install dirsearch
   pip install wfuzz
   pip install arjun
   pip install httpx
   pip install dnspython
   pip install requests
   pip install beautifulsoup4
   pip install selenium
   pip install webdriver-manager
}

# Function to create shell configuration
create_shell_config() {
   echo -e "${GREEN}[+] Creating shell configuration...${NC}"
   
   local shell_rc=""
   if [ -f "$HOME/.zshrc" ]; then
       shell_rc="$HOME/.zshrc"
   elif [ -f "$HOME/.bashrc" ]; then
       shell_rc="$HOME/.bashrc"
   else
       shell_rc="$HOME/.bashrc"
       touch "$shell_rc"
   fi

   if [ -n "$shell_rc" ]; then
       cat << EOF >> "$shell_rc"
# Bug Bounty Tools Configuration
export PATH="\$PATH:$GO_TOOLS_DIR:$VENV_PATH/bin"
export GOPATH="$INSTALL_DIR/go"
EOF
       echo -e "${GREEN}[+] Shell configuration updated in $shell_rc${NC}"
   fi
}

# Function to create uninstall script
create_uninstall_script() {
   cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
read -p "Are you sure you want to uninstall bug bounty tools? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
   rm -rf ~/.bugbounty-tools
   echo "Bug bounty tools have been uninstalled."
   echo "Please remove the configuration from your shell RC file manually."
fi
EOF
   chmod +x "$INSTALL_DIR/uninstall.sh"
}

# Function for completion message
complete_installation() {
   echo -e "${GREEN}[+] Installation complete!${NC}"
   if [ -n "$shell_rc" ]; then
       echo -e "${YELLOW}[*] Please restart your terminal or run: source $shell_rc${NC}"
   else
       echo -e "${YELLOW}[*] Please restart your terminal${NC}"
   fi
   echo -e "${YELLOW}[*] To uninstall, run: ~/.bugbounty-tools/uninstall.sh${NC}"
}

# Main function
main() {
   print_banner
   
   local os=$(detect_os)
   if [ "$os" == "unknown" ]; then
       echo -e "${RED}[!] Unsupported operating system${NC}"
       exit 1
   fi

   echo -e "${YELLOW}OS detected: $os${NC}"

   # Create installation directory
   mkdir -p $INSTALL_DIR $TOOLS_DIR

   # Install dependencies
   install_dependencies

   # Install tools based on architecture
   case $(uname -m) in
       x86_64)
           install_tools "amd64"
           ;;
       aarch64|arm64)
           install_tools "arm64"
           ;;
       *)
           echo -e "${RED}[!] Unsupported architecture: $(uname -m)${NC}"
           exit 1
           ;;
   esac

   # Create uninstall script
   create_uninstall_script

   # Create shell configuration
   create_shell_config

   # Show completion message
   complete_installation
}

# Run main function
main "$@"