package estructuras::listaDobleCircular::ListaDobleCircular;
use estructuras::listaDobleCircular::NodoDobleCircular;

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

sub insertar {
    my ($self, $valor) = @_;
    my $nuevo = estructuras::listaDobleCircular::NodoDobleCircular->new($valor);

    if (!defined $self->{primero}) {
        $self->{primero} = $nuevo;
        $self->{ultimo}  = $nuevo;
        $nuevo->{siguiente} = $nuevo;
        $nuevo->{anterior}  = $nuevo;
    } else {
        $nuevo->{anterior} = $self->{ultimo};
        $nuevo->{siguiente} = $self->{primero};
        $self->{ultimo}->{siguiente} = $nuevo;
        $self->{primero}->{anterior} = $nuevo;
        $self->{ultimo} = $nuevo;
    }
    $self->{tamanio}++;
}

sub mostrar {
    my $self = shift;
    return if !defined $self->{primero};

    my $actual = $self->{primero};

    for (my $i = 0; $i < $self->{tamanio}; $i++) {

        print $actual->{valor}->to_string(), "\n";

        $actual = $actual->{siguiente};
    }
}



sub buscar {
    my ($self, $id) = @_;
    return undef if !defined $self->{primero};

    my $actual = $self->{primero};
    for (my $i = 0; $i < $self->{tamanio}; $i++) {
        return $actual->{valor} if $actual->{valor}->{id} eq $id;
        $actual = $actual->{siguiente};
    }
    return undef;
}

sub is_empty {
    my ($self) = @_;
    return !defined $self->{primero};
}

sub obtener_primero {
    my ($self) = @_;
    return undef if !defined $self->{primero};
    return $self->{primero}->{valor};
}

sub eliminar_primero {
    my ($self) = @_;
    return undef if !defined $self->{primero};

    my $eliminado = $self->{primero}->{valor};

    if ($self->{tamanio} == 1) {
        $self->{primero} = undef;
        $self->{ultimo}  = undef;
    } else {
        my $nuevo_primero = $self->{primero}->{siguiente};

        $nuevo_primero->{anterior} = $self->{ultimo};
        $self->{ultimo}->{siguiente} = $nuevo_primero;

        $self->{primero} = $nuevo_primero;
    }

    $self->{tamanio}--;
    return $eliminado;
}

sub generarDotSolicitudesPendientes {
    my ($self, $ruta_dot) = @_;

    open(my $fh, ">", $ruta_dot)
        or die "No se pudo crear el archivo DOT ($ruta_dot): $!";

    print $fh "digraph ListaCircularDoble {\n";
    print $fh "rankdir=LR;\n";
    print $fh "node [shape=circle fontname=\"Arial\"];\n\n";

    my $actual = $self->{primero};
    my @ids;
    my $index = 0;
    my $contador = 0;

    if ($actual) {
        do {

            my $sol = $actual->{valor};

            if ($sol->estado() eq "PENDIENTE") {

                my $id = "Nodo$index";
                push @ids, $id;

                print $fh "$id [label=\"";
                print $fh "ID: " . $sol->{id} . "\\n";
                print $fh "Cod: " . $sol->codigo() . "\\n";
                print $fh "Cant: " . $sol->cantidad();
                print $fh "\"];\n";

                $index++;
                $contador++;
            }

            $actual = $actual->{siguiente};

        } while ($actual && $actual != $self->{primero});
    }

    print $fh "\n";

    # Conexiones circulares dobles
    my $total = scalar(@ids);

    for (my $i = 0; $i < $total; $i++) {

        my $sig = ($i + 1) % $total;

        # Flecha adelante
        print $fh "$ids[$i] -> $ids[$sig];\n";

        # Flecha atrás
        print $fh "$ids[$sig] -> $ids[$i];\n";
    }

    print $fh "\n";

    print $fh "Total [shape=box label=\"Solicitudes pendientes: $contador\"];\n";

    print $fh "}\n";
    close $fh;
}


1;
