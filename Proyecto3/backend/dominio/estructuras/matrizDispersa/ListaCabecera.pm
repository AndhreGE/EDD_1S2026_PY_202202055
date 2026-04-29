package estructuras::matrizDispersa::ListaCabecera;

use estructuras::matrizDispersa::NodoCabecera;

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

sub obtenerCabecera {
    my ($self, $id) = @_;
    my $actual = $self->{primero};

    while ($actual) {
        return $actual if $actual->{id} eq $id;
        $actual = $actual->{siguiente};
    }

    return undef;
}

sub insertarCabecera {
    my ($self, $id) = @_;

    # evitar duplicados
    my $existe = $self->obtenerCabecera($id);
    return $existe if $existe;

    my $nuevo = estructuras::matrizDispersa::NodoCabecera->new($id);

    if (!$self->{primero}) {
        $self->{primero} = $nuevo;
        $self->{ultimo}  = $nuevo;
    }
    elsif ($id lt $self->{primero}->{id}) {
        $nuevo->{siguiente} = $self->{primero};
        $self->{primero}->{anterior} = $nuevo;
        $self->{primero} = $nuevo;
    }
    else {
        my $actual = $self->{primero};
        while ($actual->{siguiente} && $id gt $actual->{siguiente}->{id}) {
            $actual = $actual->{siguiente};
        }

        $nuevo->{siguiente} = $actual->{siguiente};
        $nuevo->{anterior}  = $actual;

        $actual->{siguiente}->{anterior} = $nuevo if $actual->{siguiente};
        $actual->{siguiente} = $nuevo;

        $self->{ultimo} = $nuevo unless $nuevo->{siguiente};
    }

    $self->{tamanio}++;
    return $nuevo;
}

1;
