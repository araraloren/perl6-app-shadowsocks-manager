
unit module App::ShadowsocksManager::State;

class State is export {
    has $.data;
    has $.state;

    method has-data() {
        $!data.defined;
    }
}

class StateMachine is export {
    has @.state;
    has $!state;
    has $!index     = 0;
    has $!manual    = False;

    method from-enum(::ET) {
        if (ET.HOW !~~ Metamodel::EnumHOW) {
            die "ERROR: {ET} is not a enum type!";
        }
        @!state = ET.enums.keys.sort;
    }

    method update($state) {
        if ($state !(elem) @!state) {
            die "ERROR: unknow state: $state";
        }
        ($!state, $!manual) = ($state, True);
    }

    method !internal-update() {
        if (! $!manual) {
            $!state = @!state[$!index];
            $!index = ($!index + 1) % +@!state;
        }
        else {
            $!manual = False;
        }
        State.new(state => $!state);
    }

    method Supply($interval where * >= 0 --> Supply) {
        supply {
            whenever Supply.interval($interval) {
                emit self!internal-update();
            }
        }
    }
}
