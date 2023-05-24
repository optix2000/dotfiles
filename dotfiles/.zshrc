# Set homebrew path
if [[ "$OSTYPE" == "darwin"* ]]; then
  eval $(/opt/homebrew/bin/brew shellenv)
fi

source ~/.zsh/zsh-snap/znap.zsh

# Install base zshrc
znap clone grml/grml-etc-core
source ~/.zsh/grml/grml-etc-core/etc/zsh/zshrc

znap source ohmyzsh/ohmyzsh plugins/terraform
znap source ohmyzsh/ohmyzsh plugins/gem
znap source ohmyzsh/ohmyzsh plugins/golang
znap source ohmyzsh/ohmyzsh plugins/heroku
znap source ohmyzsh/ohmyzsh plugins/gnu-utils
#znap source ohmyzsh/ohmyzsh plugins/ripgrep

if command -v kubectl &>/dev/null; then
  znap fpath _kubectl 'kubectl completion zsh'
fi
