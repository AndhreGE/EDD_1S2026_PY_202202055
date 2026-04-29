package reportes::generarProveedores;

use strict;
use warnings;

sub generar {
    

    my ($proveedores, $ruta_dot) = @_;
    $ruta_dot ||= "proveedores.dot";

    my $ruta_png = $ruta_dot;
    $ruta_png =~ s/\.dot$/.png/;

    open(my $fh, '>', $ruta_dot) or die "No se pudo crear el archivo DOT";

    print $fh "digraph Proveedores {\n";
    print $fh "rankdir=LR;\n";
    print $fh "node [shape=box];\n";

    return unless defined $proveedores->{primero};

    my $actual = $proveedores->{primero};
    my $contador = 0;

    # --------------- CLUSTERS -----------------
    my $temp = $proveedores->{primero};
        print "Primer proveedor NIT: ", $temp->{valor}->nit(), "\n";
        print "Entregas tamaño en DOT: ",
        $temp->{valor}->entregas()->{tamanio}, "\n";

    do {

        my $prov = $actual->{valor};
        my $prov_id = "P$contador";

        print $fh "subgraph cluster_$contador {\n";
        print $fh "label=\"Proveedor: " . $prov->nit() . "\\n" . $prov->contacto() . "\";\n";
        print $fh "style=rounded;\n";

        print $fh "$prov_id [shape=box, style=filled, fillcolor=lightblue];\n";

        my $entregas = $prov->entregas();
        my $e_actual = $entregas->{primero};
        my $e_count = 0;
        my $anterior = "";

        while ($e_actual) {

            my $ent = $e_actual->{valor};
            my $ent_id = "E${contador}_$e_count";

            print $fh "$ent_id [label=\"Factura: "
                . $ent->{factura}
                . "\\nCod: "
                . $ent->{codigo_medicamento}
                . "\\nCant: "
                . $ent->{cantidad}
                . "\", shape=ellipse];\n";

            if ($e_count == 0) {
                print $fh "$prov_id -> $ent_id;\n";
            }

            if ($anterior ne "") {
                print $fh "$anterior -> $ent_id;\n";
            }

            $anterior = $ent_id;
            $e_actual = $e_actual->{siguiente};
            $e_count++;
        }

        print $fh "}\n";

        $actual = $actual->{siguiente};
        $contador++;

    } while ($actual ne $proveedores->{primero});

    # --------- Enlaces circulares ---------
    $actual = $proveedores->{primero};
    $contador = 0;

    do {
        my $actual_id = "P$contador";
        my $sig_id = "P" . (($contador + 1) % $proveedores->{tamanio});

        print $fh "$actual_id -> $sig_id [color=red];\n";

        $actual = $actual->{siguiente};
        $contador++;

    } while ($actual ne $proveedores->{primero});

    print $fh "}\n";
    close($fh);

    # -------------- GENERAR PNG -----------------

    my $resultado = system("dot -Tpng \"$ruta_dot\" -o \"$ruta_png\"");

    if ($resultado == 0) {
        print "PNG generado correctamente: $ruta_png\n";
    } else {
        print "Error al ejecutar Graphviz. Verifica que 'dot' esté instalado y en el PATH.\n";
    }
}

1;
