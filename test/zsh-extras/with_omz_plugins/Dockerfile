# Like a team image that loads widget-wrapping plugins via oh-my-zsh before the
# zsh-extras block (base:debian already has oh-my-zsh for vscode).
FROM mcr.microsoft.com/devcontainers/base:debian
USER vscode
RUN git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
 && git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
 && sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
USER root
