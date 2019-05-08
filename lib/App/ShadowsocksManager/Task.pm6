
unit module App::ShadowsocksManager::Task;

role Status {
    method what(--> Str) { }
}

class Next does Status is export { }

class Ready does Status is export { }

class Running does Status is export { }

class Success does Status is export { }

class Failed does Status is export {
    has $.payload;

    method what( --> Str ) { $!payload; }
}

role Task is export {
    has Str $.name is required;
    has Str $.description;
    has @.dependencies;
    has Status $.status;

    method init($runtime) {
        $!status = Ready;
    }

    method is-ready() {
        $!status === Ready;
    }

    method is-running() {
        $!status === Running;
    }

    method is-success() {
        $!status === Success;
    }

    method is-failed() {
        $!status === Failed;
    }

    method set-status(Status:U $status = Next) {
        if $status === Next {
            $!status = do given $!status {
                when Ready {
                    Running;
                }
                when Running {
                    Success;
                }
            }
        } else {
            $!status = $status;
        }
    }

    method set-success() {
        $!status := Success;
    }

    method set-failed() {
        $!status := Failed;
    }

    method dependencies() {
        @!dependencies;
    }

    method check-dependency($runtime --> Bool) {
        my $ret = True;
        if +@!dependencies {
            for @!dependencies -> $task-or-name {
                if $task-or-name ~~ Task {
                    if $task-or-name.is-ready() {
                        $runtime.run-task($task-or-name);
                    } elsif ! $task-or-name.is-success() {
                        $ret = False;
                    }
                } elsif $task-or-name ~~ Str {
                    $ret &&= $runtime.get-task($task-or-name).is-success();
                }
            }
        }
        return $ret;
    }

    method add-dependency($dependency --> ::?CLASS:D) {
        @!dependencies.push($dependency);
        self;
    }

    method info() {
        "Task: [{$!name} | {$!description}]";
    }

    method execute($runtime) { ... }
}
