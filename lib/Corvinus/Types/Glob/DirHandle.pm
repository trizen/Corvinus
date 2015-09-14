package Corvinus::Types::Glob::DirHandle {

    use utf8;
    use 5.020;
    use experimental qw(signatures);
    use parent qw(Corvinus::Object::Object);

    sub new($, %opt) {
        bless {
               dir_h => $opt{dir_h},
               dir   => $opt{dir},
              },
          __PACKAGE__;
    }

    sub get_value($self) {
        $self->{dir_h};
    }

    sub dir($self) {
        $self->{dir};
    }

    *parent = \&dir;

    sub get_files($self) {
        $self->rewind;

        my @files;
        while (defined(my $file = $self->get_file)) {
            push @files, $file;
        }
        Corvinus::Types::Array::Array->new(@files);
    }

    *intrari = \&get_files;
    *fisiere = \&get_files;

    sub get_file($self) {

        require Encode;
        require File::Spec;

        {
            my $file = CORE::readdir($self->{dir_h}) // return;

            if ($file eq '.' or $file eq '..') {
                redo;
            }

            my $dfile = Encode::decode_utf8($file);
            my $dir = File::Spec->catdir($self->{dir}->get_value, $dfile);

            lstat($dir);
            if (-l _) { redo }
            ;    # ignore links

            return (
                    (-d _)
                    ? Corvinus::Types::Glob::Dir->new($dir)
                    : Corvinus::Types::Glob::File->new(File::Spec->catfile($self->{dir}->get_value, $dfile))
                   );
        }

        return;
    }

    *intrare = \&get_file;
    *fisier = \&get_file;

    sub tell($self) {
        Corvinus::Types::Number::Number->new(telldir($self->{dir_h}));
    }

    sub seek($self, $pos) {
        Corvinus::Types::Bool::Bool->new(seekdir($self->{dir_h}, $pos->get_value));
    }

    sub rewind($self) {
        Corvinus::Types::Bool::Bool->new(rewinddir($self->{dir_h}));
    }

    *deruleaza = \&rewind;

    sub close($self) {
        Corvinus::Types::Bool::Bool->new(closedir($self->{dir_h}));
    }

    *inchide = \&close;

    sub chdir($self) {
        Corvinus::Types::Bool::Bool->new(chdir($self->{dir_h}));
    }

    *schimba = \&chdir;

    sub stat($self) {
        Corvinus::Types::Glob::Stat->stat($self->{dir_h}, $self);
    }

    sub lstat($self) {
        Corvinus::Types::Glob::Stat->lstat($self->{dir_h}, $self);
    }

    sub each($self, $code) {

        require Encode;
        while (defined(my $file = CORE::readdir($self->{dir_h}))) {
            if (defined(my $res = $code->_run_code(Corvinus::Types::String::String->new(Encode::decode_utf8($file))))) {
                return $res;
            }
        }

        $self;
    }

    *fiecare = \&each;
};

1
