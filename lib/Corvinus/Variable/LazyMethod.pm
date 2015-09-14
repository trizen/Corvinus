package Corvinus::Variable::LazyMethod {

    our $AUTOLOAD;
    use parent qw(Corvinus);

    sub new {
        my (undef, %hash) = @_;
        bless \%hash, __PACKAGE__;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        my $call = $self->{method};

        if ($call->SUPER::isa('Corvinus::Types::Block::Code')) {
            if ($method eq 'call') {
                return $call->call($self->{obj}, @{$self->{args}}, @args);
            }
            return $call->call($self->{obj}, @{$self->{args}})->$method(@args);
        }

        if (ref($call) ne 'CODE') {
            $call = $call->get_value;
        }

        if ($method eq 'call') {
            return $self->{obj}->$call(@{$self->{args}}, @args);
        }

        $self->{obj}->$call(@{$self->{args}})->$method(@args);
    }

};

1
