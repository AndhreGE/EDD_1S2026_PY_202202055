package Proveedores;
use strict;
use warnings;

# 'our' permite que la variable sea accesible desde medtrack.pl
our $head_proveedores = undef;

sub insertar_proveedor {
    my ($class, $nuevo) = @_;

    if (!defined $head_proveedores) {
        $head_proveedores = $nuevo;
        $nuevo->{next} = $head_proveedores; # Apunta a sí mismo (Círculo)
    } else {
        my $actual = $head_proveedores;
        # Buscar el último nodo (el que apunta al head)
        while ($actual->{next} != $head_proveedores) {
            $actual = $actual->{next};
        }
        $actual->{next} = $nuevo;
        $nuevo->{next} = $head_proveedores; # Cierra el círculo
    }
}

sub registrar_entrega {
    my ($class, $nit_prov, $entrega) = @_;
    return if !defined $head_proveedores;

    my $actual = $head_proveedores;
    do {
        if ($actual->{nit} eq $nit_prov) {
            # Insertar en la lista simple de este proveedor
            if (!defined $actual->{lista_entregas}) {
                $actual->{lista_entregas} = $entrega;
            } else {
                my $aux = $actual->{lista_entregas};
                while (defined $aux->{next}) { $aux = $aux->{next}; }
                $aux->{next} = $entrega;
            }
            return;
        }
        $actual = $actual->{next};
    } while ($actual != $head_proveedores);
}

sub registrar_entrega {
    my ($class, $nit_prov, $fecha, $factura, $codigo, $cantidad) = @_;
    
    my $actual = $head_proveedores;
    return if !defined $actual;

    do {
        if ($actual->{nit} eq $nit_prov) {
            # Crear el nuevo nodo de entrega usando tu módulo Nodo
            my $nueva_entrega = Nodo->crear_entrega($fecha, $factura, $codigo, $cantidad);
            
            # Insertar al inicio de la lista simple de entregas del proveedor
            $nueva_entrega->{next} = $actual->{lista_entregas};
            $actual->{lista_entregas} = $nueva_entrega;
            print "Entrega registrada para el proveedor: $actual->{nombre}\n";
            return 1;
        }
        $actual = $actual->{next};
    } while ($actual != $head_proveedores);
    
    print "Proveedor con NIT $nit_prov no encontrado.\n";
    return 0;
}

sub historial_transacciones {
    my $prov = $Proveedores::head_proveedores;
    return print "No hay proveedores registrados.\n" if !defined $prov;

    print "\n--- HISTORIAL DE ENTREGAS ---\n";
    do {
        my $entrega = $prov->{lista_entregas};
        while (defined $entrega) {
            printf("Proveedor: %-15s | Factura: %-10s | Cod: %-8s | Cant: %-5d\n",
                $prov->{nombre}, $entrega->{factura}, $entrega->{codigo}, $entrega->{cantidad});
            $entrega = $entrega->{next};
        }
        $prov = $prov->{next};
    } while ($prov != $Proveedores::head_proveedores);
}

1;