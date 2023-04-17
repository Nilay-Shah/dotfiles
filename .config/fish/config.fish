set -xg DISABLE_SPRING true
set theme_complete_pathset yes

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

# after homebrew 3.0.0, Intel & M1 macs have diff install prefixes. fix this
# by supporting both (for now) by adding the new M1 mac install prefix to $PATH.
# more info: https://brew.sh/2021/02/05/homebrew-3.0.0/
set -x PATH $PATH /opt/homebrew/bin

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

# ---PocketHealth Specific---
# go
#export NVM_DIR="$HOME/.nvm"
export NVM_DIR="/usr/local/opt/nvm"
#[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
#[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
# ---PocketHealth Specific---

# The next line updates PATH for the Google Cloud SDK.
if test -e /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc
  source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc
end

# init starship prompt: https://github.com/starship/starship
starship init fish | source
