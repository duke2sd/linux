export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
CASE_SENSITIVE="true"
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

plugins=(git sudo z fzf autojump command-not-found cp copypath copyfile history-substring-search zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

alias s="sudo"
alias sn="shutdown now"
alias rb="reboot"
alias add="nix-env -iA"
alias del="nix-env --uninstall"
alias channel-list="sudo nix-channel --list"
alias channel-update="sudo nix-channel --update"
alias channel-add="sudo nix-channel --add"
alias channel-remove="sudo nix-channel --remove"
alias update="sudo nixos-rebuild switch && nix-env -u '*' && home-manager switch"
alias list="nix-env --query"
alias find="nix search nixpkgs"
alias config="sudo nano /etc/nixos/configuration.nix"
alias rebuild="sudo nixos-rebuild boot && reboot"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"

alias s="sudo"
alias sn="sudo shutdown now"
alias rb="sudo reboot"
alias add="sudo pacman -S"
alias del="sudo pacman -R"
alias upgrade="sudo pacman -Syyu"
alias list="sudo pacman -Qe"
alias find="sudo pacman -Q"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias y="yay -S --noconfirm"


fastfetch
setopt nonomatch

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
