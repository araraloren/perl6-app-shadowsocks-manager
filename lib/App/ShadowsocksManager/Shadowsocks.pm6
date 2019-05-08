
use File::Which;

unit module Shadowsocks;

class EncryptMethod is export {
    enum __Method <
            RC4_MD5
            AES_128_GCM
            AES_192_GCM
            AES_256_GCM
            AES_128_CFB
            AES_192_CFB
            AES_256_CFB
            AES_128_CTR
            AES_192_CTR
            AES_256_CTR
            CAMELLIA_128_CFG
            CAMELLIA_192_CFG
            CAMELLIA_256_CFG
            CF_CFB
            CHACHA20_IETF_OPLY1305
            XCHACHA20_IETF_OPLY1305
            SALAS20
            CHACHA20
            CHACHA20_IETF
        >;
}

sub to-method(EncryptMethod::__Method $em --> Str) is export {
    $em.Str.subst('_', '-', :g).lc;
}

role SSInstance {
    has Proc::Async $.proc;
    has Str $.bin;
    has Str $.out;
    has Str $.err;
    has Str $.cfg;
    has Bool $.sudo;
    has $!promise;
    has $!pid;

    method status(--> Str) {
        $!promise.defined ?? $!promise.status.Str !! "Ready";
    }

    method pid(--> Int) {
        $!pid // ($!pid = await $!proc.pid);
    }

    method create-proc() {
        $!proc // ($!proc .= new(self.bin(), self.arguments()));
    }

    method run(--> Bool) { ... }

    method stop() {
        $!proc // $!proc.kill(Signal::SIGKILL);
    }

    method arguments() { ... }

    method password(--> Str) { ... }

    method port(--> Int) { ... }

    method timeout(--> Int) { ... }

    method method(--> Str) { ... }

    method server(--> Str) { ... }

    method set-bin(Str $path) { $!bin = $path; }

    method set-password(Str $password) { ... }

    method set-port(Int $port) { ... }

    method set-timeout(Int $timeout) { ... }

    method set-method(Int $em) { ... }

    method set-server(Str $ip) { ... }

    method enable-fastopen() { ... }

    method set-special-data($data) { ... }
}

class BinInstance does SSInstance is export {
    has %!ss-arguments;
    has $!fast-open;
    has @!cache;

    submethod TWEAK() {
        %!ss-arguments<s> = "0.0.0.0";
        %!ss-arguments<p> = 8388;
        %!ss-arguments<m> = EncryptMethod::RC4_MD5.&to-method;
        %!ss-arguments<t> = 300;
        unless $!bin.defined {
            self.set-bin(.sudo() ?? &which('sudo') !! &which('ss-server'));
        }
    }

    method run(--> Bool) {
        unless $!promise {
            my $proc = self.proc();
            $proc.bind-stdout(open(self.out(), :w));
            $proc.bind-stderr(open(self.err(), :w));
            $!promise = $proc.start();
        }
        $!promise.started;
    }

    method arguments() {
        unless +@!cache > 0 {
            @!cache.append("-{.key}", .value) for %!ss-arguments;
            @!cache.append("--fast-open");
        }
        @!cache;
    }

    method password(--> Str) {
        %!ss-arguments<k>;
    }

    method port(--> Int) {
        %!ss-arguments<p>;
    }

    method timeout(--> Int) {
        %!ss-arguments<t>;
    }

    method method(--> Str) {
        %!ss-arguments<m>;
    }

    method server(--> Str) {
        %!ss-arguments<s>;
    }

    method set-password(Str $password) {
        %!ss-arguments<k> = $password;
    }

    method set-port(Int $port) {
        %!ss-arguments<p> = $port;
    }

    method set-timeout(Int $timeout) {
        %!ss-arguments<t> = $timeout;
    }

    method set-method(Int $em) {
        %!ss-arguments<m> = $em.&to-method;
    }

    method set-server(Str $ip) {
        %!ss-arguments<s> = $ip;
    }

    method set-config(Str $path) {
        my $require := try require JSON::Fast <&from-json>;

        if $require !=== Nil {
            my %config = from-json $path.IO.slurp;
            self.set-password(%config<password>)
                if %config<password>:exists;
            self.set-port(%config<server_port>)
                if %config<server_port>:exists;
            self.set-timeout(%config<timeout>)
                if %config<timeout>:exists;
            self.set-method(%config<method>)
                if %config<method>:exists;
            self.set-server(%config<server>)
                if %config<server>:exists;
            self.enable-fastopen()
                if %config<fast_open>:exists;
        }
    }

    method enable-fastopen() {
        $!fast-open = True;
    }

    method set-special-data($data) { }
}
