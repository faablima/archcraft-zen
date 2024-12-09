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

# Função para instalar pacote do AUR
install_aur_package() {
    local package_name=$1
    local package_url=$2
    log "Instalando $package_name do AUR..."
    
    # Criar diretório temporário
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    
    # Clonar e compilar
    git clone "$package_url"
    cd "$(basename "$package_url" .git)" || exit 1
    makepkg -si --noconfirm
    
    # Limpar
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    
    if pacman -Qi "$package_name" &> /dev/null; then
        log "✓ $package_name instalado com sucesso!"
        return 0
    else
        error "✗ Falha ao instalar $package_name"
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

# Lista de pacotes essenciais (removidos os pacotes que precisam de tratamento especial)
essential_packages=(
    "gnome-tweaks"
    "zsh"
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

# Instalar getnf para as Nerd Fonts
log "Instalando getnf para Nerd Fonts..."
if ! command -v getnf &> /dev/null; then
    log "Instalando getnf..."
    curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash
    if [ $? -eq 0 ]; then
        log "✓ getnf instalado com sucesso!"
        # Instalar algumas fontes populares
        log "Instalando fontes Nerd Fonts..."
        getnf install Meslo
        getnf install FiraCode
        getnf install JetBrainsMono
    else
        error "✗ Falha ao instalar getnf"
    fi
else
    log "✓ getnf já está instalado"
fi

# Instalar Oh My Zsh
log "Instalando Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    if [ $? -eq 0 ]; then
        log "✓ Oh My Zsh instalado com sucesso!"
    else
        error "✗ Falha ao instalar Oh My Zsh"
    fi
else
    log "✓ Oh My Zsh já está instalado"
fi

# Instalar Powerlevel10k
log "Instalando Powerlevel10k..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [ $? -eq 0 ]; then
        log "✓ Powerlevel10k instalado com sucesso!"
    else
        error "✗ Falha ao instalar Powerlevel10k"
    fi
else
    log "✓ Powerlevel10k já está instalado"
fi

# Instalar gnome-terminal-transparency do AUR
log "Instalando gnome-terminal-transparency..."
if ! pacman -Qi gnome-terminal-transparency &> /dev/null; then
    # Criar diretório temporário
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    
    # Clonar e compilar gnome-terminal-transparency
    git clone https://aur.archlinux.org/gnome-terminal-transparency.git
    cd gnome-terminal-transparency || exit 1
    makepkg -si --noconfirm
    
    # Limpar diretório temporário
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    
    if pacman -Qi gnome-terminal-transparency &> /dev/null; then
        log "✓ gnome-terminal-transparency instalado com sucesso!"
    else
        error "✗ Falha ao instalar gnome-terminal-transparency"
    fi
else
    log "✓ gnome-terminal-transparency já está instalado"
fi

# Configurar .zshrc para Powerlevel10k
log "Configurando Powerlevel10k no .zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    # Fazer backup do .zshrc existente
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    # Atualizar o tema
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
fi

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

# Instalar extensões do GNOME via AUR
log "Instalando extensões do GNOME do AUR..."
declare -A gnome_extensions=(
    ["gnome-shell-extension-clipboard-indicator"]="https://aur.archlinux.org/gnome-shell-extension-clipboard-indicator.git"
    ["gnome-shell-extension-openweather"]="https://aur.archlinux.org/gnome-shell-extension-openweather.git"
    ["gnome-shell-extension-forge"]="https://aur.archlinux.org/gnome-shell-extension-forge.git"
    ["gnome-shell-extension-material-shell"]="https://aur.archlinux.org/gnome-shell-extension-material-shell.git"
    ["gnome-shell-extension-dash-to-dock"]="https://aur.archlinux.org/gnome-shell-extension-dash-to-dock.git"
    ["gnome-shell-extension-tiling-assistant"]="https://aur.archlinux.org/gnome-shell-extension-tiling-assistant.git"
    ["gnome-shell-extension-panel-corners"]="https://aur.archlinux.org/gnome-shell-extension-panel-corners.git"
)

for ext_name in "${!gnome_extensions[@]}"; do
    install_aur_package "$ext_name" "${gnome_extensions[$ext_name]}"
done

# Instalar e configurar temas
log "Instalando temas..."

# Ant Theme
log "Instalando Ant Theme..."
if [ ! -d "$HOME/.themes/Ant" ]; then
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    git clone https://github.com/EliverLara/Ant.git
    mkdir -p "$HOME/.themes"
    cp -r Ant "$HOME/.themes/"
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    log "✓ Ant Theme instalado com sucesso!"
else
    log "✓ Ant Theme já está instalado"
fi

# Cursors Theme (Qogir)
log "Instalando Qogir Cursors..."
if [ ! -d "$HOME/.icons/Qogir-cursors" ]; then
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    wget https://github.com/vinceliuice/Qogir-icon-theme/releases/download/latest/Qogir-cursors.tar.gz
    tar xf Qogir-cursors.tar.gz
    mkdir -p "$HOME/.icons"
    cp -r Qogir-cursors "$HOME/.icons/"
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    log "✓ Qogir Cursors instalado com sucesso!"
else
    log "✓ Qogir Cursors já está instalado"
fi

# Tela Icons
log "Instalando Tela Icons..."
if [ ! -d "$HOME/.icons/Tela" ]; then
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    git clone https://github.com/vinceliuice/Tela-icon-theme.git
    cd Tela-icon-theme
    ./install.sh -a
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    log "✓ Tela Icons instalado com sucesso!"
else
    log "✓ Tela Icons já está instalado"
fi

# Aplicar temas
log "Aplicando temas..."
gsettings set org.gnome.desktop.interface gtk-theme "Ant"
gsettings set org.gnome.desktop.interface icon-theme "Tela"
gsettings set org.gnome.desktop.interface cursor-theme "Qogir-cursors"

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

# Configurar ZSH como shell padrão
log "Configurando ZSH como shell padrão..."
if [ "$SHELL" != "/bin/zsh" ]; then
    log "Mudando shell padrão para ZSH..."
    chsh -s /bin/zsh
    if [ $? -eq 0 ]; then
        log "✓ Shell padrão alterado para ZSH com sucesso!"
    else
        error "✗ Falha ao alterar shell padrão"
        error "Execute manualmente: chsh -s /bin/zsh"
    fi
else
    log "✓ ZSH já é o shell padrão"
fi

# Configuração do GNOME
log "Configurando GNOME..."
gsettings set org.gnome.desktop.interface gtk-theme "Ant"
gsettings set org.gnome.desktop.interface icon-theme "Tela"
gsettings set org.gnome.desktop.interface cursor-theme "Qogir-cursors"
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

# Mensagem final com instruções claras
log "🎉 Instalação concluída com sucesso!"
echo
echo -e "${GREEN}=== Próximos Passos ===${NC}"
echo "1. Reinicie o sistema para aplicar todas as alterações:"
echo "   sudo reboot"
echo
echo "2. Após reiniciar, configure o Powerlevel10k executando:"
echo "   p10k configure"
echo
echo "3. Suas configurações antigas foram salvas em:"
echo "   - ZSH: ~/.zshrc.backup"
echo "   - GNOME: ~/.config/backup_*"
echo
echo -e "${YELLOW}Dicas:${NC}"
echo "- Use 'getnf install' para instalar mais fontes Nerd Fonts"
echo "- Ajuste a transparência do terminal em Preferências do Terminal"
echo "- Explore as extensões do GNOME em Ajustes > Extensões"
echo
echo -e "${GREEN}Aproveite seu novo ambiente! 🚀${NC}"

# Registrar conclusão no log
echo "Instalação concluída em $(date)" >> "$LOG_FILE"