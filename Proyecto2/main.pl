use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use estructuras::listaDoble::ListaDoble;
use estructuras::listaDobleCircular::ListaDobleCircular;
use estructuras::listaSimple::ListaSimple;
use estructuras::listaSimpleCircular::ListaCircular;
use estructuras::pila::Pila;
use modelos::Medicamento;
use modelos::Solicitud;
use modelos::Proveedor;
use modelos::Entrega;
use reportes::generarProveedores;
use estructuras::modulos::Inventario;


my $listaMedicamentos = estructuras::listaDoble::ListaDoble->new();
my $listaProveedores  = estructuras::listaSimpleCircular::ListaCircular->new();

my $inventario = estructuras::modulos::Inventario->new(
    $listaMedicamentos,
    $listaProveedores
);


our $solicitudes  = estructuras::listaDobleCircular::ListaDobleCircular->new();  # Solicitudes pendientes
our $usuarios     = estructuras::listaSimple::ListaSimple->new();         # Usuarios
our $procesadas  = estructuras::listaSimpleCircular::ListaCircular->new();      # Historial




sub menu_principal {
    print "\n";
    print "----- ********* PROYECTO 1 - ESTRUCTURAS DE DATOS 0772 ********* -----\n";
    print "\n EDD MedTrack \n";
    print "1. Administrador\n";
    print "2. Usuario Departamental\n";
    print "3. Salir\n";
    print "Seleccione una opcion: ";
}
# SOLO ADMINS
sub menu_admin {
    print "\n--- MENU ADMINISTRADOR ---\n";
    print "1. Registrar medicamento\n";
    print "2. Ver inventario\n";
    print "3. Ver solicitudes pendientes\n";
    print "4. Procesar siguiente solicitud\n";
    print "5. Ver historial de solicitudes\n";
    print "6. Cargar medicamentos desde CSV\n";
    print "7. Gestionar proveedores\n";
    print "8. Generar reporte inventario\n";
    print "9. Salir\n";
    print "Seleccione una opcion: ";
}
sub menu_proveedores {
    print "\n--- GESTION DE PROVEEDORES ---\n";
    print "1. Registrar proveedor\n";
    print "2. Registrar entrega de proveedor\n";
    print "3. Ver proveedores\n";
    print "4. Volver\n";
    print "Seleccione una opcion: ";
}

# PARA LOS USUARIOS
sub menu_usuario {
    print "\n--- MENU USUARIO ---\n";
    print "1. Consultar medicamento\n";
    print "2. Solicitar reabastecimiento\n";
    print "3. Ver historial\n";
    print "4. Salir\n";
    print "Seleccione una opcion: ";
}
while (1) {

    my $rol = login();
    next unless defined $rol;

    if ($rol eq "ADMIN") {

        while (1) {
            menu_admin();
            chomp(my $op = <STDIN>);

            last if $op == 9;

            if ($op == 1) {
                registrar_medicamento();
            }
            elsif ($op == 2) {
                $inventario->imprimirMedicamentos();
            }
            elsif ($op == 3) {
                $solicitudes->mostrar();
                $solicitudes->generarDotSolicitudesPendientes("reporte_pendientes.dot");
                generarReporteSolicitudesPendientes();
                $inventario->_actualizarReporteMatriz();
            }
            elsif ($op == 4) {
                procesar_solicitud();
            }
            elsif ($op == 5) {
                $procesadas->mostrar();
            }
            elsif ($op == 6) {
                cargar_medicamentos_csv();
            }
            elsif ($op == 7) {

                while (1) {
                    menu_proveedores();
                    chomp(my $subop = <STDIN>);

                    last if $subop == 4;

                    if ($subop == 1) {
                        registrar_proveedor();
                    }
                    elsif ($subop == 2) {
                        registrar_entrega_proveedor();
                    }
                    elsif ($subop == 3) {
                        $inventario->mostrarProveedores();
                    }
                }
            }
            elsif ($op == 8) {
                $inventario->generarReporteInventario();
                $inventario->_actualizarReporteMatriz();
            }
        }

    }
    elsif ($rol eq "USUARIO") {

        while (1) {
            menu_usuario();
            chomp(my $op = <STDIN>);

            last if $op == 4;

            if ($op == 1) {
                consultar_medicamento();
            }
            elsif ($op == 2) {
                crear_solicitud();
            }
            elsif ($op == 3) {
                $procesadas->mostrar();
            }
        }
    }
}



sub consultar_medicamento {
    print "Ingrese codigo del medicamento: ";
    chomp(my $codigo = <STDIN>);

    my $med = $inventario->buscarMedicamento($codigo);
    if ($med) {
        print "Nombre: " . $med->nombre . "\n";
        print "Cantidad: " . $med->cantidad . "\n";
        print "Precio unitario: " . $med->precio_unitario . "\n";
        print "Fecha vencimiento: " . $med->fecha_vencimiento . "\n";
        print "Nivel minimo: " . $med->nivel_minimo . "\n";
        print "Principio activo: " . $med->principio_activo . "\n";
        print "Laboratorio: " . $med->laboratorio . "\n";
    } else {
        print "-----------------------------\n";
        print "Medicamento no encontrado\n";
        print "-----------------------------\n";
    }
}

sub crear_solicitud {

    print "Codigo medicamento: ";
    chomp(my $codigo = <STDIN>);

    print "Cantidad solicitada: ";
    chomp(my $cantidad = <STDIN>);
    $cantidad = $cantidad + 0;

    my $id = time();  # o cualquier generador simple

    my $solicitud = modelos::Solicitud->new($id, $codigo, $cantidad);

    $solicitudes->insertar($solicitud);

    print "Solicitud enviada correctamente\n";
}



sub registrar_medicamento {
    print "Codigo: ";
    chomp(my $codigo = <STDIN>);
    print "Nombre: ";
    chomp(my $nombre = <STDIN>);
    print "Principio activo: ";
    chomp(my $principio = <STDIN>);
    print "Laboratorio: ";
    chomp(my $laboratorio = <STDIN>);
    print "Precio unitario: ";
    chomp(my $precio = <STDIN>);
    print "Cantidad em stock: ";
    chomp(my $cantidad = <STDIN>);
    print "Fecha vencimiento (YYYY-MM-DD): ";
    chomp(my $fecha = <STDIN>);
    print "Nivel minimo de reorden: ";
    chomp(my $nivel = <STDIN>);

    my $medicamento = modelos::Medicamento->new(
        codigo => $codigo,
        nombre => $nombre,
        principio_activo => $principio,
        laboratorio => $laboratorio,
        precio_unitario => $precio,
        cantidad => $cantidad,
        fecha_vencimiento => $fecha,
        nivel_minimo => $nivel
    );

    $inventario->insertar($medicamento);
    $inventario->_actualizarReporteMatriz();
    print $medicamento->to_string() . "\n";
    print "Medicamento registrado correctamente\n";
}


sub procesar_solicitud {
    print "Entrando a procesar solicitud...\n";


    if ($solicitudes->is_empty()) {
        print "No hay solicitudes pendientes\n";
        return;
    }

    my $sol = $solicitudes->obtener_primero();

    my $codigo   = $sol->codigo;
    my $cantidad = $sol->cantidad;

    my $med = $inventario->buscarMedicamento($codigo);

    if (!$med) {
        print "Medicamento no encontrado\n";
        $sol->rechazar();
    }
    
    elsif ($med->reducir_stock($cantidad)) {
        $sol->aprobar();
        print "Cantidad solicitada: $cantidad\n";
        print "Solicitud aprobada\n";
    }
    else {
        $sol->rechazar();
        print "Stock insuficiente\n";
    }

    my $procesada = $solicitudes->eliminar_primero();
    $procesadas->insertar($procesada);
    print "Solicitud movida a historial\n";
}

sub cargar_medicamentos_csv {

    print "Ruta del archivo CSV: ";
    chomp(my $ruta = <STDIN>);

    open(my $fh, '<', $ruta) or do {
        print "No se pudo abrir el archivo\n";
        return;
    };

    my $linea = <$fh>; # Saltar encabezado

    while ($linea = <$fh>) {
        chomp($linea);
        next if $linea =~ /^\s*$/;

        my @campos = split /,/, $linea;

        my $med = modelos::Medicamento->new(
            codigo            => $campos[0],
            nombre            => $campos[1],
            principio_activo  => $campos[2],
            laboratorio       => $campos[3],
            precio_unitario   => $campos[4],
            cantidad          => $campos[5],
            fecha_vencimiento => $campos[6],
            nivel_minimo      => $campos[7],
        );

        $inventario->insertarMedicamentoDesdeCSV($med);
        #$listaMedicamentos->generarDotInventario($med);
    }
    
    close($fh);
    mkdir "reportesDOT" unless -d "reportesDOT";
    $listaMedicamentos->generarDotInventario("reporte_inventario.dot");
    $inventario->_actualizarReporteMatriz();
    

    print "Carga masiva completada correctamente\n";
}

sub login {

    print "Usuario: ";
    chomp(my $user = <STDIN>);

    print "Password: ";
    chomp(my $pass = <STDIN>);

    if ($user eq "admin" && $pass eq "admin123") {
        return "ADMIN";
    }
    elsif ($user eq "enfermeras" && $pass eq "enfermeras123") {
        return "USUARIO";
    }
    else {
        print "Credenciales incorrectas\n";
        return undef;
    }
}

sub registrar_proveedor {

    print "NIT: ";
    chomp(my $nit = <STDIN>);

    print "Nombre de la empresa: ";
    chomp(my $nombre = <STDIN>);

    print "Contacto principal: ";
    chomp(my $contacto = <STDIN>);

    print "Telefono: ";
    chomp(my $telefono = <STDIN>);

    print "Direccion: ";
    chomp(my $direccion = <STDIN>);

    my $prov = modelos::Proveedor->new(
        nit            => $nit,
        nombre_empresa => $nombre,
        contacto       => $contacto,
        telefono       => $telefono,
        direccion      => $direccion
    );

    $inventario->insertarProveedor($prov);
    #$inventario->_actualizarReporteMatriz();
    reportes::generarProveedores::generar($inventario->{proveedores});

    print "Proveedor registrado correctamente\n";
}


sub generar_reporte_graphviz {

    open(my $fh, '>', 'inventario.dot') or die "No se pudo crear archivo";

    print $fh "digraph Inventario {\n";
    print $fh "node [shape=box, style=filled];\n";

    my $actual = $inventario->{primero};

    while (defined $actual) {

        my $med = $actual->{valor};

        my $color = "green";

        if ($med->estado_alerta() eq "BAJO_MINIMO") {
            $color = "red";
        }
        elsif ($med->estado_alerta() eq "PROXIMO_VENCER") {
            $color = "orange";
        }

        print $fh "$med->{codigo} [label=\""
                  . $med->{nombre}
                  . "\\nStock: $med->{cantidad}\", fillcolor=$color];\n";

        $actual = $actual->{siguiente};
    }

    print $fh "}\n";
    close($fh);

    print "Archivo inventario.dot generado correctamente\n";
}

sub registrar_entrega_proveedor {

    print "NIT del proveedor: ";
    chomp(my $nit = <STDIN>);

    my $prov = $inventario->{proveedores}->buscar($nit);

    unless ($prov) {
        print "Proveedor no encontrado\n";
        return;
    }

    print "Fecha de entrega (YYYY-MM-DD): ";
    chomp(my $fecha = <STDIN>);

    print "Numero de factura: ";
    chomp(my $factura = <STDIN>);

    print "Codigo de medicamento: ";
    chomp(my $codigo = <STDIN>);

    print "Cantidad entregada: ";
    chomp(my $cantidad = <STDIN>);
    $cantidad = $cantidad + 0;

    my $med = $inventario->buscarMedicamento($codigo);

    unless ($med) {
        print "Medicamento no encontrado en inventario\n";
        return;
    }

    my $entrega = modelos::Entrega->new(
        fecha              => $fecha,
        numero_factura     => $factura,
        codigo_medicamento => $codigo,
        cantidad           => $cantidad
    );

    $prov->entregas()->insertar($entrega);
    print "Tamaño entregas proveedor ", $prov->nit(), ": ",
    $prov->entregas()->{tamanio}, "\n";
    $med->aumentar_stock($cantidad);
    reportes::generarProveedores::generar($inventario->{proveedores});
    $inventario->_actualizarReporteMatriz();



    print "Entrega registrada y stock actualizado correctamente\n";
}

sub generarReporteSolicitudesPendientes {

    my $dot = "reportesDOT/solicitudes_pendientes.dot";
    my $png = "reportesDOT/solicitudes_pendientes.png";

    mkdir "reportesDOT" unless -d "reportesDOT";

    $solicitudes->generarDotSolicitudesPendientes($dot);

    my $resultado = system("dot -Tpng $dot -o $png");

    if ($resultado == 0) {
        print "Reporte generado correctamente\n";
    } else {
        print "Error generando PNG\n";
    }
}






