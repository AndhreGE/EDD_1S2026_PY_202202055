package Reportes;
use strict;
use warnings;

# Función para el reporte de la Lista Doblemente Enlazada (Inventario)
sub generar_inventario {
    my ($class, $head) = @_;
    my $nombre_dot = "reporte_inventario.dot";
    my $nombre_png = "reporte_inventario.png";

    open(my $dot, '>', $nombre_dot) or die "Error al crear archivo dot";
    
    print $dot "digraph G {\n";
    print $dot "  rankdir=LR;\n";
    print $dot "  node [shape=record, style=filled, fillcolor=white];\n";
    print $dot "  label=\"Inventario - EDD MedTrack\";\n";

    my $actual = $head;
    my $id = 0;

    while (defined $actual) {
        # Lógica de colores según enunciado: Rojo (bajo stock), Amarillo (próximo a vencer), Verde (normal) [cite: 157]
        my $color = "green";
        if ($actual->{cantidad} < $actual->{nivel_min}) {
            $color = "red";
        }

        # Nodo con formato de registro [cite: 152, 155]
        print $dot "  nodo$id [fillcolor=$color, label=\"{Cod: $actual->{codigo} | $actual->{nombre} | Cant: $actual->{cantidad} | Vence: $actual->{fecha_venc}}\"];\n";

        # Flechas bidireccionales [cite: 153, 155]
        if (defined $actual->{next}) {
            my $sig = $id + 1;
            print $dot "  nodo$id -> nodo$sig [dir=both];\n";
        }

        $actual = $actual->{next};
        $id++;
    }

    print $dot "}\n";
    close($dot);
    
    # Ejecución del comando dot en el sistema [cite: 230]
    system("dot -Tpng $nombre_dot -o $nombre_png");
}

# Función para la Lista Circular de Listas (Proveedores)
sub generar_proveedores {
    my ($class, $head_prov) = @_;
    return if !defined $head_prov;

    my $nombre_dot = "reporte_proveedores.dot";
    my $nombre_png = "reporte_proveedores.png";

    open(my $dot, '>', $nombre_dot) or die "Error al crear archivo dot";
    
    print $dot "digraph G {\n";
    print $dot "  rankdir=TB;\n"; # Orientación arriba-abajo para las sublistas
    print $dot "  node [shape=box];\n";
    print $dot "  label=\"Proveedores y Entregas\";\n";

    my $p = $head_prov;
    my $p_id = 0;

    # Recorrido de lista circular [cite: 180]
    do {
        # Nodo del proveedor
        print $dot "  prov$p_id [label=\"NIT: $p->{nit}\\n$p->{nombre}\", style=bold];\n";

        # Conectar con el siguiente proveedor (Circular) [cite: 180, 185]
        my $sig_p = $p_id + 1;
        # Si es el último, apunta al primero
        if ($p->{next} == $head_prov) {
            print $dot "  prov$p_id -> prov0 [constraint=false];\n";
        } else {
            print $dot "  prov$p_id -> prov$sig_p;\n";
        }

        # Graficar sublista de entregas (vertical) [cite: 181, 184]
        my $e = $p->{lista_entregas};
        my $e_id = 0;
        if (defined $e) {
            # Conexión del proveedor a su primera entrega
            print $dot "  prov$p_id -> ent_${p_id}_0;\n";
            
            while (defined $e) {
                print $dot "  ent_${p_id}_$e_id [label=\"Fact: $e->{factura}\\nCant: $e->{cantidad}\", shape=ellipse];\n";
                
                if (defined $e->{next}) {
                    my $sig_e = $e_id + 1;
                    print $dot "  ent_${p_id}_$e_id -> ent_${p_id}_$sig_e;\n";
                }
                $e = $e->{next};
                $e_id++;
            }
        }

        $p = $p->{next};
        $p_id++;
    } while ($p != $head_prov);

    print $dot "}\n";
    close($dot);
    system("dot -Tpng $nombre_dot -o $nombre_png");
}

# En Reportes.pm
sub generar_solicitudes {
    my ($class, $head) = @_;
    return if !defined $head;

    my $nombre_dot = "reporte_solicitudes.dot";
    my $nombre_png = "reporte_solicitudes.png";

    open(my $dot, '>', $nombre_dot);
    print $dot "digraph G {\n";
    print $dot "  rankdir=LR;\n";
    print $dot "  node [shape=circle];\n"; # Nodos circulares según el PDF
    print $dot "  label=\"Solicitudes Pendientes: $Solicitudes::contador_solicitudes\";\n";

    my $actual = $head;
    my $id = 0;
    do {
        print $dot "  sol$id [label=\"No. $actual->{numero}\\n$actual->{depto}\\n$actual->{med}\"];\n";
        
        my $sig = $id + 1;
        # Flechas bidireccionales
        if ($actual->{next} == $head) {
            print $dot "  sol$id -> sol0 [dir=both, constraint=false];\n";
        } else {
            print $dot "  sol$id -> sol$sig [dir=both];\n";
        }
        
        $actual = $actual->{next};
        $id++;
    } while ($actual != $head);

    print $dot "}\n";
    close($dot);
    system("dot -Tpng $nombre_dot -o $nombre_png");
}

1;