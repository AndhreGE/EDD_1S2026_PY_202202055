package ui::AdminWindow;

use strict;
use warnings;
use utf8;

use Gtk3;
use Glib qw/TRUE FALSE/;

use modelos::Equipo;
use modelos::Suministro;
use modelos::PersonalMedico;

sub new {
    my ($class, %args) = @_;

    my $self = {
        inventario       => $args{inventario},
        gestor_usuarios  => $args{gestor_usuarios},
        cargador_json    => $args{cargador_json},

        on_logout        => $args{on_logout},

        path_reportes    => defined $args{path_reportes} ? $args{path_reportes} : 'reportesdot',

        window           => undef,
        textview_log     => undef,
        textbuffer_log   => undef,
        lbl_bienvenida   => undef,

        image_reporte    => undef,
        lbl_reporte      => undef,
    };

    bless $self, $class;
    $self->_build_ui();

    return $self;
}

# =========================================================
# Construcción de interfaz
# =========================================================
sub _build_ui {
    my ($self) = @_;

    my $window = Gtk3::Window->new('toplevel');
    $window->set_title('EDD MedTrack - Administrador');
    $window->set_default_size(1380, 860);
    $window->set_border_width(12);

    $window->signal_connect(
        destroy => sub {
            Gtk3::main_quit();
        }
    );

    my $main_hbox = Gtk3::Box->new('horizontal', 12);
    $window->add($main_hbox);

    my $left_vbox = Gtk3::Box->new('vertical', 10);
    $main_hbox->pack_start($left_vbox, TRUE, TRUE, 0);

    my $lbl_titulo = Gtk3::Label->new();
    $lbl_titulo->set_markup('<span size="x-large" weight="bold">Panel de Administración</span>');
    $lbl_titulo->set_xalign(0);

    my $lbl_bienvenida = Gtk3::Label->new('Bienvenido, administrador del sistema.');
    $lbl_bienvenida->set_xalign(0);

    $left_vbox->pack_start($lbl_titulo, FALSE, FALSE, 0);
    $left_vbox->pack_start($lbl_bienvenida, FALSE, FALSE, 0);

    my $frame_acciones = Gtk3::Frame->new('Acciones disponibles');
    $left_vbox->pack_start($frame_acciones, FALSE, FALSE, 0);

    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(8);
    $grid->set_border_width(8);
    $frame_acciones->add($grid);

    my $btn_cargar_inventario = Gtk3::Button->new('Cargar inventario JSON');
    my $btn_cargar_usuarios   = Gtk3::Button->new('Cargar usuarios JSON');
    my $btn_cargar_todo       = Gtk3::Button->new('Cargar ambos JSON');
    my $btn_generar_reportes  = Gtk3::Button->new('Generar reportes');
    my $btn_resumen           = Gtk3::Button->new('Ver resumen del sistema');
    my $btn_logout            = Gtk3::Button->new('Cerrar sesión');

    my $btn_registrar_equipo  = Gtk3::Button->new('Registrar equipo');
    my $btn_buscar_equipo     = Gtk3::Button->new('Buscar equipo');
    my $btn_editar_equipo     = Gtk3::Button->new('Editar equipo');
    my $btn_eliminar_equipo   = Gtk3::Button->new('Eliminar equipo');
    my $btn_recorrido_equipo  = Gtk3::Button->new('Ver equipos por recorrido');

    my $btn_registrar_suministro = Gtk3::Button->new('Registrar suministro');
    my $btn_buscar_suministro    = Gtk3::Button->new('Buscar suministro');
    my $btn_editar_suministro    = Gtk3::Button->new('Editar suministro');
    my $btn_eliminar_suministro  = Gtk3::Button->new('Eliminar suministro');
    my $btn_recorrido_suministro = Gtk3::Button->new('Ver suministros por recorrido');

    my $btn_registrar_usuario = Gtk3::Button->new('Registrar usuario');
    my $btn_buscar_usuario    = Gtk3::Button->new('Buscar usuario');
    my $btn_eliminar_usuario  = Gtk3::Button->new('Eliminar usuario');
    my $btn_recorrido_usuario = Gtk3::Button->new('Ver usuarios por recorrido');
    my $btn_tabla_usuarios    = Gtk3::Button->new('Tabla personal médico');

    my $btn_consultar_pf      = Gtk3::Button->new('Consultar Prov/Fab');
    my $btn_comparar_pf       = Gtk3::Button->new('Comparar Prov/Fab');

    my $btn_ver_bst           = Gtk3::Button->new('Ver reporte BST');
    my $btn_ver_avl           = Gtk3::Button->new('Ver reporte AVL');
    my $btn_ver_b             = Gtk3::Button->new('Ver reporte Árbol B');
    my $btn_ver_matriz        = Gtk3::Button->new('Ver reporte Matriz');

    $grid->attach($btn_cargar_inventario,    0, 0, 1, 1);
    $grid->attach($btn_cargar_usuarios,      1, 0, 1, 1);
    $grid->attach($btn_cargar_todo,          2, 0, 1, 1);

    $grid->attach($btn_generar_reportes,     0, 1, 1, 1);
    $grid->attach($btn_resumen,              1, 1, 1, 1);
    $grid->attach($btn_logout,               2, 1, 1, 1);

    $grid->attach($btn_registrar_equipo,     0, 2, 1, 1);
    $grid->attach($btn_buscar_equipo,        1, 2, 1, 1);
    $grid->attach($btn_editar_equipo,        2, 2, 1, 1);

    $grid->attach($btn_eliminar_equipo,      0, 3, 1, 1);
    $grid->attach($btn_recorrido_equipo,     1, 3, 2, 1);

    $grid->attach($btn_registrar_suministro, 0, 4, 1, 1);
    $grid->attach($btn_buscar_suministro,    1, 4, 1, 1);
    $grid->attach($btn_editar_suministro,    2, 4, 1, 1);

    $grid->attach($btn_eliminar_suministro,  0, 5, 1, 1);
    $grid->attach($btn_recorrido_suministro, 1, 5, 2, 1);

    $grid->attach($btn_registrar_usuario,    0, 6, 1, 1);
    $grid->attach($btn_buscar_usuario,       1, 6, 1, 1);
    $grid->attach($btn_eliminar_usuario,     2, 6, 1, 1);

    $grid->attach($btn_recorrido_usuario,    0, 7, 2, 1);
    $grid->attach($btn_tabla_usuarios,       2, 7, 1, 1);

    $grid->attach($btn_consultar_pf,         0, 8, 1, 1);
    $grid->attach($btn_comparar_pf,          1, 8, 2, 1);

    $grid->attach($btn_ver_bst,              0, 9, 1, 1);
    $grid->attach($btn_ver_avl,              1, 9, 1, 1);
    $grid->attach($btn_ver_b,                2, 9, 1, 1);

    $grid->attach($btn_ver_matriz,           0, 10, 3, 1);

    my $frame_log = Gtk3::Frame->new('Salida del sistema');
    $left_vbox->pack_start($frame_log, TRUE, TRUE, 0);

    my $scrolled_log = Gtk3::ScrolledWindow->new();
    $scrolled_log->set_policy('automatic', 'automatic');
    $frame_log->add($scrolled_log);

    my $textview = Gtk3::TextView->new();
    $textview->set_editable(FALSE);
    $textview->set_cursor_visible(FALSE);
    $textview->set_wrap_mode('word');

    my $buffer = $textview->get_buffer();
    $scrolled_log->add($textview);

    my $right_vbox = Gtk3::Box->new('vertical', 10);
    $main_hbox->pack_start($right_vbox, TRUE, TRUE, 0);

    my $frame_reporte = Gtk3::Frame->new('Visor de reportes');
    $right_vbox->pack_start($frame_reporte, TRUE, TRUE, 0);

    my $reporte_vbox = Gtk3::Box->new('vertical', 8);
    $reporte_vbox->set_border_width(8);
    $frame_reporte->add($reporte_vbox);

    my $lbl_reporte = Gtk3::Label->new('Aquí se mostrará el reporte seleccionado.');
    $lbl_reporte->set_xalign(0);
    $reporte_vbox->pack_start($lbl_reporte, FALSE, FALSE, 0);

    my $scrolled_img = Gtk3::ScrolledWindow->new();
    $scrolled_img->set_policy('automatic', 'automatic');
    $reporte_vbox->pack_start($scrolled_img, TRUE, TRUE, 0);

    my $image = Gtk3::Image->new();
    $scrolled_img->add_with_viewport($image);

    $btn_cargar_inventario->signal_connect(clicked => sub { $self->_accion_cargar_inventario(); });
    $btn_cargar_usuarios->signal_connect(clicked => sub { $self->_accion_cargar_usuarios(); });
    $btn_cargar_todo->signal_connect(clicked => sub { $self->_accion_cargar_todo(); });
    $btn_generar_reportes->signal_connect(clicked => sub { $self->_accion_generar_reportes(); });
    $btn_resumen->signal_connect(clicked => sub { $self->_accion_ver_resumen(); });
    $btn_logout->signal_connect(clicked => sub { $self->_accion_logout(); });

    $btn_registrar_equipo->signal_connect(clicked => sub { $self->_accion_registrar_equipo(); });
    $btn_buscar_equipo->signal_connect(clicked => sub { $self->_accion_buscar_equipo(); });
    $btn_editar_equipo->signal_connect(clicked => sub { $self->_accion_editar_equipo(); });
    $btn_eliminar_equipo->signal_connect(clicked => sub { $self->_accion_eliminar_equipo(); });
    $btn_recorrido_equipo->signal_connect(clicked => sub { $self->_accion_ver_recorrido_equipos(); });

    $btn_registrar_suministro->signal_connect(clicked => sub { $self->_accion_registrar_suministro(); });
    $btn_buscar_suministro->signal_connect(clicked => sub { $self->_accion_buscar_suministro(); });
    $btn_editar_suministro->signal_connect(clicked => sub { $self->_accion_editar_suministro(); });
    $btn_eliminar_suministro->signal_connect(clicked => sub { $self->_accion_eliminar_suministro(); });
    $btn_recorrido_suministro->signal_connect(clicked => sub { $self->_accion_ver_recorrido_suministros(); });

    $btn_registrar_usuario->signal_connect(clicked => sub { $self->_accion_registrar_usuario(); });
    $btn_buscar_usuario->signal_connect(clicked => sub { $self->_accion_buscar_usuario(); });
    $btn_eliminar_usuario->signal_connect(clicked => sub { $self->_accion_eliminar_usuario(); });
    $btn_recorrido_usuario->signal_connect(clicked => sub { $self->_accion_ver_recorrido_usuarios(); });
    $btn_tabla_usuarios->signal_connect(clicked => sub { $self->_accion_ver_tabla_usuarios(); });

    $btn_consultar_pf->signal_connect(clicked => sub { $self->_accion_consultar_proveedor_fabricante(); });
    $btn_comparar_pf->signal_connect(clicked => sub { $self->_accion_comparar_proveedor_fabricante(); });

    $btn_ver_bst->signal_connect(clicked => sub {
        $self->_mostrar_reporte('Reporte BST - Inventario de Equipos', "$self->{path_reportes}/bst_equipos.png");
    });

    $btn_ver_avl->signal_connect(clicked => sub {
        $self->_mostrar_reporte('Reporte AVL - Personal Médico', "$self->{path_reportes}/avl_personal.png");
    });

    $btn_ver_b->signal_connect(clicked => sub {
        $self->_mostrar_reporte('Reporte Árbol B - Suministros', "$self->{path_reportes}/arbol_b_suministros.png");
    });

    $btn_ver_matriz->signal_connect(clicked => sub {
        $self->_mostrar_reporte('Reporte Matriz Dispersa / Resumen', "$self->{path_reportes}/matriz_resumen.png");
    });

    $self->{window}         = $window;
    $self->{textview_log}   = $textview;
    $self->{textbuffer_log} = $buffer;
    $self->{lbl_bienvenida} = $lbl_bienvenida;
    $self->{image_reporte}  = $image;
    $self->{lbl_reporte}    = $lbl_reporte;

    $self->_append_log('Panel de administración listo.');
    $self->_append_log('Ya puedes gestionar inventario, usuarios y comparar proveedor/fabricante.');
}

# =========================================================
# Acciones principales
# =========================================================
sub _accion_cargar_inventario {
    my ($self) = @_;

    if (!$self->{cargador_json}) {
        $self->_append_log('Error: no hay cargador JSON configurado.');
        return;
    }

    my $ruta = $self->_seleccionar_archivo('Seleccionar inventario JSON');
    return if !defined $ruta || $ruta eq '';

    my $resultado = $self->{cargador_json}->cargarInventarioDesdeArchivo($ruta);

    $self->_append_log('=== CARGA DE INVENTARIO ===');
    $self->_append_log("Archivo: $ruta");
    $self->_append_log('Mensaje: ' . ($resultado->{mensaje} // ''));
    $self->_append_log('Proveedores leídos: ' . ($resultado->{proveedores_leidos} // 0));
    $self->_append_log('Proveedores registrados: ' . ($resultado->{proveedores_registrados} // 0));
    $self->_append_log('Items leídos: ' . ($resultado->{items_leidos} // 0));
    $self->_append_log('Medicamentos cargados: ' . ($resultado->{medicamentos_ok} // 0));
    $self->_append_log('Equipos cargados: ' . ($resultado->{equipos_ok} // 0));
    $self->_append_log('Suministros cargados: ' . ($resultado->{suministros_ok} // 0));

    $self->_append_errores($resultado->{errores});
}

sub _accion_cargar_usuarios {
    my ($self) = @_;

    if (!$self->{cargador_json}) {
        $self->_append_log('Error: no hay cargador JSON configurado.');
        return;
    }

    my $ruta = $self->_seleccionar_archivo('Seleccionar usuarios JSON');
    return if !defined $ruta || $ruta eq '';

    my $resultado = $self->{cargador_json}->cargarUsuariosDesdeArchivo($ruta);

    $self->_append_log('=== CARGA DE USUARIOS ===');
    $self->_append_log("Archivo: $ruta");
    $self->_append_log('Mensaje: ' . ($resultado->{mensaje} // ''));
    $self->_append_log('Usuarios leídos: ' . ($resultado->{usuarios_leidos} // 0));
    $self->_append_log('Usuarios registrados: ' . ($resultado->{usuarios_registrados} // 0));

    $self->_append_errores($resultado->{errores});
}

sub _accion_cargar_todo {
    my ($self) = @_;

    if (!$self->{cargador_json}) {
        $self->_append_log('Error: no hay cargador JSON configurado.');
        return;
    }

    my $ruta_inventario = $self->_seleccionar_archivo('Seleccionar inventario JSON');
    return if !defined $ruta_inventario || $ruta_inventario eq '';

    my $ruta_usuarios = $self->_seleccionar_archivo('Seleccionar usuarios JSON');
    return if !defined $ruta_usuarios || $ruta_usuarios eq '';

    my $resultado = $self->{cargador_json}->cargarTodo(
        inventario => $ruta_inventario,
        usuarios   => $ruta_usuarios,
    );

    $self->_append_log('=== CARGA COMPLETA ===');

    if ($resultado->{inventario}) {
        my $r = $resultado->{inventario};
        $self->_append_log('--- Inventario ---');
        $self->_append_log('Mensaje: ' . ($r->{mensaje} // ''));
        $self->_append_log('Proveedores registrados: ' . ($r->{proveedores_registrados} // 0));
        $self->_append_log('Medicamentos cargados: ' . ($r->{medicamentos_ok} // 0));
        $self->_append_log('Equipos cargados: ' . ($r->{equipos_ok} // 0));
        $self->_append_log('Suministros cargados: ' . ($r->{suministros_ok} // 0));
        $self->_append_errores($r->{errores});
    }

    if ($resultado->{usuarios}) {
        my $r = $resultado->{usuarios};
        $self->_append_log('--- Usuarios ---');
        $self->_append_log('Mensaje: ' . ($r->{mensaje} // ''));
        $self->_append_log('Usuarios registrados: ' . ($r->{usuarios_registrados} // 0));
        $self->_append_errores($r->{errores});
    }
}

sub _accion_generar_reportes {
    my ($self) = @_;

    if (!$self->{inventario}) {
        $self->_append_log('Error: no hay inventario configurado.');
        return;
    }

    my $dir = $self->{path_reportes};

    my $resultado = $self->{inventario}->generarTodosLosReportes($dir);

    $self->_append_log('=== GENERACIÓN DE REPORTES ===');
    $self->_append_log($resultado->{medicamentos_msg} // 'Sin resultado de medicamentos');
    $self->_append_log($resultado->{equipos_msg}      // 'Sin resultado de equipos');
    $self->_append_log($resultado->{suministros_msg}  // 'Sin resultado de suministros');
    $self->_append_log($resultado->{proveedores_msg}  // 'Sin resultado de proveedores');
    $self->_append_log($resultado->{matriz_msg}       // 'Sin resultado de matriz');

    if ($self->{gestor_usuarios}) {
        my ($ok, $msg) = $self->{gestor_usuarios}->generarReporteUsuarios(
            "$dir/avl_personal.dot",
            "$dir/avl_personal.png"
        );
        $self->_append_log($msg);
    }

    if (-e "$dir/bst_equipos.png") {
        $self->_mostrar_reporte('Reporte BST - Inventario de Equipos', "$dir/bst_equipos.png");
    }
}

sub _accion_ver_resumen {
    my ($self) = @_;

    $self->_append_log('=== RESUMEN DEL SISTEMA ===');

    if ($self->{inventario}) {
        my $r = $self->{inventario}->obtenerResumenGeneral();

        $self->_append_log('Medicamentos: ' . ($r->{medicamentos} // 0));
        $self->_append_log('Equipos: ' . ($r->{equipos} // 0));
        $self->_append_log('Suministros: ' . ($r->{suministros} // 0));
        $self->_append_log('Proveedores: ' . ($r->{proveedores} // 0));
        $self->_append_log('Total items: ' . ($r->{total_items} // 0));
    }
    else {
        $self->_append_log('Inventario no configurado.');
    }

    if ($self->{gestor_usuarios}) {
        my $r = $self->{gestor_usuarios}->obtenerResumen();
        $self->_append_log('Total usuarios: ' . ($r->{total_usuarios} // 0));

        if (defined $r->{por_departamento} && ref($r->{por_departamento}) eq 'HASH') {
            foreach my $depto (sort keys %{ $r->{por_departamento} }) {
                $self->_append_log("Usuarios en $depto: " . $r->{por_departamento}{$depto});
            }
        }
    }
    else {
        $self->_append_log('Gestor de usuarios no configurado.');
    }
}

sub _accion_logout {
    my ($self) = @_;

    $self->_append_log('Cerrando sesión de administrador...');

    if (defined $self->{on_logout} && ref($self->{on_logout}) eq 'CODE') {
        $self->{on_logout}->();
        return;
    }

    $self->{window}->hide();
}

# =========================================================
# Gestión de equipos
# =========================================================
sub _accion_registrar_equipo {
    my ($self) = @_;

    if (!$self->{inventario}) {
        $self->_mostrar_error('No hay inventario configurado.');
        return;
    }

    my $datos = $self->_dialogo_equipo('Registrar equipo');
    return if !defined $datos;

    my $equipo = modelos::Equipo->new(
        codigo          => $datos->{codigo},
        nombre          => $datos->{nombre},
        fabricante      => $datos->{fabricante},
        precio_unitario => $datos->{precio_unitario},
        cantidad        => $datos->{cantidad},
        fecha_ingreso   => $datos->{fecha_ingreso},
        nivel_minimo    => $datos->{nivel_minimo},
    );

    my ($ok, $msg) = $self->{inventario}->registrarEquipo($equipo, $datos->{nit_proveedor});

    $self->_append_log('=== REGISTRO DE EQUIPO ===');
    $self->_append_log($msg);

    $ok ? $self->_mostrar_info($msg) : $self->_mostrar_error($msg);
}

sub _accion_buscar_equipo {
    my ($self) = @_;

    my $codigo = $self->_pedir_codigo('Buscar equipo', 'Ingrese el código del equipo:');
    return if !defined $codigo || $codigo eq '';

    my $equipo = $self->{inventario}->buscarEquipo($codigo);

    $self->_append_log('=== BÚSQUEDA DE EQUIPO ===');

    if ($equipo) {
        my $texto = $self->_detalles_equipo($equipo);
        $self->_append_log($texto);
        $self->_mostrar_texto_largo('Equipo encontrado', $texto);
    } else {
        $self->_append_log("No se encontró el equipo $codigo");
        $self->_mostrar_error("No se encontró el equipo $codigo");
    }
}

sub _accion_editar_equipo {
    my ($self) = @_;

    my $codigo = $self->_pedir_codigo('Editar equipo', 'Ingrese el código del equipo a editar:');
    return if !defined $codigo || $codigo eq '';

    my $equipo = $self->{inventario}->buscarEquipo($codigo);

    if (!$equipo) {
        $self->_append_log("No se encontró el equipo $codigo");
        $self->_mostrar_error("No se encontró el equipo $codigo");
        return;
    }

    my $datos = $self->_dialogo_equipo(
        'Editar equipo',
        {
            codigo          => $equipo->getCodigo(),
            nombre          => $equipo->getNombre(),
            fabricante      => $equipo->getFabricante(),
            precio_unitario => $equipo->getPrecioUnitario(),
            cantidad        => $equipo->getCantidad(),
            fecha_ingreso   => $equipo->getFechaIngreso(),
            nivel_minimo    => $equipo->getNivelMinimo(),
            nit_proveedor   => '',
        },
        1,
    );

    return if !defined $datos;

    my ($ok, $msg) = $self->{inventario}->editarEquipo(
        $codigo,
        nombre          => $datos->{nombre},
        fabricante      => $datos->{fabricante},
        precio_unitario => $datos->{precio_unitario},
        cantidad        => $datos->{cantidad},
        fecha_ingreso   => $datos->{fecha_ingreso},
        nivel_minimo    => $datos->{nivel_minimo},
    );

    $self->_append_log('=== EDICIÓN DE EQUIPO ===');
    $self->_append_log($msg);

    if ($ok) {
        my $editado = $self->{inventario}->buscarEquipo($codigo);
        $self->_mostrar_texto_largo('Equipo actualizado', $self->_detalles_equipo($editado));
    } else {
        $self->_mostrar_error($msg);
    }
}

sub _accion_eliminar_equipo {
    my ($self) = @_;

    my $codigo = $self->_pedir_codigo('Eliminar equipo', 'Ingrese el código del equipo a eliminar:');
    return if !defined $codigo || $codigo eq '';

    my $equipo = $self->{inventario}->buscarEquipo($codigo);

    if (!$equipo) {
        $self->_append_log("No se encontró el equipo $codigo");
        $self->_mostrar_error("No se encontró el equipo $codigo");
        return;
    }

    my $confirm = Gtk3::MessageDialog->new(
        $self->{window},
        'destroy-with-parent',
        'question',
        'yes-no',
        "¿Desea eliminar el equipo $codigo?"
    );

    my $respuesta = $confirm->run();
    $confirm->destroy();

    return if $respuesta ne 'yes';

    my ($ok, $msg) = $self->{inventario}->eliminarEquipo($codigo);

    $self->_append_log('=== ELIMINACIÓN DE EQUIPO ===');
    $self->_append_log($msg);

    $ok ? $self->_mostrar_info($msg) : $self->_mostrar_error($msg);
}

sub _accion_ver_recorrido_equipos {
    my ($self) = @_;

    my $recorrido = $self->_pedir_tipo_recorrido('Seleccione el recorrido del BST de equipos:');
    return if !defined $recorrido;

    my $texto = $self->{inventario}->equiposComoTexto($recorrido);

    $self->_append_log("=== RECORRIDO DE EQUIPOS: $recorrido ===");
    $self->_append_log($texto);

    $self->_mostrar_texto_largo("Equipos - $recorrido", $texto);
}

# =========================================================
# Gestión de suministros
# =========================================================
sub _accion_registrar_suministro {
    my ($self) = @_;

    if (!$self->{inventario}) {
        $self->_mostrar_error('No hay inventario configurado.');
        return;
    }

    my $datos = $self->_dialogo_suministro('Registrar suministro');
    return if !defined $datos;

    my $suministro = modelos::Suministro->new(
        codigo            => $datos->{codigo},
        nombre            => $datos->{nombre},
        fabricante        => $datos->{fabricante},
        precio_unitario   => $datos->{precio_unitario},
        cantidad          => $datos->{cantidad},
        fecha_vencimiento => $datos->{fecha_vencimiento},
        nivel_minimo      => $datos->{nivel_minimo},
    );

    my ($ok, $msg) = $self->{inventario}->registrarSuministro($suministro, $datos->{nit_proveedor});

    $self->_append_log('=== REGISTRO DE SUMINISTRO ===');
    $self->_append_log($msg);

    $ok ? $self->_mostrar_info($msg) : $self->_mostrar_error($msg);
}

sub _accion_buscar_suministro {
    my ($self) = @_;

    my $codigo = $self->_pedir_codigo('Buscar suministro', 'Ingrese el código del suministro:');
    return if !defined $codigo || $codigo eq '';

    my $suministro = $self->{inventario}->buscarSuministro($codigo);

    $self->_append_log('=== BÚSQUEDA DE SUMINISTRO ===');

    if ($suministro) {
        my $texto = $self->_detalles_suministro($suministro);
        $self->_append_log($texto);
        $self->_mostrar_texto_largo('Suministro encontrado', $texto);
    } else {
        $self->_append_log("No se encontró el suministro $codigo");
        $self->_mostrar_error("No se encontró el suministro $codigo");
    }
}

sub _accion_editar_suministro {
    my ($self) = @_;

    my $codigo = $self->_pedir_codigo('Editar suministro', 'Ingrese el código del suministro a editar:');
    return if !defined $codigo || $codigo eq '';

    my $suministro = $self->{inventario}->buscarSuministro($codigo);

    if (!$suministro) {
        $self->_append_log("No se encontró el suministro $codigo");
        $self->_mostrar_error("No se encontró el suministro $codigo");
        return;
    }

    my $datos = $self->_dialogo_suministro(
        'Editar suministro',
        {
            codigo            => $suministro->getCodigo(),
            nombre            => $suministro->getNombre(),
            fabricante        => $suministro->getFabricante(),
            precio_unitario   => $suministro->getPrecioUnitario(),
            cantidad          => $suministro->getCantidad(),
            fecha_vencimiento => $suministro->getFechaVencimiento(),
            nivel_minimo      => $suministro->getNivelMinimo(),
            nit_proveedor     => '',
        },
        1,
    );

    return if !defined $datos;

    my ($ok, $msg) = $self->{inventario}->editarSuministro(
        $codigo,
        nombre            => $datos->{nombre},
        fabricante        => $datos->{fabricante},
        precio_unitario   => $datos->{precio_unitario},
        cantidad          => $datos->{cantidad},
        fecha_vencimiento => $datos->{fecha_vencimiento},
        nivel_minimo      => $datos->{nivel_minimo},
    );

    $self->_append_log('=== EDICIÓN DE SUMINISTRO ===');
    $self->_append_log($msg);

    if ($ok) {
        my $editado = $self->{inventario}->buscarSuministro($codigo);
        $self->_mostrar_texto_largo('Suministro actualizado', $self->_detalles_suministro($editado));
    } else {
        $self->_mostrar_error($msg);
    }
}

sub _accion_eliminar_suministro {
    my ($self) = @_;

    my $codigo = $self->_pedir_codigo('Eliminar suministro', 'Ingrese el código del suministro a eliminar:');
    return if !defined $codigo || $codigo eq '';

    my $suministro = $self->{inventario}->buscarSuministro($codigo);

    if (!$suministro) {
        $self->_append_log("No se encontró el suministro $codigo");
        $self->_mostrar_error("No se encontró el suministro $codigo");
        return;
    }

    my $confirm = Gtk3::MessageDialog->new(
        $self->{window},
        'destroy-with-parent',
        'question',
        'yes-no',
        "¿Desea eliminar el suministro $codigo?"
    );

    my $respuesta = $confirm->run();
    $confirm->destroy();

    return if $respuesta ne 'yes';

    my ($ok, $msg) = $self->{inventario}->eliminarSuministro($codigo);

    $self->_append_log('=== ELIMINACIÓN DE SUMINISTRO ===');
    $self->_append_log($msg);

    $ok ? $self->_mostrar_info($msg) : $self->_mostrar_error($msg);
}

sub _accion_ver_recorrido_suministros {
    my ($self) = @_;

    my $recorrido = $self->_pedir_tipo_recorrido('Seleccione el recorrido del Árbol B de suministros:');
    return if !defined $recorrido;

    my $texto = $self->{inventario}->suministrosComoTexto($recorrido);

    $self->_append_log("=== RECORRIDO DE SUMINISTROS: $recorrido ===");
    $self->_append_log($texto);

    $self->_mostrar_texto_largo("Suministros - $recorrido", $texto);
}

# =========================================================
# Gestión de usuarios
# =========================================================
sub _accion_registrar_usuario {
    my ($self) = @_;

    if (!$self->{gestor_usuarios}) {
        $self->_mostrar_error('No hay gestor de usuarios configurado.');
        return;
    }

    my $datos = $self->_dialogo_usuario('Registrar usuario');
    return if !defined $datos;

    my $usuario = modelos::PersonalMedico->new(
        numero_colegio  => $datos->{numero_colegio},
        nombre_completo => $datos->{nombre_completo},
        tipo_usuario    => $datos->{tipo_usuario},
        departamento    => $datos->{departamento},
        especialidad    => $datos->{especialidad},
        contrasena      => $datos->{contrasena},
    );

    my ($ok, $msg) = $self->{gestor_usuarios}->registrarUsuario($usuario);

    $self->_append_log('=== REGISTRO DE USUARIO ===');
    $self->_append_log($msg);

    $ok ? $self->_mostrar_info($msg) : $self->_mostrar_error($msg);
}

sub _accion_buscar_usuario {
    my ($self) = @_;

    my $colegio = $self->_pedir_codigo('Buscar usuario', 'Ingrese el número de colegio:');
    return if !defined $colegio || $colegio eq '';

    my $usuario = $self->{gestor_usuarios}->buscarUsuario($colegio);

    $self->_append_log('=== BÚSQUEDA DE USUARIO ===');

    if ($usuario) {
        my $texto = $self->_detalles_usuario($usuario);
        $self->_append_log($texto);
        $self->_mostrar_texto_largo('Usuario encontrado', $texto);
    } else {
        $self->_append_log("No se encontró el usuario $colegio");
        $self->_mostrar_error("No se encontró el usuario $colegio");
    }
}

sub _accion_eliminar_usuario {
    my ($self) = @_;

    my $colegio = $self->_pedir_codigo('Eliminar usuario', 'Ingrese el número de colegio del usuario a eliminar:');
    return if !defined $colegio || $colegio eq '';

    my $usuario = $self->{gestor_usuarios}->buscarUsuario($colegio);

    if (!$usuario) {
        $self->_append_log("No se encontró el usuario $colegio");
        $self->_mostrar_error("No se encontró el usuario $colegio");
        return;
    }

    my $confirm = Gtk3::MessageDialog->new(
        $self->{window},
        'destroy-with-parent',
        'question',
        'yes-no',
        "¿Desea eliminar el usuario $colegio?"
    );

    my $respuesta = $confirm->run();
    $confirm->destroy();

    return if $respuesta ne 'yes';

    my ($ok, $msg) = $self->{gestor_usuarios}->eliminarUsuario($colegio);

    $self->_append_log('=== ELIMINACIÓN DE USUARIO ===');
    $self->_append_log($msg);

    $ok ? $self->_mostrar_info($msg) : $self->_mostrar_error($msg);
}

sub _accion_ver_recorrido_usuarios {
    my ($self) = @_;

    if (!$self->{gestor_usuarios}) {
        $self->_mostrar_error('No hay gestor de usuarios configurado.');
        return;
    }

    my $recorrido = $self->_pedir_tipo_recorrido('Seleccione el recorrido del AVL de usuarios:');
    return if !defined $recorrido;

    my $lista;
    if ($recorrido eq 'PREORDEN') {
        $lista = $self->{gestor_usuarios}->listarUsuariosPreOrden();
    }
    elsif ($recorrido eq 'POSTORDEN') {
        $lista = $self->{gestor_usuarios}->listarUsuariosPostOrden();
    }
    else {
        $lista = $self->{gestor_usuarios}->listarUsuarios();
    }

    my $texto = $self->_lista_usuarios_a_texto($lista);

    $self->_append_log("=== RECORRIDO DE USUARIOS: $recorrido ===");
    $self->_append_log($texto);

    $self->_mostrar_texto_largo("Usuarios - $recorrido", $texto);
}

sub _accion_ver_tabla_usuarios {
    my ($self) = @_;

    if (!$self->{gestor_usuarios}) {
        $self->_mostrar_error('No hay gestor de usuarios configurado.');
        return;
    }

    my $usuarios = $self->{gestor_usuarios}->listarUsuarios();

    my $dialog = Gtk3::Dialog->new_with_buttons(
        'Tabla de personal médico',
        $self->{window},
        ['modal'],
        'gtk-close' => 'close',
    );

    $dialog->set_default_size(950, 440);

    my $content = $dialog->get_content_area();

    my $scrolled = Gtk3::ScrolledWindow->new();
    $scrolled->set_policy('automatic', 'automatic');
    $content->pack_start($scrolled, TRUE, TRUE, 0);

    my $store = Gtk3::ListStore->new(
        'Glib::String', 'Glib::String', 'Glib::String',
        'Glib::String', 'Glib::String'
    );

    foreach my $u (@$usuarios) {
        my $iter = $store->append();
        $store->set(
            $iter,
            0, $u->getNumeroColegio(),
            1, $u->getNombreCompleto(),
            2, $u->getTipoUsuario(),
            3, $u->getDepartamento(),
            4, $u->getEspecialidad(),
        );
    }

    my $tree = Gtk3::TreeView->new($store);

    my @columnas = (
        ['No. Colegio', 0],
        ['Nombre completo', 1],
        ['Tipo', 2],
        ['Departamento', 3],
        ['Especialidad', 4],
    );

    foreach my $col (@columnas) {
        my ($titulo, $idx) = @$col;
        my $renderer = Gtk3::CellRendererText->new();
        my $column = Gtk3::TreeViewColumn->new_with_attributes($titulo, $renderer, text => $idx);
        $column->set_resizable(TRUE);
        $tree->append_column($column);
    }

    $scrolled->add($tree);

    $self->_append_log('=== TABLA DE PERSONAL MÉDICO ===');
    $self->_append_log('Se abrió la tabla de usuarios.');

    $dialog->show_all();
    $dialog->run();
    $dialog->destroy();
}

# =========================================================
# Consultar y comparar proveedor/fabricante
# =========================================================
sub _accion_consultar_proveedor_fabricante {
    my ($self) = @_;

    if (!$self->{inventario}) {
        $self->_mostrar_error('No hay inventario configurado.');
        return;
    }

    my $nit = $self->_pedir_texto(
        'Consultar proveedor/fabricante',
        'Ingrese el NIT del proveedor a consultar:'
    );

    return if !defined $nit || $nit eq '';

    if (!$self->{inventario}->existeProveedorEnResumen($nit)) {
        $self->_append_log("No hay resumen proveedor/fabricante para el NIT $nit");
        $self->_mostrar_error("No hay resumen proveedor/fabricante para el NIT $nit");
        return;
    }

    my $texto = $self->{inventario}->consultarProveedorFabricanteComoTexto($nit);

    $self->_append_log("=== CONSULTA PROVEEDOR/FABRICANTE: $nit ===");
    $self->_append_log($texto);

    $self->_mostrar_texto_largo("Proveedor/Fabricante - $nit", $texto);
}

sub _accion_comparar_proveedor_fabricante {
    my ($self) = @_;

    if (!$self->{inventario}) {
        $self->_mostrar_error('No hay inventario configurado.');
        return;
    }

    my $filas = $self->{inventario}->listarComparacionProveedorFabricante();

    if (!defined $filas || !@$filas) {
        $self->_append_log('No hay datos para comparar proveedor/fabricante.');
        $self->_mostrar_error('No hay datos para comparar proveedor/fabricante.');
        return;
    }

    my $dialog = Gtk3::Dialog->new_with_buttons(
        'Comparación Proveedor/Fabricante',
        $self->{window},
        ['modal'],
        'gtk-close' => 'close',
    );

    $dialog->set_default_size(980, 460);

    my $content = $dialog->get_content_area();

    my $scrolled = Gtk3::ScrolledWindow->new();
    $scrolled->set_policy('automatic', 'automatic');
    $content->pack_start($scrolled, TRUE, TRUE, 0);

    my $store = Gtk3::ListStore->new(
        'Glib::String', 'Glib::String', 'Glib::String',
        'Glib::String', 'Glib::String', 'Glib::String'
    );

    foreach my $fila (@$filas) {
        my $iter = $store->append();
        $store->set(
            $iter,
            0, $fila->{nit},
            1, $fila->{fabricante},
            2, $fila->{medicamento},
            3, $fila->{equipo},
            4, $fila->{suministro},
            5, $fila->{total},
        );
    }

    my $tree = Gtk3::TreeView->new($store);

    my @columnas = (
        ['Proveedor',   0],
        ['Fabricante',  1],
        ['Medicamento', 2],
        ['Equipo',      3],
        ['Suministro',  4],
        ['Total',       5],
    );

    foreach my $col (@columnas) {
        my ($titulo, $idx) = @$col;
        my $renderer = Gtk3::CellRendererText->new();
        my $column = Gtk3::TreeViewColumn->new_with_attributes($titulo, $renderer, text => $idx);
        $column->set_resizable(TRUE);
        $tree->append_column($column);
    }

    $scrolled->add($tree);

    $self->_append_log('=== COMPARACIÓN PROVEEDOR/FABRICANTE ===');
    $self->_append_log('Se abrió la tabla comparativa de proveedor/fabricante.');

    $dialog->show_all();
    $dialog->run();
    $dialog->destroy();
}

# =========================================================
# Visor de reportes
# =========================================================
sub _mostrar_reporte {
    my ($self, $titulo, $ruta_png) = @_;

    if (!defined $ruta_png || $ruta_png eq '' || !-e $ruta_png) {
        $self->_append_log("No se encontró el reporte: $ruta_png");
        $self->_mostrar_error("No se encontró el reporte:\n$ruta_png");
        return;
    }

    $self->{lbl_reporte}->set_text("$titulo\n$ruta_png");

    eval {
        $self->{image_reporte}->set_from_file($ruta_png);
        1;
    } or do {
        my $err = $@ || 'Error desconocido al mostrar la imagen';
        $self->_append_log("Error al mostrar reporte: $err");
        $self->_mostrar_error("No se pudo mostrar el reporte:\n$err");
    };
}

# =========================================================
# Helpers UI
# =========================================================
sub show {
    my ($self) = @_;
    $self->{window}->show_all() if defined $self->{window};
}

sub hide {
    my ($self) = @_;
    $self->{window}->hide() if defined $self->{window};
}

sub get_window {
    my ($self) = @_;
    return $self->{window};
}

sub set_admin_name {
    my ($self, $nombre) = @_;
    return if !defined $self->{lbl_bienvenida};

    $nombre = defined $nombre && $nombre ne '' ? $nombre : 'administrador';
    $self->{lbl_bienvenida}->set_text("Bienvenido, $nombre.");
}

sub _append_log {
    my ($self, $texto) = @_;

    return if !defined $self->{textbuffer_log};

    $texto = '' if !defined $texto;

    my $iter = $self->{textbuffer_log}->get_end_iter();
    $self->{textbuffer_log}->insert($iter, $texto . "\n");
}

sub _append_errores {
    my ($self, $errores) = @_;

    if (defined $errores && ref($errores) eq 'ARRAY' && @$errores) {
        $self->_append_log('Errores:');
        foreach my $err (@$errores) {
            $self->_append_log(" - $err");
        }
    } else {
        $self->_append_log('Errores: ninguno');
    }
}

sub _seleccionar_archivo {
    my ($self, $titulo) = @_;

    my $dialog = Gtk3::FileChooserDialog->new(
        $titulo,
        $self->{window},
        'open',
        'gtk-cancel' => 'cancel',
        'gtk-open'   => 'accept',
    );

    my $filter = Gtk3::FileFilter->new();
    $filter->set_name('Archivos JSON');
    $filter->add_pattern('*.json');
    $dialog->add_filter($filter);

    my $respuesta = $dialog->run();
    my $filename;

    if ($respuesta eq 'accept') {
        $filename = $dialog->get_filename();
    }

    $dialog->destroy();
    return $filename;
}

sub _pedir_codigo {
    my ($self, $titulo, $label_texto) = @_;
    return $self->_pedir_texto($titulo, $label_texto);
}

sub _pedir_texto {
    my ($self, $titulo, $label_texto) = @_;

    my $dialog = Gtk3::Dialog->new_with_buttons(
        $titulo,
        $self->{window},
        ['modal'],
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok',
    );

    my $content = $dialog->get_content_area();
    my $entry = Gtk3::Entry->new();

    $content->pack_start(Gtk3::Label->new($label_texto), FALSE, FALSE, 6);
    $content->pack_start($entry, FALSE, FALSE, 6);

    $dialog->show_all();
    my $respuesta = $dialog->run();

    if ($respuesta ne 'ok') {
        $dialog->destroy();
        return undef;
    }

    my $valor = $entry->get_text();
    $dialog->destroy();

    return $valor;
}

sub _pedir_tipo_recorrido {
    my ($self, $label_texto) = @_;

    my $dialog = Gtk3::Dialog->new_with_buttons(
        'Seleccionar recorrido',
        $self->{window},
        ['modal'],
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok',
    );

    my $content = $dialog->get_content_area();
    my $combo = Gtk3::ComboBoxText->new();

    $combo->append_text('INORDEN');
    $combo->append_text('PREORDEN');
    $combo->append_text('POSTORDEN');
    $combo->set_active(0);

    $content->pack_start(Gtk3::Label->new($label_texto), FALSE, FALSE, 6);
    $content->pack_start($combo, FALSE, FALSE, 6);

    $dialog->show_all();
    my $respuesta = $dialog->run();

    if ($respuesta ne 'ok') {
        $dialog->destroy();
        return undef;
    }

    my $recorrido = $combo->get_active_text();
    $dialog->destroy();

    return $recorrido;
}

sub _dialogo_equipo {
    my ($self, $titulo, $datos_iniciales, $solo_edicion) = @_;

    $datos_iniciales ||= {};
    $solo_edicion ||= 0;

    my $dialog = Gtk3::Dialog->new_with_buttons(
        $titulo,
        $self->{window},
        ['modal'],
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok',
    );

    $dialog->set_default_size(420, 320);

    my $content = $dialog->get_content_area();
    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(8);
    $grid->set_border_width(8);
    $content->pack_start($grid, TRUE, TRUE, 0);

    my %entries;
    my @campos = (
        ['codigo',          'Código'],
        ['nombre',          'Nombre'],
        ['fabricante',      'Fabricante'],
        ['precio_unitario', 'Precio unitario'],
        ['cantidad',        'Cantidad'],
        ['fecha_ingreso',   'Fecha ingreso (YYYY-MM-DD)'],
        ['nivel_minimo',    'Nivel mínimo'],
        ['nit_proveedor',   'NIT proveedor (opcional)'],
    );

    my $fila = 0;
    foreach my $campo (@campos) {
        my ($clave, $texto) = @$campo;

        my $lbl = Gtk3::Label->new($texto . ':');
        $lbl->set_xalign(0);

        my $entry = Gtk3::Entry->new();
        $entry->set_text(defined $datos_iniciales->{$clave} ? $datos_iniciales->{$clave} : '');

        if ($solo_edicion && $clave eq 'codigo') {
            $entry->set_editable(FALSE);
        }

        $grid->attach($lbl,   0, $fila, 1, 1);
        $grid->attach($entry, 1, $fila, 1, 1);

        $entries{$clave} = $entry;
        $fila++;
    }

    $dialog->show_all();
    my $respuesta = $dialog->run();

    if ($respuesta ne 'ok') {
        $dialog->destroy();
        return undef;
    }

    my %datos;
    foreach my $clave (keys %entries) {
        $datos{$clave} = $entries{$clave}->get_text();
    }

    $dialog->destroy();
    return \%datos;
}

sub _dialogo_suministro {
    my ($self, $titulo, $datos_iniciales, $solo_edicion) = @_;

    $datos_iniciales ||= {};
    $solo_edicion ||= 0;

    my $dialog = Gtk3::Dialog->new_with_buttons(
        $titulo,
        $self->{window},
        ['modal'],
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok',
    );

    $dialog->set_default_size(420, 320);

    my $content = $dialog->get_content_area();
    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(8);
    $grid->set_border_width(8);
    $content->pack_start($grid, TRUE, TRUE, 0);

    my %entries;
    my @campos = (
        ['codigo',            'Código'],
        ['nombre',            'Nombre'],
        ['fabricante',        'Fabricante'],
        ['precio_unitario',   'Precio unitario'],
        ['cantidad',          'Cantidad'],
        ['fecha_vencimiento', 'Fecha vencimiento (YYYY-MM-DD)'],
        ['nivel_minimo',      'Nivel mínimo'],
        ['nit_proveedor',     'NIT proveedor (opcional)'],
    );

    my $fila = 0;
    foreach my $campo (@campos) {
        my ($clave, $texto) = @$campo;

        my $lbl = Gtk3::Label->new($texto . ':');
        $lbl->set_xalign(0);

        my $entry = Gtk3::Entry->new();
        $entry->set_text(defined $datos_iniciales->{$clave} ? $datos_iniciales->{$clave} : '');

        if ($solo_edicion && $clave eq 'codigo') {
            $entry->set_editable(FALSE);
        }

        $grid->attach($lbl,   0, $fila, 1, 1);
        $grid->attach($entry, 1, $fila, 1, 1);

        $entries{$clave} = $entry;
        $fila++;
    }

    $dialog->show_all();
    my $respuesta = $dialog->run();

    if ($respuesta ne 'ok') {
        $dialog->destroy();
        return undef;
    }

    my %datos;
    foreach my $clave (keys %entries) {
        $datos{$clave} = $entries{$clave}->get_text();
    }

    $dialog->destroy();
    return \%datos;
}

sub _dialogo_usuario {
    my ($self, $titulo, $datos_iniciales) = @_;

    $datos_iniciales ||= {};

    my $dialog = Gtk3::Dialog->new_with_buttons(
        $titulo,
        $self->{window},
        ['modal'],
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok',
    );

    $dialog->set_default_size(460, 360);

    my $content = $dialog->get_content_area();
    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(8);
    $grid->set_border_width(8);
    $content->pack_start($grid, TRUE, TRUE, 0);

    my %entries;
    my @campos = (
        ['numero_colegio',  'No. colegio'],
        ['nombre_completo', 'Nombre completo'],
        ['tipo_usuario',    'Tipo usuario (TIPO-01..TIPO-05)'],
        ['departamento',    'Departamento (DEP-MED, DEP-CIR, DEP-FAR, DEP-LAB, DEP-ADM)'],
        ['especialidad',    'Especialidad'],
        ['contrasena',      'Contraseña'],
    );

    my $fila = 0;
    foreach my $campo (@campos) {
        my ($clave, $texto) = @$campo;

        my $lbl = Gtk3::Label->new($texto . ':');
        $lbl->set_xalign(0);

        my $entry = Gtk3::Entry->new();
        $entry->set_text(defined $datos_iniciales->{$clave} ? $datos_iniciales->{$clave} : '');

        if ($clave eq 'contrasena') {
            $entry->set_visibility(FALSE);
            $entry->set_invisible_char('*');
        }

        $grid->attach($lbl,   0, $fila, 1, 1);
        $grid->attach($entry, 1, $fila, 1, 1);

        $entries{$clave} = $entry;
        $fila++;
    }

    $dialog->show_all();
    my $respuesta = $dialog->run();

    if ($respuesta ne 'ok') {
        $dialog->destroy();
        return undef;
    }

    my %datos;
    foreach my $clave (keys %entries) {
        $datos{$clave} = $entries{$clave}->get_text();
    }

    $dialog->destroy();
    return \%datos;
}

sub _mostrar_texto_largo {
    my ($self, $titulo, $texto) = @_;

    my $dialog = Gtk3::Dialog->new_with_buttons(
        $titulo,
        $self->{window},
        ['modal'],
        'gtk-close' => 'close',
    );

    $dialog->set_default_size(620, 400);

    my $content = $dialog->get_content_area();

    my $scrolled = Gtk3::ScrolledWindow->new();
    $scrolled->set_policy('automatic', 'automatic');
    $content->pack_start($scrolled, TRUE, TRUE, 0);

    my $textview = Gtk3::TextView->new();
    $textview->set_editable(FALSE);
    $textview->set_cursor_visible(FALSE);
    $textview->set_wrap_mode('word');

    my $buffer = $textview->get_buffer();
    $buffer->set_text(defined $texto ? $texto : '');

    $scrolled->add($textview);

    $dialog->show_all();
    $dialog->run();
    $dialog->destroy();
}

sub _detalles_equipo {
    my ($self, $equipo) = @_;

    return 'Equipo no disponible' if !defined $equipo;

    return
        "Código: " . $equipo->getCodigo() . "\n" .
        "Nombre: " . $equipo->getNombre() . "\n" .
        "Fabricante: " . $equipo->getFabricante() . "\n" .
        "Precio unitario: " . $equipo->getPrecioUnitario() . "\n" .
        "Cantidad: " . $equipo->getCantidad() . "\n" .
        "Fecha ingreso: " . $equipo->getFechaIngreso() . "\n" .
        "Nivel mínimo: " . $equipo->getNivelMinimo();
}

sub _detalles_suministro {
    my ($self, $suministro) = @_;

    return 'Suministro no disponible' if !defined $suministro;

    return
        "Código: " . $suministro->getCodigo() . "\n" .
        "Nombre: " . $suministro->getNombre() . "\n" .
        "Fabricante: " . $suministro->getFabricante() . "\n" .
        "Precio unitario: " . $suministro->getPrecioUnitario() . "\n" .
        "Cantidad: " . $suministro->getCantidad() . "\n" .
        "Fecha vencimiento: " . $suministro->getFechaVencimiento() . "\n" .
        "Nivel mínimo: " . $suministro->getNivelMinimo();
}

sub _detalles_usuario {
    my ($self, $usuario) = @_;

    return 'Usuario no disponible' if !defined $usuario;

    return
        "No. colegio: " . $usuario->getNumeroColegio() . "\n" .
        "Nombre completo: " . $usuario->getNombreCompleto() . "\n" .
        "Tipo usuario: " . $usuario->getTipoUsuario() . "\n" .
        "Departamento: " . $usuario->getDepartamento() . "\n" .
        "Especialidad: " . $usuario->getEspecialidad();
}

sub _lista_usuarios_a_texto {
    my ($self, $lista) = @_;

    return 'Sin usuarios' if !defined $lista || scalar(@$lista) == 0;

    my @lineas = map { $_->toString() } @$lista;
    return join("\n", @lineas);
}

sub _mostrar_error {
    my ($self, $mensaje) = @_;

    my $dialog = Gtk3::MessageDialog->new(
        $self->{window},
        'destroy-with-parent',
        'error',
        'ok',
        $mensaje
    );

    $dialog->run();
    $dialog->destroy();
}

sub _mostrar_info {
    my ($self, $mensaje) = @_;

    my $dialog = Gtk3::MessageDialog->new(
        $self->{window},
        'destroy-with-parent',
        'info',
        'ok',
        $mensaje
    );

    $dialog->run();
    $dialog->destroy();
}

1;