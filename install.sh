#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para logging
log() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "${msg}" >> "$LOG_FILE"
}

error() {
    local msg="[ERROR] $1"
    echo -e "${RED}${msg}${NC}"
    echo "${msg}" >> "$LOG_FILE"
}

warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "${msg}" >> "$LOG_FILE"
}

# Função para verificar se comando foi executado com sucesso
check_error() {
    if [ $? -ne 0 ]; then
        error "$1"
        exit 1
    fi
}

# Função para instalar pacotes com verificação individual
install_package() {
    local package=$1
    log "Tentando instalar: $package"
    if sudo pacman -S --needed --noconfirm "$package"; then
        log "✓ Pacote instalado com sucesso: $package"
        return 0
    else
        error "✗ Falha ao instalar pacote: $package"
        return 1
    fi
}

# Criar diretório de logs
mkdir -p ~/.logs
LOG_FILE=~/.logs/install_$(date +'%Y%m%d_%H%M%S').log

# Backup das configurações existentes
backup_configs() {
    log "Criando backup das configurações existentes..."
    BACKUP_DIR=~/.config/backup_$(date +'%Y%m%d_%H%M%S')
    mkdir -p "$BACKUP_DIR"
    
    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc "$BACKUP_DIR/"
    fi
    
    if [ -d ~/.config/gnome-shell ]; then
        cp -r ~/.config/gnome-shell "$BACKUP_DIR/"
    fi
}

# Verificar se é Arch Linux
if [ ! -f /etc/arch-release ]; then
    error "Este script é específico para Arch Linux!"
    exit 1
fi

# Início da instalação
log "Iniciando instalação e configuração do ambiente..."
backup_configs

# Atualização do sistema
log "Atualizando o sistema..."
sudo pacman -Syyu --noconfirm || check_error "Falha na atualização do sistema"

# Instalação de pacotes essenciais
log "Instalando pacotes essenciais..."
failed_packages=()

# Lista de pacotes essenciais (removido yay da lista pois será instalado separadamente)
essential_packages=(
    "gnome-tweaks"
    "zsh"
    "nerd-fonts-complete"
    "powerlevel10k"
    "gnome-terminal-transparency"
    "dconf-editor"
    "python"
    "python-pip"
    "git"
    "code"
    "firefox"
    "thunderbird"
    "neofetch"
    "htop"
    "docker"
    "docker-compose"
    "base-devel"
    "nodejs"
    "npm"
    "ripgrep"
    "fd"
    "bat"
    "exa"
    "fzf"
    "tldr"
)

# Instalar cada pacote individualmente
for package in "${essential_packages[@]}"; do
    if ! install_package "$package"; then
        failed_packages+=("$package")
    fi
done

# Instalação do YAY (após a instalação dos pacotes essenciais)
log "Instalando YAY (AUR Helper)..."
if ! command -v yay &> /dev/null; then
    log "YAY não encontrado, instalando..."
    # Criar diretório temporário
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    
    # Clonar e compilar yay
    log "Clonando repositório do YAY..."
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit 1
    log "Compilando YAY..."
    makepkg -si --noconfirm
    
    # Limpar diretório temporário
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    
    if command -v yay &> /dev/null; then
        log "✓ YAY instalado com sucesso!"
    else
        error "✗ Falha ao instalar YAY"
        error "Você pode tentar instalar manualmente depois:"
        error "1. git clone https://aur.archlinux.org/yay.git"
        error "2. cd yay"
        error "3. makepkg -si"
        read -p "Deseja continuar com a instalação? (s/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            error "Instalação abortada pelo usuário"
            exit 1
        fi
    fi
else
    log "✓ YAY já está instalado"
fi

# Verificar se houve falhas
if [ ${#failed_packages[@]} -ne 0 ]; then
    error "Os seguintes pacotes falharam durante a instalação:"
    printf '%s\n' "${failed_packages[@]}" | tee -a "$LOG_FILE"
    error "Verifique o arquivo de log em $LOG_FILE para mais detalhes"
    error "Você pode tentar instalar estes pacotes manualmente ou verificar se eles existem no repositório"
    read -p "Deseja continuar com a instalação? (s/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        error "Instalação abortada pelo usuário"
        exit 1
    fi
fi

# Habilitar e iniciar Docker
log "Configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Instalação de extensões do GNOME
log "Instalando extensões do GNOME..."
sudo pacman -S --needed --noconfirm \
    gnome-shell-extensions \
    gnome-shell-extension-clipboard-indicator \
    gnome-shell-extension-vitals \
    gnome-shell-extension-openweather \
    gnome-shell-extension-forge \
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-material-shell \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-tiling-assistant \
    gnome-shell-extension-panel-corners \
    gnome-shell-extension-v-shell \
    papirus-icon-theme \
    orchis-theme \
    nordic-theme \
    || check_error "Falha na instalação das extensões GNOME"

# Instalação do Pokeshell
log "Instalando Pokeshell..."
git clone https://github.com/acxz/pokeshell.git ~/.pokeshell
cd ~/.pokeshell
make install || check_error "Falha na instalação do Pokeshell"

# Configuração do ZSH
log "Configurando ZSH..."
mkdir -p ~/.zsh
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone https://github.com/romkatv/powerlevel10k.git ~/.config/powerlevel10k
git clone https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions

# Configuração do ambiente Python
log "Configurando ambiente Python..."
pip install --user --upgrade \
    pip \
    virtualenv \
    pylint \
    black \
    flake8 \
    mypy \
    pytest \
    jupyter \
    notebook \
    windsurf \
    python-debugpy \
    || check_error "Falha na instalação dos pacotes Python"

# Criando arquivo .zshrc personalizado
cat > ~/.zshrc << 'EOF'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Configuração do Powerlevel10k
source ~/.config/powerlevel10k/powerlevel10k.zsh-theme

# Plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-completions/zsh-completions.zsh

# Aliases úteis
alias ls='exa --icons'
alias ll='exa -l --icons'
alias la='exa -la --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='htop'

# Configuração do Pokeshell
source ~/.pokeshell/pokeshell.zsh

# Python virtual environment
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/projects
source /usr/bin/virtualenvwrapper.sh

# Configurações do PATH
export PATH="$HOME/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

# Configuração do GNOME
log "Configurando GNOME..."
gsettings set org.gnome.desktop.interface gtk-theme "Nordic-darker"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
gsettings set org.gnome.desktop.interface font-name "Noto Sans 11"
gsettings set org.gnome.desktop.interface monospace-font-name "FiraCode Nerd Font Mono 12"
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
gsettings set org.gnome.desktop.interface enable-animations true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Configurações do terminal
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant 'dark'
gsettings set org.gnome.Terminal.Legacy.Settings default-show-menubar false

# Configurar VS Code
log "Configurando VS Code..."
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension dracula-theme.theme-dracula
code --install-extension pkief.material-icon-theme
code --install-extension esbenp.prettier-vscode
code --install-extension eamodio.gitlens
code --install-extension github.copilot

# Criar diretório de projetos
mkdir -p ~/projects

# Mensagem final
log "Instalação concluída com sucesso!"
log "Por favor, execute os seguintes comandos manualmente após reiniciar:"
echo "1. chsh -s /bin/zsh"
echo "2. p10k configure"
echo "3. Reinicie o sistema para aplicar todas as alterações"

# Registrar conclusão no log
echo "Instalação concluída em $(date)" >> "$LOG_FILE"