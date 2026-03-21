package estructuras::listaDobleCircular::NodoDobleCircular;

sub new {
    my ($class, $valor) = @_;
    my $self = {
        valor     => $valor,
        siguiente => undef,
        anterior  => undef
    };
    bless $self, $class;
    return $self;
}

1;
