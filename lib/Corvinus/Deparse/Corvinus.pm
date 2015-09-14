package Corvinus::Deparse::Corvinus {

    use 5.014;
    use parent qw(Corvinus);
    use Scalar::Util qw(refaddr reftype);

    my %addr;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
                    before         => '',
                    between        => ";\n",
                    after          => ";\n",
                    class          => 'main',
                    extra_parens   => 0,
                    namespaces     => [],
                    obj_with_block => {
                                       'Corvinus::Types::Bool::While' => {
                                                                       while => 1,
                                                                      },
                                      },
                    %args,
                   );
        %addr = ();    # reset the addr map
        bless \%opts, __PACKAGE__;
    }

    sub _dump_init_vars {
        my ($self, @init_vars) = @_;
        $self->_dump_vars(map { @{$_->{vars}} } @init_vars);
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        join(
            ', ',
            map {
                    (exists($_->{array}) ? '*' : exists($_->{hash}) ? ':' : '')
                  . (exists($_->{class}) && $_->{class} ne $self->{class} ? $_->{class} . '::' : '')
                  . $_->{name}
                  . (
                    ref($_->{value}) eq 'Corvinus::Types::Nil::Nil' ? '' : do {
                        my $type = $self->deparse_expr({self => $_->{value}});
                        $type =~ /^[[:alpha:]_]\w*\z/ ? " is $type" : "=$type";
                      }
                    )
              } @vars
            );
    }

    sub _dump_array {
        my ($self, $array) = @_;
        '[' . join(
            ', ',

            ref($array) eq 'Corvinus::Types::Array::Array'
            ? (map { $self->deparse_expr({self => $_->get_value}) } @{$array})
            : (map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array})
          )
          . ']';
    }

    sub _dump_class_name {
        my ($self, $name) = @_;
        ref($name) ? $self->deparse_expr({self => $name}) : $name;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code = '';
        my $obj  = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
            if ($self->{extra_parens}) {
                $code = "($code)";
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Variable') {
            if ($obj->{type} eq 'var' or $obj->{type} eq 'static' or $obj->{type} eq 'const' or $obj->{type} eq 'def') {
                $code =
                  $obj->{name} =~ /^[0-9]+\z/
                  ? ('$' . $obj->{name})
                  : (($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name});
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{refaddr($obj)}++) {
                    $code =
                      $obj->{name} eq ''
                      ? '__FUNC__'
                      : (($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name});
                }
                else {
                    my $block     = $obj->{value};
                    my $in_module = $obj->{class} ne $self->{class};

                    if ($in_module) {
                        $code = "module $obj->{class} {\n";
                        $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                        $code .= ' ' x $Corvinus::SPACES;
                    }

                    $code .= $obj->{type} . ' ' . $obj->{name};
                    local $self->{class} = $obj->{class};
                    my $vars = delete $block->{init_vars};
                    $code .= '(' . $self->_dump_init_vars(@{$vars}[($obj->{type} eq 'method' ? 1 : 0) .. $#{$vars} - 1]) . ')';
                    if (exists $obj->{returns}) {
                        $code .= ' -> ' . $self->deparse_expr({self => $obj->{returns}}) . ' ';
                    }
                    $code .= $self->deparse_expr({self => $block});
                    $block->{init_vars} = $vars;

                    if ($in_module) {
                        $code .= "\n}";
                        $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                    }
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Struct') {
            if ($addr{refaddr($obj)}++) {
                $code = $obj->{__NAME__};
            }
            else {
                my @vars;
                foreach my $key (sort keys %{$obj}) {
                    next if $key eq '__NAME__';
                    push @vars, $obj->{$key};
                }
                $code = "struct $obj->{__NAME__} {" . $self->_dump_vars(@vars) . '}';
            }
        }
        elsif ($ref eq 'Corvinus::Variable::InitLocal') {
            $code = "local $obj->{name}";
        }
        elsif ($ref eq 'Corvinus::Variable::Local') {
            $code = "$obj->{name}";
        }
        elsif ($ref eq 'Corvinus::Variable::Init') {
            $code = "$obj->{vars}[0]{type}\(" . $self->_dump_init_vars($obj) . ')';
        }
        elsif ($ref eq 'Corvinus::Variable::ClassInit') {
            if ($addr{refaddr($obj)}++) {
                $code =
                  $self->_dump_class_name(
                                     $obj->{name} eq ''
                                     ? '__CLASS__'
                                     : ($obj->{class} ne $self->{class} ? ($obj->{class} . '::' . $obj->{name}) : $obj->{name})
                  );
            }
            else {
                my $block     = $obj->{__BLOCK__};
                my $in_module = $obj->{class} ne $self->{class};

                if ($in_module) {
                    $code = "module $obj->{class} {\n";
                    $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                    $code .= ' ' x $Corvinus::SPACES;
                }

                local $self->{class} = $obj->{class};
                $code .= "class " . $self->_dump_class_name($obj->{name});
                my $vars = $obj->{__VARS__};
                $code .= '(' . $self->_dump_vars(@{$vars}) . ')';
                if (exists $obj->{inherit}) {
                    $code .= ' << ' . join(', ', @{$obj->{inherit}}) . ' ';
                }
                $code .= $self->deparse_expr({self => $block});

                if ($in_module) {
                    $code .= "\n}";
                    $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                }
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::Code') {
            if ($addr{refaddr($obj)}++) {
                $code = %{$obj} ? '__BLOCK__' : 'Block';
            }
            else {
                if (%{$obj}) {
                    $code = '{';
                    if (exists($obj->{init_vars}) and @{$obj->{init_vars}} > 1) {
                        my $vars = $obj->{init_vars};
                        $code .= '|' . $self->_dump_init_vars(@{$vars}[0 .. $#{$vars} - 1]) . "|";
                    }

                    $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                    my @statements = $self->deparse_script($obj->{code});

                    $code .=
                      @statements
                      ? ("\n"
                         . (" " x $Corvinus::SPACES)
                         . join(";\n" . (" " x $Corvinus::SPACES), @statements) . "\n"
                         . (" " x ($Corvinus::SPACES - $Corvinus::SPACES_INCR)) . '}')
                      : '}';

                    $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                }
                else {
                    $code = 'Block';
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Ref') {
            if (not exists $expr->{call}) {
                $code = 'Ref';
            }
        }
        elsif ($ref eq 'Corvinus::Sys::Sys') {
            $code = exists($obj->{file_name}) ? '' : 'Sys';
        }
        elsif ($ref eq 'Corvinus::Parser') {
            $code = 'Parser';
        }
        elsif ($ref eq 'Corvinus') {
            $code = 'Corvinus';
        }
        elsif ($ref eq 'Corvinus::Variable::LazyMethod') {
            $code = 'LazyMethod';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Break') {
            if (not exists $expr->{call}) {
                $code = 'break';
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::Next') {
            if (not exists $expr->{call}) {
                $code = 'next';
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::Continue') {
            $code = 'continue';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Return') {
            if (not exists $expr->{call}) {
                $code = 'return';
            }
        }
        elsif ($ref eq 'Corvinus::Module::OO') {
            $code = "%s($obj->{module})";
        }
        elsif ($ref eq 'Corvinus::Module::Func') {
            $code = "%S($obj->{module})";
        }
        elsif ($ref eq 'Corvinus::Types::Array::List') {
            $code = join(', ', map { $self->deparse_expr({self => $_}) } @{$obj});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Gather') {
            if (exists $addr{refaddr($obj->{block})}) {
                $code = '';
            }
            else {
                return 'gather ' . $self->deparse_expr({self => $obj->{block}});
            }
        }
        elsif ($ref eq 'Corvinus::Math::Math') {
            $code = 'Math';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::DirHandle') {
            $code = 'DirHandle';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = 'STDIN';
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = 'STDOUT';
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = 'STDERR';
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = 'ARGF';
            }
            else {
                $code = 'DATA';
                if (not exists $addr{$obj->{fh}}) {
                    my $orig_pos = tell($obj->{fh});
                    seek($obj->{fh}, 0, 0);
                    $self->{after} .= "\n__DATA__\n" . do {
                        local $/;
                        readline($obj->{fh});
                    };
                    seek($obj->{fh}, $orig_pos, 0);
                    $addr{$obj->{fh}} = 1;
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Magic') {

            state $magic_vars = {
                                 \$.  => '$.',
                                 \$?  => '$?',
                                 \$$  => '$$',
                                 \$^T => '$^T',
                                 \$|  => '$|',
                                 \$!  => '$!',
                                 \$"  => '$"',
                                 \$\  => '$\\',
                                 \$/  => '$/',
                                 \$;  => '$;',
                                 \$,  => '$,',
                                 \$^O => '$^O',
                                 \$^X => '$^PERL',
                                 \$0  => '$0',
                                 \$(  => '$(',
                                 \$)  => '$)',
                                 \$<  => '$<',
                                 \$>  => '$>',
                                };

            if (exists $magic_vars->{$obj->{ref}}) {
                $code = $magic_vars->{$obj->{ref}};
            }
        }
        elsif ($ref eq 'Corvinus::Types::Hash::Hash') {
            $code = 'Hash';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::Socket') {
            $code = 'Socket';
        }
        elsif ($ref eq 'Corvinus::Perl::Perl') {
            $code = 'Perl';
        }
        elsif ($ref eq 'Corvinus::Time::Time') {
            $code = 'Time';
        }
        elsif ($ref eq 'Corvinus::Sys::SIG') {
            $code = 'Sig';
        }
        elsif ($ref eq 'Corvinus::Types::Number::Complex') {
            $code = reftype($obj) eq 'HASH' ? 'Complex' : $obj->dump->get_value;
        }
        elsif ($ref eq 'Corvinus::Types::Number::Number') {
            my $value = $obj->get_value;
            my $num = ref($value) ? ref($value) eq 'Math::BigRat' ? $value->numify : $value->bstr : $value;
            $code = lc($num) eq 'inf' ? '0.inf' : lc($num) eq 'nan' ? '0.nan' : $num;
        }
        elsif ($ref eq 'Corvinus::Types::Array::Array' or $ref eq 'Corvinus::Types::Array::HCArray') {
            $code = $self->_dump_array($obj);
        }
        elsif ($obj->can('dump')) {
            $code = $obj->dump->get_value;

            if ($ref eq 'Corvinus::Types::Glob::Backtick') {
                if (${$obj} eq '') {
                    $code = 'Backtick';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Regex::Regex') {
                if ($code eq '//') {
                    $code = 'Regex';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Glob::File') {
                if (${$obj} eq '') {
                    $code = 'File';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Array::Pair') {
                if (    ref($obj->[0]->get_value) eq 'Corvinus::Types::Nil::Nil'
                    and ref($obj->[1]->get_value) eq 'Corvinus::Types::Nil::Nil') {
                    $code = 'Pair';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Byte::Bytes') {
                if ($#{$obj} == -1) {
                    $code = 'Bytes';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Byte::Byte') {
                if (${$obj} == 0) {
                    $code = 'Byte';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Char::Chars') {
                if ($#{$obj} == -1) {
                    $code = 'Chars';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Glob::Dir') {
                if (${$obj} eq '') {
                    $code = 'Dir';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Char::Char') {
                if (${$obj} eq "\0") {
                    $code = 'Char';
                }
            }
            elsif ($ref eq 'Corvinus::Types::String::String') {
                if (${$obj} eq '') {
                    $code = 'String';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Array::MultiArray') {
                if ($#{$obj} == -1) {
                    $code = 'MultiArr';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Glob::Pipe') {
                if ($#{$obj} == -1) {
                    $code = 'Pipe';
                }
            }
        }

        # Indices
        if (exists $expr->{ind}) {
            foreach my $ind (@{$expr->{ind}}) {
                $code .= $self->_dump_array($ind);
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $call (@{$expr->{call}}) {
                my $method = $call->{method};

                if (ref($method) ne '') {
                    $method = (
                               '('
                                 . $self->deparse_expr(
                                                       ref($method) eq 'HASH'
                                                       ? $method
                                                       : {self => $method}
                                                      )
                                 . ')'
                              );
                }

                if ($code eq 'Hash' and $method eq ':') {
                    $method = 'new';
                }
                elsif ($code =~ /\.\w+\z/ && $method =~ /^[?!:]/) {
                    $code = '(' . $code . ')';
                }
                elsif ($code =~ /^\w+\z/ and $method eq ':') {
                    $code = '(' . $code . ')';
                }

                if ($method =~ /^[[:alpha:]_(]/) {
                    $code .= '.' if $code ne '';
                    $code .= $method;
                }
                else {
                    $code .= $method;
                }

                if (exists $call->{arg}) {
                    $code .= '(' . join(
                        ', ',
                        map {
                            ref($_) eq 'HASH' ? $self->deparse_script($_)
                              : exists($self->{obj_with_block}{$ref})
                              && exists($self->{obj_with_block}{$ref}{$method}) ? $self->deparse_expr({self => $_->{code}})
                              : $ref eq 'Corvinus::Types::Block::For'
                              && $#{$call->{arg}} == 2
                              && ref($_) eq 'Corvinus::Types::Block::Code' ? $self->deparse_expr($_->{code})
                              : ref($_) ? $self->deparse_expr({self => $_})
                              : Corvinus::Types::String::String->new($_)->dump
                          } @{$call->{arg}}
                      )
                      . ')';
                }

                if ($code eq 'Hash.new()') {
                    $code = 'Hash.new';
                }
            }
        }

        $code;
    }

    sub deparse_script {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {
            my $in_module = $class ne $self->{class};
            local $self->{class} = $class;
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});
            }
            if ($in_module) {
                my $spaces = " " x $Corvinus::SPACES_INCR;
                s/^/$spaces/gm for @results;
                $results[0] = "module $class {\n" . $results[0];
                $results[-1] .= "\n}";
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);
        $self->{before} . join($self->{between}, @statements) . $self->{after};
    }
};

1
