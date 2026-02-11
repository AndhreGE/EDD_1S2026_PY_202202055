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

1;