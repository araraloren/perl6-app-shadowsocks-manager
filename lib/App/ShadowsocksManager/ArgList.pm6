
unit module App::ShadowsocksManager::ArgList;

class ArgList is export {
    has @.opts;
    has $.subcmd;
    has @.subopts;
    has @.nonopts;

    method add-opt(*@opts) {
        @!opts.append(@opts);
        self;
    }

    method add-nonopt(*@nonopts) {
        @!nonopts.append(@nonopts);
        self;
    }

    method set-subcmd(Str:D $cmd, *@subopts) {
        $!subcmd = $cmd;
        @!subopts = @subopts;
        self;
    }

    method add-subopt(*@subopts) {
        @!subopts.append(@subopts);
    }

    method args() {
        my @args;
        @args.append(@!opts);
        @args.append($!subcmd);
        @args.append(@!subopts);
        @args.append(@!nonopts);
        @args;
    }
}
