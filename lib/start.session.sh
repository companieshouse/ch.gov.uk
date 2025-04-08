#!/bin/bash

# set up plenv
PLENV_ROOT=/opt/plenv
PATH="$PLENV_ROOT/bin:$PLENV_ROOT/shims:$PATH"
eval "$(plenv init -)"

# set PERL5LIB
export PERL5LIB=/app/local/lib/perl5:$PERL5LIB

# run my code
perl -e "use MojoX::Security::Session; MojoX::Security::Session::_many_sessionIDs($SESSION_ID_COUNT)"