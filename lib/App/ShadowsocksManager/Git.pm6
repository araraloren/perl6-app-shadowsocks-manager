
use App::ShadowsocksManager::ArgList;
use App::ShadowsocksManager::State;

unit module App::ShadowsocksManager::Git;

class RepoURI is export {
    has $.protocol;
    has $.name;
    has $.repo;

    method uri() {
        given $!protocol {
            when 'ssh' {
                "git\@github.com:{$!name}/{$!repo}.git";
            }
            when 'https' {
                "https://github.com/{$!name}/{$!repo}";
            }
            default {
                fail "Unknow protocol";
            }
        }
    }
}

class Git is export {

    enum Clone < WAIT ENUMERATE RECEIVE RESOLVE DONE >;

    has RepoURI $.repo is required;

    method name(--> Str) {
        'git';
    }

    method execute(ArgList $al --> Proc::Async) {
        Proc::Async.new(self.name(), $al.args());
    }

    method clone-repo(Str $dir?) {
        supply {
            my $al = ArgList.new(subcmd => 'clone');
            my $last;
            $al.add-subopt('--progress', $!repo.uri());
            $al.add-subopt($dir) if $dir.defined;
            given self.execute($al) -> $p {
                whenever $p.stderr.lines {
                    given $_ {
                        when /^ 'Cloning into ' \'(.+)\'/ {
                            $last = State.new(state => Clone::WAIT, data => $0.Str);
                        }
                        when /^ 'remote: Enumerating objects:' \s+ (\d+)/ {
                            $last = State.new(state => Clone::ENUMERATE, data => $0.Int);
                        }
                        when /^ 'Receiving objects:' \s+ (\d+)'%' \s+ \( (\d+) '/' \d+ \)/ {
                            $last = State.new(state => Clone::RECEIVE, data => [$0.Int, $1.Int]);
                        }
                        when /^ 'Resolving deltas:' \s+ (\d+)'%' \s+ \( (\d+) '/' \d+ \)/ {
                            $last = State.new(state => Clone::RESOLVE, data => [$0.Int, $1.Int]);
                        }
                        default {}
                    }
                    emit $last;
                }
                whenever $p.start {
                    emit State.new(state => Clone::DONE);
                    done;
                }
            }
        }
    }

    method chdir($dir) {
        chdir($dir);
    }

    method list-tag() {
        supply {
            my $al = ArgList.new(subcmd => 'tag');
            given self.execute($al) -> $p {
                whenever $p.stderr.lines {
                    say " --> ", $_;
                }
                whenever $p.start {
                    say "DONE";
                    done;
                }
            }
        }
    }
}
