package estructuras::listaDoble::ListaDoble;
use strict;
use warnings;
use estructuras::listaDoble::NodoDoble;
# esta es la que debe llevar el inventario 
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
    my $nuevo = estructuras::listaDoble::NodoDoble->new($valor);

    if (!defined $self->{primero}) {
        $self->{primero} = $nuevo;
        $self->{ultimo}  = $nuevo;
    } else {
        $self->{ultimo}->{siguiente} = $nuevo;
        $nuevo->{anterior} = $self->{ultimo};
        $self->{ultimo} = $nuevo;
    }

    $self->{tamanio}++;
}

sub buscar {
    my ($self, $codigo) = @_;
    my $actual = $self->{primero};

    while (defined $actual) {
        if ($actual->{valor}->codigo() eq $codigo) {
            return $actual->{valor};
        }
        $actual = $actual->{siguiente};
    }
    return undef;
}

sub login {
    my ($self, $id, $pwd) = @_;
    my $actual = $self->{primero};

    while (defined $actual) {
        if ($actual->{valor}->id() eq $id &&
            $actual->{valor}->password() eq $pwd) {
            return 1;
        }
        $actual = $actual->{siguiente};
    }
    return 0;
}

sub imprimir_adelante {
    my ($self) = @_;
    my $actual = $self->{primero};

    while (defined $actual) {
        print $actual->{valor}->to_string(), "\n";
        $actual = $actual->{siguiente};
    }
}

sub imprimir_atras {
    my ($self) = @_;
    my $actual = $self->{ultimo};

    while (defined $actual) {
        print $actual->{valor}->to_string(), "\n";
        $actual = $actual->{anterior};
    }
}

sub generarDotInventario {
    my ($self, $ruta_dot) = @_;

    open(my $fh, ">", $ruta_dot)
        or die "No se pudo crear el archivo DOT ($ruta_dot): $!";

    print $fh "digraph ListaDoble {\n";
    print $fh "rankdir=LR;\n";
    print $fh "node [shape=record fontname=\"Arial\"];\n\n";

    my $actual = $self->{primero};
    my $contador = 0;
    my @ids;

    while ($actual) {

        my $med = $actual->{valor};
        my $id = "Nodo$contador";
        push @ids, $id;

        my $estado = $med->estado_alerta();
        my $color = "palegreen";

        if ($estado eq "BAJO_MINIMO") {
            $color = "lightcoral";
        }
        elsif ($estado eq "PROXIMO_VENCER") {
            $color = "khaki";
        }

        print $fh "$id [style=filled fillcolor=\"$color\" ";
        print $fh "label=\"{ <prev> | ";
        print $fh "{ Codigo: " . $med->codigo() . " | ";
        print $fh "Nombre: " . $med->nombre() . " | ";
        print $fh "Stock: " . $med->cantidad() . " | ";
        print $fh "Vence: " . $med->fecha_vencimiento() . " } | ";
        print $fh "<next> }\"];\n";

        $actual = $actual->{siguiente};
        $contador++;
    }

    print $fh "\n";

    for (my $i = 0; $i < @ids - 1; $i++) {

        # Flecha hacia adelante
        print $fh "$ids[$i]:next -> $ids[$i+1]:prev;\n";

        # Flecha hacia atrás
        print $fh "$ids[$i+1]:prev -> $ids[$i]:next;\n";
    }

    print $fh "}\n";
    close $fh;
}

1;
