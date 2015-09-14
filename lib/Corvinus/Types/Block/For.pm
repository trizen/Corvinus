package Corvinus::Types::Block::For {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, @args) = @_;
        $self->{arg} = \@args;
        $self;
    }

    *pentru = \&for;

    sub do {
        my ($self, $code) = @_;
        ref($self->{arg}) eq 'ARRAY'
          ? $code->for(@{$self->{arg}})
          : $self->{arg}->each($code);
    }

    *atunci = \&do;
};

1
