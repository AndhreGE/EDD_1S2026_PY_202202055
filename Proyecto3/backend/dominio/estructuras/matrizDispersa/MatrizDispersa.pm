package estructuras::matrizDispersa::MatrizDispersa;

use estructuras::matrizDispersa::ListaCabecera;
use estructuras::matrizDispersa::NodoCelda;

sub new {
    my ($class) = @_;

    my $self = {
        filas    => estructuras::matrizDispersa::ListaCabecera->new(),
        columnas => estructuras::matrizDispersa::ListaCabecera->new()
    };

    bless $self, $class;
    return $self;
}
sub insertar {
    my ($self, $medicamento, $laboratorio, $precio, $cantidad) = @_;

    # Buscar cabeceras
    my $cabFila = $self->{filas}->insertarCabecera($medicamento);
    my $cabCol  = $self->{columnas}->insertarCabecera($laboratorio);

    # Verificar si la celda ya existe
    my $actual = $cabFila->{acceso};
    while ($actual) {
        if ($actual->{laboratorio} eq $laboratorio) {
            $actual->{precio}   = $precio;
            $actual->{cantidad} = $cantidad;
            return;
        }
        $actual = $actual->{derecha};
    }

    # Crear nueva celda
    my $nuevo = estructuras::matrizDispersa::NodoCelda
        ->new($medicamento, $laboratorio, $precio, $cantidad);

    # ---- INSERTAR EN FILA ----
    if (!$cabFila->{acceso}) {
        $cabFila->{acceso} = $nuevo;
    } else {
        my $actual = $cabFila->{acceso};
        if ($laboratorio lt $actual->{laboratorio}) {
            $nuevo->{derecha} = $actual;
            $actual->{izquierda} = $nuevo;
            $cabFila->{acceso} = $nuevo;
        } else {
            while ($actual->{derecha}
                   && $laboratorio gt $actual->{derecha}->{laboratorio}) {
                $actual = $actual->{derecha};
            }

            $nuevo->{derecha} = $actual->{derecha};
            $nuevo->{izquierda} = $actual;

            $actual->{derecha}->{izquierda} = $nuevo if $actual->{derecha};
            $actual->{derecha} = $nuevo;
        }
    }

    # ---- INSERTAR EN COLUMNA ----
    if (!$cabCol->{acceso}) {
        $cabCol->{acceso} = $nuevo;
    } else {
        my $actual = $cabCol->{acceso};
        if ($medicamento lt $actual->{medicamento}) {
            $nuevo->{abajo} = $actual;
            $actual->{arriba} = $nuevo;
            $cabCol->{acceso} = $nuevo;
        } else {
            while ($actual->{abajo}
                   && $medicamento gt $actual->{abajo}->{medicamento}) {
                $actual = $actual->{abajo};
            }

            $nuevo->{abajo} = $actual->{abajo};
            $nuevo->{arriba} = $actual;

            $actual->{abajo}->{arriba} = $nuevo if $actual->{abajo};
            $actual->{abajo} = $nuevo;
        }
    }
}
sub consultarMedicamento {
    my ($self, $medicamento) = @_;

    my $cabFila = $self->{filas}->obtenerCabecera($medicamento);
    return unless $cabFila;

    my $actual = $cabFila->{acceso};

    while ($actual) {
        print "Laboratorio: ", $actual->{laboratorio}, "\n";
        print "Precio: Q", $actual->{precio}, "\n";
        print "Cantidad: ", $actual->{cantidad}, "\n";
        print "-------------------------\n";

        $actual = $actual->{derecha};
    }
}

sub generarDot {
    my ($self, $ruta_dot) = @_;

    open(my $fh, ">", $ruta_dot) or die "No se pudo crear el archivo DOT";

    print $fh "digraph G {\n";
    print $fh "rankdir=TB;\n";
    print $fh "graph [pad=\"0.6\", nodesep=\"0.8\", ranksep=\"1\"];\n";
    print $fh "node [shape=box, height=0.8, fontname=\"Arial\"];\n";
    print $fh "edge [fontname=\"Arial\"];\n\n";

    my $clean = sub {
        my $id = shift;
        $id =~ s/\s+/_/g;
        $id =~ s/[^A-Za-z0-9_]/_/g;
        return $id;
    };

    
    # 1. Raiz de la matriz
    
    print $fh "\tRaiz [label=\"\" width=0.3 shape=point];\n";

    # 2. COLUMNAS ARRIBA   
    my $colActual = $self->{columnas}->{primero};
    my @columnasIDs;
    my %grupoColumna;
    my $grupo = 1;

    while ($colActual) {

        my $colID = "Col_" . $clean->($colActual->{id});
        push @columnasIDs, $colID;
        $grupoColumna{$colActual->{id}} = $grupo;

        print $fh "\t$colID [label=\"$colActual->{id}\" group=$grupo];\n";

        $grupo++;
        $colActual = $colActual->{siguiente};
    }

    # Alinear columnas arriba
    print $fh "\t{ rank=same; Raiz; " . join("; ", @columnasIDs) . "; }\n";

    # Conexión horizontal columnas
    for (my $i = 0; $i < @columnasIDs - 1; $i++) {
        print $fh "\t$columnasIDs[$i] -> $columnasIDs[$i+1] [dir=both];\n";
    }

    print $fh "\tRaiz -> $columnasIDs[0] [dir=both];\n\n"
        if @columnasIDs;

    # 3. FILAS IZQUIERDA
    my $filaActual = $self->{filas}->{primero};
    my @filasIDs;

    while ($filaActual) {

        my $filaID = "Fila_" . $clean->($filaActual->{id});
        push @filasIDs, $filaID;

        print $fh "\t$filaID [label=\"$filaActual->{id}\" group=0];\n";

        $filaActual = $filaActual->{siguiente};
    }

    # Conexión vertical filas
    for (my $i = 0; $i < @filasIDs - 1; $i++) {
        print $fh "\t$filasIDs[$i] -> $filasIDs[$i+1] [dir=both];\n";
    }

    print $fh "\tRaiz -> $filasIDs[0] [dir=both];\n\n"
        if @filasIDs;

    # 4. NODOS INTERNOS
    $filaActual = $self->{filas}->{primero};

    while ($filaActual) {

        my $filaID = "Fila_" . $clean->($filaActual->{id});
        my $actual = $filaActual->{acceso};

        print $fh "\t{ rank=same; $filaID; ";

        my $primero = 1;

        while ($actual) {

            my $nombre = "Nodo_"
                . $clean->($actual->{medicamento})
                . "_"
                . $clean->($actual->{laboratorio});

            my $grupoNodo = $grupoColumna{$actual->{laboratorio}};

            print $fh "\t$nombre [shape=circle group=$grupoNodo label=\"Q$actual->{precio}\\nCant:$actual->{cantidad}\"];\n";

            print $fh "$nombre; ";

            # Conectar fila al primer nodo
            if ($primero) {
                print $fh "\t$filaID -> $nombre [dir=both];\n";
                $primero = 0;
            }

            # Horizontal
            if ($actual->{derecha}) {
                my $der = "Nodo_"
                    . $clean->($actual->{derecha}->{medicamento})
                    . "_"
                    . $clean->($actual->{derecha}->{laboratorio});

                print $fh "\t$nombre -> $der [dir=both];\n";
            }

            $actual = $actual->{derecha};
        }

        print $fh "}\n";
        $filaActual = $filaActual->{siguiente};
    }

    # 5. CONEXIONES VERTICALES

    $colActual = $self->{columnas}->{primero};

    while ($colActual) {

        my $colID = "Col_" . $clean->($colActual->{id});
        my $actual = $colActual->{acceso};

        my $primero = 1;

        while ($actual) {

            my $nombre = "Nodo_"
                . $clean->($actual->{medicamento})
                . "_"
                . $clean->($actual->{laboratorio});

            if ($primero) {
                print $fh "\t$colID -> $nombre [dir=both];\n";
                $primero = 0;
            }

            if ($actual->{abajo}) {
                my $abajo = "Nodo_"
                    . $clean->($actual->{abajo}->{medicamento})
                    . "_"
                    . $clean->($actual->{abajo}->{laboratorio});

                print $fh "\t$nombre -> $abajo [dir=both];\n";
            }

            $actual = $actual->{abajo};
        }

        $colActual = $colActual->{siguiente};
    }

    print $fh "}\n";
    close $fh;
}

1;
