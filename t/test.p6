
use App::ShadowsocksManager::Task;
use App::ShadowsocksManager::Runtime;

class Task::Command does App::ShadowsocksManager::Task::Task {
    has &.task;

    method execute($runtime) {
        say "Task {self.name()} execute ok, !!!";
        &!task() if ?&!task;
        self.set-success();
    }
}

my $runtime = Runtime.new(maxthread => 2);

$runtime.add-task(
    Task::Command.new(
        name => "first",
        dependencies => ["second", ],
        task => sub {
            sleep 3;
            say "Doing first task!";
        },
    )
);
$runtime.add-task(
    Task::Command.new(
        name => "second",
        task => sub {
            sleep 1;
            say "Doing second task!";
        }
    )
);

react {
    whenever $runtime.execute() {
        say .name, " is complete, result = ", $runtime.get-task-result(.name);
    }
}
