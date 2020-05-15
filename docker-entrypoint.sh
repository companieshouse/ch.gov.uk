#!/bin/bash

export PERL5LIB="/app/local/lib/perl5"
exec plenv exec perl "/app/script/start_app" daemon -l "http://*:2000"
