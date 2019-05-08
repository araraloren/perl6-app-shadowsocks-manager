
use App::ShadowsocksManager::Task;

unit module App::ShadowsocksManager::Runtime;

class Runtime is export {
    has %!complete;
    has Task %.task;
    has %!running;
    has @!remains;
    has Int $.maxthread;
    has Int $!thread = 0;

    method complete-task(Task:D $task, $result) {
        %!complete{$task.name} = $result;
    }

    method add-task(Task:D $task) {
        %!task{$task.name} = $task;
    }

    method get-task(Str:D $name) {
        %!task{$name};
    }

    method run-task(Task:D $task) {
        my $should-add = $!thread < $!maxthread && !$task.is-running();
        if $should-add {
            %!running{$task.name} = start {
                $task.set-status();
                $task.execute(self);
            };
            $!thread++;
        }
        return $should-add;
    }

    method get-running() {
        %!running.keys;
    }

    method get-running-thread(Str:D $name) {
        %!running{$name};
    }

    method get-task-result(Str:D $name) {
        %!complete{$name};
    }

    method init() {
        for %!task {
            .value.init(self);
        }
    }

    method execute( --> Supply) {
        my @waiting = %!task.values;

        self.init();
        supply {
            while +@waiting > 0 || +%!running > 0 {
                for @waiting -> $task {
                    if $task.check-dependency(self) {
                        if ! self.run-task($task) {
                            @!remains.push($task);
                        }
                    } else {
                        @!remains.push($task);
                    }
                }

                my @runnings = self.get-running();

                for @runnings -> $name {
                    if self.get-task($name) -> $task {
                        if ! $task.is-running() {
                            self.complete-task($task, await self.get-running-thread($name));
                            %!running{$name}:delete;
                            $!thread--;
                            emit $task;
                        }
                    }
                }

                @waiting = @!remains;
                @!remains = [];
            }
        }
    }
}
