package Corvinus::Types::Number::Complex {

    use utf8;
    use 5.014;

    use parent qw(
      Corvinus::Convert::Convert
      Corvinus::Types::Number::Number
      );

    use overload
      q{""}   => \&get_value,
      q{bool} => \&get_value;

    sub new {
        my (undef, $x, $y) = @_;

        my $self = bless({}, __PACKAGE__);
        defined($x) || return $self;

        state $_x = require Math::Complex;

        #
        ## Check X
        #
        if (ref($x) eq __PACKAGE__ or ref($x) eq 'Corvinus::Types::Number::Number') {
            $x = $$x;
        }

        if (not defined $y and ref($x) eq 'Math::Complex') {
            return bless \$x, __PACKAGE__;
        }

        if (my $rx = ref($x)) {
            if ($rx eq 'Math::BigFloat' or $rx eq 'Math::BigInt') {
                ## ok
            }
            elsif ($rx eq 'Math::BigRat') {
                $x = $x->as_float;
            }
            elsif ($rx eq 'Math::Complex') {
                $x = Math::Complex::Re($x);
            }
            else {
                $x = $x->get_value;
            }
        }

        if (not defined(&Math::BigFloat::_cartesian)) {
            *Math::BigFloat::_cartesian = sub {
                Math::Complex->make($_[0], 0)->_cartesian;
            };
        }

        #
        ## Check Y
        #
        if (ref($y) eq __PACKAGE__ or ref($y) eq 'Corvinus::Types::Number::Number') {
            $y = $$y;
        }

        if (my $ry = ref($y)) {
            if ($ry eq 'Math::BigFloat' or $ry eq 'Math::BigInt') {
                ## ok
            }
            elsif ($ry eq 'Math::BigRat') {
                $y = $y->as_float;
            }
            elsif ($ry eq 'Math::Complex') {
                $y = Math::Complex::Im($y);
            }
            else {
                $y = $y->get_value;
            }
        }

        bless \Math::Complex->make($x, $y), __PACKAGE__;
    }

    *call = \&new;

    sub cartesian {
        my ($self) = @_;
        ${$self}->display_format('cartesian');
        $self;
    }

    sub polar {
        my ($self) = @_;
        ${$self}->display_format('polar');
        $self;
    }

    sub real {
        my ($self) = @_;
        state $_x = require Math::Complex;
        Corvinus::Types::Number::Number->new(Math::Complex::Re($$self));
    }

    *re = \&real;
    *Re = \&real;

    sub imaginary {
        my ($self) = @_;
        state $_x = require Math::Complex;
        Corvinus::Types::Number::Number->new(Math::Complex::Im($$self));
    }

    *im = \&imaginary;
    *Im = \&imaginary;

    sub reciprocal {
        __PACKAGE__->new(1)->div($_[0]);
    }

    sub get_constant {
        my ($self, $name) = @_;

        state $_x = require Math::Complex;

        state %cache;
        state $table = {i => sub { __PACKAGE__->new(Math::Complex->i) },};

        $cache{lc($name)} //= exists($table->{lc($name)}) ? $table->{lc($name)}->() : do {
            warn qq{[WARN] Inexistent Complex constant "$name"!\n};
            undef;
        };
    }

    sub get_value {
        ${$_[0]};
    }

    sub inc {
        my ($self) = @_;
        $self->new($self->get_value + 1);
    }

    sub dec {
        my ($self) = @_;
        $self->new($self->get_value - 1);
    }

    sub cmp {
        my ($self, $num) = @_;
        Corvinus::Types::Number::Number->new($self->get_value <=> $num->get_value);
    }

    sub factorial {
        my ($self) = @_;
        my $fac = 1;
        $fac *= $_ for (2 .. $self->get_value);
        $self->new($fac);
    }

    *fact = \&factorial;

    sub int {
        my ($self) = @_;
        $self->new(CORE::int($self->get_value));
    }

    *as_int = \&int;

    sub neg {
        my ($self) = @_;
        $self->new(-$self->get_value);
    }

    *negate = \&neg;

    sub not {
        my ($self) = @_;
        $self->new(-$self->get_value - 1);
    }

    *conjugated = \&not;
    *conj       = \&not;

    sub sign {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->get_value >= 0 ? '+' : '-');
    }

    sub is_zero {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value == 0);
    }

    *isZero = \&is_zero;

    sub is_nan {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->false;
    }

    *isNaN  = \&is_nan;
    *is_NaN = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value >= 0);
    }

    *isPositive = \&is_positive;
    *isPos      = \&is_positive;
    *is_pos     = \&is_positive;

    sub is_negative {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value < 0);
    }

    *isNegative = \&is_negative;
    *isNeg      = \&is_negative;
    *is_neg     = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value % 2 == 0);
    }

    *isEven = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value % 2 != 0);
    }

    *isOdd = \&is_odd;

    sub is_inf {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value == 'inf');
    }

    *isInf       = \&is_inf;
    *is_infinite = \&is_inf;
    *isInfinite  = \&is_inf;

    sub is_integer {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value == CORE::int($self->get_value));
    }

    *isInt     = \&is_integer;
    *is_int    = \&is_integer;
    *isInteger = \&is_integer;

    sub rand {
        my ($self, $max) = @_;

        my $min = $self->get_value;
        $max = ref($max) ? $max->get_value : do { $min = 0; $self->get_value };

        $self->new($min + CORE::rand($max - $min));
    }

    sub ceil {
        my ($self) = @_;

        CORE::int($self->get_value) == $self->get_value
          && return $self;

        $self->new(CORE::int($self->get_value + 1));
    }

    sub floor {
        my ($self) = @_;
        $self->new(CORE::int($self->get_value));
    }

    sub round { ... }

    sub roundf {
        my ($self, $num) = @_;
        $self->new(sprintf "%.*f", $num->get_value * -1, $self->get_value);
    }

    *fround = \&roundf;
    *fRound = \&roundf;

    sub digit { ... }

    sub nok { ... }
    *binomial = \&nok;

    sub length { ... }

    *len = \&length;

    sub sstr {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->get_value);
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Complex.new(' . $self->real . ', ', $self->imaginary . ')');
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
    }
};

1
