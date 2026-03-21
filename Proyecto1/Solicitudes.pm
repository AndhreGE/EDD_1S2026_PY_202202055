package Solicitudes;
use strict;
use warnings;

our $head_solicitudes = undef;
our $contador_solicitudes = 0;

sub insertar_solicitud {
    my ($class, $nuevo) = @_;
    $contador_solicitudes++;

    if (!defined $head_solicitudes) {
        $head_solicitudes = $nuevo;
        $nuevo->{next} = $head_solicitudes;
        $nuevo->{prev} = $head_solicitudes;
    } else {
        my $ultimo = $head_solicitudes->{prev};
        
        # El nuevo nodo se inserta entre el último y el primero
        $nuevo->{next} = $head_solicitudes;
        $nuevo->{prev} = $ultimo;
        
        $ultimo->{next} = $nuevo;
        $head_solicitudes->{prev} = $nuevo;
    }
}

# Función para que el administrador "procese" (elimine) la primera solicitud
sub atender_solicitud {
    return if !defined $head_solicitudes;
    
    if ($head_solicitudes->{next} == $head_solicitudes) {
        $head_solicitudes = undef;
    } else {
        my $ultimo = $head_solicitudes->{prev};
        my $siguiente = $head_solicitudes->{next};
        
        $siguiente->{prev} = $ultimo;
        $ultimo->{next} = $siguiente;
        $head_solicitudes = $siguiente;
    }
    $contador_solicitudes--;
}

sub procesar_reabastecimiento {
    my $solicitud = $Solicitudes::head_solicitudes;
    return print "No hay solicitudes pendientes.\n" if !defined $solicitud;

    # 1. Buscar el medicamento en la Lista Doblemente Enlazada (Inventario)
    my $actual = $Inventario::head;
    my $encontrado = 0;
    while (defined $actual) {
        if ($actual->{nombre} eq $solicitud->{med}) {
            # 2. Aumentar el stock
            $actual->{cantidad} += $solicitud->{cantidad};
            print "Reabastecimiento completado: $solicitud->{med} +$solicitud->{cantidad}\n";
            $encontrado = 1;
            last;
        }
        $actual = $actual->{next};
    }

    if ($encontrado) {
        # 3. Eliminar la solicitud ya procesada (Atender)
        Solicitudes->atender_solicitud();
    } else {
        print "Error: El medicamento solicitado no existe en el inventario.\n";
    }
}

1;