package Corvinus::Types::Block::Gather {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new {
        my (undef, $block) = @_;
        bless {block => $block}, __PACKAGE__;
    }

    sub gather($self) {
        local $self->{values} = [];

        sub take($self, @args) {
            push @{$self->{values}}, @args;
        }

        $self->{block}->run;
        Corvinus::Types::Array::Array->new(@{$self->{values}});
    }

    *aduna = \&gather;
}

1;
