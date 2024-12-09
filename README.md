# 🚀 Arch Linux GNOME Personalization Script

Este script automatiza a instalação e configuração de um ambiente de desenvolvimento Python completo no Arch Linux, com foco em um visual minimalista e escuro usando GNOME.

## 📋 Pré-requisitos

- Arch Linux instalado
- Acesso root (sudo)
- Conexão com a internet

## 🎨 Recursos Inclusos

### Interface Gráfica
- **GNOME Shell** personalizado com tema Nordic-darker
- **Extensões GNOME**:
  - Clipboard Indicator
  - Vitals (monitor do sistema)
  - OpenWeather
  - Blur My Shell
  - Material Shell
  - Dash to Dock
  - Tiling Assistant
  - Panel Corners
  - V-Shell

### Terminal e Shell
- **ZSH** com:
  - Powerlevel10k
  - Autosuggestions
  - Syntax Highlighting
  - Completions
  - Pokeshell (visualizador de Pokémon no terminal)
- **Terminal Personalizado**:
  - Tema escuro
  - Fonte FiraCode Nerd Font
  - Transparência

### Ambiente de Desenvolvimento
- **Python**:
  - pip (atualizado)
  - virtualenv e virtualenvwrapper
  - pylint
  - black
  - flake8
  - mypy
  - pytest
  - jupyter notebook
  - windsurf
  - python-debugpy

- **VS Code** com extensões:
  - Python
  - Pylance
  - Jupyter
  - Dracula Theme
  - Material Icon Theme
  - Prettier
  - GitLens
  - GitHub Copilot

### Ferramentas de Desenvolvimento
- Docker e Docker Compose
- Git
- Node.js e npm
- Base-devel

### Utilitários Modernos
- `exa` (substituto moderno do ls)
- `bat` (substituto moderno do cat)
- `ripgrep` (substituto moderno do grep)
- `fd` (substituto moderno do find)
- `htop` (monitor do sistema)
- `neofetch` (informações do sistema)
- `fzf` (fuzzy finder)
- `tldr` (exemplos práticos de comandos)

## 🚀 Instalação

1. Clone este repositório:
```bash
git clone https://github.com/seu-usuario/gnome-personalization.git
cd gnome-personalization
```

2. Torne o script executável:
```bash
chmod +x install.sh
```

3. Execute o script:
```bash
./install.sh
```

## 📝 Pós-instalação

Após a execução do script, você precisará:

1. Reiniciar o sistema:
```bash
sudo reboot
```

2. Após reiniciar, defina o ZSH como shell padrão:
```bash
chsh -s /bin/zsh
```

3. Configure o Powerlevel10k:
```bash
p10k configure
```

## 🔍 Logs e Backup

- **Logs**: Todos os logs de instalação são salvos em `~/.logs/`
- **Backup**: Suas configurações antigas são automaticamente salvas em `~/.config/backup_[data]/`

## ⚙️ Personalizações

### Aliases Inclusos
- `ls` → `exa --icons`
- `ll` → `exa -l --icons`
- `la` → `exa -la --icons`
- `cat` → `bat`
- `grep` → `rg`
- `find` → `fd`
- `top` → `htop`

### Estrutura de Diretórios
```
~/
├── .config/           # Configurações
├── .zsh/              # Plugins ZSH
├── .logs/             # Logs de instalação
├── projects/          # Diretório para projetos
└── .virtualenvs/      # Ambientes virtuais Python
```

## 🛠️ Solução de Problemas

### Logs de Erro
- Verifique os logs em `~/.logs/` para detalhes de erros
- Mensagens de erro em vermelho indicam falhas durante a instalação

### Problemas Comuns
1. **Falha na instalação de pacotes**:
   - Verifique sua conexão com a internet
   - Atualize os mirrors do Arch: `sudo pacman -Syy`

2. **Extensões GNOME não aparecem**:
   - Reinicie o GNOME Shell: Alt+F2, digite 'r', pressione Enter
   - Verifique se o gnome-tweaks está instalado

3. **ZSH não é o shell padrão**:
   - Execute: `chsh -s /bin/zsh`
   - Faça logout e login novamente

## 🔄 Atualizações

Para manter seu ambiente atualizado:

```bash
# Atualizar pacotes do sistema
sudo pacman -Syu

# Atualizar pacotes Python
pip install --upgrade pip
pip list --outdated | cut -d' ' -f1 | tail -n +3 | xargs -n1 pip install -U

# Atualizar extensões VS Code
code --list-extensions | xargs -L 1 code --install-extension
```

## 🤝 Contribuindo

Sinta-se à vontade para contribuir com este projeto! Você pode:
1. Fazer um fork do repositório
2. Criar uma branch para sua feature
3. Fazer commit das mudanças
4. Fazer push para a branch
5. Abrir um Pull Request

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## ✨ Agradecimentos

- [Arch Linux](https://archlinux.org/)
- [GNOME](https://www.gnome.org/)
- [Pokeshell](https://github.com/acxz/pokeshell)
- Todos os mantenedores dos pacotes e extensões incluídos
