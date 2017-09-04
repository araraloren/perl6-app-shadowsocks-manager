#!/usr/bin/env perl6

role Task {
	has Str $.name;
	has Str $.description;
	has Str @.dependencies;
	has Bool $.success = True;
	has Str $.error;

	method set-result(Bool $result, Str $error = Str) {
		$!success = $result;
		$!error = $error;
	}

	method display-info() {
		"Task: [{$!name} | {$!description}]";
	}

	method execute($runtime) { ... }
}

role TaskRunner {
	has %.complete;
	has Task %!task;
	has %.running;

	method complete-task($task) {
		%!complete{$task.name} = True;
	}

	method add-task(Task $task) {
		%!task{$task.name} = $task;
	}

	method !execute-all-task() {
		my @waiting = %!task.values;
		supply {
			while +@waiting > 0 {
				my @remains;
				for @waiting -> $task {
					if (all %!task{$task.dependencies}) {
						if (all %!complete{$task.dependencies}) {
							whenever $task.execute(self) {
								emit $_;
							}
						} elsif (not all %!running{$task.dependencies}) {
							@remains.push($task);
						}
					}
				}
				@waiting = @remains;
			}
		}
	}

	method execute() {
		react {
			whenever self!execute-all-task() {
				note "{.display-info} = ", .success ?? "OK!" !! "FAILED ?]=> {.error}."
                if $*DEBUG;
				%!complete{.name} = .success;
			}
		}
	}
}

class Task::Command does Task {
	has @.command;

	method execute($runtime) {
		supply {
			my $proc = Proc::Async.new(|@!command);
			my ($out, $err) = ("", "");

			whenever $proc.stdout { $out ~= $_ }
			whenever $proc.stderr { $err ~= $_ }
			whenever $proc.start {
				note "{self.display-info} START" if $*DEBUG;
				with .exitcode {
					self.set-result($_ == 0, $_ == 0 ?? Str !! ($err || $out));
					$runtime.complete-task(self);
				}
				emit self;
			}
		}
	}
}
