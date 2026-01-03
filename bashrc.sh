export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

# Some more alias to avoid making mistakes:
alias rm='rm -ir'
alias cp='cp -i'
alias mv='mv -i'

# fix for opening nano inside of tmux
export TERM=xterm

alias dc='docker compose'
alias dcu='docker compose up -d --pull always --remove-orphans'
alias dcb='docker compose --progress=plain build'
alias dcub='docker compose up -d --pull always --build --remove-orphans'
alias dcbu=dcub
alias dcl='docker compose logs -f -n 100'
alias dcul='dcu && dcl'
alias dcr='docker compose restart'

alias rsync='rsync --info=progress2'

alias df='df -hlx overlay'

alias dive="docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock docker.io/wagoodman/dive"
