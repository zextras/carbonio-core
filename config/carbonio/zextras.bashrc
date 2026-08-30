# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias h='history 40'
alias j='jobs'

# Source global definitions
if [ -f /etc/bashrc ]; then
  # shellcheck source=/dev/null
  . /etc/bashrc
fi

JAVA_HOME=/opt/zextras/common/lib/jvm/java
export JAVA_HOME

PATH=/opt/zextras/bin:${JAVA_HOME}/bin:/opt/zextras/common/bin:/opt/zextras/common/sbin:/usr/sbin:${PATH}
export PATH

unset LD_LIBRARY_PATH

eval "$(/usr/bin/perl -V:archname)"
PERLLIB=/opt/zextras/common/lib/perl5/$archname:/opt/zextras/common/lib/perl5
export PERLLIB

PERL5LIB=$PERLLIB
export PERL5LIB

umask 0027

unset DISPLAY

export MANPATH=/opt/zextras/common/share/man:${MANPATH}

export HISTTIMEFORMAT="%y%m%d %T "

# configd bash completion
if [ -f /opt/zextras/common/share/bash-completion/completions/configd ]; then
  # shellcheck source=/dev/null
  . /opt/zextras/common/share/bash-completion/completions/configd
fi

# configd wrapper bash completion
if [ -f /opt/zextras/common/share/bash-completion/completions/configd-wrappers ]; then
  # shellcheck source=/dev/null
  . /opt/zextras/common/share/bash-completion/completions/configd-wrappers
fi
