package estructuras::modulos::Inventario;

use strict;
use warnings;

use File::Path qw(make_path);

use estructuras::listaDoble::ListaDoble;
use estructuras::listaDobleCircular::ListaDobleCircular;
use estructuras::matrizDispersa::MatrizDispersa;
use estructuras::bst::ArbolBST;
use estructuras::arbolB::ArbolB;

sub new {
    my ($class, @args) = @_;

    my %args;

    if (@args == 1 && ref($args[0]) eq 'HASH') {
        %args = %{ $args[0] };
    }
    elsif (@args >= 2 && ref($args[0])) {
        $args{medicamentos} = $args[0];
        $args{proveedores}  = $args[1];
    }
    else {
        %args = @args;
    }

    my $self = {
        medicamentos => $args{medicamentos} // estructuras::listaDoble::ListaDoble->new(),
        equipos      => $args{equipos}      // estructuras::bst::ArbolBST->new(),
        suministros  => $args{suministros}  // estructuras::arbolB::ArbolB->new(),
        proveedores  => $args{proveedores}  // estructuras::listaDobleCircular::ListaDobleCircular->new(),
        matriz       => $args{matriz}       // estructuras::matrizDispersa::MatrizDispersa->new(),

        indice_medicamentos => {},
        indice_proveedores  => {},

        orden_medicamentos => [],
        orden_proveedores  => [],

        resumen_matriz => {},
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Getters de estructuras
# =========================================================
sub getMedicamentos { return $_[0]->{medicamentos}; }
sub getEquipos      { return $_[0]->{equipos}; }
sub getSuministros  { return $_[0]->{suministros}; }
sub getProveedores  { return $_[0]->{proveedores}; }
sub getMatriz       { return $_[0]->{matriz}; }

# =========================================================
# Registro de proveedores
# =========================================================
sub registrarProveedor {
    my ($self, $proveedor) = @_;

    if (!defined $proveedor) {
        return (0, 'No se puede registrar un proveedor indefinido');
    }

    my $nit = $self->_obtener_campo($proveedor, 'nit');
    return (0, 'El proveedor no tiene NIT') if !defined $nit || $nit eq '';

    if (exists $self->{indice_proveedores}{$nit}) {
        return (0, "Ya existe un proveedor con NIT $nit");
    }

    my ($ok, $msg) = $self->_insertar_en_lista($self->{proveedores}, $proveedor);
    return ($ok, $msg) if !$ok;

    $self->{indice_proveedores}{$nit} = $proveedor;
    push @{ $self->{orden_proveedores} }, $nit;

    return (1, 'Proveedor registrado correctamente');
}

sub buscarProveedor {
    my ($self, $nit) = @_;
    return $self->{indice_proveedores}{$nit};
}

sub listarProveedores {
    my ($self) = @_;

    my @lista;
    foreach my $nit (@{ $self->{orden_proveedores} }) {
        next if !exists $self->{indice_proveedores}{$nit};
        push @lista, $self->{indice_proveedores}{$nit};
    }

    return \@lista;
}

sub eliminarProveedor {
    my ($self, $nit) = @_;

    return (0, 'Debe indicar el NIT del proveedor') if !defined $nit || $nit eq '';
    return (0, "No existe un proveedor con NIT $nit") if !exists $self->{indice_proveedores}{$nit};

    my $proveedor = delete $self->{indice_proveedores}{$nit};
    $self->_eliminar_de_lista($self->{proveedores}, $nit, $proveedor);

    @{ $self->{orden_proveedores} } = grep { $_ ne $nit } @{ $self->{orden_proveedores} };

    delete $self->{resumen_matriz}{$nit};

    return (1, 'Proveedor eliminado correctamente');
}

# =========================================================
# Registro de medicamentos
# =========================================================
sub registrarMedicamento {
    my ($self, $medicamento, $nit_proveedor) = @_;

    if (!defined $medicamento) {
        return (0, 'No se puede registrar un medicamento indefinido');
    }

    my $codigo = $self->_obtener_campo($medicamento, 'codigo');
    return (0, 'El medicamento no tiene codigo') if !defined $codigo || $codigo eq '';

    if (exists $self->{indice_medicamentos}{$codigo}) {
        return (0, "Ya existe un medicamento con codigo $codigo");
    }

    my ($ok, $msg) = $self->_insertar_en_lista($self->{medicamentos}, $medicamento);
    return ($ok, $msg) if !$ok;

    $self->{indice_medicamentos}{$codigo} = $medicamento;
    push @{ $self->{orden_medicamentos} }, $codigo;

    my $fabricante = $self->_obtener_fabricante($medicamento);
    my $cantidad   = $self->_obtener_campo($medicamento, 'cantidad') // 0;

    $self->_registrar_relacion_matriz($nit_proveedor, $fabricante, 'MEDICAMENTO', $cantidad);

    return (1, 'Medicamento registrado correctamente');
}

sub buscarMedicamento {
    my ($self, $codigo) = @_;
    return $self->{indice_medicamentos}{$codigo};
}

sub listarMedicamentos {
    my ($self) = @_;

    my @lista;
    foreach my $codigo (@{ $self->{orden_medicamentos} }) {
        next if !exists $self->{indice_medicamentos}{$codigo};
        push @lista, $self->{indice_medicamentos}{$codigo};
    }

    return \@lista;
}

sub eliminarMedicamento {
    my ($self, $codigo) = @_;

    return (0, 'Debe indicar el codigo del medicamento') if !defined $codigo || $codigo eq '';
    return (0, "No existe un medicamento con codigo $codigo") if !exists $self->{indice_medicamentos}{$codigo};

    my $medicamento = delete $self->{indice_medicamentos}{$codigo};
    $self->_eliminar_de_lista($self->{medicamentos}, $codigo, $medicamento);

    @{ $self->{orden_medicamentos} } = grep { $_ ne $codigo } @{ $self->{orden_medicamentos} };

    return (1, 'Medicamento eliminado correctamente');
}

# =========================================================
# Registro de equipos (BST)
# =========================================================
sub registrarEquipo {
    my ($self, $equipo, $nit_proveedor) = @_;

    my ($ok, $msg) = $self->{equipos}->insertar($equipo);
    return ($ok, $msg) if !$ok;

    my $fabricante = $self->_obtener_fabricante($equipo);
    my $cantidad   = $self->_obtener_campo($equipo, 'cantidad') // 0;

    $self->_registrar_relacion_matriz($nit_proveedor, $fabricante, 'EQUIPO', $cantidad);

    return (1, 'Equipo registrado correctamente');
}

sub buscarEquipo {
    my ($self, $codigo) = @_;
    return undef if !defined $codigo || $codigo eq '';
    return $self->{equipos}->buscar($codigo);
}

sub existeEquipo {
    my ($self, $codigo) = @_;
    return defined $self->buscarEquipo($codigo);
}

sub editarEquipo {
    my ($self, $codigo, %cambios) = @_;

    return (0, 'Debe indicar el codigo del equipo') if !defined $codigo || $codigo eq '';

    my $equipo = $self->buscarEquipo($codigo);
    return (0, "No existe un equipo con codigo $codigo") if !$equipo;

    if (exists $cambios{codigo} && defined $cambios{codigo} && $cambios{codigo} ne $codigo) {
        return (0, 'No se puede cambiar el codigo del equipo porque es la clave del BST');
    }

    my %mapa_setters = (
        nombre          => 'setNombre',
        fabricante      => 'setFabricante',
        precio_unitario => 'setPrecioUnitario',
        cantidad        => 'setCantidad',
        fecha_ingreso   => 'setFechaIngreso',
        nivel_minimo    => 'setNivelMinimo',
    );

    foreach my $campo (keys %mapa_setters) {
        next if !exists $cambios{$campo};

        my $setter = $mapa_setters{$campo};
        next if !$equipo->can($setter);

        $equipo->$setter($cambios{$campo});
    }

    if ($equipo->can('esValido') && !$equipo->esValido()) {
        my @errores = $equipo->validar();
        return (0, 'Los cambios dejan al equipo en estado inválido: ' . join(', ', @errores));
    }

    return (1, 'Equipo actualizado correctamente');
}

sub eliminarEquipo {
    my ($self, $codigo) = @_;
    return $self->{equipos}->eliminar($codigo);
}

sub listarEquipos {
    my ($self) = @_;
    return $self->{equipos}->inOrden();
}

sub listarEquiposInOrden {
    my ($self) = @_;
    return $self->{equipos}->inOrden();
}

sub listarEquiposPreOrden {
    my ($self) = @_;
    return $self->{equipos}->preOrden();
}

sub listarEquiposPostOrden {
    my ($self) = @_;
    return $self->{equipos}->postOrden();
}

sub obtenerEquiposPorRecorrido {
    my ($self, $tipo_recorrido) = @_;

    $tipo_recorrido = '' if !defined $tipo_recorrido;
    $tipo_recorrido = uc($tipo_recorrido);

    if ($tipo_recorrido eq 'PREORDEN') {
        return $self->listarEquiposPreOrden();
    }
    elsif ($tipo_recorrido eq 'POSTORDEN') {
        return $self->listarEquiposPostOrden();
    }

    return $self->listarEquiposInOrden();
}

sub equiposComoTexto {
    my ($self, $tipo_recorrido) = @_;
    my $lista = $self->obtenerEquiposPorRecorrido($tipo_recorrido);
    return $self->_lista_a_texto($lista);
}

sub imprimirEquipos {
    my ($self, $tipo_recorrido) = @_;
    print $self->equiposComoTexto($tipo_recorrido) . "\n";
}

# =========================================================
# Registro de suministros (Árbol B)
# =========================================================
sub registrarSuministro {
    my ($self, $suministro, $nit_proveedor) = @_;

    my ($ok, $msg) = $self->{suministros}->insertar($suministro);
    return ($ok, $msg) if !$ok;

    my $fabricante = $self->_obtener_fabricante($suministro);
    my $cantidad   = $self->_obtener_campo($suministro, 'cantidad') // 0;

    $self->_registrar_relacion_matriz($nit_proveedor, $fabricante, 'SUMINISTRO', $cantidad);

    return (1, 'Suministro registrado correctamente');
}

sub buscarSuministro {
    my ($self, $codigo) = @_;
    return undef if !defined $codigo || $codigo eq '';
    return $self->{suministros}->buscar($codigo);
}

sub existeSuministro {
    my ($self, $codigo) = @_;
    return defined $self->buscarSuministro($codigo);
}

sub editarSuministro {
    my ($self, $codigo, %cambios) = @_;

    return (0, 'Debe indicar el codigo del suministro') if !defined $codigo || $codigo eq '';

    my $suministro = $self->buscarSuministro($codigo);
    return (0, "No existe un suministro con codigo $codigo") if !$suministro;

    if (exists $cambios{codigo} && defined $cambios{codigo} && $cambios{codigo} ne $codigo) {
        return (0, 'No se puede cambiar el codigo del suministro porque es la clave del Árbol B');
    }

    my %mapa_setters = (
        nombre            => 'setNombre',
        fabricante        => 'setFabricante',
        precio_unitario   => 'setPrecioUnitario',
        cantidad          => 'setCantidad',
        fecha_vencimiento => 'setFechaVencimiento',
        nivel_minimo      => 'setNivelMinimo',
    );

    foreach my $campo (keys %mapa_setters) {
        next if !exists $cambios{$campo};

        my $setter = $mapa_setters{$campo};
        next if !$suministro->can($setter);

        $suministro->$setter($cambios{$campo});
    }

    if ($suministro->can('esValido') && !$suministro->esValido()) {
        my @errores = $suministro->validar();
        return (0, 'Los cambios dejan al suministro en estado inválido: ' . join(', ', @errores));
    }

    return (1, 'Suministro actualizado correctamente');
}

sub eliminarSuministro {
    my ($self, $codigo) = @_;
    return $self->{suministros}->eliminar($codigo);
}

sub listarSuministros {
    my ($self) = @_;
    return $self->{suministros}->inOrden();
}

sub listarSuministrosInOrden {
    my ($self) = @_;
    return $self->{suministros}->inOrden();
}

sub listarSuministrosPreOrden {
    my ($self) = @_;
    return $self->{suministros}->preOrden();
}

sub listarSuministrosPostOrden {
    my ($self) = @_;
    return $self->{suministros}->postOrden();
}

sub obtenerSuministrosPorRecorrido {
    my ($self, $tipo_recorrido) = @_;

    $tipo_recorrido = '' if !defined $tipo_recorrido;
    $tipo_recorrido = uc($tipo_recorrido);

    if ($tipo_recorrido eq 'PREORDEN') {
        return $self->listarSuministrosPreOrden();
    }
    elsif ($tipo_recorrido eq 'POSTORDEN') {
        return $self->listarSuministrosPostOrden();
    }

    return $self->listarSuministrosInOrden();
}

sub suministrosComoTexto {
    my ($self, $tipo_recorrido) = @_;
    my $lista = $self->obtenerSuministrosPorRecorrido($tipo_recorrido);
    return $self->_lista_a_texto($lista);
}

sub imprimirSuministros {
    my ($self, $tipo_recorrido) = @_;
    print $self->suministrosComoTexto($tipo_recorrido) . "\n";
}

# =========================================================
# Registro genérico por tipo
# =========================================================
sub registrarItem {
    my ($self, $obj, %opts) = @_;

    my $nit_proveedor = $opts{nit_proveedor};
    my $tipo = $opts{tipo} // $self->_inferir_tipo_objeto($obj);

    if ($tipo eq 'MEDICAMENTO') {
        return $self->registrarMedicamento($obj, $nit_proveedor);
    }
    elsif ($tipo eq 'EQUIPO') {
        return $self->registrarEquipo($obj, $nit_proveedor);
    }
    elsif ($tipo eq 'SUMINISTRO') {
        return $self->registrarSuministro($obj, $nit_proveedor);
    }

    return (0, 'No se pudo inferir el tipo del item a registrar');
}

# =========================================================
# Resúmenes generales
# =========================================================
sub obtenerResumenGeneral {
    my ($self) = @_;

    my $cantidad_medicamentos = scalar @{ $self->listarMedicamentos() };
    my $cantidad_equipos      = $self->{equipos}->getSize();
    my $cantidad_suministros  = $self->{suministros}->getSize();
    my $cantidad_proveedores  = scalar @{ $self->listarProveedores() };

    return {
        medicamentos => $cantidad_medicamentos,
        equipos      => $cantidad_equipos,
        suministros  => $cantidad_suministros,
        proveedores  => $cantidad_proveedores,
        total_items  => $cantidad_medicamentos + $cantidad_equipos + $cantidad_suministros,
    };
}

# =========================================================
# Consultar y comparar proveedor/fabricante
# =========================================================
sub obtenerResumenProveedorFabricante {
    my ($self) = @_;

    my %copia;

    foreach my $nit (keys %{ $self->{resumen_matriz} }) {
        foreach my $fabricante (keys %{ $self->{resumen_matriz}{$nit} }) {
            my $info = $self->{resumen_matriz}{$nit}{$fabricante};

            $copia{$nit}{$fabricante} = {
                MEDICAMENTO => $info->{MEDICAMENTO} // 0,
                EQUIPO      => $info->{EQUIPO}      // 0,
                SUMINISTRO  => $info->{SUMINISTRO}  // 0,
                TOTAL       => $info->{TOTAL}       // 0,
            };
        }
    }

    return \%copia;
}

sub listarComparacionProveedorFabricante {
    my ($self, $nit_filtro) = @_;

    my $resumen = $self->obtenerResumenProveedorFabricante();
    my @filas;

    foreach my $nit (sort keys %$resumen) {
        next if defined $nit_filtro && $nit_filtro ne '' && $nit ne $nit_filtro;

        foreach my $fabricante (sort keys %{ $resumen->{$nit} }) {
            my $info = $resumen->{$nit}{$fabricante};

            push @filas, {
                nit          => $nit,
                fabricante   => $fabricante,
                medicamento  => $info->{MEDICAMENTO} // 0,
                equipo       => $info->{EQUIPO}      // 0,
                suministro   => $info->{SUMINISTRO}  // 0,
                total        => $info->{TOTAL}       // 0,
            };
        }
    }

    return \@filas;
}

sub consultarProveedorFabricanteComoTexto {
    my ($self, $nit_filtro) = @_;

    my $filas = $self->listarComparacionProveedorFabricante($nit_filtro);

    return 'Sin datos de proveedor/fabricante' if !defined $filas || !@$filas;

    my @lineas;
    foreach my $fila (@$filas) {
        push @lineas,
            "Proveedor: $fila->{nit}" .
            " | Fabricante: $fila->{fabricante}" .
            " | MED: $fila->{medicamento}" .
            " | EQU: $fila->{equipo}" .
            " | SUM: $fila->{suministro}" .
            " | TOTAL: $fila->{total}";
    }

    return join("\n", @lineas);
}

sub existeProveedorEnResumen {
    my ($self, $nit) = @_;
    return 0 if !defined $nit || $nit eq '';
    return exists $self->{resumen_matriz}{$nit};
}

sub obtenerFabricantesDeProveedor {
    my ($self, $nit) = @_;

    return [] if !defined $nit || $nit eq '';
    return [] if !exists $self->{resumen_matriz}{$nit};

    my @fabricantes = sort keys %{ $self->{resumen_matriz}{$nit} };
    return \@fabricantes;
}

# =========================================================
# Impresiones rápidas
# =========================================================
sub imprimirMedicamentos {
    my ($self) = @_;
    print $self->_lista_a_texto($self->listarMedicamentos()) . "\n";
}

sub mostrarProveedores {
    my ($self) = @_;
    print $self->_lista_a_texto($self->listarProveedores()) . "\n";
}

# =========================================================
# Reportes
# =========================================================
sub generarReporteMedicamentos {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/inventario_medicamentos.dot';
    $ruta_png ||= 'reportesdot/inventario_medicamentos.png';

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    if ($self->{medicamentos}->can('generarDotInventario')) {
        $self->{medicamentos}->generarDotInventario($ruta_dot);
        my $ok = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png) == 0;
        return ($ok ? 1 : 0, $ok ? 'Reporte de medicamentos generado correctamente' : 'No se pudo generar el PNG de medicamentos');
    }

    return $self->_generar_reporte_lineal(
        $self->listarMedicamentos(),
        'Medicamentos',
        $ruta_dot,
        $ruta_png
    );
}

sub generarReporteEquipos {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/bst_equipos.dot';
    $ruta_png ||= 'reportesdot/bst_equipos.png';

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    my $ok = $self->{equipos}->generarPNG($ruta_dot, $ruta_png);
    return ($ok ? 1 : 0, $ok ? 'Reporte de equipos generado correctamente' : 'No se pudo generar el reporte de equipos');
}

sub generarReporteSuministros {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/arbol_b_suministros.dot';
    $ruta_png ||= 'reportesdot/arbol_b_suministros.png';

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    my $ok = $self->{suministros}->generarPNG($ruta_dot, $ruta_png);
    return ($ok ? 1 : 0, $ok ? 'Reporte de suministros generado correctamente' : 'No se pudo generar el reporte de suministros');
}

sub generarReporteProveedores {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/proveedores.dot';
    $ruta_png ||= 'reportesdot/proveedores.png';

    return $self->_generar_reporte_lineal(
        $self->listarProveedores(),
        'Proveedores',
        $ruta_dot,
        $ruta_png
    );
}

sub generarReporteMatrizResumen {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/matriz_resumen.dot';
    $ruta_png ||= 'reportesdot/matriz_resumen.png';

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    open(my $fh, '>', $ruta_dot) or return (0, "No se pudo crear $ruta_dot");

    print $fh "digraph MatrizResumen {\n";
    print $fh "    rankdir=LR;\n";
    print $fh "    node [shape=box, style=filled, fillcolor=lightgray];\n";

    my %fabricantes_creados;

    foreach my $nit (sort keys %{ $self->{resumen_matriz} }) {
        my $id_proveedor = $self->_id_seguro("prov_$nit");
        print $fh qq{    $id_proveedor [label="Proveedor\\n$nit", fillcolor=lightblue];\n};

        foreach my $fabricante (sort keys %{ $self->{resumen_matriz}{$nit} }) {
            my $id_fabricante = $self->_id_seguro("fab_$fabricante");

            if (!$fabricantes_creados{$fabricante}) {
                print $fh qq{    $id_fabricante [label="Fabricante\\n$fabricante", fillcolor=lightgoldenrod1];\n};
                $fabricantes_creados{$fabricante} = 1;
            }

            my $info = $self->{resumen_matriz}{$nit}{$fabricante};
            my $label = "MED: $info->{MEDICAMENTO}\\nEQU: $info->{EQUIPO}\\nSUM: $info->{SUMINISTRO}\\nTOTAL: $info->{TOTAL}";
            $label =~ s/"/\\"/g;

            print $fh qq{    $id_proveedor -> $id_fabricante [label="$label"];\n};
        }
    }

    if (!keys %{ $self->{resumen_matriz} }) {
        print $fh qq{    vacio [label="Sin relaciones proveedor/fabricante"];\n};
    }

    print $fh "}\n";
    close($fh);

    my $ok = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png) == 0;
    return ($ok ? 1 : 0, $ok ? 'Reporte de matriz resumen generado correctamente' : 'No se pudo generar el PNG de la matriz resumen');
}

sub generarTodosLosReportes {
    my ($self, $directorio) = @_;
    $directorio ||= 'reportesdot';
    make_path($directorio) unless -d $directorio;

    my %resultado;

    ($resultado{medicamentos_ok}, $resultado{medicamentos_msg}) =
        $self->generarReporteMedicamentos("$directorio/inventario_medicamentos.dot", "$directorio/inventario_medicamentos.png");

    ($resultado{equipos_ok}, $resultado{equipos_msg}) =
        $self->generarReporteEquipos("$directorio/bst_equipos.dot", "$directorio/bst_equipos.png");

    ($resultado{suministros_ok}, $resultado{suministros_msg}) =
        $self->generarReporteSuministros("$directorio/arbol_b_suministros.dot", "$directorio/arbol_b_suministros.png");

    ($resultado{proveedores_ok}, $resultado{proveedores_msg}) =
        $self->generarReporteProveedores("$directorio/proveedores.dot", "$directorio/proveedores.png");

    ($resultado{matriz_ok}, $resultado{matriz_msg}) =
        $self->generarReporteMatrizResumen("$directorio/matriz_resumen.dot", "$directorio/matriz_resumen.png");

    return \%resultado;
}

# =========================================================
# Matriz / resumen proveedor-fabricante
# =========================================================
sub _registrar_relacion_matriz {
    my ($self, $nit_proveedor, $fabricante, $tipo, $cantidad) = @_;

    return if !defined $nit_proveedor || $nit_proveedor eq '';
    return if !defined $fabricante   || $fabricante eq '';

    $tipo     ||= 'DESCONOCIDO';
    $cantidad ||= 0;

    $self->{resumen_matriz}{$nit_proveedor}{$fabricante}{MEDICAMENTO} ||= 0;
    $self->{resumen_matriz}{$nit_proveedor}{$fabricante}{EQUIPO}      ||= 0;
    $self->{resumen_matriz}{$nit_proveedor}{$fabricante}{SUMINISTRO}  ||= 0;
    $self->{resumen_matriz}{$nit_proveedor}{$fabricante}{TOTAL}       ||= 0;

    if ($tipo eq 'MEDICAMENTO' || $tipo eq 'EQUIPO' || $tipo eq 'SUMINISTRO') {
        $self->{resumen_matriz}{$nit_proveedor}{$fabricante}{$tipo} += $cantidad;
    }

    $self->{resumen_matriz}{$nit_proveedor}{$fabricante}{TOTAL} += $cantidad;

    $self->_intentar_actualizar_matriz_real($nit_proveedor, $fabricante, $cantidad);
}

sub _intentar_actualizar_matriz_real {
    my ($self, $fila, $columna, $valor) = @_;

    my $matriz = $self->{matriz};
    return if !defined $matriz;

    foreach my $metodo (qw(insertar insertarValor agregar agregarValor setValor)) {
        next if !$matriz->can($metodo);

        eval {
            $matriz->$metodo($fila, $columna, $valor);
        };
        return if !$@;
    }
}

# =========================================================
# Helpers de listas y objetos
# =========================================================
sub _insertar_en_lista {
    my ($self, $lista, $obj) = @_;

    foreach my $metodo (qw(insertar agregar add append push_back insertar_final insertar_ultimo)) {
        next if !$lista->can($metodo);

        my $ok = eval {
            $lista->$metodo($obj);
            1;
        };

        return (1, 'Insertado correctamente') if $ok;
    }

    return (0, 'La estructura de lista no expone un método compatible de inserción');
}

sub _eliminar_de_lista {
    my ($self, $lista, $clave, $obj) = @_;

    foreach my $metodo (qw(eliminar eliminarPorCodigo remove borrar delete eliminar_objeto)) {
        next if !$lista->can($metodo);

        eval { $lista->$metodo($clave); };
        return if !$@;

        eval { $lista->$metodo($obj); };
        return if !$@;
    }
}

sub _lista_a_texto {
    my ($self, $lista) = @_;

    return 'Sin elementos' if !defined $lista || scalar(@$lista) == 0;

    my @lineas = map { $self->_objeto_a_texto($_) } @$lista;
    return join("\n", @lineas);
}

sub _objeto_a_texto {
    my ($self, $obj) = @_;

    return '' if !defined $obj;

    return $obj->toString() if $obj->can('toString');
    return $obj->to_string() if $obj->can('to_string');

    my $clave = $self->_obtener_campo($obj, 'codigo', 'nit', 'numero_colegio') // 'SIN-CLAVE';
    my $nombre = $self->_obtener_campo($obj, 'nombre', 'nombre_completo', 'nombre_empresa') // 'Sin nombre';

    return "[$clave] $nombre";
}

sub _obtener_fabricante {
    my ($self, $obj) = @_;
    return $self->_obtener_campo($obj, 'fabricante', 'laboratorio');
}

sub _inferir_tipo_objeto {
    my ($self, $obj) = @_;

    return '' if !defined $obj;

    if ($obj->can('getTipo')) {
        my $tipo = $obj->getTipo();
        return uc($tipo) if defined $tipo;
    }

    my $ref = ref($obj) || '';

    return 'MEDICAMENTO' if $ref =~ /Medicamento$/;
    return 'EQUIPO'      if $ref =~ /Equipo$/;
    return 'SUMINISTRO'  if $ref =~ /Suministro$/;

    return '';
}

sub _obtener_campo {
    my ($self, $obj, @campos) = @_;

    return undef if !defined $obj;

    foreach my $campo (@campos) {
        next if !defined $campo || $campo eq '';

        my $getter = 'get' . $self->_camelizar($campo);

        if ($obj->can($getter)) {
            my $valor = eval { $obj->$getter() };
            return $valor if defined $valor;
        }

        if ($obj->can($campo)) {
            my $valor = eval { $obj->$campo() };
            return $valor if defined $valor;
        }

        my $valor = eval { $obj->{$campo} };
        return $valor if defined $valor;
    }

    return undef;
}

sub _camelizar {
    my ($self, $texto) = @_;
    $texto //= '';
    $texto =~ s/(^|_)([a-z])/\U$2/g;
    return $texto;
}

sub _asegurar_directorio {
    my ($self, $ruta) = @_;
    return if !defined $ruta || $ruta eq '';

    if ($ruta =~ m{^(.*)/[^/]+$}) {
        my $dir = $1;
        make_path($dir) unless -d $dir;
    }
}

sub _generar_reporte_lineal {
    my ($self, $lista, $titulo, $ruta_dot, $ruta_png) = @_;

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    open(my $fh, '>', $ruta_dot) or return (0, "No se pudo crear $ruta_dot");

    print $fh "digraph $titulo {\n";
    print $fh "    rankdir=LR;\n";
    print $fh "    node [shape=box, style=filled, fillcolor=lightsteelblue1];\n";

    if (!defined $lista || scalar(@$lista) == 0) {
        print $fh qq{    vacio [label="$titulo vacío"];\n};
    }
    else {
        for (my $i = 0; $i < scalar(@$lista); $i++) {
            my $texto = $self->_escapar_texto($self->_objeto_a_texto($lista->[$i]));
            print $fh qq{    nodo_$i [label="$texto"];\n};

            if ($i < scalar(@$lista) - 1) {
                my $j = $i + 1;
                print $fh qq{    nodo_$i -> nodo_$j;\n};
            }
        }
    }

    print $fh "}\n";
    close($fh);

    my $ok = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png) == 0;
    return ($ok ? 1 : 0, $ok ? "Reporte de $titulo generado correctamente" : "No se pudo generar el PNG de $titulo");
}

sub _escapar_texto {
    my ($self, $texto) = @_;
    $texto = '' if !defined $texto;
    $texto =~ s/"/\\"/g;
    $texto =~ s/\|/\\|/g;
    $texto =~ s/\{/\\{/g;
    $texto =~ s/\}/\\}/g;
    return $texto;
}

sub _id_seguro {
    my ($self, $texto) = @_;
    $texto //= 'id';
    $texto =~ s/[^A-Za-z0-9_]/_/g;
    return $texto;
}

1;