package Inventario;
use strict;
use warnings;

our $head = undef; # 'our' permite que sea vista desde afuera

sub insertar_ordenado {
    my ($nodo) = @_;
    if (!defined $head) {
        $head = $nodo;
        return;
    }
    if ($nodo->{codigo} lt $head->{codigo}) {
        $nodo->{next} = $head;
        $head->{prev} = $nodo;
        $head = $nodo;
        return;
    }
    my $actual = $head;
    while (defined $actual->{next} && $actual->{next}->{codigo} lt $nodo->{codigo}) {
        $actual = $actual->{next};
    }
    $nodo->{next} = $actual->{next};
    $actual->{next}->{prev} = $nodo if defined $actual->{next};
    $actual->{next} = $nodo;
    $nodo->{prev} = $actual;
}

sub cargar_csv {
    my ($ruta) = @_;
    open(my $fh, '<', $ruta) or do {
        print "Error: No se pudo abrir el archivo '$ruta'\n";
        return;
    };
    
    <$fh>; # Saltar encabezado
    
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/; # Ignora líneas vacías

        my @d = split(',', $line);
        foreach (@d) { s/^\s+|\s+$//g; } # Limpieza de espacios

        # VALIDACIÓN: Verificar que la línea tenga los 8 campos requeridos
        if (scalar(@d) == 8) {
            # VALIDACIÓN: Precio (índice 4) y Cantidad (índice 5) deben ser números
            # Usamos la función de validación que definimos antes
            if (es_numero_valido($d[4]) && es_numero_valido($d[5])) {
                my $nuevo = Nodo->crear_medicamento(@d);
                insertar_ordenado($nuevo);
            } else {
                print "Aviso: Datos numericos invalidos en linea: $line\n";
            }
        } else {
            print "Aviso: Linea con formato incorrecto (se esperan 8 campos): $line\n";
        }
    }
    close($fh);
    print "Carga masiva finalizada correctamente.\n";
}

sub buscar_medicamento {
    my ($busqueda) = @_;
    my $actual = $head;
    my $encontrado = 0;

    if (!defined $actual) {
        print "\nEl inventario esta vacio.\n";
        return;
    }

    while (defined $actual) {
        # Comparamos ignorando mayúsculas/minúsculas (lc = lower case)
        if (lc($actual->{codigo}) eq lc($busqueda) || lc($actual->{nombre}) eq lc($busqueda)) {
            print "\n--- Medicamento Encontrado ---";
            print "\nNombre:    $actual->{nombre}";
            print "\nCantidad:  $actual->{cantidad}";
            
            # Alerta si está por debajo del nivel mínimo [cite: 141]
            if ($actual->{cantidad} < $actual->{nivel_min}) {
                print "\nAVISO: Stock bajo. Tiempo estimado de reabastecimiento: 24hrs.";
            }
            print "\n-----------------------------\n";
            $encontrado = 1;
            last; # Salimos del ciclo al encontrarlo
        }
        $actual = $actual->{next};
    }

    if (!$encontrado) {
        print "\nNo se encontro ningun medicamento con el criterio: $busqueda\n";
    }
}


sub descontar_stock {
    my ($criterio, $cantidad_a_quitar) = @_;
    my $actual = $head;

    while (defined $actual) {
        if (lc($actual->{codigo}) eq lc($criterio) || lc($actual->{nombre}) eq lc($criterio)) {
            if ($actual->{cantidad} >= $cantidad_a_quitar) {
                $actual->{cantidad} -= $cantidad_a_quitar;
                return 1; # Éxito
            } else {
                print "\nError: Stock insuficiente en inventario (Disponible: $actual->{cantidad}).";
                return 0; # Falla
            }
        }
        $actual = $actual->{next};
    }
    print "\nError: El medicamento '$criterio' no existe en el inventario.";
    return 0;
}

# Agregar esto al final de Inventario.pm (antes del 1;)
sub visualizar_consola {
    my ($class, $actual) = @_;
    
    # Si no recibe un nodo por parámetro, usa el head global del módulo
    $actual = $head if !defined $actual;

    print "\n" . "=" x 65 . "\n";
    printf("%-10s | %-15s | %-8s | %-10s | %-10s\n", 
        "CODIGO", "NOMBRE", "STOCK", "ESTADO", "VENCE");
    print "-" x 65 . "\n";

    if (!defined $actual) {
        print "   EL INVENTARIO SE ENCUENTRA VACIO ACTUALMENTE\n";
    }

    while (defined $actual) {
        my $estado = ($actual->{cantidad} < $actual->{nivel_min}) ? "BAJO" : "OK";
        
        printf("%-10s | %-15s | %-8d | %-10s | %-10s\n",
            $actual->{codigo},
            $actual->{nombre},
            $actual->{cantidad},
            $estado,
            $actual->{fecha_venc});
        
        $actual = $actual->{next};
    }
    print "=" x 65 . "\n";
}

# --- AGREGAR ESTA FUNCIÓN AL FINAL DE Inventario.pm ---
sub es_numero_valido {
    my ($valor) = @_;
    # Verifica que sea un número (entero o decimal)
    if (defined $valor && $valor =~ /^\d+(\.\d+)?$/) {
        return 1;
    }
    return 0;
}

1; # Final del archivoper