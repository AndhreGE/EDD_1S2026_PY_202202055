package estructuras::matrizDispersa::NodoCelda;

sub new {
    my ($class, $medicamento, $laboratorio, $precio, $cantidad) = @_;

    my $self = {
        medicamento => $medicamento,
        laboratorio => $laboratorio,
        precio      => $precio,
        cantidad    => $cantidad,
        arriba      => undef,
        abajo       => undef,
        izquierda   => undef,
        derecha     => undef
    };

    bless $self, $class;
    return $self;
}

1;
