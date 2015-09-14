package Corvinus::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    use overload;

    sub to_s {
        my ($self) = @_;
        $self->isa('SCALAR')
          || $self->isa('REF')
          ? Corvinus::Types::String::String->new(overload::StrVal($self) ? "$self" : defined($$self) ? "$$self" : "")
          : $self;
    }

    *to_str    = \&to_s;
    *to_string = \&to_s;

    sub to_obj {
        my ($self, $obj) = @_;
        return $self if ref($self) eq ref($obj);
        $obj->new($self);
    }

    *to_object = \&to_obj;

    sub to_i {
        Corvinus::Types::Number::Number->new_int($_[0]->get_value);
    }

    *to_integer = \&to_i;
    *to_int     = \&to_i;

    sub to_rat {
        Corvinus::Types::Number::Number->new_rat($_[0]->get_value);
    }

    *to_rational = \&to_rat;
    *to_r        = \&to_rat;

    sub to_complex {
        Corvinus::Types::Number::Complex->new($_[0]->get_value);
    }

    *to_c = \&to_complex;

    sub to_n {
        Corvinus::Types::Number::Number->new($_[0]->get_value);
    }

    *to_num    = \&to_n;
    *to_number = \&to_n;

    sub to_float {
        Corvinus::Types::Number::Number->new_float($_[0]->get_value);
    }

    *to_f = \&to_float;

    sub to_file {
        Corvinus::Types::Glob::File->new($_[0]->get_value);
    }

    sub to_dir {
        Corvinus::Types::Glob::Dir->new($_[0]->get_value);
    }

    sub to_bool {
        Corvinus::Types::Bool::Bool->new($_[0]->get_value);
    }

    sub to_byte {
        Corvinus::Types::Byte::Byte->new(CORE::ord($_[0]->get_value));
    }

    sub to_char {
        Corvinus::Types::Char::Char->call($_[0]->get_value);
    }

    sub to_regex {
        Corvinus::Types::Regex::Regex->new($_[0]->get_value);
    }

    *to_re = \&to_regex;

    sub to_bytes {
        Corvinus::Types::Byte::Bytes->call($_[0]->get_value);
    }

    sub to_chars {
        Corvinus::Types::Char::Chars->call($_[0]->get_value);
    }

    sub to_array {
        Corvinus::Types::Array::Array->new($_[0]);
    }

    sub to_caller {
        Corvinus::Module::OO->__NEW__($_[0]->get_value);
    }

    sub to_fcaller {
        Corvinus::Module::Func->__NEW__($_[0]->get_value);
    }
};

1
