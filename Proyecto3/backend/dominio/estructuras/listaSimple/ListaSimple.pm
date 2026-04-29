package estructuras::listaSimple::ListaSimple;
use estructuras::listaSimple::NodoSimple;

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef,
        tamanio => 0
    };
    bless $self, $class;
    return $self;
}

sub insertar {
    my ($self, $valor) = @_;

    my $nuevo = estructuras::listaSimple::NodoSimple->new($valor);

    if (!defined $self->{primero}) {
        $self->{primero} = $nuevo;
    } else {
        my $actual = $self->{primero};
        $actual = $actual->{siguiente} while defined $actual->{siguiente};
        $actual->{siguiente} = $nuevo;
    }

    $self->{tamanio}++;
}

sub login {
    my ($self, $id, $pwd) = @_;
    my $actual = $self->{primero};

    while (defined $actual) {
        if ($actual->{valor}->{id} eq $id &&
            $actual->{valor}->{password} eq $pwd) {
            return 1;
        }
        $actual = $actual->{siguiente};
    }
    return 0;
}

sub mostrar {
    my ($self) = @_;
    my $actual = $self->{primero};
    while (defined $actual) {
        print $actual->{valor}, "\n";
        $actual = $actual->{siguiente};
    }
}

1;
