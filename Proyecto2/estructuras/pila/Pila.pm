package estructuras::pila::Pila;
use estructuras::pila::NodoPila;

sub new {
    my $class = @_;
    my $self = {
        cima    => undef,
        tamanio => 0
    };
    bless $self, $class;
    return $self;
}

sub push {
    my ($self, $valor) = @_;
    my $nuevo = NodoPila->new($valor);
    $nuevo->{abajo} = $self->{cima};
    $self->{cima} = $nuevo;
    $self->{tamanio}++;
}

sub pop {
    my $self = @_;
    return undef unless defined $self->{cima};

    my $valor = $self->{cima}->{valor};
    $self->{cima} = $self->{cima}->{abajo};
    $self->{tamanio}--;
    return $valor;
}

sub peek {
    my $self = @_;
    return undef unless defined $self->{cima};
    return $self->{cima}->{valor};
}

sub is_empty {
    my $self = @_;
    return !defined $self->{cima};
}

sub mostrar {
    my $self = @_;
    my $actual = $self->{cima};

    if (!defined $actual) {
        print "La pila está vacía\n";
        return;
    }

    while (defined $actual) {
        print $actual->{valor}, "\n";
        $actual = $actual->{abajo};
    }
}

1;
