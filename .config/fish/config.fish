set -xg DISABLE_SPRING true
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


# enable the "Tomorrow Night" color theme
set fish_color_autosuggestion 969896
set fish_color_cwd_root red
set fish_color_host normal
set fish_color_quote b9ca4a
set fish_color_user brgreen
set fish_color_cancel -r
set fish_color_end c397d8
set fish_color_match --background=brblue
set fish_color_redirection 70c0b1
set fish_color_valid_path --underline
set fish_color_command c397d8
set fish_color_error d54e53
set fish_color_normal normal
set fish_color_search_match 'bryellow' '--background=brblack'
set fish_color_comment e7c547
set fish_color_escape 00a6b2
set fish_color_operator 00a6b2
set fish_color_selection 'white' '--bold' '--background=brblack'
set fish_color_cwd green
set fish_color_history_current --bold
set fish_color_param 7aa6da
set fish_color_status red

# install fisher
if not functions -q fisher
  set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
  curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
  fish -c fisher
end

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

# kube
if set -q KUBECONFIG[1]
  set -x KUBECONFIG "$KUBECONFIG:/Users/nilay/.kube/config:/Users/nilay/.kube/config.shopify.cloudplatform:/Users/nilay/.kube/config.shopify.production-registry"
else
  set -x KUBECONFIG "/Users/nilay/.kube/config:/Users/nilay/.kube/config.shopify.cloudplatform:/Users/nilay/.kube/config.shopify.production-registry"
end
# ---Shopify Specific---

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/nilay/google-cloud-sdk/path.fish.inc' ]; . '/Users/nilay/google-cloud-sdk/path.fish.inc'; end
