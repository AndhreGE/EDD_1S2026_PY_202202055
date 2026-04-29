package estructuras::pila::NodoPila;

sub new {
    my ($class, $valor) = @_;
    my $self = {
        valor => $valor,
        abajo => undef
    };
    bless $self, $class;
    return $self;
}

1;
