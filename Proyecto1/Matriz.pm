package Matriz;
use strict;
use warnings;

our $root_filas = undef;    # Cabecera de medicamentos
our $root_columnas = undef; # Cabecera de laboratorios

# Buscar o crear cabecera
sub obtener_cabecera {
    my ($root, $id) = @_;
    my $actual = $$root;
    
    if (!defined $actual) {
        my $nuevo = Nodo->crear_cabecera($id);
        $$root = $nuevo;
        return $nuevo;
    }
    
    # Buscar si ya existe
    while (defined $actual) {
        return $actual if $actual->{id} eq $id;
        last if !defined $actual->{next};
        $actual = $actual->{next};
    }
    
    # Si no existe, insertar al final
    my $nuevo = Nodo->crear_cabecera($id);
    $actual->{next} = $nuevo;
    $nuevo->{prev} = $actual;
    return $nuevo;
}

sub insertar_valor {
    my ($class, $medicamento, $laboratorio, $nodo_valor) = @_;
    
    my $f = obtener_cabecera(\$root_filas, $medicamento);
    my $c = obtener_cabecera(\$root_columnas, $laboratorio);
    
    # Inserción en Fila (Izquierda a Derecha)
    if (!defined $f->{access}) {
        $f->{access} = $nodo_valor;
    } else {
        my $aux = $f->{access};
        while (defined $aux->{right}) { $aux = $aux->{right}; }
        $aux->{right} = $nodo_valor;
        $nodo_valor->{left} = $aux;
    }
    
    # Inserción en Columna (Arriba hacia Abajo)
    if (!defined $c->{access}) {
        $c->{access} = $nodo_valor;
    } else {
        my $aux = $c->{access};
        while (defined $aux->{down}) { $aux = $aux->{down}; }
        $aux->{down} = $nodo_valor;
        $nodo_valor->{up} = $aux;
    }
}

sub consultar_precios_medicamento {
    my ($class, $nombre_medicamento) = @_;
    
    # 1. Buscar la cabecera de la columna (Medicamento)
    my $col = $root_columnas;
    my $encontrado = 0;

    while (defined $col) {
        if (lc($col->{id}) eq lc($nombre_medicamento)) {
            $encontrado = 1;
            print "\n--- Comparativa de Precios para: " . uc($col->{id}) . " ---\n";
            print sprintf("%-20s | %-10s | %-10s\n", "Laboratorio", "Precio", "Stock");
            print "-" x 45 . "\n";

            # 2. Recorrer hacia abajo (punteros 'down') para ver todos los laboratorios
            my $actual = $col->{access};
            while (defined $actual) {
                # Para saber el nombre del laboratorio, subimos a la cabecera de fila
                # o podemos guardar el nombre del lab en el nodo de valor al insertar.
                # Aquí asumimos que buscamos el nodo de fila correspondiente:
                my $fila_lab = $actual->{up_header}; # Necesitarás este puntero en el nodo

                printf("%-20s | Q%-9.2f | %-10d\n", 
                    $actual->{nombre_lab}, 
                    $actual->{precio}, 
                    $actual->{cantidad});
                
                $actual = $actual->{down};
            }
            last;
        }
        $col = $col->{next};
    }

    if (!$encontrado) {
        print "\nNo se encontraron registros para el medicamento: $nombre_medicamento\n";
    }
}

1;