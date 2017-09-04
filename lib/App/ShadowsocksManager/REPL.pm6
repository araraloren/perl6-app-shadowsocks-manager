use Readline;
use Getopt::Advance;
use Getopt::Advance::Helper;

class CommandMaker {
	has &.cmd;
	has &.tweak;

	method tweak($opts) {
		&!tweak($opts) if &!tweak.defined;
		$opts;
	}
}

class REPL {
	sub make-opts {
		my OptionSet $opts .= new;
		$opts.append('h|help=b' => 'print this help message.');
		$opts;
	}

	sub main(@command, @optsets, |c) {
		getopt(@command, @optsets, |c);
	}

    # 临时版本
	sub helper($optset, $outfh) {
		my ($usage, @annotations) := &ga-helper-impl($optset, $outfh);
		my $no-pn = $usage;

		$no-pn ~~ s/"{$*PROGRAM-NAME} "//;
		$outfh.say($no-pn);
		$outfh.say($_) for @annotations;
	}

	has $.prompt    = ">>";
	has %.command   = Hash.new;
	has &.main      = &main;
	has &.helper    = &helper;
	has $.readline  = Readline.new;
	has &.make-opts = &make-opts;
	has $.data      = Nil;

	submethod TWEAK() {
		unless %!command<help>:exists {
			%!command<help> = CommandMaker.new(
				tweak => -> $opts {
					$opts.insert-pos(
						"command",
						1,
						-> $cmd {
							if %!command{$cmd.value}:exists {
								getopt([$cmd.value, "-h", ],
									   self!prepare-one-optionset(
										   $cmd.value,
										   %!command{$cmd.value}
									   ),
									   helper => &!helper,
									   :autohv
                                );
							} else {
								note "Unrecognize command: {$cmd.value}";
							}
						},
					);
				}
			);
		}
	}

	method set-data($data) {
		$!data = $data;
	}

	method add-command($name, :&cmd = Block, :&tweak = Block) {
		%!command{$name} = CommandMaker.new( :&cmd, :&tweak );
	}

	method alias($from, $to) {
		%!command{$to} := %!command{$from};
	}

	method !prepare-one-optionset($name, $cmdmaker) {
		my $opts = &!make-opts();
		$opts.insert-cmd($name);
		$opts.insert-main($cmdmaker.cmd) with $cmdmaker.cmd;
		$cmdmaker.tweak($opts);
		$opts;
	}

	method !make-optionsets() {
		my @ret;
		@ret.push(self!prepare-one-optionset(.key, .value)) for %!command;
		@ret;
	}

	method main-loop() {
		my $flag = True;

		while $flag {
			if $!readline.readline($!prompt) -> $line {
				if $line.trim -> $line {
					my @command = $line.split(/\s+/, :skip-empty);
					if %!command{@command[0]}:exists {
						try {
							&!main(@command, self!make-optionsets(), helper => &!helper, :autohv);
						}
					} else {
						note "Unrecognize command: {$line}";
					}
				}
			}
		}
	}
}
