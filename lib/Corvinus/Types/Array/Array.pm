package Corvinus::Types::Array::Array {

    use utf8;
    use 5.014;

    use parent qw(
      Corvinus::Object::Object
      );

    use overload
      q{""}   => \&dump,
      q{bool} => sub { scalar(@{$_[0]}) };

    sub new {
        my (undef, @items) = @_;
        bless [map { Corvinus::Variable::Variable->new(name => '', type => 'var', value => $_) } @items], __PACKAGE__;
    }

    *call = \&new;
    *nou = \&new;
    *noua = \&new;

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;

            if (index(ref($item), 'Corvinus::') == 0) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    sub unroll_operator {
        my ($self, $operator, $arg) = @_;

        if (ref $operator) {
            $operator = $operator->get_value;
        }

        my @array;
        if (defined $arg) {
            my $argc  = @{$arg};
            my $selfc = @{$self};
            my $max   = $argc > $selfc ? $argc - 1 : $selfc - 1;
            foreach my $i (0 .. $max) {
                push @array, $self->[$i % $selfc]->get_value->$operator($arg->[$i % $argc]->get_value);
            }
        }
        else {
            foreach my $i (0 .. $#{$self}) {
                push @array, $self->[$i]->get_value->$operator;
            }
        }

        $self->new(@array);
    }

    sub map_operator {
        my ($self, $operator, @args) = @_;

        if (ref $operator) {
            $operator = $operator->get_value;
        }

        my @array;
        foreach my $i (0 .. $#{$self}) {
            push @array, $self->[$i]->get_value->$operator(@args);
        }

        $self->new(@array);
    }

    sub pam_operator {
        my ($self, $operator, $arg) = @_;

        if (ref $operator) {
            $operator = $operator->get_value;
        }

        my @array;
        foreach my $i (0 .. $#{$self}) {
            push @array, $arg->$operator($self->[$i]->get_value);
        }

        $self->new(@array);
    }

    sub reduce_operator {
        my ($self, $operator) = @_;

        if (ref $operator) {
            $operator = $operator->get_value;
        }

        (my $offset = $#{$self}) >= 0 || return;

        my $x = $self->[0]->get_value;
        foreach my $i (1 .. $offset) {
            $x = ($x->$operator($self->[$i]->get_value));
        }
        $x;
    }

    sub _grep {
        my ($self, $array, $bool) = @_;

        my @new_array;
        foreach my $item (@{$self}) {

            my $exists = 0;
            my $value  = $item->get_value;

            if ($array->contains($value)) {
                $exists = 1;
            }

            push(@new_array, $value) if ($exists - $bool);
        }

        $self->new(@new_array);
    }

    sub multiply {
        my ($self, $num) = @_;
        $self->new((map { $_->get_value } @{$self}) x $num->get_value);
    }

    sub divide {
        my ($self, $num) = @_;

        my @obj = map { $_->get_value } @{$self};

        my @array;
        my $len = @obj / $num->get_value;

        my $i   = 1;
        my $pos = $len;
        while (@obj) {
            my $j = $pos - $i * int($len);
            $pos -= $j if $j >= 1;
            push @array, $self->new(splice @obj, 0, $len + $j);
            $pos += $len;
            $i++;
        }

        $self->new(@array);
    }

    *div = \&divide;

    sub or {
        my ($self, $array) = @_;
        my $new_array = $self->new;

        $self->xor($array)->concat($self->and($array));
    }

    sub xor {
        my ($self, $array) = @_;
        my $new_array = $self->new;

        ($self->concat($array))->subtract($self->and($array));
    }

    sub and {
        my ($self, $array) = @_;
        $self->_grep($array, 0);
    }

    sub is_empty {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($#{$self} == -1);
    }

    *isEmpty = \&is_empty;

    sub subtract {
        my ($self, $array) = @_;
        $self->_grep($array, 1);
    }

    sub concat {
        my ($self, $arg) = @_;

        defined($arg) && $arg->isa('ARRAY')
          ? $self->new(map { $_->get_value } @{$self}, @{$arg})
          : $self->new((map { $_->get_value } @{$self}), $arg);
    }

    sub levenshtein {
        my ($self, $arg) = @_;

        my @s = map { $_->get_value } @{$self};
        my @t = map { $_->get_value } @{$arg};

        my $len1 = scalar(@s);
        my $len2 = scalar(@t);

        state $eq = '==';
        state $x  = require List::Util;

        my @d = ([0 .. $len2], map { [$_] } 1 .. $len1);
        foreach my $i (1 .. $len1) {
            foreach my $j (1 .. $len2) {
                $d[$i][$j] =
                    $s[$i - 1]->$eq($t[$j - 1])
                  ? $d[$i - 1][$j - 1]
                  : List::Util::min($d[$i - 1][$j], $d[$i][$j - 1], $d[$i - 1][$j - 1]) + 1;
            }
        }

        Corvinus::Types::Number::Number->new($d[-1][-1]);
    }

    *lev   = \&levenshtein;
    *leven = \&levenshtein;

    sub _combinations {
        my ($n, @set) = @_;

        @set || return;
        $n == 1 && return map { [$_] } @set;

        my $head = shift @set;
        my @result = _combinations($n - 1, @set);
        foreach my $subarray (@result) {
            unshift @{$subarray}, $head;
        }
        @result, _combinations($n, @set);
    }

    sub combinations {
        my ($self, $n) = @_;

        Corvinus::Types::Array::Array->new(
            map {
                Corvinus::Types::Array::Array->new(map { $_->get_value } @{$_})
              } _combinations($n->get_value, @{$self})
        );
    }
    *combination = \&combinations;

    sub count {
        my ($self, $obj) = @_;

        my $counter = 0;
        if ($obj->SUPER::isa('Corvinus::Types::Block::Code')) {

            foreach my $item (@{$self}) {
                if ($obj->run($item->get_value)) {
                    ++$counter;
                }
            }

            return Corvinus::Types::Number::Number->new($counter);
        }

        state $eq = '==';
        foreach my $item (@{$self}) {
            my $value = $item->get_value;
            if (ref($value) eq ref($obj)) {
                $value->$eq($obj) && $counter++;
            }
        }

        Corvinus::Types::Number::Number->new($counter);
    }

    *countObj  = \&count;
    *count_obj = \&count;

    sub equals {
        my ($self, $array) = @_;

        if (not defined $array or not $array->isa('ARRAY') or $#{$self} != $#{$array}) {
            return Corvinus::Types::Bool::Bool->false;
        }

        state $eq = '==';
        foreach my $i (0 .. $#{$self}) {
            my ($x, $y) = ($self->[$i]->get_value, $array->[$i]->get_value);
            if (not $x->$eq($y)) {
                return Corvinus::Types::Bool::Bool->false;
            }
        }

        return Corvinus::Types::Bool::Bool->true;
    }

    *is = \&equals;
    *eq = \&equals;

    sub ne {
        my ($self, $array) = @_;
        $self->equals($array)->not;
    }

    sub mesh {
        my ($self, $array) = @_;

        my $min = $#{$self} > $#{$array} ? $#{$array} : $#{$self};

        my @new_array;
        foreach my $i (0 .. $min) {
            push @new_array, $self->[$i]->get_value, $array->[$i]->get_value;
        }

        if ($#{$self} > $#{$array}) {
            foreach my $i ($min + 1 .. $#{$self}) {
                push @new_array, $self->[$i]->get_value;
            }
        }
        else {
            foreach my $i ($min + 1 .. $#{$array}) {
                push @new_array, $array->[$i]->get_value;
            }
        }

        $self->new(@new_array);
    }

    *zip = \&mesh;

    sub make {
        my ($self, $size, $type) = @_;
        $self->new(($type) x $size->get_value);
    }

    sub _min_max {
        my ($self, $method) = @_;

        $#{$self} > -1 or return;

        my $max_item = $self->[0]->get_value;

        foreach my $i (1 .. $#{$self}) {
            my $val = $self->[$i]->get_value;
            $max_item = $val if $val->$method($max_item);
        }

        return $max_item;
    }

    sub max {
        $_[0]->_min_max('>');
    }

    sub min {
        $_[0]->_min_max('<');
    }

    sub minmax {
        my ($self) = @_;
        Corvinus::Types::Array::List->new($self->min, $self->max);
    }

    sub sum {
        $_[0]->reduce_operator('+');
    }

    *collapse = \&sum;

    sub prod {
        $_[0]->reduce_operator('*');
    }

    *product = \&prod;

    sub max_by {
        my ($self, $code) = @_;

        my $max;
        my $min = Corvinus::Types::Number::Number->new->inf->neg;

        foreach my $item (@{$self}) {
            my $result = $code->run($item->get_value);

            if ($result->gt($min)) {
                $max = $item->get_value;
                $min = $result;
            }
        }

        $max;
    }

    *maxBy = \&max_by;

    sub min_by {
        my ($self, $code) = @_;

        my $min;
        my $max = Corvinus::Types::Number::Number->new->inf;

        foreach my $item (@{$self}) {
            my $result = $code->run($item->get_value);

            if ($result->lt($max)) {
                $min = $item->get_value;
                $max = $result;
            }
        }

        $min;
    }

    *minBy = \&min_by;

    sub last {
        my ($self, $arg) = @_;

        if (defined $arg) {
            my $from = @{$self} - $arg->get_value;
            return $self->new(map { $_->get_value } @{$self}[($from < 0 ? 0 : $from) .. $#{$self}]);
        }

        $#{$self} == -1 ? () : $self->[-1]->get_value;
    }

    sub swap {
        my ($self, $i, $j) = @_;
        @{$self}[$i, $j] = @{$self}[$j, $i];
        $self;
    }

    sub first {
        my ($self, $arg) = @_;

        if (defined $arg) {
            if ($arg->SUPER::isa('Corvinus::Types::Block::Code')) {
                return return $self->find($arg);
            }

            return $self->new(map { $_->get_value } @{$self}[0 .. $arg->get_value - 1]);
        }

        $#{$self} == -1 ? () : $self->[0]->get_value;
    }

    sub _flatten {    # this exists for performance reasons
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;
            push @array, ref($item) eq ref($self) ? $item->_flatten : $item;
        }

        @array;
    }

    sub flatten {
        my ($self) = @_;

        my @new_array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;
            push @new_array, ref($item) eq ref($self) ? ($item->_flatten) : $item;
        }

        $self->new(@new_array);
    }

    sub exists {
        my ($self, $index) = @_;
        Corvinus::Types::Bool::Bool->new(exists $self->[$index->get_value]);
    }

    *existsIndex = \&exists;

    sub defined {
        my ($self, $index) = @_;
        Corvinus::Types::Bool::Bool->new(defined($self->[$index->get_value]) and $self->[$index->get_value]->_is_defined);
    }

    sub get {
        my ($self, @indices) = @_;

        if (@indices > 1) {
            return Corvinus::Types::Array::List->new(map { exists($self->[$_]) ? $self->[$_]->get_value : undef } @indices);
        }

        @indices && exists($self->[$indices[0]]) ? $self->[$indices[0]]->get_value : ();
    }

    *item = \&get;

    sub _slice {
        my ($self, $from, $to) = @_;

        my $max = $#{$self};

        $from = defined($from) ? ($from->get_value) : 0;
        $to   = defined($to)   ? ($to->get_value)   : $max;

        if ($from < 0) {
            $from = $max + $from + 1;
        }

        if ($to < 0) {
            $to = $max + $to + 1;
        }

        if (abs($from) > $max) {
            return;
        }

        if ($to > $max) {
            $to = $max;
        }

        @{$self}[$from .. $to];
    }

    sub slice {
        my ($self) = @_;
        my @items  = _slice(@_);
        my $array  = $self->new;
        push @{$array}, @items if @items;
        $array;
    }

    sub ft {
        my ($self) = @_;
        $self->new(map { $_->get_value } _slice(@_));
    }

    *fromTo  = \&ft;
    *from_to = \&ft;

    sub each {
        my ($self, $code) = @_;

        foreach my $item (@{$self}) {
            if (defined(my $res = $code->_run_code($item->get_value))) {
                return $res;
            }
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub each_index {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            if (defined(my $res = $code->_run_code(Corvinus::Types::Number::Number->new($i)))) {
                return $res;
            }
        }

        $self;
    }

    sub each_with_index {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            if (defined(my $res = $code->_run_code(Corvinus::Types::Number::Number->new($i), $self->[$i]->get_value))) {
                return $res;
            }
        }

        $self;
    }

    sub map {
        my ($self, $code) = @_;
        $self->new(map { $code->run($_->get_value) } @{$self});
    }

    *collect = \&map;

    sub grep {
        my ($self, $code) = @_;
        $self->new(grep { $code->run($_) } map { $_->get_value } @{$self});
    }

    *filter = \&grep;
    *select = \&grep;

    sub group_by {
        my ($self, $code) = @_;

        my $hash = Corvinus::Types::Hash::Hash->new;
        foreach my $item (@{$self}) {
            my $key = $code->run(my $val = $item->get_value);
            exists($hash->{data}{$key}) || $hash->append($key, Corvinus::Types::Array::Array->new);
            $hash->{data}{$key}->get_value->append($val);
        }

        $hash;
    }

    *groupBy = \&group_by;

    sub find {
        my ($self, $code) = @_;
        foreach my $var (@{$self}) {
            my $val = $var->get_value;
            return $val if $code->run($val);
        }

        return;
    }

    sub any {
        my ($self, $code) = @_;

        foreach my $var (@{$self}) {
            if ($code->run($var->get_value)) {
                return Corvinus::Types::Bool::Bool->true;
            }
        }

        Corvinus::Types::Bool::Bool->false;
    }

    sub all {
        my ($self, $code) = @_;

        $#{$self} == -1
          && return Corvinus::Types::Bool::Bool->false;

        foreach my $var (@{$self}) {
            if (not $code->run($var->get_value)) {
                return Corvinus::Types::Bool::Bool->false;
            }
        }

        Corvinus::Types::Bool::Bool->true;
    }

    sub assign_to {
        my ($self, @vars) = @_;

        for my $i (0 .. $#vars) {

            if (exists $self->[$i]) {
                $vars[$i]->get_var->set_value($self->[$i]->get_value);
            }
        }

        $self;
    }

    *unroll_to = \&assign_to;
    *unrollTo  = \&assign_to;
    *assignTo  = \&assign_to;

    sub index {
        my ($self, $obj) = @_;

        state $method = '=';
        foreach my $i (0 .. $#{$self}) {
            $self->[$i]->get_value->$method($obj)
              && return Corvinus::Types::Number::Number->new($i);
        }

        Corvinus::Types::Number::Number->new(-1);
    }

    sub rindex {
        my ($self, $obj) = @_;

        state $method = '=';
        for (my $i = $#{$self} ; $i >= 0 ; $i--) {
            $self->[$i]->get_value->$method($obj)
              && return Corvinus::Types::Number::Number->new($i);
        }

        Corvinus::Types::Number::Number->new(-1);
    }

    sub first_index {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            $code->run($self->[$i]->get_value)
              && return Corvinus::Types::Number::Number->new($i);
        }

        Corvinus::Types::Number::Number->new(-1);
    }

    *indexWhere = \&first_index;
    *firstIndex = \&first_index;

    sub last_index {
        my ($self, $code) = @_;

        for (my $i = $#{$self} ; $i >= 0 ; $i--) {
            $code->run($self->[$i]->get_value)
              && return Corvinus::Types::Number::Number->new($i);
        }

        Corvinus::Types::Number::Number->new(-1);
    }

    *lastIndexWhere = \&last_index;
    *lastIndex      = \&last_index;

    sub reduce_pairs {
        my ($self, $obj) = @_;

        (my $offset = $#{$self}) == -1
          && return $self->new;

        my @array;
        if ($obj->SUPER::isa('Corvinus::Types::Block::Code')) {
            for (my $i = 1 ; $i <= $offset ; $i += 2) {
                push @array, $obj->run($self->[$i - 1]->get_value, $self->[$i]->get_value);
            }
        }
        else {
            my $method = $obj->get_value;
            for (my $i = 1 ; $i <= $offset ; $i += 2) {
                my $x = $self->[$i - 1]->get_value;
                push @array, $x->$method($self->[$i]->get_value);
            }
        }

        $self->new(@array);
    }

    *reducePairs = \&reduce_pairs;

    sub shuffle {
        my ($self) = @_;
        state $x = require List::Util;
        $self->new(map { $_->get_value } List::Util::shuffle(@{$self}));
    }

    sub best_shuffle {
        my ($s) = @_;
        my ($t) = $s->shuffle;

        my $not_equals = '!=';
        foreach my $i (0 .. $#{$s}) {
            foreach my $j (0 .. $#{$s}) {
                     $i != $j
                  && $t->[$i]->get_value->$not_equals($s->[$j]->get_value)
                  && $t->[$j]->get_value->$not_equals($s->[$i]->get_value)
                  && do {
                    @{$t}[$i, $j] = @{$t}[$j, $i];
                    last;
                  }
            }
        }

        $t;
    }

    *bshuffle    = \&best_shuffle;
    *bestShuffle = \&best_shuffle;

    sub pair_with {
        my ($self, @args) = @_;
        Corvinus::Types::Array::MultiArray->new($self, @args);
    }

    *pairWith = \&pair_with;

    sub reduce {
        my ($self, $obj) = @_;

        if ($obj->SUPER::isa('Corvinus::Types::Block::Code')) {
            (my $offset = $#{$self}) >= 0 || return;

            my $x = $self->[0]->get_value;
            foreach my $i (1 .. $offset) {
                $x = $obj->run($x, $self->[$i]->get_value);
            }

            return $x;
        }

        $self->reduce_operator($obj->get_value);
    }

    *inject = \&reduce;

    sub length {
        my ($self) = @_;
        Corvinus::Types::Number::Number->new(scalar @{$self});
    }

    *len  = \&length;    # alias
    *size = \&length;

    sub offset {
        my ($self) = @_;
        Corvinus::Types::Number::Number->new($#{$self});
    }

    *end = \&offset;

    sub resize {
        my ($self, $num) = @_;
        $#{$self} = $num->get_value;
        $num;
    }

    *resizeTo  = \&resize;
    *resize_to = \&resize;

    sub rand {
        my ($self, $amount) = @_;
        if (defined $amount) {
            return $self->new(map { $self->[CORE::rand($#{$self} + 1)]->get_value } 1 .. $amount);
        }
        $self->[CORE::rand($#{$self} + 1)];
    }

    *pick   = \&rand;
    *sample = \&rand;

    sub range {
        my ($self) = @_;
        Corvinus::Types::Array::RangeNumber->new(from => 0, to => $#{$self}, step => 1);
    }

    sub pairs {
        my ($self) = @_;
        __PACKAGE__->new(map { Corvinus::Types::Array::Pair->new(Corvinus::Types::Number::Number->new($_), $self->[$_]->get_value) }
                         0 .. $#{$self});
    }

    sub insert {
        my ($self, $index, @objects) = @_;
        splice(@{$self}, $index->get_value, 0, @{__PACKAGE__->new(@objects)});
        $self;
    }

    sub _unique {
        my ($self, $last) = @_;

        state $method = '==';

        my %indices;
        my $max = $#{$self};

        for (my $i = 0 ; $i <= ($max - 1) ; $i++) {
            for (my $j = $i + 1 ; $j <= $max ; $j++) {
                my $diff = ($#{$self} - $max);
                my ($x, $y) = ($self->[$i + $diff]->get_value, $self->[$j + $diff]->get_value);

                if (ref($x) eq ref($y)
                    and $x->$method($y)) {

                    undef $indices{$last ? ($i + $diff) : ($j + $diff)};

                    --$max;
                    --$j;
                    --$i;
                }
            }
        }

        $self->new(map  { $self->[$_]->get_value }
                   grep { not exists $indices{$_} } 0 .. $#{$self});
    }

    sub unique {
        my ($self) = @_;
        $self->_unique(0);
    }

    *uniq     = \&unique;
    *distinct = \&unique;

    sub last_unique {
        my ($self) = @_;
        $self->_unique(1);
    }

    *last_uniq  = \&last_unique;
    *lastUniq   = \&last_unique;
    *lastUnique = \&last_unique;

    sub abbrev {
        my ($self, $code) = @_;

        my $__END__ = {};                                                                  # some unique value
        my $__CALL__ = defined($code) && $code->SUPER::isa('Corvinus::Types::Block::Code');

        my %table;
        foreach my $sub_array (map { $_->get_value } @{$self}) {
            my $ref = \%table;

            foreach my $item (@{$sub_array}) {
                $ref = $ref->{$item->get_value} //= {};
            }
            $ref->{$__END__} = $sub_array;
        }

        my $abbrevs = $__CALL__ ? undef : $self->new();
        my $callback = sub {
            $abbrevs->append($self->new(map { $_->get_value } @_));
        };

        my $traverse;
        (
         $traverse = sub {
             my ($hash) = @_;

             foreach my $key (my @keys = sort keys %{$hash}) {
                 next if $key eq $__END__;
                 $traverse->($hash->{$key});

                 if ($#keys > 0) {
                     my $count = 0;
                     my $ref   = delete $hash->{$key};
                     while (my ($key) = CORE::each %{$ref}) {
                         if ($key eq $__END__) {

                             if ($__CALL__) {
                                 $code->run($self->new(map { $_->get_value } @{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]));
                             }
                             else {
                                 $callback->(@{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]);
                             }

                             last;
                         }
                         $ref = $ref->{$key};
                         $count++;
                     }
                 }
             }
         }
        )->(\%table);

        $abbrevs;
    }

    *abbreviations = \&abbrev;

    sub contains {
        my ($self, $obj) = @_;

        if ($obj->SUPER::isa('Corvinus::Types::Block::Code')) {
            foreach my $item (@{$self}) {
                if ($obj->run($item->get_value)) {
                    return Corvinus::Types::Bool::Bool->true;
                }
            }

            return Corvinus::Types::Bool::Bool->false;
        }

        state $method = '==';
        foreach my $var (@{$self}) {
            my $item = $var->get_value;
            if (ref($item) eq ref($obj)
                and $item->$method($obj)) {
                return Corvinus::Types::Bool::Bool->true;
            }
        }

        Corvinus::Types::Bool::Bool->false;
    }

    sub contains_type {
        my ($self, $obj) = @_;

        foreach my $item (@{$self}) {
            if (ref($item->get_value) eq ref($obj)) {
                return Corvinus::Types::Bool::Bool->true;
            }
        }

        return Corvinus::Types::Bool::Bool->false;
    }

    *containsType = \&contains_type;

    sub contains_any {
        my ($self, $array) = @_;

        foreach my $item (@{$array}) {
            return Corvinus::Types::Bool::Bool->true if $self->contains($item->get_value);
        }

        Corvinus::Types::Bool::Bool->false;
    }

    *containsAny = \&contains_any;

    sub contains_all {
        my ($self, $array) = @_;

        foreach my $item (@{$array}) {
            return Corvinus::Types::Bool::Bool->false unless $self->contains($item->get_value);
        }

        Corvinus::Types::Bool::Bool->true;
    }

    *containsAll = \&contains_all;

    sub shift {
        my ($self, $num) = @_;

        if (defined $num) {
            return $self->new(map { $_->get_value } CORE::splice(@{$self}, 0, $num->get_value));
        }

        $#{$self} > -1 || return;
        shift(@{$self})->get_value;
    }

    *dropFirst  = \&shift;
    *drop_first = \&shift;
    *dropLeft   = \&shift;
    *drop_left  = \&shift;

    sub pop {
        my ($self, $num) = @_;

        if (defined $num) {
            $num = $num->get_value > $#{$self} ? 0 : @{$self} - $num->get_value;
            return $self->new(map { $_->get_value } CORE::splice(@{$self}, $num));
        }

        $#{$self} > -1 || return;
        pop(@{$self})->get_value;
    }

    *drop_last  = \&pop;
    *dropLast   = \&pop;
    *drop_right = \&pop;
    *dropRight  = \&pop;

    sub pop_rand {
        my ($self) = @_;
        $#{$self} > -1 || return;
        CORE::splice(@{$self}, CORE::rand($#{$self} + 1), 1)->get_value;
    }

    *popRand = \&pop_rand;

    sub delete_index {
        my ($self, $offset) = @_;
        CORE::splice(@{$self}, $offset->get_value, 1)->get_value;
    }

    *pop_at      = \&delete_index;
    *deleteIndex = \&delete_index;
    *popAt       = \&delete_index;

    sub splice {
        my ($self, $offset, $length, @objects) = @_;

        $offset = defined($offset) ? $offset->get_value : 0;
        $length = defined($length) ? $length->get_value : scalar(@{$self});

        if (@objects) {
            return $self->new(map { $_->get_value } CORE::splice(@{$self}, $offset, $length, @{__PACKAGE__->new(@objects)}));
        }

        $self->new(map { $_->get_value } CORE::splice(@{$self}, $offset, $length));
    }

    sub takeRight {
        my ($self, $amount) = @_;

        my $offset = $#{$self};
        $amount = $offset > ($amount->get_value - 1) ? $amount->get_value - 1 : $offset;
        $self->new(map { $_->get_value } @{$self}[$offset - $amount .. $offset]);
    }

    *take_right = \&takeRight;

    sub takeLeft {
        my ($self, $amount) = @_;

        $amount = $#{$self} > ($amount->get_value - 1) ? $amount->get_value - 1 : $#{$self};
        $self->new(map { $_->get_value } @{$self}[0 .. $amount]);
    }

    *take_left = \&takeLeft;

    sub sort {
        my ($self, $code) = @_;

        if (defined $code) {
            return
              $self->new(sort { $code->run($a, $b) }
                         map { $_->get_value } @{$self});
        }

        state $method = '<=>';
        $self->new(sort { $a->$method($b) } map { $_->get_value } @{$self});
    }

    # Insert an object between each element
    sub join_insert {
        my ($self, $delim_obj) = @_;

        $#{$self} > -1 || return $self->new;

        my @array = $self->[0]->get_value;
        foreach my $i (1 .. $#{$self}) {
            push @array, $delim_obj, $self->[$i]->get_value;
        }
        $self->new(@array);
    }

    *joinInsert = \&join_insert;

    sub permute {
        my ($self, $code) = @_;

        $#{$self} == -1 && return $self;
        my @idx = 0 .. $#{$self};

        if (defined($code)) {
            while (1) {
                if (defined(my $res = $code->_run_code($self->new(map { $_->get_value } @{$self}[@idx])))) {
                    return $res;
                }

                my $p = $#idx;
                --$p while $idx[$p - 1] > $idx[$p];
                my $q = $p or (return $self);
                push @idx, CORE::reverse CORE::splice @idx, $p;
                ++$q while $idx[$p - 1] > $idx[$q];
                @idx[$p - 1, $q] = @idx[$q, $p - 1];
            }
        }

        my @array;
        while (1) {
            push @array, $self->new(map { $_->get_value } @{$self}[@idx]);
            my $p = $#idx;
            --$p while $idx[$p - 1] > $idx[$p];
            my $q = $p or (return $self->new(@array));
            push @idx, CORE::reverse CORE::splice @idx, $p;
            ++$q while $idx[$p - 1] > $idx[$q];
            @idx[$p - 1, $q] = @idx[$q, $p - 1];
        }
    }

    *permutations = \&permute;

    sub pack {
        my ($self, $format) = @_;
        Corvinus::Types::String::String->new(CORE::pack($format->get_value, map { $_->get_value } @{$self}));
    }

    sub push {
        my ($self, @args) = @_;
        push @{$self}, @{$self->new(@args)};
        $self;
    }

    *append = \&push;

    sub unshift {
        my ($self, @args) = @_;
        unshift @{$self}, @{$self->new(@args)};
        $self;
    }

    *prepend = \&unshift;

    sub rotate {
        my ($self, $num) = @_;

        my $array = $self->new(map { $_->get_value } @{$self});
        if ($num->get_value < 0) {
            CORE::unshift(@{$array}, CORE::pop(@{$array})) for 1 .. abs($num->get_value);
        }
        else {
            CORE::push(@{$array}, CORE::shift(@{$array})) for 1 .. $num->get_value;
        }

        $array;
    }

    # Join the array as string
    sub join {
        my ($self, $delim, $block) = @_;
        $delim = defined($delim) ? $delim->get_value : '';

        if (defined $block) {
            return Corvinus::Types::String::String->new(CORE::join($delim, map { $block->run($_->get_value); } @{$self}));
        }

        Corvinus::Types::String::String->new(CORE::join($delim, map { $_->get_value } @{$self}));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(reverse map { $_->get_value } @{$self});
    }

    *reversed = \&reverse;    # alias

    sub to_hash {
        my ($self) = @_;
        Corvinus::Types::Hash::Hash->new(map { $_->get_value } @{$self});
    }

    *toHash = \&to_hash;
    *to_h   = \&to_hash;

    sub copy {
        my ($self) = @_;

        state $x = require Storable;
        Storable::dclone($self);
    }

    sub delete_first {
        my ($self, $obj) = @_;

        my $method = '==';
        foreach my $i (0 .. $#{$self}) {
            my $var  = $self->[$i];
            my $item = $var->get_value;
            if (ref($item) eq ref($obj)
                and $item->$method($obj)) {
                CORE::splice(@{$self}, $i, 1);
                return Corvinus::Types::Bool::Bool->true;
            }
        }

        Corvinus::Types::Bool::Bool->false;
    }

    *remove_first = \&delete_first;
    *removeFirst  = \&delete_first;
    *deleteFirst  = \&delete_first;

    sub delete {
        my ($self, $obj) = @_;

        my $method = '==';
        for (my $i = 0 ; $i <= $#{$self} ; $i++) {
            my $item = $self->[$i]->get_value;
            if (ref($item) eq ref($obj)
                and $item->$method($obj)) {
                CORE::splice(@{$self}, $i--, 1);
            }
        }

        $self;
    }

    *remove = \&delete;

    sub delete_if {
        my ($self, $code) = @_;

        for (my $i = 0 ; $i <= $#{$self} ; $i++) {
            $code->run($self->[$i]->get_value) && CORE::splice(@{$self}, $i--, 1);
        }

        $self;
    }

    *remove_if = \&delete_if;
    *removeIf  = \&delete_if;
    *deleteIf  = \&delete_if;

    sub delete_first_if {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i];
            $code->run($item->get_value) && do {
                CORE::splice(@{$self}, $i, 1);
                return Corvinus::Types::Bool::Bool->true;
            };
        }

        Corvinus::Types::Bool::Bool->false;
    }

    *remove_first_if = \&delete_first_if;
    *removeFirstIf   = \&delete_first_if;
    *deleteFirstIf   = \&delete_first_if;

    sub to_list {
        Corvinus::Types::Array::List->new(map { $_->get_value } @{$_[0]});
    }

    sub dump {
        my ($self) = @_;

        Corvinus::Types::String::String->new(
            '[' . CORE::join(
                ', ',
                map {
                    my $item = defined($self->[$_]) ? $self->[$_]->get_value : 'nil';
                    ref($item) && defined(eval { $item->can('dump') }) ? $item->dump() : $item;
                  } 0 .. $#{$self}
              )
              . ']'
        );
    }

    sub to_s {
        my ($self) = @_;
        Corvinus::Types::String::String->new(CORE::join(' ', map { $_->get_value } @{$self}));
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '*'}   = \&multiply;
        *{__PACKAGE__ . '::' . '<<'}  = \&dropLeft;
        *{__PACKAGE__ . '::' . '>>'}  = \&dropRight;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '=='}  = \&equals;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '/'}   = \&divide;
        *{__PACKAGE__ . '::' . '»'}  = \&assign_to;
        *{__PACKAGE__ . '::' . '«'}  = \&append;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $obj) = @_;
            $self->push($obj);
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            $self->pop;
            $self;
        };

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $arg) = @_;

            if ($arg->isa('ARRAY')) {
                my @values = map { $_->get_value } @{$arg};

                foreach my $i (0 .. $#{$self}) {
                    $self->[$i]->set_value(
                                           exists $values[$i]
                                           ? $values[$i]
                                           : Corvinus::Types::Nil::Nil->new
                                          );
                }
            }
            else {
                map { $_->set_value($arg) } @{$self};
            }

            $self;
        };

        *{__PACKAGE__ . '::' . '+='} = sub {
            my ($self, $arg) = @_;

            if ($arg->isa('ARRAY')) {
                my @values = map { $_->get_value } @{$arg};

                foreach my $i (0 .. $#{$self}) {
                    my $value = $self->[$i]->get_value;
                    ref($value) eq ref($self) || do {
                        $self->[$i]->set_value(
                                               $self->new(
                                                          ref($value) eq 'Corvinus::Types::Nil::Nil'
                                                          ? ()
                                                          : $value
                                                         )
                                              );
                    };
                    $self->[$i]->get_value->append(
                                                   exists $values[$i]
                                                   ? $values[$i]
                                                   : Corvinus::Types::Nil::Nil->new
                                                  );
                }
            }
            else {
                map {
                    my $value = $_->get_value;
                    ref($value) eq ref($self) || do {
                        $_->set_value(
                                      $self->new(
                                                 ref($value) eq 'Corvinus::Types::Nil::Nil'
                                                 ? ()
                                                 : $value
                                                )
                                     );
                    };
                    $_->get_value->append($arg)
                } @{$self};
            }

            $self;
        };
    }

};

1
