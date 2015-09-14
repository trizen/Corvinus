package Corvinus::Types::Number::Number {

    use utf8;
    use 5.014;

    our $GET_PERL_VALUE = 0;

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload
      q{bool} => sub { ${$_[0]} != 0 },
      q{""}   => \&get_value;

    sub new_float {
        my (undef, $num) = @_;

        state $x = require Math::BigFloat;
        ref($num) eq 'Math::BigFloat'
          ? (bless \$num, __PACKAGE__)
          : (
            bless \do {
                eval { Math::BigFloat->new($num) } // Math::BigFloat->new(Math::BigInt->new($num));
            },
            __PACKAGE__
            );
    }

    *new = \&new_float;

    sub new_int {
        my (undef, $num) = @_;

        state $x = require Math::BigInt;
        my $ref = ref($num);
        $ref eq 'Math::BigInt' ? (bless \$num, __PACKAGE__)
          : (   $ref eq 'Math::BigFloat'
             || $ref eq 'Math::BigRat') ? (bless \($num->as_int), __PACKAGE__)
          : (bless \Math::BigInt->new(index($num, '.') > 0 ? CORE::int($num) : $num), __PACKAGE__);
    }

    sub new_rat {
        my (undef, $num) = @_;

        state $x = require Math::BigRat;
        ref($num) eq 'Math::BigRat'
          ? (bless \$num, __PACKAGE__)
          : (
            bless \do {
                eval { Math::BigRat->new($num) }
                  // eval { Math::BigRat->new(Math::BigFloat->new($num)) } // Math::BigRat->new(Math::BigInt->new($num));
            },
            __PACKAGE__
            );
    }

    sub get_value {
        $GET_PERL_VALUE ? ${$_[0]}->numify : ${$_[0]};
    }

    sub mod {
        my ($self, $num) = @_;
        $self->new($self->get_value % $num->get_value);
    }

    sub modpow {
        my ($self, $y, $mod) = @_;
        $self->new($self->get_value->copy->bmodpow($y->get_value, $mod->get_value));
    }

    *expmod = \&modpow;

    sub pow {
        my ($self, $num) = @_;
        $self->new($self->get_value**$num->get_value);
    }

    sub inc {
        my ($self) = @_;
        $self->new($self->get_value->copy->binc);
    }

    sub dec {
        my ($self) = @_;
        $self->new($self->get_value->copy->bdec);
    }

    sub and {
        my ($self, $num) = @_;
        $self->new($self->get_value->as_int->band($num->get_value->as_int));
    }

    sub or {
        my ($self, $num) = @_;
        $self->new($self->get_value->as_int->bior($num->get_value->as_int));
    }

    sub xor {
        my ($self, $num) = @_;
        $self->new($self->get_value->as_int->bxor($num->get_value->as_int));
    }

    sub eq {
        my ($self, $num) = @_;
        my $value = defined($num) ? $num->get_value : undef;
        Corvinus::Types::Bool::Bool->new(length($value) ? $self->get_value == $value : 0);
    }

    *equals = \&eq;

    sub ne {
        my ($self, $num) = @_;
        my $value = defined($num) ? $num->get_value : undef;
        Corvinus::Types::Bool::Bool->new(length($value) ? $self->get_value != $value : 1);
    }

    sub cmp {
        my ($self, $num) = @_;
        __PACKAGE__->new($self->get_value->bcmp($num->get_value));
    }

    sub acmp {
        my ($self, $num) = @_;
        __PACKAGE__->new($self->get_value->bacmp($num->get_value));
    }

    sub gt {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value > $num->get_value);
    }

    sub lt {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value < $num->get_value);
    }

    sub ge {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value >= $num->get_value);
    }

    sub le {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value <= $num->get_value);
    }

    sub subtract {
        my ($self, $num) = @_;
        $self->new($self->get_value - $num->get_value);
    }

    sub add {
        my ($self, $num) = @_;
        $self->new($self->get_value + $num->get_value);
    }

    sub multiply {
        my ($self, $num) = @_;
        $self->new($self->get_value * $num->get_value);
    }

    *x = \&multiply;
    *multiplica = \&multiply;

    sub div {
        my ($self, $num) = @_;
        $self->new($self->get_value / $num->get_value);
    }

    sub divmod {
        my ($self, $num) = @_;
        Corvinus::Types::Array::List->new($self->div($num)->int, $self->mod($num));
    }

    sub factorial {
        my ($self) = @_;
        $self->new($self->get_value->copy->bfac);
    }

    *fact = \&factorial;

    sub comb {
        my ($self, $num) = @_;

        my $k = $self->get_value;
        my $n = $num->get_value;
        my @c = 0 .. $k - 1;

        my @bag;
        while (1) {
            push @bag, [@c];
            next if $c[$k - 1]++ < $n - 1;
            my $i = $k - 2;
            $i-- while $i >= 0 && $c[$i] >= $n - ($k - $i);
            last if $i < 0;
            $c[$i]++;
            while (++$i < $k) { $c[$i] = $c[$i - 1] + 1; }
        }

        Corvinus::Types::Array::Array->new(
            map {
                Corvinus::Types::Array::Array->new(map { Corvinus::Types::Number::Number->new($_) } @{$_})
              } @bag
        );
    }

    sub array_to {
        my ($self, $num, $step) = @_;

        $step = defined($step) ? $step->get_value : 1;

        my @array;
        my $to = $num->get_value;

        if ($step == 1) {

            # Unpack limit
            $to = $to->bstr if ref($to);

            foreach my $i ($self->get_value .. $to) {
                push @array, $self->new($i);
            }
        }
        else {
            for (my $i = $self->get_value ; $i <= $to ; $i += $step) {
                push @array, $self->new($i);
            }
        }

        Corvinus::Types::Array::Array->new(@array);
    }

    *arr_to = \&array_to;

    sub array_downto {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;

        my @array;
        my $downto = $num->get_value;

        for (my $i = $self->get_value ; $i >= $downto ; $i -= $step) {
            push @array, $self->new($i);
        }

        Corvinus::Types::Array::Array->new(@array);
    }

    *arr_downto = \&array_downto;

    sub to {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;
        Corvinus::Types::Array::RangeNumber->new(
                                              from => $self->get_value,
                                              to   => $num->get_value,
                                              step => $step,
                                             );
    }

    *upto = \&to;
    *pana_la = \&to;

    sub downto {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;
        Corvinus::Types::Array::RangeNumber->new(
                                              from => $self->get_value,
                                              to   => $num->get_value,
                                              step => -$step,
                                             );
    }

    *coboara_la = \&downto;

    sub range {
        my ($self, $to, $step) = @_;

        defined($to)
          ? $self->to($to, $step)
          : $self->new(0)->to($self);
    }

    *sir = \&range;

    sub sqrt {
        my ($self) = @_;
        $self->new(CORE::sqrt($self->get_value));
    }

    *radical = \&sqrt;

    sub root {
        my ($self, $n) = @_;
        $self->new($self->get_value->copy->broot($n->get_value));
    }

    *n_radical = \&root;

    sub abs {
        my ($self) = @_;
        $self->new(CORE::abs($self->get_value));
    }

    *pos      = \&abs;
    *positive = \&abs;
    *absolut = \&abs;

    sub hex {
        my ($self) = @_;
        state $x = require Math::BigInt;
        $self->new(Math::BigInt->new("0x$self->get_value"));
    }

    *from_hex = \&hex;
    *din_hex = \&hex;
    *din_hexadecimal = \&hex;

    sub oct {
        my ($self) = @_;
        state $x = require Math::BigInt;
        __PACKAGE__->new(Math::BigInt->from_oct($self->get_value));
    }

    *from_oct = \&oct;
    *din_oct = \&oct;
    *din_octal = \&oct;

    sub bin {
        my ($self) = @_;
        state $x = require Math::BigInt;
        $self->new(Math::BigInt->new("0b$self->get_value"));
    }

    *from_bin = \&bin;
    *din_bin = \&bin;
    *din_binar = \&bin;

    sub exp {
        my ($self) = @_;
        $self->new(CORE::exp($self->get_value));
    }

    sub int {
        my ($self) = @_;
        $self->new($self->get_value->as_int);
    }

    *as_int = \&int;
    *intreg = \&int;
    *ca_intreg = \&int;

    sub max {
        my ($self, $num) = @_;
        my ($x, $y) = ($self->get_value, $num->get_value);
        $self->new($x > $y ? $x : $y);
    }

    sub min {
        my ($self, $num) = @_;
        my ($x, $y) = ($self->get_value, $num->get_value);
        $self->new($x < $y ? $x : $y);
    }

    sub cos {
        my ($self) = @_;
        $self->new(CORE::cos($self->get_value));
    }

    sub sin {
        my ($self) = @_;
        $self->new(CORE::sin($self->get_value));
    }

    sub atan {
        my ($x) = @_;
        Corvinus::Types::Number::Number->new($x->get_value->copy->batan);
    }

    sub atan2 {
        my ($x, $y) = @_;
        Corvinus::Types::Number::Number->new(CORE::atan2($x->get_value, $y->get_value));
    }

    sub log {
        my ($self, $base) = @_;
        $self->new($self->get_value->copy->blog(defined($base) ? $base->get_value : ()));
    }

    sub ln {
        my ($self) = @_;
        $self->new($self->get_value->copy->blog);
    }

    sub log10 {
        my ($self) = @_;
        $self->new($self->get_value->copy->blog(10));
    }

    sub log2 {
        my ($self) = @_;
        $self->new($self->get_value->copy->blog(2));
    }

    sub inf {
        my ($self) = @_;
        $self->new(Math::BigFloat->binf);
    }

    sub neg {
        my ($self) = @_;
        $self->new($self->get_value->copy->bneg);
    }

    *neaga = \&neg;
    *negate = \&neg;
    *negat = \&neg;

    sub not {
        my ($self) = @_;
        $self->new($self->get_value->copy->bnot);
    }

    sub sign {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->get_value->sign);
    }

    *semn = \&sign;

    sub nan {
        my ($self) = @_;
        $self->new(Math::BigFloat->bnan);
    }

    *nen = \&nan;
    *NaN = \&nan;

    sub chr {
        my ($self) = @_;
        Corvinus::Types::Char::Char->new(CORE::chr $self->get_value);
    }

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << ($self->get_value->copy->blog(2)->as_int));
    }

    *npow2 = \&next_power_of_two;

    sub next_power_of {
        my ($self, $num) = @_;
        $self->new($num->get_value**($self->get_value->copy->blog($num->get_value)->as_int->binc));
    }

    *npow = \&next_power_of;

    sub is_zero {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->is_zero);
    }

    *e_zero = \&is_zero;

    sub is_nan {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->is_nan);
    }

    *is_NaN = \&is_nan;
    *nu_e_numar = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->is_pos);
    }

    *is_pos     = \&is_positive;
    *e_pozitiv = \&is_positive;

    sub is_negative {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->is_neg);
    }

    *e_negativ = \&is_negative;
    *is_neg     = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->as_int->is_even);
    }

    *e_par = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->as_int->is_odd);
    }

    *e_impar = \&is_odd;

    sub is_inf {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->is_inf);
    }

    *is_infinite = \&is_inf;
    *e_infinit = \&is_inf;

    sub is_integer {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value->is_int);
    }

    *e_intreg = \&is_integer;
    *is_int    = \&is_integer;

    sub rand {
        my ($self, $max) = @_;
        defined($max)
          ? $self->new($self->get_value + CORE::rand($max->get_value - $self->get_value))
          : $self->new(CORE::rand($self->get_value));
    }

    *aleatoriu = \&rand;

    sub ceil {
        my ($self) = @_;
        $self->new($self->get_value->copy->bceil);
    }

    *rotunjeste_sus = \&ceil;

    sub floor {
        my ($self) = @_;
        $self->new($self->get_value->copy->bfloor);
    }

    *rotunjeste_jos = \&floor;

    sub round {
        my ($self, $places) = @_;
        $self->new(
                   $self->get_value->copy->bround(
                                                  defined($places)
                                                  ? $places->get_value
                                                  : ()
                                                 )
                  );
    }

    *rotunjeste = \&round;

    sub roundf {
        my ($self, $places) = @_;
        $self->new(
                   $self->get_value->copy->bfround(
                                                   defined($places)
                                                   ? $places->get_value
                                                   : ()
                                                  )
                  );
    }

    *rotunjeste_decimal = \&roundf;
    *fround = \&roundf;

    sub length {
        my ($self) = @_;
        $self->new($self->get_value->length);
    }

    *len = \&length;
    *lungime = \&length;

    sub digit {
        my ($self, $n) = @_;
        $self->new($self->get_value->as_int->digit($n->get_value));
    }

    *cifra = \&digit;

    sub nok {
        my ($self, $k) = @_;
        $self->new($self->get_value->as_int->bnok($k->get_value));
    }

    *binomial = \&nok;

    sub of {
        my ($self, $obj) = @_;

        if ($obj->SUPER::isa('Corvinus::Types::Block::Code')) {
            return Corvinus::Types::Array::Array->new(map { $obj->run(__PACKAGE__->new($_)) } 1 .. $self->get_value);
        }

        Corvinus::Types::Array::Array->new(($obj) x $self->get_value);
    }

    *de = \&of;

    sub times {
        my ($self, $obj) = @_;
        $obj->repeat($self);
    }

    *ori = \&times;

    sub to_bin {
        my ($self) = @_;
        state $x = require Math::BigInt;
        Corvinus::Types::String::String->new(substr(Math::BigInt->new($self->get_value)->as_bin, 2));
    }

    *as_bin = \&to_bin;
    *ca_binar = \&to_bin;

    sub to_oct {
        my ($self) = @_;
        state $x = require Math::BigInt;
        Corvinus::Types::String::String->new(substr(Math::BigInt->new($self->get_value)->as_oct, 1));
    }

    *as_oct = \&to_oct;
    *ca_octal = \&to_oct;

    sub to_hex {
        my ($self) = @_;
        state $x = require Math::BigInt;
        Corvinus::Types::String::String->new(substr(Math::BigInt->new($self->get_value)->as_hex, 2));
    }

    *ca_hex = \&to_hex;
    *ca_hexadecimal = \&to_hex;
    *as_hex = \&to_hex;

    sub is_div {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($self->get_value % $num->get_value == 0);
    }

    *e_divizbil_de = \&is_div;

    sub divides {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($num->get_value % $self->get_value == 0);
    }

    *divide = \&divides;

    sub commify {
        my ($self) = @_;

        my $n = $self->get_value->bstr;
        my $x = $n;

        my $neg = $n =~ s{^-}{};
        $n =~ /\.|$/;

        if ($-[0] > 3) {

            my $l = $-[0] - 3;
            my $i = ($l - 1) % 3 + 1;

            $x = substr($n, 0, $i) . ',';

            while ($i < $l) {
                $x .= substr($n, $i, 3) . ',';
                $i += 3;
            }

            $x .= substr($n, $i);
        }

        Corvinus::Types::String::String->new(($neg ? '-' : '') . $x);
    }

    *cu_virgule = \&commify;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->get_value->bstr);
    }

    sub sstr {
        my ($self) = @_;
        Corvinus::Types::String::String->new($self->get_value->bsstr);
    }

    sub shift_right {
        my ($self, $num, $base) = @_;
        $self->new($self->get_value->copy->brsft($num->get_value, (defined($base) ? $base->get_value : ())));
    }

    *shiftRight = \&shift_right;

    sub shift_left {
        my ($self, $num, $base) = @_;
        $self->new($self->get_value->copy->blsft($num->get_value, defined($base) ? $base->get_value : ()));
    }

    *shiftLeft = \&shift_left;

    sub complex {
        my ($self, $num) = @_;
        Corvinus::Types::Number::Complex->new($self, $num);
    }

    *c = \&complex;

    sub i {
        my ($self, $num) = @_;
        Corvinus::Types::Number::Complex->new($self)->multiply(Corvinus::Types::Number::Complex->get_constant('i'));
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&multiply;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '='}   = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '..'}  = \&array_to;
        *{__PACKAGE__ . '::' . '...'} = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&to;
        *{__PACKAGE__ . '::' . '^..'} = \&downto;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
    }
};

1;
