package Corvinus::Time::Time {

    use 5.014;
    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload
      q{""}   => \&get_value,
      q{bool} => \&get_value;

    sub new {
        my (undef, $sec) = @_;

        if (defined($sec)) {
            if (ref($sec)) {
                $sec = $sec->get_value;
            }
            elsif ($sec eq '__INIT__') {
                undef $sec;
            }
        }
        else {
            $sec = time;
        }

        bless \$sec, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]} // CORE::time;
    }

    sub time {
        my ($self) = @_;
        Corvinus::Types::Number::Number->new($self->get_value);
    }

    *sec = \&time;

    sub timeNow {
        Corvinus::Types::Number::Number->new(CORE::time);
    }

    *now      = \&timeNow;
    *time_now = \&timeNow;

    sub microTime {
        my ($self) = @_;
        state $x = require Time::HiRes;
        Corvinus::Types::Number::Number->new(scalar Time::HiRes::gettimeofday());
    }

    *micro         = \&microTime;
    *micro_sec     = \&microTime;
    *microSec      = \&microTime;
    *microSeconds  = \&microTime;
    *micro_seconds = \&microTime;

    sub localtime {
        my ($self) = @_;
        Corvinus::Time::Localtime->new($self->get_value);
    }

    *local     = \&localtime;
    *localTime = \&localtime;

    sub gmtime {
        my ($self) = @_;
        Corvinus::Time::Gmtime->new($self->get_value);
    }

    *gmTime = \&gmtime;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Time.new(' . $self->get_value . ')');
    }

};

1;
