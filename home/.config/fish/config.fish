if not status is-interactive
	exit
end

if test -f ~/.sh_secrets.local
	. ~/.sh_secrets.local
end

alias ls='ls --color=auto'

#unalias vim 2>/dev/null
#set VIM $(which vim)
#alias vi="$VIM"
#alias vim='nvim'
alias ll='ls -l'

alias cd..='cd ..'
alias getRoot='git rev-parse --show-toplevel 2>/dev/null || echo $DEFAULT_PROJECT_PATH'
alias cdProject="cd $(getRoot) 2>/dev/null || cd"

alias gitgr='date "+%a %b %d %T" && git log --graph --full-history --date=format-local:"%a %d %b %H:%M:%S" --max-count=35 --all --color --pretty=tformat:"%C(red)%h%C(reset) -%C(yellow)%d%C(reset) %s %C(green)(%cd) %C(bold blue)<%an>%C(reset)" --abbrev-commit'
alias gitgrM='gitgr --max-count=10000'
abbr nv nvim
abbr nvp 'nvim -R -'
abbr nvd 'nvim -d'

