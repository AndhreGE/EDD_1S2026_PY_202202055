package estructuras::matrizDispersa::NodoCabecera;

sub new {
    my ($class, $id) = @_;

    my $self = {
        id        => $id,
        siguiente => undef,
        anterior  => undef,
        acceso    => undef
    };

    bless $self, $class;
    return $self;
}

1;
