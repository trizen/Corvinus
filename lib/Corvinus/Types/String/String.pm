package Corvinus::Types::String::String {

    use utf8;
    use 5.020;
    use experimental qw(signatures);

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload
      q{bool} => \&get_value,
      q{""}   => \&get_value;

    sub new {
        my (undef, $str) = @_;
        if (@_ > 2) {
            $str = CORE::join('', map { ref($_) ? $_->to_s->get_value : $_ } @_[1 .. $#_]);
        }
        elsif (ref $str) {
            return $str->to_s;
        }
        $str //= '';
        bless \$str, __PACKAGE__;
    }

    *call = \&new;
    *nou = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub to_s {
        $_[0];
    }

    sub unroll_operator {
        my ($self, $operator, $arg) = @_;
        $self->to_chars->unroll_operator(

            # The operator, followed by...
            $operator,

            # ...an optional argument
            defined($arg)
            ? $arg->to_chars
            : ()

        )->join;
    }

    sub reduce_operator($self, $operator) {
        Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(//, $self->get_value))->reduce_operator($operator);
    }

    sub inc($self) {
        my $copy = $self->get_value;
        $self->new(++$copy);
    }

    *incrementeaza = \&inc;

    sub div($self, $num) {
        (my $strlen = int(length($self->get_value) / $num->get_value)) < 1 && return;
        Corvinus::Types::Array::Array->new(map { $self->new($_) } unpack "(a$strlen)*", $self->get_value);
    }

    *divide = \&div;

    sub lt($self, $string) {
        Corvinus::Types::Bool::Bool->new($self->get_value lt $string->get_value);
    }

    sub gt($self, $string) {
        Corvinus::Types::Bool::Bool->new($self->get_value gt $string->get_value);
    }

    sub le($self, $string) {
        Corvinus::Types::Bool::Bool->new($self->get_value le $string->get_value);
    }

    sub ge($self, $string) {
        Corvinus::Types::Bool::Bool->new($self->get_value ge $string->get_value);
    }

    sub subtract($self, $obj) {

        if (ref($obj) eq 'Corvinus::Types::Regex::Regex') {

            $obj->match($self)->to_bool or return $self;

            my $str = $self->get_value;
            if (exists $obj->{global}) {
                return $self->new($str =~ s/$obj->{regex}//gr);
            }

            if ($str =~ /$obj->{regex}/) {
                return $self->new(CORE::substr($str, 0, $-[0]) . CORE::substr($str, $+[0]));
            }

            return $self;
        }

        if ((my $ind = CORE::index($self->get_value, $obj->get_value)) != -1) {
            return $self->new(  CORE::substr($self->get_value, 0, $ind)
                              . CORE::substr($self->get_value, $ind + CORE::length($obj->get_value)));
        }
        $self;
    }

    *elimina = \&subtract;
    *exclude = \&subtract;
    *inlatura = \&subtract;

    {
        my %cache;

        sub match($self, $regex, @rest) {
            (
             ref($regex) eq 'Corvinus::Types::Regex::Regex' ? $regex : do {
                 state $x = require Scalar::Util;
                 $cache{Scalar::Util::refaddr($regex)} //= Corvinus::Types::Regex::Regex->new($regex);
               }
            )->match($self, @rest);
        }
    }

    *matches = \&match;
    *potrivire = \&match;

    {
        my %cache;

        sub gmatch($self, $regex, @rest) {
            (
             ref($regex) eq 'Corvinus::Types::Regex::Regex' ? $regex : do {
                 state $x = require Scalar::Util;
                 $cache{Scalar::Util::refaddr($regex)} //=
                   Corvinus::Types::Regex::Regex->new($regex);
               }
            )->gmatch($self, @rest);
        }
    }

    *gmatches = \&gmatch;
    *potrivire_globala = \&gmatch;

    sub array_to($self, $string) {
        my ($s1, $s2) = ($self->get_value, $string->get_value);

        if (length($s1) == 1 and length($s2) == 1) {
            return Corvinus::Types::Array::Array->new(map { $self->new(chr($_)) } ord($s1) .. ord($s2));
        }
        Corvinus::Types::Array::Array->new(map { $self->new($_) } $s1 .. $s2);
    }

    *arr_to = \&array_to;

    sub array_downto($self, $string) {
        $string->array_to($self)->reverse;
    }

    *arr_downto = \&array_downto;

    sub to($self, $string) {
        Corvinus::Types::Array::RangeString->new(
                                              from => $self->get_value,
                                              to   => $string->get_value,
                                              asc  => 1,
                                             );
    }

    *upto  = \&to;
    *upTo  = \&to;
    *range = \&to;
    *pana_la = \&to;

    sub downto($self, $string) {
        Corvinus::Types::Array::RangeString->new(
                                              from => $self->get_value,
                                              to   => $string->get_value,
                                              asc  => 0,
                                             );
    }

    *downTo = \&downto;
    *coboara_la = \&downto;

    sub cmp($self, $string) {
        Corvinus::Types::Number::Number->new($self->get_value cmp $string->get_value);
    }

    *compara = \&cmp;

    sub xor($self, $str) {
        $self->new($self->get_value ^ $str->get_value);
    }

    sub or($self, $str) {
        $self->new($self->get_value | $str->get_value);
    }

    sub and($self, $str) {
        $self->new($self->get_value & $str->get_value);
    }

    sub not($self) {
        $self->new(~$self->get_value);
    }

    sub times($self, $num) {
        $self->new($self->get_value x $num->get_value);
    }

    *multiply = \&times;
    *ori = \&times;
    *multiplica = \&times;

    sub repeat($self, $num=1) {
        $num = $num->get_value if ref($num);
        $self->new($self->get_value x $num);
    }

    *repeta = \&repeat;

    sub equals($self, $arg) {
        my $value = $arg->get_value;
        Corvinus::Types::Bool::Bool->new(defined($value) ? $self->get_value eq $value : 0);
    }

    *este = \&equals;
    *este_echivalent = \&equals;

    sub ne($self, $arg) {
        my $value = $arg->get_value;
        Corvinus::Types::Bool::Bool->new(defined($value) ? $self->get_value ne $value : 1);
    }

    *nu_este = \&ne;
    *nu_este_echivalent = \&ne;

    sub append($self, $string) {
        __PACKAGE__->new($self->get_value . $string->get_value);
    }

    *concat = \&append;
    *adauga = \&append;
    *uneste = \&append;

    sub lc($self) {
        $self->new(CORE::lc $self->get_value);
    }

    *litere_mici = \&lc;
    *in_litere_mici = \&lc;

    sub uc($self) {
        $self->new(CORE::uc $self->get_value);
    }

    *litere_mari = \&uc;
    *in_litere_mari = \&uc;

    sub lcfirst($self) {
        $self->new(CORE::lcfirst $self->get_value);
    }

    *prima_litera_mica = \&lcfirst;
    *cu_prima_litera_mica = \&lcfirst;

    sub ucfirst($self) {
        $self->new(CORE::ucfirst $self->get_value);
    }

    *prima_litera_mare = \&ucfirst;
    *cu_prima_litera_mare = \&ucfirst;

    sub char_at($self, $pos) {
        Corvinus::Types::Char::Char->new(CORE::substr($self->get_value, $pos->get_value, 1));
    }

    *caracterul = \&char_at;

    sub wordcase($self) {
        my $str    = $self->get_value;
        my $string = '';

        if ($str =~ /\G(\s+)/gc) {
            $string = $1;
        }

        while ($str =~ /\G(\S++)(\s*+)/gc) {
            $string .= CORE::ucfirst(CORE::lc($1)) . $2;
        }

        $self->new($string);
    }

    *capitalizeaza_cuvintele = \&wordcase;

    sub capitalize($self) {
        $self->new(CORE::ucfirst(CORE::lc($self->get_value)));
    }

    *capitalizeaza = \&capitalize;

    sub chop($self) {
        $self->new(CORE::substr($self->get_value, 0, -1));
    }

    *fara_ultimul_caracter = \&chop;

    sub pop($self) {
        $self->new(CORE::substr($self->get_value, -1));
    }

    *ultimul_caracter = \&pop;

    sub chomp($self) {
        if (substr($self->get_value, -1) eq "\n") {
            return $self->chop;
        }

        $self;
    }

    sub crypt($self, $salt) {
        $self->new(crypt($self->get_value, $salt->get_value));
    }

    sub hex($self) {
        Corvinus::Types::Number::Number->new(CORE::hex($self->get_value));
    }

    *hexadecimal = \&hex;

    sub oct($self) {
        Corvinus::Types::Number::Number->new(CORE::oct($self->get_value));
    }

    *octal = \&oct;

    sub bin($self) {
        my $value = $self->get_value;
        Corvinus::Types::Number::Number->new(CORE::oct(index($value, '0b') == 0 ? $value : ('0b' . $value)));
    }

    *binar = \&bin;

    sub num($self) {
        Corvinus::Types::Number::Number->new($self->get_value);
    }

    *numar = \&num;

    sub substr($self, $offs, $len=undef) {
        __PACKAGE__->new(
                         defined($len)
                         ? CORE::substr($self->get_value, $offs->get_value, $len->get_value)
                         : CORE::substr($self->get_value, $offs->get_value)
                        );
    }

    *ft        = \&substr;
    *substring = \&substr;
    *extrage = \&substr;

    sub insert($self, $string, $pos, $len=undef) {
        CORE::substr(my $copy_str = $self->get_value, $pos->get_value,
                     (defined($len) ? $len->get_value : 0), $string->get_value);
        __PACKAGE__->new($copy_str);
    }

    *introdu = \&insert;

    sub join($self, @rest) {
        __PACKAGE__->new(CORE::join($self->get_value, map { $_->get_value } @rest));
    }

    *imbina = \&join;

    sub clear($self) {
        $self->new('');
    }

    *gol = \&clear;

    sub is_empty($self) {
        Corvinus::Types::Bool::Bool->new($self->get_value eq '');
    }

    *e_gol = \&is_empty;

    sub index($self, $substr, $pos=undef) {
        Corvinus::Types::Number::Number->new(
                                          defined($pos)
                                          ? CORE::index($self->get_value, $substr->get_value, $pos->get_value)
                                          : CORE::index($self->get_value, $substr->get_value)
                                         );
    }

    *cauta = \&index;

    sub ord($self) {
        Corvinus::Types::Number::Number->new(CORE::ord($self->get_value));
    }

    sub reverse($self) {
        $self->new(scalar CORE::reverse($self->get_value));
    }

    *invers = \&reverse;
    *inversat = \&reverse;

    sub printf($self, @arguments) {
        Corvinus::Types::Bool::Bool->new(printf $self->get_value, @arguments);
    }

    sub sprintf($self, @arguments) {
        __PACKAGE__->new(CORE::sprintf $self->get_value, @arguments);
    }

    sub _string_or_regex {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Corvinus::Types::Regex::Regex') {
            return $obj->{regex};
        }

        CORE::quotemeta($obj->get_value);
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        $str //= __PACKAGE__->new('');

        $str->SUPER::isa('Corvinus::Types::Block::Code')
          && return $self->esub($regex, $str);

        if (ref($regex) eq 'Corvinus::Types::Regex::Regex') {
            $regex->match($self)->{matched} or return $self;
        }

        my $search = $self->_string_or_regex($regex);
        my $value  = $str->get_value;

        $self->new($self->get_value =~ s{$search}{$value}r);
    }

    *replace = \&sub;
    *inlocuieste = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        $str //= __PACKAGE__->new('');

        $str->SUPER::isa('Corvinus::Types::Block::Code')
          && return $self->gesub($regex, $str);

        if (ref($regex) eq 'Corvinus::Types::Regex::Regex') {
            $regex->match($self)->{matched} or return $self;
        }

        my $search = $self->_string_or_regex($regex);
        my $value  = $str->get_value;
        $self->new($self->get_value =~ s{$search}{$value}gr);
    }

    *gReplace = \&gsub;
    *inlocuieste_global = \&gsub;

    sub _get_captures {
        my ($string) = @_;
        map { __PACKAGE__->new(CORE::substr($string, $-[$_], $+[$_] - $-[$_])) } 1 .. $#{-};
    }

    sub esub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if (ref($regex) eq 'Corvinus::Types::Regex::Regex') {
            $regex->match($self)->{matched} or return $self;
        }

        if ($code->SUPER::isa('Corvinus::Types::Block::Code')) {
            return __PACKAGE__->new($self->get_value =~ s{$search}{$code->run(_get_captures($self->get_value))}er);
        }

        __PACKAGE__->new($self->get_value =~ s{$search}{$code->get_value}eer);
    }

    sub gesub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if (ref($regex) eq 'Corvinus::Types::Regex::Regex') {
            $regex->match($self)->{matched} or return $self;
        }

        if ($code->SUPER::isa('Corvinus::Types::Block::Code')) {
            my $value = $self->get_value;
            return __PACKAGE__->new($value =~ s{$search}{$code->run(_get_captures($value))}ger);
        }

        my $value = $code->get_value;
        __PACKAGE__->new($self->get_value =~ s{$search}{$value}geer);
    }

    sub glob($self) {
        state $x = require Encode;
        Corvinus::Types::Array::Array->new(map { __PACKAGE__->new(Encode::decode_utf8($_)) } CORE::glob($self->get_value));
    }

    sub quotemeta($self) {
        __PACKAGE__->new(CORE::quotemeta($self->get_value));
    }

    *escape = \&quotemeta;

    sub scan($self, $regex) {
        my $str = $self->get_value;
        Corvinus::Types::Array::Array->new(map { Corvinus::Types::String::String->new($_) } $str =~ /$regex->{regex}/g);
    }

    *scaneaza = \&scan;

    sub split($self, $sep, $size=0) {

        $size = $size->get_value if ref($size);

        if (CORE::not defined $sep) {
            return
              Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                                split(' ', $self->get_value, $size));
        }

        if (ref($sep) eq 'Corvinus::Types::Number::Number') {
            return
              Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) } unpack '(a' . $sep->get_value . ')*',
                                              $self->get_value);
        }

        $sep = $self->_string_or_regex($sep);
        Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                          split(/$sep/, $self->get_value, $size));
    }

    *imparte = \&split;

    sub sort($self, $block=undef) {

        if (defined $block) {
            return $self->to_chars->sort($block)->join;
        }

        $self->new(CORE::join('', sort(CORE::split(//, $self->get_value))));
    }

    *sorteaza = \&sort;

    sub format {
        my ($self) = @_;
        CORE::chomp(my $text = 'format __MY_FORMAT__ = ' . "\n" . $self->get_value);
        eval($text . "\n.");

        open my $str_h, '>', \my $acc;
        my $old_h = select($str_h);
        local $~ = '__MY_FORMAT__';
        write;
        select($old_h);
        close $str_h;

        Corvinus::Types::String::String->new($acc);
    }

    sub each_word {
        my ($self, $obj) = @_;
        my $array = Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(' ', $self->get_value));
        $obj // return $array;
        $array->each($obj);
    }

    *words    = \&each_word;
    *eachWord = \&each_word;
    *fiecare_cuvant = \&each_word;

    sub bytes($self) {
        $self->to_bytes;
    }

    *octeti = \&bytes;

    sub chars($self) {
        Corvinus::Types::Char::Chars->call($self->get_value);
    }

    *caractere = \&chars;

    sub each($self, $code) {
        foreach my $char (CORE::split(//, $self->get_value)) {
            if (defined(my $res = $code->_run_code(__PACKAGE__->new($char)))) {
                return $res;
            }
        }
        $self;
    }

    *each_char = \&each;
    *fiecare = \&each;
    *fiecare_caracter = \&each;

    sub lines($self) {
        Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(/\R/, $self->get_value));
    }

    *linii = \&lines;

    sub each_line {
        my ($self, $obj) = @_;
        $self->lines->each($obj);
    }

    *eachLine = \&each_line;

    sub open_r($self, @rest) {
        state $x = require Encode;
        my $string = Encode::encode_utf8($self->get_value);
        Corvinus::Types::Glob::File->new(\$string)->open_r(@rest);
    }

    *deschide_citire = \&open_r;

    sub open($self, @rest) {
        state $x = require Encode;
        my $string = Encode::encode_utf8($self->get_value);
        Corvinus::Types::Glob::File->new(\$string)->open(@rest);
    }

    *deschide = \&open;

    sub trim {
        my ($self) = @_;
        $self->new(unpack('A*', $self->get_value) =~ s/^\s+//r);
    }

    *strip = \&trim;

    sub strip_beg {
        my ($self) = @_;
        $self->new($self->get_value =~ s/^\s+//r);
    }

    *trim_beg = \&strip_beg;
    *trimBeg  = \&strip_beg;
    *stripBeg = \&strip_beg;

    sub strip_end {
        my ($self) = @_;
        $self->new(unpack('A*', $self->get_value));
    }

    *trim_end = \&strip_end;
    *trimEnd  = \&strip_end;
    *stripEnd = \&strip_end;

    sub trans {
        my ($self, $orig, $repl) = @_;

        my %map;
        if (CORE::not defined($repl) and defined($orig)) {    # assume an array of pairs
            foreach my $pair (map { $_->get_value } @{$orig}) {
                $map{$pair->first} = $pair->second->get_value;
            }
        }
        else {
            @map{@{$orig}} = map { $_->get_value } @{$repl};
        }

        my $tries = CORE::join('|', map { CORE::quotemeta($_) }
                                 sort { length($b) <=> length($a) } CORE::keys(%map));
        $self->new($self->get_value =~ s{($tries)}{$map{$1}}gr);
    }

    sub translit {
        my ($self, $orig, $repl, $modes) = @_;

        $orig->isa('ARRAY') && return $self->trans($orig, $repl);
        $self->new(
                       eval qq{"\Q${\$self->get_value}\E"=~tr/}
                     . $orig->get_value =~ s{([/\\])}{\\$1}gr . "/"
                     . $repl->get_value =~ s{([/\\])}{\\$1}gr . "/r"
                     . (
                        defined($modes)
                        ? $modes->get_value
                        : ''
                       )
                  );
    }

    *tr = \&translit;

    sub unpack {
        my ($self, $arg) = @_;
        my @values = map { __PACKAGE__->new($_) } CORE::unpack($self->get_value, $arg->get_value);
        @values > 1 ? Corvinus::Types::Array::List->new(@values) : $values[0];
    }

    sub pack {
        my ($self, @list) = @_;
        __PACKAGE__->new(CORE::pack($self->get_value, @list));
    }

    sub length {
        my ($self) = @_;
        Corvinus::Types::Number::Number->new(CORE::length($self->get_value));
    }

    *len = \&length;
    *lungime = \&length;

    sub graphs($self) {
        my $str = $self->get_value;
        Corvinus::Types::Array::Array->new(map { __PACKAGE__->new($_) } $str =~ /\X/g);
    }

    *graphemes    = \&graphs;
    *to_graphemes = \&graphs;

    sub levenshtein($self, $arg) {

        my @s = split(//, $self->get_value);
        my @t = split(//, $arg->get_value);

        my $len1 = scalar(@s);
        my $len2 = scalar(@t);

        state $x = require List::Util;

        my @d = ([0 .. $len2], map { [$_] } 1 .. $len1);
        foreach my $i (1 .. $len1) {
            foreach my $j (1 .. $len2) {
                $d[$i][$j] =
                    $s[$i - 1] eq $t[$j - 1]
                  ? $d[$i - 1][$j - 1]
                  : List::Util::min($d[$i - 1][$j], $d[$i][$j - 1], $d[$i - 1][$j - 1]) + 1;
            }
        }

        Corvinus::Types::Number::Number->new($d[-1][-1]);
    }

    *lev   = \&levenshtein;
    *leven = \&levenshtein;

    sub contains($self, $string, $start_pos=0) {

        $start_pos = $start_pos->get_value if ref($start_pos);

        if ($start_pos < 0) {
            $start_pos = CORE::length($self->get_value) + $start_pos;
        }

        Corvinus::Types::Bool::Bool->new(CORE::index($self->get_value, $string->get_value, $start_pos) != -1);
    }

    *include = \&contains;
    *contine = \&contains;

    sub count($self, $substr) {

        my $s  = $self->get_value;
        my $ss = $substr->get_value;

        my $counter = 0;
        ++$counter while $s =~ /\Q$ss\E/g;
        Corvinus::Types::Number::Number->new($counter);
    }

    *numara = \&count;

    sub overlaps {
        my ($self, $arg) = @_;
        Corvinus::Types::Bool::Bool->new(CORE::index($self->get_value ^ $arg->get_value, "\0") != -1);
    }

    sub begins_with {
        my ($self, $string) = @_;

        CORE::length($self->get_value) < (my $len = CORE::length($string->get_value))
          && return Corvinus::Types::Bool::Bool->false;

        CORE::substr($self->get_value, 0, $len) eq $string->get_value
          && return Corvinus::Types::Bool::Bool->true;

        Corvinus::Types::Bool::Bool->false;
    }

    *incepe_cu = \&begins_with;

    sub ends_with($self, $string) {

        CORE::length($self->get_value) < (my $len = CORE::length($string->get_value))
          && return Corvinus::Types::Bool::Bool->false;

        CORE::substr($self->get_value, -$len) eq $string->get_value
          && return Corvinus::Types::Bool::Bool->true;

        Corvinus::Types::Bool::Bool->false;
    }

    *se_termina_cu = \&ends_with;

    sub looks_like_number($self) {
        state $x = require Scalar::Util;
        Corvinus::Types::Bool::Bool->new(Scalar::Util::looks_like_number($self->get_value));
    }

    *arata_ca_numar = \&looks_like_number;

    sub warn($self) {
        warn $self->get_value;
    }

    sub die($self) {
        die $self->get_value;
    }

    sub encode($self, $enc) {
        state $x = require Encode;
        $self->new(Encode::encode($enc->get_value, $self->get_value));
    }

    sub decode($self, $enc) {
        state $x = require Encode;
        $self->new(Encode::decode($enc->get_value, $self->get_value));
    }

    sub encode_utf8 {
        my ($self) = @_;
        state $x = require Encode;
        $self->new(Encode::encode_utf8($self->get_value));
    }

    sub decode_utf8 {
        my ($self) = @_;
        state $x = require Encode;
        $self->new(Encode::decode_utf8($self->get_value));
    }

    sub _require {
        my ($self) = @_;

        my $name = $self->get_value;
        eval { require(($name . '.pm') =~ s{::}{/}gr) };

        if ($@) {
            CORE::die CORE::substr($@, 0, CORE::rindex($@, ' at ')), "\n";
        }

        $name;
    }

    sub require($self) {
        Corvinus::Module::OO->__NEW__($self->_require);
    }

    *oo = \&require;
    *foloseste = \&require;

    sub frequire($self) {
        Corvinus::Module::Func->__NEW__($self->_require);
    }

    *ff = \&frequire;

    sub unescape {
        my ($self) = @_;
        $self->new($self->get_value =~ s{\\(.)}{$1}grs);
    }

    sub apply_escapes {
        my ($self, $parser) = @_;

        state $x = require Encode;
        my $str = $self->get_value;

        state $esc = {
                      a => "\a",
                      b => "\b",
                      e => "\e",
                      f => "\f",
                      n => "\n",
                      r => "\r",
                      t => "\t",
                      s => ' ',
                      v => chr(11),
                     };

        my @inline_expressions;
        my @chars = split(//, $str);

        my $spec = 'E';
        for (my $i = 0 ; $i <= $#chars ; $i++) {

            if ($chars[$i] eq '\\' and exists $chars[$i + 1]) {
                my $char = $chars[$i + 1];

                if (exists $esc->{$char}) {
                    splice(@chars, $i--, 2, $esc->{$char});
                    next;
                }
                elsif (   $char eq 'L'
                       or $char eq 'U'
                       or $char eq 'E'
                       or $char eq 'Q') {
                    $spec = $char;
                    splice(@chars, $i--, 2);
                    next;
                }
                elsif ($char eq 'l') {
                    if (exists $chars[$i + 2]) {
                        splice(@chars, $i, 3, CORE::lc($chars[$i + 2]));
                        next;
                    }
                    else {
                        splice(@chars, $i, 2);
                    }
                }
                elsif ($char eq 'u') {
                    if (exists $chars[$i + 2]) {
                        splice(@chars, $i, 3, CORE::uc($chars[$i + 2]));
                        next;
                    }
                    else {
                        splice(@chars, $i, 2);
                    }
                }
                elsif ($char eq 'N') {
                    if (exists $chars[$i + 2] and $chars[$i + 2] eq '{') {
                        my $str = CORE::join('', @chars[$i + 2 .. $#chars]);
                        if ($str =~ /^\{(.*?)\}/) {
                            state $x = require charnames;
                            my $char = charnames::string_vianame($1);
                            if (defined $char) {
                                splice(@chars, $i--, 2 + $+[0], $char);
                                next;
                            }
                        }
                        else {
                            CORE::warn("Missing right brace on \\N{, within string!\n");
                        }
                    }
                    else {
                        CORE::warn("Missing braces on \\N{}, within string!\n");
                    }
                    splice(@chars, $i, 1);
                }
                elsif ($char eq 'x') {
                    if (exists $chars[$i + 2]) {
                        my $str = CORE::join('', @chars[$i + 2 .. $#chars]);
                        if ($str =~ /^\{([[:xdigit:]]+)\}/) {
                            splice(@chars, $i, 2 + $+[0], chr(CORE::hex($1)));
                            next;
                        }
                        elsif ($str =~ /^([[:xdigit:]]{1,2})/) {
                            splice(@chars, $i, 2 + $+[0], chr(CORE::hex($1)));
                            next;
                        }
                    }
                    splice(@chars, $i, 1);
                }
                elsif ($char eq 'o') {
                    if (exists $chars[$i + 2] and $chars[$i + 2] eq '{') {
                        my $str = CORE::join('', @chars[$i + 2 .. $#chars]);
                        if ($str =~ /^\{(.*?)\}/) {
                            splice(@chars, $i--, 2 + $+[0], CORE::chr(CORE::oct($1)));
                            next;
                        }
                        else {
                            CORE::warn("Missing right brace on \\o{, within string!\n");
                        }
                    }
                    else {
                        CORE::warn("Missing braces on \\o{}, within string!\n");
                    }
                    splice(@chars, $i, 1);
                }
                elsif ($char =~ /^[0-7]/) {
                    my $str = CORE::join('', @chars[$i + 1 .. $#chars]);
                    if ($str =~ /^(0[0-7]{1,2}|[0-7]{1,2})/) {
                        splice @chars, $i, 1 + $+[0], CORE::chr(CORE::oct($1));
                    }
                }
                elsif ($char eq 'd') {
                    splice(@chars, $i - 1, 3);
                }
                elsif ($char eq 'c') {
                    if (exists $chars[$i + 2]) {    # bug for: "\c\\"
                        splice(@chars, $i, 3, chr((CORE::ord(CORE::uc($chars[$i + 2])) + 64) % 128));
                    }
                    else {
                        CORE::warn "[WARN] Missing control char name in \\c, within string\n";
                        splice(@chars, $i, 2);
                    }
                }
                else {
                    splice(@chars, $i, 1);
                }
            }
            elsif (    $chars[$i] eq '#'
                   and exists $chars[$i + 1]
                   and $chars[$i + 1] eq '{') {
                if (ref $parser eq 'Corvinus::Parser') {
                    my $code = CORE::join('', @chars[$i + 1 .. $#chars]);
                    my $block = $parser->parse_block(code => \$code);
                    if (@{$block->{vars}} == 1) {
                        $block = $block->{code};
                    }
                    push @inline_expressions, [$i, $block];
                    splice(@chars, $i--, 1 + pos($code));
                }
                else {
                    # Can't eval #{} at runtime!
                }
            }

            if ($spec ne 'E') {
                if ($spec eq 'U') {
                    $chars[$i] = CORE::uc($chars[$i]);
                }
                elsif ($spec eq 'L') {
                    $chars[$i] = CORE::lc($chars[$i]);
                }
                elsif ($spec eq 'Q') {
                    $chars[$i] = CORE::quotemeta($chars[$i]);
                }
            }
        }

        if (@inline_expressions) {

            foreach my $i (0 .. $#inline_expressions) {
                my $pair = $inline_expressions[$i];
                splice @chars, $pair->[0] + $i, 0, $pair->[1];
            }

            my $expr = {
                        $parser->{class} => [
                                             {
                                              self => $self->new,
                                              call => [{method => 'meta_join'}]
                                             }
                                            ]
                       };

            my $append_arg = sub {
                push @{$expr->{$parser->{class}}[0]{call}[-1]{arg}}, $_[0];
            };

            my $string = '';
            foreach my $char (@chars) {
                if (ref($char)) {
                    my $block =
                      ref($char) eq 'HASH'
                      ? $char
                      : {
                         $parser->{class} => [
                                              {
                                               self => $char,
                                               call => [{method => 'run'}]
                                              }
                                             ]
                        };

                    if ($string ne '') {
                        $append_arg->(Encode::decode_utf8(Encode::encode_utf8($string)));
                        $string = '';
                    }
                    $append_arg->($block);
                }
                else {
                    $string .= $char;
                }
            }

            if ($string ne '') {
                $append_arg->(Encode::decode_utf8(Encode::encode_utf8($string)));
            }

            return $expr;
        }

        $self->new(Encode::decode_utf8(Encode::encode_utf8(CORE::join('', @chars))));
    }

    *applyEscapes = \&apply_escapes;

    sub shift_left {
        my ($self, $i) = @_;
        my $len = CORE::length($self->get_value);
        $i = $i->get_value > $len ? $len : $i->get_value;
        $self->new(CORE::substr($self->get_value, $i));
    }

    *dropLeft  = \&shift_left;
    *drop_left = \&shift_left;
    *shiftLeft = \&shift_left;

    sub shift_right {
        my ($self, $i) = @_;
        $self->new(CORE::substr($self->get_value, 0, -$i->get_value));
    }

    *dropRight  = \&shift_right;
    *drop_right = \&shift_right;
    *shiftRight = \&shift_right;

    sub pair_with {
        Corvinus::Types::Array::Pair->new($_[0], $_[1]);
    }

    *pairWith = \&pair_with;

    sub basic_dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $self->get_value =~ s{([\\'])}{\\$1}gr . q{'});
    }

    sub dump {
        my ($self) = @_;

        state $x = eval { require Data::Dump };
        $x || return $self->basic_dump;

        local $Data::Dump::TRY_BASE64 = 0;
        $self->new(Data::Dump::quote($self->get_value) =~ s<(#\{)>{\\$1}gr);
    }

    *inspect = \&dump;

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '=~'}  = \&match;
        *{__PACKAGE__ . '::' . '*'}   = \&times;
        *{__PACKAGE__ . '::' . '+'}   = \&append;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '=='}  = \&equals;
        *{__PACKAGE__ . '::' . '='}   = \&equals;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '..'}  = \&array_to;
        *{__PACKAGE__ . '::' . '...'} = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&to;
        *{__PACKAGE__ . '::' . '^..'} = \&downto;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '%'}   = \&sprintf;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
    }
};

1
