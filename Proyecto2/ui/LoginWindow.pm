package ui::LoginWindow;

use strict;
use warnings;
use utf8;

use Gtk3;
use Glib qw/TRUE FALSE/;

use ui::AdminWindow;
use ui::UsuarioWindow;

sub new {
    my ($class, %args) = @_;

    my $self = {
        gestor_usuarios  => $args{gestor_usuarios},
        gestor_permisos  => $args{gestor_permisos},
        inventario       => $args{inventario},
        cargador_json    => $args{cargador_json},

        admin_user       => defined $args{admin_user}     ? $args{admin_user}     : 'admin',
        admin_password   => defined $args{admin_password} ? $args{admin_password} : 'admin123',

        on_exit          => $args{on_exit},

        # Datos personales / académicos
        datos_personales => $args{datos_personales} || {
            nombre    => 'Tu nombre aquí',
            carnet    => 'Tu carnet aquí',
            curso     => 'Estructuras de Datos',
            seccion   => 'Sección X',
            proyecto  => 'EDD MedTrack',
            fase      => 'Fase 2',
            semestre  => '2026',
        },

        window           => undef,
        entry_usuario    => undef,
        entry_password   => undef,
        lbl_estado       => undef,

        admin_window     => undef,
        usuario_window   => undef,
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
    $window->set_title('EDD MedTrack - Login');
    $window->set_default_size(520, 360);
    $window->set_border_width(12);
    $window->set_resizable(FALSE);

    $window->signal_connect(
        destroy => sub {
            if (defined $self->{on_exit} && ref($self->{on_exit}) eq 'CODE') {
                $self->{on_exit}->();
            } else {
                Gtk3::main_quit();
            }
        }
    );

    my $main_vbox = Gtk3::Box->new('vertical', 10);
    $window->add($main_vbox);

    my $lbl_app = Gtk3::Label->new();
    $lbl_app->set_markup('<span size="x-large" weight="bold">EDD MedTrack</span>');
    $lbl_app->set_xalign(0);

    my $lbl_desc = Gtk3::Label->new(
        'Sistema hospitalario con estructuras no lineales, carga JSON y visualización de reportes.'
    );
    $lbl_desc->set_xalign(0);
    $lbl_desc->set_line_wrap(TRUE);

    $main_vbox->pack_start($lbl_app, FALSE, FALSE, 0);
    $main_vbox->pack_start($lbl_desc, FALSE, FALSE, 0);

    my $notebook = Gtk3::Notebook->new();
    $main_vbox->pack_start($notebook, TRUE, TRUE, 0);

    # =====================================================
    # Pestaña 1: Login
    # =====================================================
    my $pagina_login = Gtk3::Box->new('vertical', 12);
    $pagina_login->set_border_width(12);

    my $lbl_titulo = Gtk3::Label->new();
    $lbl_titulo->set_markup('<span size="large" weight="bold">Inicio de sesión</span>');
    $lbl_titulo->set_xalign(0);

    my $lbl_subtitulo = Gtk3::Label->new(
        'Admin: usa credenciales del sistema. Usuario: usa número de colegio y contraseña.'
    );
    $lbl_subtitulo->set_xalign(0);
    $lbl_subtitulo->set_line_wrap(TRUE);

    $pagina_login->pack_start($lbl_titulo, FALSE, FALSE, 0);
    $pagina_login->pack_start($lbl_subtitulo, FALSE, FALSE, 0);

    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(10);
    $grid->set_column_spacing(10);

    my $lbl_usuario = Gtk3::Label->new('Usuario / No. Colegio:');
    $lbl_usuario->set_xalign(0);

    my $entry_usuario = Gtk3::Entry->new();
    $entry_usuario->set_hexpand(TRUE);
    $entry_usuario->set_placeholder_text('Ej. admin o COL-10001');

    my $lbl_password = Gtk3::Label->new('Contraseña:');
    $lbl_password->set_xalign(0);

    my $entry_password = Gtk3::Entry->new();
    $entry_password->set_visibility(FALSE);
    $entry_password->set_invisible_char('*');
    $entry_password->set_hexpand(TRUE);
    $entry_password->set_placeholder_text('Ingrese su contraseña');

    $grid->attach($lbl_usuario,    0, 0, 1, 1);
    $grid->attach($entry_usuario,  1, 0, 1, 1);
    $grid->attach($lbl_password,   0, 1, 1, 1);
    $grid->attach($entry_password, 1, 1, 1, 1);

    $pagina_login->pack_start($grid, FALSE, FALSE, 0);

    my $lbl_estado = Gtk3::Label->new('');
    $lbl_estado->set_xalign(0);
    $pagina_login->pack_start($lbl_estado, FALSE, FALSE, 0);

    my $button_box = Gtk3::Box->new('horizontal', 10);

    my $btn_admin   = Gtk3::Button->new('Ingresar como Admin');
    my $btn_usuario = Gtk3::Button->new('Ingresar como Usuario');
    my $btn_limpiar = Gtk3::Button->new('Limpiar');
    my $btn_salir   = Gtk3::Button->new('Salir');

    $button_box->pack_start($btn_admin,   TRUE, TRUE, 0);
    $button_box->pack_start($btn_usuario, TRUE, TRUE, 0);
    $button_box->pack_start($btn_limpiar, TRUE, TRUE, 0);
    $button_box->pack_start($btn_salir,   TRUE, TRUE, 0);

    $pagina_login->pack_start($button_box, FALSE, FALSE, 0);

    # =====================================================
    # Pestaña 2: Mis datos
    # =====================================================
    my $pagina_datos = $self->_crear_pestana_datos();

    $notebook->append_page($pagina_login, Gtk3::Label->new('Iniciar sesión'));
    $notebook->append_page($pagina_datos, Gtk3::Label->new('Mis datos'));

    # Eventos
    $btn_admin->signal_connect(clicked => sub { $self->_login_admin(); });
    $btn_usuario->signal_connect(clicked => sub { $self->_login_usuario(); });
    $btn_limpiar->signal_connect(clicked => sub { $self->limpiar_campos(); });

    $btn_salir->signal_connect(
        clicked => sub {
            if (defined $self->{on_exit} && ref($self->{on_exit}) eq 'CODE') {
                $self->{on_exit}->();
            } else {
                Gtk3::main_quit();
            }
        }
    );

    $entry_password->signal_connect(
        activate => sub { $self->_login_usuario(); }
    );

    $self->{window}         = $window;
    $self->{entry_usuario}  = $entry_usuario;
    $self->{entry_password} = $entry_password;
    $self->{lbl_estado}     = $lbl_estado;
}

sub _crear_pestana_datos {
    my ($self) = @_;

    my $datos = $self->{datos_personales};

    my $pagina = Gtk3::Box->new('vertical', 10);
    $pagina->set_border_width(12);

    my $lbl_titulo = Gtk3::Label->new();
    $lbl_titulo->set_markup('<span size="large" weight="bold">Mis datos</span>');
    $lbl_titulo->set_xalign(0);

    $pagina->pack_start($lbl_titulo, FALSE, FALSE, 0);

    my $grid = Gtk3::Grid->new();
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(12);

    my @campos = (
        ['Nombre',   $datos->{nombre}],
        ['Carnet',   $datos->{carnet}],
        ['Curso',    $datos->{curso}],
        ['Sección',  $datos->{seccion}],
        ['Proyecto', $datos->{proyecto}],
        ['Fase',     $datos->{fase}],
        ['Semestre', $datos->{semestre}],
    );

    my $fila = 0;
    foreach my $campo (@campos) {
        my ($etiqueta, $valor) = @$campo;

        my $lbl_a = Gtk3::Label->new($etiqueta . ':');
        $lbl_a->set_xalign(0);

        my $lbl_b = Gtk3::Label->new(defined $valor ? $valor : '');
        $lbl_b->set_xalign(0);

        $grid->attach($lbl_a, 0, $fila, 1, 1);
        $grid->attach($lbl_b, 1, $fila, 1, 1);
        $fila++;
    }

    $pagina->pack_start($grid, FALSE, FALSE, 0);

    my $lbl_nota = Gtk3::Label->new(
        'Esta pestaña muestra la información del autor del proyecto.'
    );
    $lbl_nota->set_xalign(0);
    $lbl_nota->set_line_wrap(TRUE);

    $pagina->pack_start($lbl_nota, FALSE, FALSE, 0);

    return $pagina;
}

# =========================================================
# Login admin
# =========================================================
sub _login_admin {
    my ($self) = @_;

    my $usuario  = $self->_texto_usuario();
    my $password = $self->_texto_password();

    if ($usuario eq '' || $password eq '') {
        $self->_set_estado('Debe completar usuario y contraseña.');
        $self->_mostrar_error('Debe completar usuario y contraseña.');
        return;
    }

    if ($usuario ne $self->{admin_user} || $password ne $self->{admin_password}) {
        $self->_set_estado('Credenciales de administrador incorrectas.');
        $self->_mostrar_error('Credenciales de administrador incorrectas.');
        return;
    }

    $self->_set_estado('Autenticación de administrador exitosa.');

    if (!defined $self->{admin_window}) {
        $self->{admin_window} = ui::AdminWindow->new(
            inventario      => $self->{inventario},
            gestor_usuarios => $self->{gestor_usuarios},
            cargador_json   => $self->{cargador_json},
            on_logout       => sub {
                $self->_cerrar_admin_y_volver_login();
            },
        );

        $self->{admin_window}->set_admin_name('Administrador del Sistema');
    }

    $self->hide();
    $self->{admin_window}->show();
    $self->limpiar_campos();
}

sub _cerrar_admin_y_volver_login {
    my ($self) = @_;

    if (defined $self->{admin_window}) {
        $self->{admin_window}->hide();
    }

    $self->show();
}

# =========================================================
# Login usuario
# =========================================================
sub _login_usuario {
    my ($self) = @_;

    my $usuario  = $self->_texto_usuario();
    my $password = $self->_texto_password();

    if ($usuario eq '' || $password eq '') {
        $self->_set_estado('Debe completar usuario y contraseña.');
        $self->_mostrar_error('Debe completar usuario y contraseña.');
        return;
    }

    if (!defined $self->{gestor_usuarios}) {
        $self->_set_estado('No hay gestor de usuarios configurado.');
        $self->_mostrar_error('No hay gestor de usuarios configurado.');
        return;
    }

    my ($ok, $msg, $obj_usuario) = $self->{gestor_usuarios}->autenticarUsuario($usuario, $password);

    if (!$ok) {
        $self->_set_estado($msg);
        $self->_mostrar_error($msg);
        return;
    }

    $self->_set_estado('Autenticación de usuario exitosa.');

    if (defined $self->{usuario_window}) {
        $self->{usuario_window}->hide();
        $self->{usuario_window} = undef;
    }

    $self->{usuario_window} = ui::UsuarioWindow->new(
        inventario      => $self->{inventario},
        gestor_permisos => $self->{gestor_permisos},
        usuario         => $obj_usuario,
        on_logout       => sub {
            $self->_cerrar_usuario_y_volver_login();
        },
    );

    $self->hide();
    $self->{usuario_window}->show();
    $self->limpiar_campos();
}

sub _cerrar_usuario_y_volver_login {
    my ($self) = @_;

    if (defined $self->{usuario_window}) {
        $self->{usuario_window}->hide();
        $self->{usuario_window} = undef;
    }

    $self->show();
}

# =========================================================
# Helpers de UI
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

sub limpiar_campos {
    my ($self) = @_;

    $self->{entry_usuario}->set_text('')  if defined $self->{entry_usuario};
    $self->{entry_password}->set_text('') if defined $self->{entry_password};

    $self->_set_estado('');

    $self->{entry_usuario}->grab_focus() if defined $self->{entry_usuario};
}

sub _texto_usuario {
    my ($self) = @_;
    return '' if !defined $self->{entry_usuario};
    return $self->{entry_usuario}->get_text();
}

sub _texto_password {
    my ($self) = @_;
    return '' if !defined $self->{entry_password};
    return $self->{entry_password}->get_text();
}

sub _set_estado {
    my ($self, $texto) = @_;
    return if !defined $self->{lbl_estado};

    my $seguro = defined $texto ? $texto : '';
    $seguro =~ s/&/&amp;/g;
    $seguro =~ s/</&lt;/g;
    $seguro =~ s/>/&gt;/g;

    $self->{lbl_estado}->set_markup("<span foreground='gray25'>$seguro</span>");
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

1;