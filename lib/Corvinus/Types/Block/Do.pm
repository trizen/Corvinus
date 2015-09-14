package Corvinus::Types::Block::Do {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub do($self, $code) {

        if ($self->{do_block}) {
            my $result = $code->run;
            my $ref    = ref($result);
            if ($ref eq 'Corvinus::Types::Block::Continue') {
                $self->{do_block} = 0;
                return $self;
            }
            elsif (   $ref eq 'Corvinus::Types::Block::Break'
                   or $ref eq 'Corvinus::Types::Block::Return'
                   or $ref eq 'Corvinus::Types::Block::Next') {
                $self->{do_block} = 0;
                return $result;
            }
            return Corvinus::Types::Black::Hole->new($result);
        }

        $self;
    }

    *then = \&do;
    *atunci = \&do;
};

1
