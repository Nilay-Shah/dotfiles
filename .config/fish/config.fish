set -xg DISABLE_SPRING true
set theme_complete_pathset yes

# chruby-fish
#source /usr/local/share/chruby/chruby.fish
#source /usr/local/share/chruby/auto.fish
#chruby 2.5.8

# ---Shopify Specific---
# dev
if test -f /opt/dev/dev.fish
  source /opt/dev/dev.fish
end

# go
set -x GOPATH $HOME
set -x PATH $PATH $GOPATH/bin

# ---Shopify Specific---
# kube
if set -q KUBECONFIG[1]
  set -x KUBECONFIG "$KUBECONFIG:/Users/nilay/.kube/config:/Users/nilay/.kube/config.shopify.cloudplatform:/Users/nilay/.kube/config.shopify.production-registry"
else
  set -x KUBECONFIG "/Users/nilay/.kube/config:/Users/nilay/.kube/config.shopify.cloudplatform:/Users/nilay/.kube/config.shopify.production-registry"
end
# ---Shopify Specific---

# ---PocketHealth Specific---
# go
#export NVM_DIR="$HOME/.nvm"
export NVM_DIR="/usr/local/opt/nvm"
#[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
#[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
# ---PocketHealth Specific---

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/nilay/google-cloud-sdk/path.fish.inc' ]; . '/Users/nilay/google-cloud-sdk/path.fish.inc'; end
