package Corvinus::Types::Block::Code {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Object::Object);

    require Corvinus::Exec;
    my $exec = Corvinus::Exec->new();

    sub new {
        $#_ == 1
          ? (bless {code => $_[1]}, __PACKAGE__)
          : do {
            my (undef, %hash) = @_;
            bless \%hash, __PACKAGE__;
          };
    }

    sub dump($self) {
        my $deparser = Corvinus::Deparse::Corvinus->new(namespaces => [@Corvinus::Exec::NAMESPACES]);
        Corvinus::Types::String::String->new($deparser->deparse_expr({self => $self}));
    }

    sub _execute($self) {
        $exec->execute($self->{code});
    }

    sub _execute_expr($self) {
        $exec->execute_expr($self->{code});
    }

    {
        my $ref = \&UNIVERSAL::AUTOLOAD;

        sub get_value {
            my ($self) = @_;
            sub {
                local *UNIVERSAL::AUTOLOAD = $ref;
                if (defined($a) || defined($b)) { push @_, $a, $b }
                elsif (defined($_)) { push @_, $_ }
                $self->call(@_);
            };
        }
    }

    sub copiaza($self) {
        state $x = require Storable;
        Storable::dclone($self);
    }

    *copy = \&copiaza;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeta;
    }

    sub asculta($self) {

        open my $str_h, '>:utf8', \my $str;
        if (defined(my $old_h = select($str_h))) {
            $self->run;
            close $str_h;
            select $old_h;
        }

        Corvinus::Types::String::String->new($str)->decode_utf8;
    }

    sub repeta($self, $num=1) {

        $num = $num->get_value if ref($num);
        return $self if $num < 1;

        if ($num > (-1 >> 1)) {
            for (my $i = 1 ; $i <= $num ; $i++) {
                if (defined(my $res = $self->_run_code(Corvinus::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        else {
            foreach my $i (1 .. $num) {
                if (defined(my $res = $self->_run_code(Corvinus::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }

        $self;
    }

    sub ca_dict {
        my ($self) = @_;
        Corvinus::Types::Hash::Hash->new($self->_execute);
    }

    *ca_dictionary = \&ca_dict;

    sub ca_lista {
        my ($self) = @_;
        Corvinus::Types::Array::Array->new($self->_execute);
    }

    sub _run_code {
        my ($self, @args) = @_;
        my $result = $self->run(@args);

        ref($result) eq 'Corvinus::Types::Block::Return'
          ? $result
          : ref($result) eq 'Corvinus::Types::Block::Break' ? --$result->{depth} <= 0
              ? $self
              : $result
          : ref($result) eq 'Corvinus::Types::Block::Next' ? --$result->{depth} <= 0
              ? ()
              : $result
          : ();
    }

    sub executa($self, @args) {

        if (@args) {
            $self->fast_init_block_vars(@args);
        }

        my $result = ($self->_execute)[-1];
        my $ref    = ref($result);
        if ($ref eq 'Corvinus::Variable::Variable' or $ref eq 'Corvinus::Variable::ClassVar') {
            $result = $result->get_value;
        }
        $self->pop_stack() if exists($self->{vars});
        $result;
    }

    *run = \&executa;

    sub exec($self) {
        $self->run;
        $self;
    }

    *do = \&exec;

    sub all($self) {

        foreach my $class (keys %{$self->{code}}) {
            foreach my $statement (@{$self->{code}{$class}}) {
                $exec->execute_expr(ref($statement) eq 'HASH' ? $statement : {self => $statement})
                  || return Corvinus::Types::Bool::Bool->false;
            }
        }

        Corvinus::Types::Bool::Bool->true;
    }

    *toate = \&all;

    sub any($self) {

        foreach my $class (keys %{$self->{code}}) {
            foreach my $statement (@{$self->{code}{$class}}) {
                $exec->execute_expr(ref($statement) eq 'HASH' ? $statement : {self => $statement})
                  && return Corvinus::Types::Bool::Bool->true;
            }
        }

        Corvinus::Types::Bool::Bool->false;
    }

    *oricare = \&any;

    sub cat_timp($self, $condition, $old_self=undef) {
        my ($self, $condition, $old_self) = @_;

        if (exists($condition->{_special_stack_vars}) and not exists($self->{_specialized})) {
            $self->{_specialized} = 1;
            push @{$self->{vars}}, @{$condition->{_special_stack_vars}};
        }

        while ($condition->run) {
            defined($old_self) && ($old_self->{did_while} //= 1);
            if (defined(my $res = $self->_run_code)) {
                return (ref($res) eq ref($self) && defined($old_self) ? $old_self : $res);
            }
        }

        $old_self // $self;
    }

    *while = \&cat_timp;

    sub loop($self) {

        while (1) {
            if (defined(my $res = $self->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    *bucla = \&loop;

    sub try($self) {
        my $try = Corvinus::Types::Block::Try->new();

        my $error = 0;
        local $SIG{__WARN__} = sub { $try->{type} = 'warning'; $try->{msg} = $_[0]; $error = 1 };
        local $SIG{__DIE__}  = sub { $try->{type} = 'error';   $try->{msg} = $_[0]; $error = 1 };

        $try->{val} = eval { $self->run };

        if ($@ || $error) {
            $try->{catch} = 1;
        }

        $try;
    }

    *incearca = \&try;

    {
        my $check_type = sub {
            my ($var, $value) = @_;

            my ($r1, $r2) = (ref($var->{value}), ref($value));
            foreach my $item ([\$r1, $var->{value}], [\$r2, $value]) {
                if (${$item->[0]} eq 'Corvinus::Variable::Class' or ${$item->[0]} eq 'Corvinus::Variable::ClassInit') {
                    ${$item->[0]} = $item->[1]->{name};
                }
            }
            $r1 eq $r2
              || die "[ERROR] Type mismatch error in variable '$var->{name}': got '", $r2,
              "', but expected '", $r1, "'!\n";
        };

        sub init_block_vars {
            my ($self, @args) = @_;

            # varName => value
            my %named_vars;

            # Init the arguments
            my $last = $#{$self->{init_vars}};
            for (my $i = 0 ; $i <= $last ; $i++) {
                my $var = $self->{init_vars}[$i];
                if (ref $args[$i] eq 'Corvinus::Types::Array::Pair') {
                    $named_vars{$args[$i][0]->get_value} = $args[$i][1]->get_value;
                    splice(@args, $i--, 1);
                }
                else {
                    my $v = $var->{vars}[0];
                    exists($v->{in_use}) || next;
                    (exists($v->{array}) || exists($v->{hash})) && do {
                        $var->set_value(@args[$i .. $#args]);
                        next;
                    };
                    exists($v->{has_value}) && exists($args[$i]) && $check_type->($v, $args[$i]);
                    $i == $last
                      ? $var->set_value(Corvinus::Types::Array::Array->new(@args[$i .. $#args]))
                      : $var->set_value(exists($args[$i]) ? $args[$i] : ());
                }
            }

            foreach my $init_var (@{$self->{init_vars}}) {
                my $var = $init_var->{vars}[0];
                if (exists $named_vars{$var->{name}}) {
                    exists($var->{has_value}) && $check_type->($var, $named_vars{$var->{name}});
                    $init_var->set_value(delete($named_vars{$var->{name}}));
                }
            }

            $last == 0
              ? @{$self->{init_vars}}
              : @{$self->{init_vars}}[0 .. $last - 1];
        }
    }

    sub fast_init_block_vars {
        my ($self, @args) = @_;

        my $nargs = $#args;
        my $last  = $#{$self->{init_vars}};

        foreach my $i (0 .. $last) {
            my $var = $self->{init_vars}[$i];

            my $v = $var->{vars}[0];
            exists($v->{in_use}) || next;

            $nargs > 0 && $i == $last
              ? $var->set_value(Corvinus::Types::Array::Array->new(@args[$i .. $nargs]))
              : $var->set_value(exists($args[$i]) ? $args[$i] : ());
        }

        $last == 0
          ? @{$self->{init_vars}}
          : @{$self->{init_vars}}[0 .. $last - 1];
    }

    sub pop_stack {
        my ($self) = @_;

        my @stack_vars = grep { exists $_->{stack} } @{$self->{vars}};

        state $x = require List::Util;
        my $max_depth = @stack_vars ? List::Util::max(map { $#{$_->{stack}} } @stack_vars) : return;

        if ($max_depth > -1) {
            foreach my $var (@stack_vars) {
                if ($#{$var->{stack}} == $max_depth) {
                    pop @{$var->{stack}};
                }
            }
        }
    }

    sub _check_function {
        my ($self, @args) = @_;

        my @candidates;
        my @possible_candidates;
        foreach my $f ($self, map { $_->get_value } @{$self->{kids}}) {
            if ($#{$f->{init_vars}} - 1 == $#args) {
                push @candidates, $f;
            }
            else {
                push @possible_candidates, $f;
            }
        }

        foreach my $f (@candidates, @possible_candidates) {
            eval { $f->init_block_vars(@args) };
            !$@ && return $f;
        }

        $self->init_block_vars(@args);
        $self;
    }

    sub call {
        my ($self, @args) = @_;

        if (exists $self->{kids}) {
            $self = $self->_check_function(@args);
        }
        else {
            $self->init_block_vars(@args);
        }

        my $result = $self->run;
        if (ref($result) eq 'Corvinus::Types::Block::Return') {
            $result = $result->{obj};
        }

        $result;
    }

    *apeleaza = \&call;

    sub if($self, $bool) {
        $bool ? $self->run : $bool;
    }

    *daca = \&if;

    sub given($self) {
        Corvinus::Types::Block::Switch->new($self->run);
    }

    *dat = \&given;

    sub fork($self) {

        state $x = require Storable;
        open(my $fh, '+>', undef);    # an anonymous temporary file
        my $fork = Corvinus::Types::Block::Fork->new(fh => $fh);

        my $pid = fork() // die "[FATAL ERROR]: cannot fork";
        if ($pid == 0) {
            srand();
            Storable::store_fd($self->run, $fh);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    *exec_paralel = \&fork;

    sub pfork($self) {
        my $fork = Corvinus::Types::Block::Fork->new();

        my $pid = CORE::fork() // die "[FATAL ERROR]: cannot fork";
        if ($pid == 0) {
            srand();
            $self->run;
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub thread($self) {
        state $x = do {
            require threads;
            *threads::get  = \&threads::join;
            *threads::wait = \&threads::join;
            1;
        };
        threads->create(sub { $self->run });
    }

    *thr = \&thread;

    sub for($self, $arg, @rest) {

        if (    $#_ == 3
            and ref($_[1]) eq __PACKAGE__
            and ref($_[2]) eq __PACKAGE__
            and ref($_[3]) eq __PACKAGE__) {
            my ($one, $two, $three) = ($_[1], $_[2], $_[3]);
            for ($one->_execute_expr ; $two->_execute_expr ; $three->_execute_expr) {
                if (defined(my $res = $self->_run_code)) {
                    return $res;
                }
            }
            $self;
        }
        elsif ($#_ == 1 and $arg->can('each')) {
            $arg->each($self);
        }
        else {
            foreach my $item ($arg, @rest) {
                if (defined(my $res = $self->_run_code($item))) {
                    return $res;
                }
            }
            $self;
        }
    }
};

1;
