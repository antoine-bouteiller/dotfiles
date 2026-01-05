export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
(( $+commands[volta] )) || curl https://get.volta.sh | bash -s -- --skip-setup