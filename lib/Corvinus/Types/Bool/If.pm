package Corvinus::Types::Bool::If {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Types::Block::Do);

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub daca($self, @args) {
        $self->{do_block} = $args[-1] ? 1 : 0;
        $self;
    }

    sub alt_daca($self, @args) {
        $self->{do_block} = $args[-1] ? 1 : 0;
        $self;
    }

    sub altfel($self, $code) {
        $self->{do_block} = 1;
        $self->do($code);
    }

};

1
