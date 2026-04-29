package ui::UsuarioWindow;

use strict;
use warnings;
use utf8;

use Gtk3;
use Glib qw/TRUE FALSE/;
use Time::Piece;
use Time::Seconds;

sub new {
    my ($class, %args) = @_;

    my $self = {
        inventario      => $args{inventario},
        gestor_permisos => $args{gestor_permisos},
        usuario         => $args{usuario},
        on_logout       => $args{on_logout},

        window          => undef,

        lbl_bienvenida  => undef,
        lbl_permisos    => undef,

        lbl_med_count   => undef,
        lbl_equ_count   => undef,
        lbl_sum_count   => undef,
        lbl_alert_stock => undef,
        lbl_alert_venc  => undef,

        store_general   => undef,
        store_busqueda  => undef,
        store_alertas   => undef,

        entry_busqueda  => undef,
        combo_campo     => undef,
        check_critico   => undef,
        check_vencen    => undef,
    };

    bless $self, $class;
    $self->_build_ui();
    $self->_refrescar_todo();

    return $self;
}

# =========================================================
# Construcción de interfaz
# =========================================================
sub _build_ui {
    my ($self) = @_;

    my $window = Gtk3::Window->new('toplevel');
    $window->set_title('EDD MedTrack - Panel de Usuario');
    $window->set_default_size(1280, 820);
    $window->set_border_width(12);

    $window->signal_connect(
        destroy => sub {
            if (defined $self->{on_logout} && ref($self->{on_logout}) eq 'CODE') {
                $self->{on_logout}->();
            } else {
                Gtk3::main_quit();
            }
        }
    );

    my $main_vbox = Gtk3::Box->new('vertical', 10);
    $window->add($main_vbox);

    # =====================================================
    # Encabezado
    # =====================================================
    my $lbl_titulo = Gtk3::Label->new();
    $lbl_titulo->set_markup('<span size="x-large" weight="bold">Panel del Personal Médico</span>');
    $lbl_titulo->set_xalign(0);

    my $lbl_bienvenida = Gtk3::Label->new('Bienvenido.');
    $lbl_bienvenida->set_xalign(0);

    my $lbl_permisos = Gtk3::Label->new('Permisos:');
    $lbl_permisos->set_xalign(0);
    $lbl_permisos->set_line_wrap(TRUE);

    $main_vbox->pack_start($lbl_titulo, FALSE, FALSE, 0);
    $main_vbox->pack_start($lbl_bienvenida, FALSE, FALSE, 0);
    $main_vbox->pack_start($lbl_permisos, FALSE, FALSE, 0);

    # =====================================================
    # Resumen rápido
    # =====================================================
    my $frame_resumen = Gtk3::Frame->new('Vista general del inventario');
    $main_vbox->pack_start($frame_resumen, FALSE, FALSE, 0);

    my $grid_resumen = Gtk3::Grid->new();
    $grid_resumen->set_row_spacing(8);
    $grid_resumen->set_column_spacing(12);
    $grid_resumen->set_border_width(8);
    $frame_resumen->add($grid_resumen);

    my $lbl_med_count   = Gtk3::Label->new('Medicamentos visibles: 0');
    my $lbl_equ_count   = Gtk3::Label->new('Equipos visibles: 0');
    my $lbl_sum_count   = Gtk3::Label->new('Suministros visibles: 0');
    my $lbl_alert_stock = Gtk3::Label->new('Stock crítico: 0');
    my $lbl_alert_venc  = Gtk3::Label->new('Próximos a vencer: 0');

    $lbl_med_count->set_xalign(0);
    $lbl_equ_count->set_xalign(0);
    $lbl_sum_count->set_xalign(0);
    $lbl_alert_stock->set_xalign(0);
    $lbl_alert_venc->set_xalign(0);

    $grid_resumen->attach($lbl_med_count,   0, 0, 1, 1);
    $grid_resumen->attach($lbl_equ_count,   1, 0, 1, 1);
    $grid_resumen->attach($lbl_sum_count,   2, 0, 1, 1);
    $grid_resumen->attach($lbl_alert_stock, 0, 1, 1, 1);
    $grid_resumen->attach($lbl_alert_venc,  1, 1, 1, 1);

    # =====================================================
    # Barra de acciones
    # =====================================================
    my $acciones_box = Gtk3::Box->new('horizontal', 10);
    $main_vbox->pack_start($acciones_box, FALSE, FALSE, 0);

    my $btn_actualizar = Gtk3::Button->new('Actualizar vista');
    my $btn_logout     = Gtk3::Button->new('Cerrar sesión');

    $acciones_box->pack_start($btn_actualizar, FALSE, FALSE, 0);
    $acciones_box->pack_start($btn_logout,     FALSE, FALSE, 0);

    # =====================================================
    # Notebook principal
    # =====================================================
    my $notebook = Gtk3::Notebook->new();
    $main_vbox->pack_start($notebook, TRUE, TRUE, 0);

    # -----------------------------------------------------
    # Pestaña 1: inventario visible
    # -----------------------------------------------------
    my $pagina_general = Gtk3::Box->new('vertical', 8);
    $pagina_general->set_border_width(8);

    my $store_general = Gtk3::ListStore->new(
        'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',
        'Glib::String', 'Glib::String', 'Glib::String'
    );

    my $tree_general = Gtk3::TreeView->new($store_general);
    $self->_agregar_columnas_treeview(
        $tree_general,
        ['Tipo', 0],
        ['Código', 1],
        ['Nombre', 2],
        ['Fabricante/Lab', 3],
        ['Cantidad', 4],
        ['Fecha', 5],
        ['Estado', 6],
    );

    my $scroll_general = Gtk3::ScrolledWindow->new();
    $scroll_general->set_policy('automatic', 'automatic');
    $scroll_general->add($tree_general);

    $pagina_general->pack_start(
        Gtk3::Label->new('Inventario visible según los permisos de consulta del usuario:'),
        FALSE, FALSE, 0
    );
    $pagina_general->pack_start($scroll_general, TRUE, TRUE, 0);

    $notebook->append_page($pagina_general, Gtk3::Label->new('Inventario'));

    # -----------------------------------------------------
    # Pestaña 2: búsqueda avanzada de medicamentos
    # -----------------------------------------------------
    my $pagina_busqueda = Gtk3::Box->new('vertical', 8);
    $pagina_busqueda->set_border_width(8);

    my $frame_busqueda = Gtk3::Frame->new('Búsqueda avanzada de medicamentos');
    $pagina_busqueda->pack_start($frame_busqueda, FALSE, FALSE, 0);

    my $grid_busqueda = Gtk3::Grid->new();
    $grid_busqueda->set_row_spacing(8);
    $grid_busqueda->set_column_spacing(8);
    $grid_busqueda->set_border_width(8);
    $frame_busqueda->add($grid_busqueda);

    my $entry_busqueda = Gtk3::Entry->new();
    $entry_busqueda->set_placeholder_text('Ingrese texto a buscar');

    my $combo_campo = Gtk3::ComboBoxText->new();
    $combo_campo->append_text('TODOS');
    $combo_campo->append_text('CODIGO');
    $combo_campo->append_text('NOMBRE');
    $combo_campo->append_text('FABRICANTE');
    $combo_campo->append_text('PRINCIPIO_ACTIVO');
    $combo_campo->set_active(0);

    my $check_critico = Gtk3::CheckButton->new('Solo stock crítico');
    my $check_vencen  = Gtk3::CheckButton->new('Solo vencen en 30 días');

    my $btn_buscar_meds = Gtk3::Button->new('Buscar medicamentos');

    $grid_busqueda->attach(Gtk3::Label->new('Texto:'), 0, 0, 1, 1);
    $grid_busqueda->attach($entry_busqueda,            1, 0, 1, 1);
    $grid_busqueda->attach(Gtk3::Label->new('Campo:'), 0, 1, 1, 1);
    $grid_busqueda->attach($combo_campo,               1, 1, 1, 1);
    $grid_busqueda->attach($check_critico,             0, 2, 1, 1);
    $grid_busqueda->attach($check_vencen,              1, 2, 1, 1);
    $grid_busqueda->attach($btn_buscar_meds,           0, 3, 2, 1);

    my $store_busqueda = Gtk3::ListStore->new(
        'Glib::String', 'Glib::String', 'Glib::String',
        'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String'
    );

    my $tree_busqueda = Gtk3::TreeView->new($store_busqueda);
    $self->_agregar_columnas_treeview(
        $tree_busqueda,
        ['Código', 0],
        ['Nombre', 1],
        ['Principio activo', 2],
        ['Fabricante/Lab', 3],
        ['Cantidad', 4],
        ['Vencimiento', 5],
        ['Estado', 6],
    );

    my $scroll_busqueda = Gtk3::ScrolledWindow->new();
    $scroll_busqueda->set_policy('automatic', 'automatic');
    $scroll_busqueda->add($tree_busqueda);

    $pagina_busqueda->pack_start($scroll_busqueda, TRUE, TRUE, 0);

    $notebook->append_page($pagina_busqueda, Gtk3::Label->new('Búsqueda'));

    # -----------------------------------------------------
    # Pestaña 3: alertas
    # -----------------------------------------------------
    my $pagina_alertas = Gtk3::Box->new('vertical', 8);
    $pagina_alertas->set_border_width(8);

    $pagina_alertas->pack_start(
        Gtk3::Label->new('Indicadores de stock crítico y alertas de vencimiento:'),
        FALSE, FALSE, 0
    );

    my $store_alertas = Gtk3::ListStore->new(
        'Glib::String', 'Glib::String', 'Glib::String',
        'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String'
    );

    my $tree_alertas = Gtk3::TreeView->new($store_alertas);
    $self->_agregar_columnas_treeview(
        $tree_alertas,
        ['Alerta', 0],
        ['Tipo', 1],
        ['Código', 2],
        ['Nombre', 3],
        ['Fabricante/Lab', 4],
        ['Cantidad', 5],
        ['Fecha', 6],
    );

    my $scroll_alertas = Gtk3::ScrolledWindow->new();
    $scroll_alertas->set_policy('automatic', 'automatic');
    $scroll_alertas->add($tree_alertas);

    $pagina_alertas->pack_start($scroll_alertas, TRUE, TRUE, 0);

    $notebook->append_page($pagina_alertas, Gtk3::Label->new('Alertas'));

    # =====================================================
    # Eventos
    # =====================================================
    $btn_actualizar->signal_connect(clicked => sub { $self->_refrescar_todo(); });

    $btn_logout->signal_connect(clicked => sub {
        if (defined $self->{on_logout} && ref($self->{on_logout}) eq 'CODE') {
            $self->{on_logout}->();
        } else {
            Gtk3::main_quit();
        }
    });

    $btn_buscar_meds->signal_connect(clicked => sub {
        $self->_buscar_medicamentos();
    });

    $entry_busqueda->signal_connect(activate => sub {
        $self->_buscar_medicamentos();
    });

    # =====================================================
    # Referencias
    # =====================================================
    $self->{window}          = $window;
    $self->{lbl_bienvenida}  = $lbl_bienvenida;
    $self->{lbl_permisos}    = $lbl_permisos;

    $self->{lbl_med_count}   = $lbl_med_count;
    $self->{lbl_equ_count}   = $lbl_equ_count;
    $self->{lbl_sum_count}   = $lbl_sum_count;
    $self->{lbl_alert_stock} = $lbl_alert_stock;
    $self->{lbl_alert_venc}  = $lbl_alert_venc;

    $self->{store_general}   = $store_general;
    $self->{store_busqueda}  = $store_busqueda;
    $self->{store_alertas}   = $store_alertas;

    $self->{entry_busqueda}  = $entry_busqueda;
    $self->{combo_campo}     = $combo_campo;
    $self->{check_critico}   = $check_critico;
    $self->{check_vencen}    = $check_vencen;
}

# =========================================================
# Refresco general
# =========================================================
sub _refrescar_todo {
    my ($self) = @_;

    $self->_actualizar_encabezado();
    $self->_actualizar_resumen();
    $self->_cargar_inventario_visible();
    $self->_cargar_alertas();
    $self->_buscar_medicamentos();
}

sub _actualizar_encabezado {
    my ($self) = @_;

    my $usuario = $self->{usuario};
    my $nombre  = $self->_obtener_campo($usuario, 'nombre_completo') // 'Usuario';
    my $tipo    = $self->_obtener_campo($usuario, 'tipo_usuario')    // 'SIN_TIPO';
    my $depto   = $self->_obtener_campo($usuario, 'departamento')    // 'SIN_DEPTO';

    $self->{lbl_bienvenida}->set_text("Bienvenido: $nombre");
    $self->{lbl_permisos}->set_text(
        "Tipo de usuario: $tipo | Departamento: $depto | Puede consultar: " .
        join(', ', @{ $self->_tipos_consultables() })
    );
}

sub _actualizar_resumen {
    my ($self) = @_;

    my $rows_general = $self->_obtener_filas_inventario_visible();
    my $alertas      = $self->_obtener_alertas();

    my $med = 0;
    my $equ = 0;
    my $sum = 0;
    my $stock = 0;
    my $venc  = 0;

    foreach my $r (@$rows_general) {
        $med++ if $r->{tipo} eq 'MEDICAMENTO';
        $equ++ if $r->{tipo} eq 'EQUIPO';
        $sum++ if $r->{tipo} eq 'SUMINISTRO';
    }

    foreach my $a (@$alertas) {
        $stock++ if $a->{alerta} eq 'STOCK CRITICO';
        $venc++  if $a->{alerta} eq 'VENCIMIENTO';
    }

    $self->{lbl_med_count}->set_text("Medicamentos visibles: $med");
    $self->{lbl_equ_count}->set_text("Equipos visibles: $equ");
    $self->{lbl_sum_count}->set_text("Suministros visibles: $sum");
    $self->{lbl_alert_stock}->set_text("Stock crítico: $stock");
    $self->{lbl_alert_venc}->set_text("Próximos a vencer: $venc");
}

# =========================================================
# Inventario visible
# =========================================================
sub _cargar_inventario_visible {
    my ($self) = @_;

    my $store = $self->{store_general};
    $store->clear();

    my $rows = $self->_obtener_filas_inventario_visible();

    foreach my $r (@$rows) {
        my $iter = $store->append();
        $store->set(
            $iter,
            0, $r->{tipo},
            1, $r->{codigo},
            2, $r->{nombre},
            3, $r->{fabricante},
            4, $r->{cantidad},
            5, $r->{fecha},
            6, $r->{estado},
        );
    }
}

sub _obtener_filas_inventario_visible {
    my ($self) = @_;

    my @rows;
    my %puede = map { $_ => 1 } @{ $self->_tipos_consultables() };

    if ($puede{MEDICAMENTO}) {
        foreach my $m (@{ $self->{inventario}->listarMedicamentos() || [] }) {
            push @rows, {
                tipo       => 'MEDICAMENTO',
                codigo     => $self->_obtener_campo($m, 'codigo'),
                nombre     => $self->_obtener_campo($m, 'nombre'),
                fabricante => $self->_obtener_fabricante($m),
                cantidad   => $self->_obtener_campo($m, 'cantidad') // 0,
                fecha      => $self->_obtener_campo($m, 'fecha_vencimiento'),
                estado     => $self->_estado_item($m),
                obj        => $m,
            };
        }
    }

    if ($puede{EQUIPO}) {
        foreach my $e (@{ $self->{inventario}->listarEquipos() || [] }) {
            push @rows, {
                tipo       => 'EQUIPO',
                codigo     => $self->_obtener_campo($e, 'codigo'),
                nombre     => $self->_obtener_campo($e, 'nombre'),
                fabricante => $self->_obtener_fabricante($e),
                cantidad   => $self->_obtener_campo($e, 'cantidad') // 0,
                fecha      => $self->_obtener_campo($e, 'fecha_ingreso'),
                estado     => $self->_estado_item($e),
                obj        => $e,
            };
        }
    }

    if ($puede{SUMINISTRO}) {
        foreach my $s (@{ $self->{inventario}->listarSuministros() || [] }) {
            push @rows, {
                tipo       => 'SUMINISTRO',
                codigo     => $self->_obtener_campo($s, 'codigo'),
                nombre     => $self->_obtener_campo($s, 'nombre'),
                fabricante => $self->_obtener_fabricante($s),
                cantidad   => $self->_obtener_campo($s, 'cantidad') // 0,
                fecha      => $self->_obtener_campo($s, 'fecha_vencimiento'),
                estado     => $self->_estado_item($s),
                obj        => $s,
            };
        }
    }

    return \@rows;
}

# =========================================================
# Búsqueda avanzada de medicamentos
# =========================================================
sub _buscar_medicamentos {
    my ($self) = @_;

    my $store = $self->{store_busqueda};
    $store->clear();

    if (!$self->_puede_consultar('MEDICAMENTO')) {
        return;
    }

    my $texto       = lc($self->{entry_busqueda}->get_text() // '');
    my $campo       = $self->{combo_campo}->get_active_text() // 'TODOS';
    my $solo_crit   = $self->{check_critico}->get_active() ? 1 : 0;
    my $solo_vencen = $self->{check_vencen}->get_active() ? 1 : 0;

    foreach my $m (@{ $self->{inventario}->listarMedicamentos() || [] }) {
        my $codigo     = $self->_obtener_campo($m, 'codigo')            // '';
        my $nombre     = $self->_obtener_campo($m, 'nombre')            // '';
        my $principio  = $self->_obtener_campo($m, 'principio_activo')  // '';
        my $fabricante = $self->_obtener_fabricante($m)                 // '';
        my $cantidad   = $self->_obtener_campo($m, 'cantidad')          // 0;
        my $fecha      = $self->_obtener_campo($m, 'fecha_vencimiento') // '';
        my $estado     = $self->_estado_item($m);

        my $coincide = 1;

        if ($texto ne '') {
            my %map = (
                CODIGO           => lc($codigo),
                NOMBRE           => lc($nombre),
                FABRICANTE       => lc($fabricante),
                PRINCIPIO_ACTIVO => lc($principio),
            );

            if ($campo eq 'TODOS') {
                my $full = join(' ', values %map);
                $coincide = index($full, $texto) >= 0 ? 1 : 0;
            } else {
                $coincide = index(($map{$campo} // ''), $texto) >= 0 ? 1 : 0;
            }
        }

        next if !$coincide;
        next if $solo_crit   && !$self->_es_stock_critico($m);
        next if $solo_vencen && !$self->_vence_pronto($m, 30);

        my $iter = $store->append();
        $store->set(
            $iter,
            0, $codigo,
            1, $nombre,
            2, $principio,
            3, $fabricante,
            4, $cantidad,
            5, $fecha,
            6, $estado,
        );
    }
}

# =========================================================
# Alertas
# =========================================================
sub _cargar_alertas {
    my ($self) = @_;

    my $store = $self->{store_alertas};
    $store->clear();

    my $alertas = $self->_obtener_alertas();

    foreach my $a (@$alertas) {
        my $iter = $store->append();
        $store->set(
            $iter,
            0, $a->{alerta},
            1, $a->{tipo},
            2, $a->{codigo},
            3, $a->{nombre},
            4, $a->{fabricante},
            5, $a->{cantidad},
            6, $a->{fecha},
        );
    }
}

sub _obtener_alertas {
    my ($self) = @_;

    my @alertas;
    my $rows = $self->_obtener_filas_inventario_visible();

    foreach my $r (@$rows) {
        my $obj = $r->{obj};

        if ($self->_es_stock_critico($obj)) {
            push @alertas, {
                alerta     => 'STOCK CRITICO',
                tipo       => $r->{tipo},
                codigo     => $r->{codigo},
                nombre     => $r->{nombre},
                fabricante => $r->{fabricante},
                cantidad   => $r->{cantidad},
                fecha      => $r->{fecha} // '',
            };
        }

        if (($r->{tipo} eq 'MEDICAMENTO' || $r->{tipo} eq 'SUMINISTRO') && $self->_vence_pronto($obj, 30)) {
            push @alertas, {
                alerta     => 'VENCIMIENTO',
                tipo       => $r->{tipo},
                codigo     => $r->{codigo},
                nombre     => $r->{nombre},
                fabricante => $r->{fabricante},
                cantidad   => $r->{cantidad},
                fecha      => $r->{fecha} // '',
            };
        }
    }

    return \@alertas;
}

# =========================================================
# Helpers de permisos y estado
# =========================================================
sub _tipos_consultables {
    my ($self) = @_;

    return [qw(MEDICAMENTO EQUIPO SUMINISTRO)]
        if !defined $self->{gestor_permisos};

    my $permisos = $self->{gestor_permisos}->obtenerPermisosUsuario($self->{usuario});
    return $permisos->{consulta} || [];
}

sub _puede_consultar {
    my ($self, $tipo) = @_;

    my %set = map { $_ => 1 } @{ $self->_tipos_consultables() };
    return $set{$tipo} ? 1 : 0;
}

sub _estado_item {
    my ($self, $obj) = @_;

    my @estados;

    push @estados, 'STOCK CRITICO' if $self->_es_stock_critico($obj);
    push @estados, 'VENCE PRONTO'  if $self->_vence_pronto($obj, 30);

    return @estados ? join(' | ', @estados) : 'NORMAL';
}

sub _es_stock_critico {
    my ($self, $obj) = @_;

    my $cantidad = $self->_obtener_campo($obj, 'cantidad');
    my $minimo   = $self->_obtener_campo($obj, 'nivel_minimo');

    return 0 if !defined $cantidad || !defined $minimo;
    return $cantidad <= $minimo ? 1 : 0;
}

sub _vence_pronto {
    my ($self, $obj, $dias_limite) = @_;

    my $fecha = $self->_obtener_campo($obj, 'fecha_vencimiento');
    return 0 if !defined $fecha || $fecha eq '';

    my $dias = $self->_dias_hasta_fecha($fecha);
    return 0 if !defined $dias;

    return ($dias >= 0 && $dias <= $dias_limite) ? 1 : 0;
}

sub _dias_hasta_fecha {
    my ($self, $fecha_texto) = @_;

    return undef if !defined $fecha_texto || $fecha_texto eq '';

    my $objetivo;
    eval {
        $objetivo = Time::Piece->strptime($fecha_texto, '%Y-%m-%d');
    };
    return undef if $@ || !defined $objetivo;

    my $hoy = localtime;
    my $delta = $objetivo - $hoy;

    return int($delta / ONE_DAY);
}

# =========================================================
# Helpers de UI
# =========================================================
sub _agregar_columnas_treeview {
    my ($self, $tree, @columnas) = @_;

    foreach my $col (@columnas) {
        my ($titulo, $idx) = @$col;
        my $renderer = Gtk3::CellRendererText->new();
        my $column = Gtk3::TreeViewColumn->new_with_attributes($titulo, $renderer, text => $idx);
        $column->set_resizable(TRUE);
        $tree->append_column($column);
    }
}

# =========================================================
# Helpers genéricos de objetos
# =========================================================
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

sub _obtener_fabricante {
    my ($self, $obj) = @_;
    return $self->_obtener_campo($obj, 'fabricante', 'laboratorio') // '';
}

sub _camelizar {
    my ($self, $texto) = @_;
    $texto //= '';
    $texto =~ s/(^|_)([a-z])/\U$2/g;
    return $texto;
}

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

1;