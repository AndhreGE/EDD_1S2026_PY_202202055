package estructuras::modulos::Inventario;

use estructuras::matrizDispersa::MatrizDispersa;

sub new {
    my ($class, $listaMedicamentos, $listaProveedores) = @_;

    my $self = {
        medicamentos => $listaMedicamentos,
        proveedores  => $listaProveedores,
        matriz       => estructuras::matrizDispersa::MatrizDispersa->new()
    };

    bless $self, $class;
    return $self;
}

sub registrarEntrega {
    my ($self, $nitProveedor, $codigoMedicamento, $precio, $cantidad) = @_;

    # Buscar proveedor
    my $prov = $self->{proveedores}->buscar($nitProveedor);
    return unless $prov;

    # Buscar medicamento por código
    my $med = $self->{medicamentos}->buscar($codigoMedicamento);
    return unless $med;

    # Actualizar inventario real
    $med->{cantidad} += $cantidad;
    $med->{precio_unitario} = $precio;

    # Registrar en lista simple del proveedor
    $prov->agregarEntrega(
        $med->{nombre},
        $cantidad,
        $precio
    );

    # Actualizar matriz dispersa
    # FILA = laboratorio fabricante
    # COLUMNA = nombre medicamento

    $self->{matriz}->insertar(
        $med->{laboratorio},
        $med->{nombre},
        $precio,
        $med->{cantidad}
    );

    print "Entrega registrada y matriz actualizada.\n";
}



sub generarReporteMatriz {
    my ($self) = @_;

    my $dot = "reportesDOT/matriz.dot";
    my $png = "reportesDOT/matriz.png";

    $self->{matriz}->generarDot($dot);

    system("dot -Tpng $dot -o $png");

    print "Reporte matriz dispersa generado correctamente.\n";
}

sub _actualizarReporteMatriz {
    my ($self) = @_;

    my $dot = "reportesDOT/matriz.dot";
    my $png = "reportesDOT/matriz.png";

    $self->{matriz}->generarDot($dot);
    system("dot -Tpng $dot -o $png");
    print "Reporte actualizado de matriz dispersa generado correctamente.\n";
}

sub generarReporteInventario {
    my ($self) = @_;

    my $dot = "reportesDOT/inventario.dot";
    my $png = "reportesDOT/inventario.png";

    mkdir "reportesDOT" unless -d "reportesDOT";

    $self->{medicamentos}->generarDotInventario($dot);

    my $resultado = system("dot -Tpng $dot -o $png");

    if ($resultado == 0) {
        print "Reporte de inventario generado correctamente.\n";
    } else {
        print "Error al generar PNG. Verifique que Graphviz esté instalado y en el PATH.\n";
    }
}

sub insertarMedicamentoDesdeCSV {
    my ($self, $med) = @_;

    # Insertar en lista
    $self->{medicamentos}->insertar($med);

    # Insertar en matriz dispersa
    $self->{matriz}->insertar(
        $med->{laboratorio},
        $med->{nombre},
        $med->{precio_unitario},
        $med->{cantidad}
    );
}

sub mostrarProveedores {
    my ($self) = @_;
    $self->{proveedores}->mostrar();
}

sub imprimirMedicamentos {
    my ($self) = @_;
    $self->{medicamentos}->imprimir_adelante();
}
sub buscarMedicamento {
    my ($self, $codigo) = @_;
    return $self->{medicamentos}->buscar($codigo);
}

sub insertarProveedor {
    my ($self, $proveedor) = @_;
    $self->{proveedores}->insertar($proveedor);
}
sub insertar {
    my ($self, $med) = @_;
    $self->insertarMedicamentoDesdeCSV($med);
}


1;




