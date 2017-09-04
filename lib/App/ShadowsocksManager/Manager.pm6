
use App::ShadowsocksManager::Shadowsocks;

unit class Manager;

enum ENV (
    VERSION('version'),
    SERVER('server'),
    VARPATH('varpath'),
    CONFIG('config'),
    PREFIX('prefix'),
    POSTFIX('postfix'),
);

has %.env;
has $.var;
has $!id-counter;
has @!servers;

submethod TWEAK() {
    %!env = %{
        version => '0.0.3',
        server  => "{$*HOME}/.shadowsocks-manager/bin/ss-server",
        varpath => '/var/lib/shadowsocks-manager',
        config  => "{$*HOME}/.shadowsocks-manager/config",
        prefix  => 'config_',
        postfix => 'json',
    };
}

method getEnv(Str $name) {
    %!env{$name};
}

multi method create(Int $count, Int $beg, @args = []) {
    my ($configpath, $varpath) = (
        self.getEnv(ENV::CONFIG), self.getEnv(CONFIG::VARPATH),
    );
    my ($prefix, $postfix) = (
        self.getEnv(ENV::PREFIX), self.getEnv(ENV::POSTFIX),
    );

    for ^$count -> $n {
        my ($rootdir, $config) = (
            "{$varpath}/{$prefix}{$beg + $n}",
            "{$configpath}/{$prefix}{$beg + $n}.{$postfix}",
        );
        @!servers.push(
            Shadowsocks.new(
                root => $rootdir,
                config => $config,
                program => self.getEnv(CONFIG::SERVER),
                logfile => "{$rootdir}/default.log",
                pid => $id-counter++,
                args => ['-c', $config, | @args],
            ).create-proc()
        );
    }
}

multi method create(Str $program, Str $config, @args = []) {
    my $rootdir = "{self.getEnv(ENV::VARPATH)}/{basename($config)}";
    @!servers.push(
        Shadowsocks.new(
            root => $rootdir,
            config => $config,
            program => $program,
            logfile => "{$rootdir}/default.log",
            pid => $id-counter++,
            args => ['-c', $config, |@args],
        ).create-proc();
    );
}

multi method start() {
    note "Create Shadowsocks server first." if +@server == 0;
    for @!servers -> $server {
        unless $server.started {
            note "START: {$server.pid}\@{$server.config.abspath}";
            $server.run();
        }
    }
}

multi method start(Int $pid) {
    note "Create Shadowsocks server first." if +@server == 0;
    for @!servers -> $server {
        if $server.pid == $pid {
            unless $server.started {
                note "START: {$server.pid}\@{$server.config.abspath}";
                $server.run();
                return;
            }
        }
    }
}

multi method kill() {
    note "Create Shadowsocks server first." if +@server == 0;
    for @!servers -> $server {
        unless $server.started {
            note "KILL: {$server.pid}\@{$server.config.abspath}";
            $server.kill();
        }
    }
}

multi method kill(Int $pid) {
    note "Create Shadowsocks server first." if +@server == 0;
    for @!servers -> $server {
        if $server.pid == $pid {
            unless $server.started {
                note "KILL: {$server.pid}\@{$server.config.abspath}";
                $server.kill();
                return;
            }
        }
    }
}

multi method ls() {
	note "Create Shadowsocks server first." if +@server == 0;
	for @!servers -> $server {
		note "PID:    {$server.pid}";
		note "BIN:    {$server.program.abspath}";
		note "CONFIG: {$server.config.dirname}/";
		note "NAME:   {$server.config.basename}";
		note "STATUS: {$server.status}";
		note "";
	}
}

multi method ls(Int $id) {
	note "NOTHING!" if +@!servers == 0;
	for @!servers -> $server {
		if $server.id == $id {
            note "PID:    {$server.pid}";
    		note "BIN:    {$server.program.abspath}";
    		note "CONFIG: {$server.config.dirname}/";
    		note "NAME:   {$server.config.basename}";
    		note "STATUS: {$server.status}";
    		note "";
            return;
		}
	}
}
