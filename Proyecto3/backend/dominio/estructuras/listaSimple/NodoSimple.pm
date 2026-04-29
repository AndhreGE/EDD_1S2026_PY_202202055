package estructuras::listaSimple::NodoSimple;

sub new {
    my ($class, $valor) = @_;
    my $self = {
        valor     => $valor,
        siguiente => undef
    };
    bless $self, $class;
    return $self;
}

1;
