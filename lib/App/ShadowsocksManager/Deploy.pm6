
# get ss-libev

# compiler

# install into .ShadowsocksManager

# check

unit class Deploy;

role Task {
    has Str $.name;
    has Str $.description;
    has Str @.dependencies;
    has Bool $.success;
    has Str $.error;
}

class Task::Command does Task {
    has Str $.command;
}

class Task::Block does Task {
    has &.block;
}
