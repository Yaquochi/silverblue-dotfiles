# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

export LIBVIRT_DEFAULT_URI='qemu:///system'
export TERM=xterm-256color
export VISUAL=vim
export EDITOR=vim
export SUDO_EDITOR=vim
export GIT_EDITOR=vim
export SYSTEMD_EDITOR=vim

eval "$(dircolors -b ~/.dircolors)"
alias ls='ls --color=auto'
PS1='\[\e[38;2;199;146;234m\]\u@\h:\[\e[38;2;137;220;235m\]\w\[\e[38;2;245;166;214m\]\$ \[\e[0m\]'

alias k-demo='export KUBECONFIG=~/.kube/config_demo && echo "Demo"'
alias k-lanit='export KUBECONFIG=~/.kube/config_lanit && echo "Test&Dev&DKS"'
alias k-presale='export KUBECONFIG=~/.kube/config_presale && echo "Presale"'
alias k-status='echo "Текущий KUBECONFIG: $KUBECONFIG" && kubectl config current-context 2>/dev/null'

export K9S_FEATURE_GATE_NODE_SHELL=true

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
