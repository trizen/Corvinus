package Corvinus::Types::Block::Switch {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Types::Block::Do);

    sub new($, $obj) {
        bless {obj => $obj, do_block => 0}, __PACKAGE__;
    }

    sub when($self, $arg) {
        state $method = '~~';
        if ($arg->$method($self->{obj})->get_value) {
            $self->{do_block} = 1;
        }
        $self;
    }

    *cand = \&when;

    sub exact($self, $arg) {
        if (ref($arg) eq ref($self->{obj})) {
            state $method = '==';
            if ($self->{obj}->$method($arg)->get_value) {
                $self->{do_block} = 1;
            }
        }
        $self;
    }

    *este = \&exact;

    sub case($self, $arg) {
        if (ref($arg) eq 'Corvinus::Types::Bool::Bool') {
            if ($arg->get_value) {
                $self->{do_block} = 1;
            }
        }
        else {
            return $self->exact($arg);
        }
        $self;
    }

    *daca = \&case;

    sub default($self, $code) {
        $self->{do_block} = 1;
        $code // return $self;
        $self->do($code);
    }

    *else   = \&default;
    *altfel = \&default;

    sub end($self) {
        Corvinus::Types::Black::Hole->new;
    }

    *gata = \&end;

    sub value($self) {
        $self->{obj};
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '~'} = \&when;
        *{__PACKAGE__ . '::' . '?'} = \&case;
        *{__PACKAGE__ . '::' . '>'} = \&exact;
        *{__PACKAGE__ . '::' . ':'} = \&default;
    }

};

1
