package estructuras::listaSimpleCircular::ListaCircular;
use estructuras::listaSimpleCircular::NodoCircular;

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef,
        ultimo  => undef,
        tamanio => 0
    };
    bless $self, $class;
    return $self;
}

sub buscar {
    my ($self, $nit) = @_;

    return undef unless defined $self->{primero};

    my $actual = $self->{primero};

    do {
        my $dato = $actual->{valor};

        if ($dato->nit() eq $nit) {
            return $dato;
        }

        $actual = $actual->{siguiente};

    } while ($actual ne $self->{primero});

    return undef;
}



sub insertar {
    my ($self, $valor) = @_;
    my $nuevo = estructuras::listaSimpleCircular::NodoCircular->new($valor);

    if (!defined $self->{primero}) {
        $self->{primero} = $nuevo;
        $self->{ultimo}  = $nuevo;
        $nuevo->{siguiente} = $nuevo;
    } else {
        $self->{ultimo}->{siguiente} = $nuevo;
        $nuevo->{siguiente} = $self->{primero};
        $self->{ultimo} = $nuevo;
    }
    $self->{tamanio}++;
}

sub mostrar {
    my ($self) = @_;
    return if !defined $self->{primero};

    my $actual = $self->{primero};
    for (my $i = 0; $i < $self->{tamanio}; $i++) {
        print $actual->{valor}->to_string(), "\n";
        $actual = $actual->{siguiente};
    }
}

sub is_empty {
    my ($self) = @_;
    return !defined $self->{primero};
}

sub eliminar_primero {
    my ($self) = @_;

    return undef if !defined $self->{primero};

    my $eliminado = $self->{primero}->{valor};

    if ($self->{tamanio} == 1) {
        $self->{primero} = undef;
        $self->{ultimo}  = undef;
    } else {
        $self->{primero} = $self->{primero}->{siguiente};
        $self->{ultimo}->{siguiente} = $self->{primero};
    }

    $self->{tamanio}--;
    return $eliminado;
}


1;
