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

1;