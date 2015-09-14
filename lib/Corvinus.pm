package Corvinus {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    our $VERSION = 0.01;

    our $SPACES      = 0;    # the current number of spaces
    our $SPACES_INCR = 4;    # the number of spaces incrementor

    {
        no strict 'refs';

        foreach my $method (['!=', 1], ['==', 0]) {

            *{__PACKAGE__ . '::' . $method->[0]} = sub {
                my ($self, $arg) = @_;

                if (not defined($arg)
                    and ref($self) eq 'Corvinus::Types::Nil::Nil') {
                    return Corvinus::Types::Bool::Bool->new(!$method->[1]);
                }

                ref($self) ne ref($arg)
                  and return Corvinus::Types::Bool::Bool->new($method->[1]);

                state $x = require Scalar::Util;
                if (Scalar::Util::reftype($self) eq 'SCALAR') {
                    return Corvinus::Types::Bool::Bool->new(
                         (defined($$self) ? (defined($$arg) ? $$self eq $$arg : 0) : (defined($$arg) ? 0 : 1)) - $method->[1]);
                }

                return Corvinus::Types::Bool::Bool->new($method->[1]);
            };
        }
    }

    sub new {
        bless {}, __PACKAGE__;
    }

    sub meta($self) {
        Corvinus::Meta::Meta->new($self);
    }

    sub method {
        my ($self, $method, @args) = @_;
        Corvinus::Variable::LazyMethod->new(obj => $self, method => $method, args => \@args);
    }

    sub meta_join {
        my ($self, @args) = @_;
        $self->new(
            CORE::join(
                '',
                map {
                    eval { ${ref($_) ne 'Corvinus::Types::String::String' ? $_->to_s : $_} }
                      // $_
                  } @args
            )
        );
    }

    sub respond_to {
        my ($self, $method) = @_;
        Corvinus::Types::Bool::Bool->new($self->can($method));
    }

    sub is_a {
        my ($self, $obj) = @_;
        Corvinus::Types::Bool::Bool->new(ref($self) eq ref($obj));
    }

    *is_an = \&is_a;

};

use utf8;

#
## Some UNIVERSAL magic
#

*UNIVERSAL::get_value = sub { $_[0] };
*UNIVERSAL::DESTROY   = sub { };
*UNIVERSAL::AUTOLOAD  = sub {
    my ($self, @args) = @_;

    $self = ref($self) if ref($self);
    index($self, 'Corvinus::') == 0 or return;
    eval { require $self =~ s{::}{/}rg . '.pm' };

    if ($@) {
        if (defined &main::load_module) {
            main::load_module($self);
        }
        else {
            die "[EROARE] $@";
        }
    }

    my $func = \&{$AUTOLOAD};
    if (defined(&$func)) {
        return $func->($self, @args);
    }

    die "[EROARE] Metodă nedefinită: $AUTOLOAD";
    return;
};

1;
