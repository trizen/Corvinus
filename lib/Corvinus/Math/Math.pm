package Corvinus::Math::Math {

    use utf8;
    use 5.020;
    use parent qw(Corvinus);
    use experimental qw(signatures);

    sub new($) {
        state $x = do {
            require Math::BigFloat;
            Math::BigFloat->new;
        };
        bless {}, __PACKAGE__;
    }

    sub get_constant($, $name) {

        state %cache;
        state $table = {
            pi  => sub { Math::BigFloat->new('3.14159265358979323846264338327950288419716939937510582097494459') },
            e   => sub { Math::BigFloat->new('2.71828182845904523536028747135266249775724709369995957496696763') },
            phi => sub { Math::BigFloat->new('1.61803398874989484820458683436563811772030917980576286213544862') },

            sqrt2   => sub { Math::BigFloat->new('1.41421356237309504880168872420969807856967187537694807317667974') },
            sqrte   => sub { Math::BigFloat->new('1.64872127070012814684865078781416357165377610071014801157507931') },
            sqrtpi  => sub { Math::BigFloat->new('1.77245385090551602729816748334114518279754945612238712821380779') },
            sqrtphi => sub { Math::BigFloat->new('1.27201964951406896425242246173749149171560804184009624861664038') },

            ln2    => sub { Math::BigFloat->new('0.693147180559945309417232121458176568075500134360255254120680009') },
            log2e  => sub { Math::BigFloat->new('1.4426950408889634073599246810018921374266459541529859') },
            ln10   => sub { Math::BigFloat->new('2.30258509299404568401799145468436420760110148862877297603332790') },
            log10e => sub { Math::BigFloat->new('0.4342944819032518276511289189166050822943970058036665') },
                       };

        $cache{lc($name)} //= exists($table->{lc($name)}) ? Corvinus::Types::Number::Number->new($table->{lc($name)}->()) : do {
            warn qq{[WARN] Inexistent Math constant "$name"!\n};
            undef;
        };
    }

    sub e($, $places=undef) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->bexp(1, defined($places) ? $places->get_value : ()));
    }

    sub exp($, $x, $places=undef) {
        Corvinus::Types::Number::Number->new(
                                         Math::BigFloat->new($x->get_value)->bexp(defined($places) ? $places->get_value : ()));
    }

    sub pi($, $places=undef) {

        $places = defined($places) ? $places->get_value : undef;

        # For large accuracy, the arctan formulas become very inefficient with
        # Math::BigFloat.  Switch to Brent-Salamin (aka AGM or Gauss-Legendre).
        if (defined($places) and $places >= 1000) {

            # Code by Dana Jacobsen from RosettaCode
            # http://rosettacode.org/wiki/Arithmetic-geometric_mean/Calculate_Pi#Perl

            my $acc  = $places + 8;
            my $HALF = Math::BigFloat->new('0.5');

            my $an = Math::BigFloat->bone;
            my $bn = $HALF->copy->bsqrt($acc);
            my $tn = $HALF->copy->bmul($HALF);
            my $pn = Math::BigFloat->bone;

            while ($pn < $acc) {
                my $prev_an = $an->copy;
                $an->badd($bn)->bmul($HALF, $acc);
                $bn->bmul($prev_an)->bsqrt($acc);
                $prev_an->bsub($an);
                $tn->bsub($pn * $prev_an * $prev_an);
                $pn->badd($pn);
            }
            $an->badd($bn);
            $an->bmul($an, $acc)->bdiv($tn->bmul(4), $places);

            return Corvinus::Types::Number::Number->new($an);
        }

        Corvinus::Types::Number::Number->new(Math::BigFloat->bpi(defined($places) ? $places : ()));
    }

    *PI = \&pi;

    sub cos($, $x, $places=undef) {
        Corvinus::Types::Number::Number->new(
                                         Math::BigFloat->new($x->get_value)->bcos(defined($places) ? $places->get_value : ()));
    }

    sub sin($, $x, $places=undef) {
        Corvinus::Types::Number::Number->new(
                                         Math::BigFloat->new($x->get_value)->bsin(defined($places) ? $places->get_value : ()));
    }

    sub log($, $n, $base=undef) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->blog(defined($base) ? $base->get_value : ()));
    }

    sub log2($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->blog(2));
    }

    sub log10($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->blog(10));
    }

    sub npow2($, $x) {
        my $y = Math::BigFloat->new(2);
        Corvinus::Types::Number::Number->new($y->blsft(Math::BigFloat->new($x->get_value)->blog($y)->as_int));
    }

    sub npow($, $x, $y) {

        $x = Math::BigFloat->new($x->get_value);
        $y = Math::BigFloat->new($y->get_value);

        Corvinus::Types::Number::Number->new($y->bpow($x->blog($y)->as_int->binc));
    }

    sub gcd($, @list) {
        Corvinus::Types::Number::Number->new(Math::BigFloat::bgcd(map { $_->get_value } @list));
    }

    sub abs($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->babs);
    }

    sub lcm($, @list) {
        Corvinus::Types::Number::Number->new(Math::BigFloat::blcm(map { $_->get_value } @list));
    }

    sub inf($) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->binf);
    }

    sub precision($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->precision($n->get_value));
    }

    sub accuracy($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->accuracy($n->get_value));
    }

    sub ceil($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bceil);
    }

    sub floor($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bfloor);
    }

    sub sqrt($, $n) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bsqrt);
    }

    sub pow($, $n, $pow) {
        Corvinus::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bpow($pow->get_value));
    }

    sub rand($, $from=undef, $to=undef) {

        if (defined($from) and not defined($to)) {
            $to   = $from->get_value;
            $from = 0;
        }
        else {
            $from = defined($from) ? $from->get_value : 0;
            $to   = defined($to)   ? $to->get_value   : 1;
        }

        Corvinus::Types::Number::Number->new($from + CORE::rand($to - $from));
    }

    sub sum($, @nums) {
        state $x = require List::Util;
        Corvinus::Types::Number::Number->new(List::Util::sum(map { $_->get_value } @nums));
    }

    sub max($, @nums) {
        state $x = require List::Util;
        Corvinus::Types::Number::Number->new(List::Util::max(map { $_->get_value } @nums));
    }

    sub min($, @nums) {
        state $x = require List::Util;
        Corvinus::Types::Number::Number->new(List::Util::min(map { $_->get_value } @nums));
    }

    sub avg($self, @nums) {
        Corvinus::Types::Number::Number->new($self->sum(@nums)->get_value / @nums);
    }

    sub range_sum($, $from, $to, $step=1) {

        $from = $from->get_value;
        $to   = $to->get_value;
        $step = $step->get_value if ref($step);

        Corvinus::Types::Number::Number->new(($from + $to) * (($to - $from) / $step + 1) / 2);
    }

    *rangeSum = \&range_sum;

    sub map($, $value, $in_min, $in_max, $out_min, $out_max) {
        $value = $value->get_value;

        $in_min = $in_min->get_value;
        $in_max = $in_max->get_value;

        $out_min = $out_min->get_value;
        $out_max = $out_max->get_value;

        Corvinus::Types::Number::Number->new(($value - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min);
    }

    sub map_range($, $amount, $from, $to) {

        $amount = $amount->get_value;
        $from   = $from->get_value;
        $to     = $to->get_value;

        Corvinus::Types::Array::RangeNumber->new(
                                              from => $from,
                                              to   => $to,
                                              step => ($to - $from) / $amount,
                                             );
    }

    sub number_to_percentage($, $num, $from, $to) {

        $num  = $num->get_value;
        $to   = $to->get_value;
        $from = $from->get_value;

        my $sum  = CORE::abs($to - $from);
        my $dist = CORE::abs($num - $to);

        Corvinus::Types::Number::Number->new(($sum - $dist) / $sum * 100);
    }

    *num2percent = \&number_to_percentage;

    {
        no strict 'refs';
        foreach my $f (

            # (Plane, 2-dimensional) angles may be converted with the following functions.
            'rad2rad',
            'deg2deg',
            'grad2grad',
            'rad2deg',
            'deg2rad',
            'grad2deg',
            'deg2grad',
            'rad2grad',
            'grad2rad',

            # The tangent
            'tan',

            # The cofunctions of the sine, cosine,
            # and tangent (cosec/csc and cotan/cot are aliases)
            'csc',
            'cosec',
            'sec',
            'cot',
            'cotan',

            # The arcus (also known as the inverse) functions
            # of the sine, cosine, and tangent
            'asin',
            'acos',
            'atan',

            # The principal value of the arc tangent of y/x
            'atan2',

            #  The arcus cofunctions of the sine, cosine, and tangent (acosec/acsc and
            # acotan/acot are aliases).  Note that atan2(0, 0) is not well-defined.
            'acsc',
            'acosec',
            'asec',
            'acot',
            'acotan',

            # The hyperbolic sine, cosine, and tangent
            'sinh',
            'cosh',
            'tanh',

            # The cofunctions of the hyperbolic sine, cosine, and tangent
            # (cosech/csch and cotanh/coth are aliases)
            'csch',
            'cosech',
            'sech',
            'coth',
            'cotanh',

            # The area (also known as the inverse) functions of the hyperbolic sine,
            # cosine, and tangent
            'asinh',
            'acosh',
            'atanh',

            # The area cofunctions of the hyperbolic sine, cosine, and tangent
            # (acsch/acosech and acoth/acotanh are aliases)
            'acsch',
            'acosech',
            'asech',
            'acoth',
            'acotanh',

          ) {
            *{__PACKAGE__ . '::' . $f} = sub($, @rest) {
                state $x = require Math::Trig;
                local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
                my $result = (\&{'Math::Trig::' . $f})->(map { $_->get_value } @rest);
                (
                 ref($result) eq 'Math::Complex'
                 ? 'Corvinus::Types::Number::Complex'
                 : 'Corvinus::Types::Number::Number'
                )->new($result);
            };
        }
    }

};

1
