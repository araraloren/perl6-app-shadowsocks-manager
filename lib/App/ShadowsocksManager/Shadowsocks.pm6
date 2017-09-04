
unit class Shadowsocks;

has $.root;
has $.config;
has $.program;
has $.logfile;
has @.args;
has $.pid;
has $!proc;
has $!log-fh;
has $.promise;

submethod TWEAK(:$root, :$config, :$program, :$logfile) {
    $!root = $root.IO;
    $!config = $root.IO;
    $!program = $program.IO;
    $!logfile = $logfile.IO;
}

method create-run-dependencies {
    try {
        $!root.mkdir;
        symlink("{$!root.abspath}/{$!config.basename}", $!config.abspath);
        symlink("{$!root.abspath}/{$!program.basename}", $!program.abspath);
        $!logfile.open(:w);
        CATCH {
            default {
                note .Str;
            }
        }
    }
}

method clean-run-dependencies {
    try {
        unlink("{$!root.abspath}/{$!config.basename}");
        unlink("{$!root.abspath}/{$!program.basename}");
        $!logfile.unlink();
        $!root.rmdir();
        CATCH {
            default {
                note .Str;
            }
        }
    }
}

method create-proc {
    self.create-run-dependencies();
    unless $!log-fh {
        $!log-fh = $!logfile.open(:w);
    }
    $!proc = Proc::Async.new($!program.abspath, @!args);
    $!proc.stdout.tap(
		-> $str 	{ $!log-fh.print("STDOUT\@{time}: $str\n"); },
		done 	=>	{ $!log-fh.print("STDOUT\@{time}: SERVER DONE.\n")  ; },
		quit 	=>	{ $!log-fh.print("STDOUT\@{time}: SERVER QUIT.\n")  ; },
		closing =>	{ $!log-fh.print("STDOUT\@{time}: CLOSING ??\n")  ; }
	);
	$!proc.stderr.tap(
		-> $str 	{ $!log-fh.print("STDERR\@{time}: $str\n"); },
		done 	=>	{ $!log-fh.print("STDERR\@{time}: SERVER DONE.\n")  ; },
		quit 	=>	{ $!log-fh.print("STDERR\@{time}: SERVER QUIT.\n")  ; },
		closing =>	{ $!log-fh.print("STDERR\@{time}: CLOSING ??\n")  ; }
	);
	self;
}

method run {
    unless $!proc.started {
        $!promise = $proc.start;
    }
    self;
}

method kill($signal = Signal::SIGKILL) {
    $!proc.kill($signal);
}

method status {
    $!promise ?? $!promise.status !! "Ready";
}

method started {
    $!proc.started;
}
