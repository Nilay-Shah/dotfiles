set theme_complete_pathset yes

# install fisher
if not functions -q fisher
  set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
  curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
  fish -c fisher
end

# ---Shopify Specific---
# for dev
if test -f /opt/dev/dev.fish
  source /opt/dev/dev.fish
end
