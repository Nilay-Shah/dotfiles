set theme_complete_pathset yes


set SPACEFISH_PACKAGE_SHOW false
set SPACEFISH_NODE_SHOW false
set SPACEFISH_JULIA_SHOW false
set SPACEFISH_DOCKER_SHOW false
set SPACEFISH_RUBY_SHOW false
set SPACEFISH_HASKELL_SHOW false
set SPACEFISH_AWS_SHOW false
set SPACEFISH_VENV_SHOW false
set SPACEFISH_CONDA_SHOW false
set SPACEFISH_PYENV_SHOW false
set SPACEFISH_GOLANG_SHOW false
set SPACEFISH_PHP_SHOW false
set SPACEFISH_RUST_SHOW false
set SPACEFISH_DOTNET_SHOW false
set SPACEFISH_BATTERY_SHOW false
set SPACEFISH_VI_MODE_SHOW false
set SPACEFISH_JOBS_SHOW false

set SPACEFISH_EXIT_CODE_SHOW true


# install fisher
if not functions -q fisher
  set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
  curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
  fish -c fisher
end


# ---Shopify Specific---
# dev
if test -f /opt/dev/dev.fish
  source /opt/dev/dev.fish
end

# go
set -x GOPATH $HOME
set -x PATH $PATH $GOPATH/bin

# kube
if set -q KUBECONFIG[1]
  set -x KUBECONFIG "$KUBECONFIG:/Users/nilay/.kube/config:/Users/nilay/.kube/config.shopify.cloudplatform"
else
  set -x KUBECONFIG "/Users/nilay/.kube/config:/Users/nilay/.kube/config.shopify.cloudplatform"
end
# ---Shopify Specific---
