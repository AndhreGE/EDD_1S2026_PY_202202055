package EDDMedTrack::Services::AppContainer;

BEGIN {
    require Cwd;
    require File::Basename;
    require File::Spec;

    my $module_dir  = File::Basename::dirname(Cwd::abs_path(__FILE__));
    my $backend_dir = Cwd::abs_path(File::Spec->catdir($module_dir, '..', '..', '..'));
    my $dominio_dir = File::Spec->catdir($backend_dir, 'dominio');

    push @INC, $dominio_dir unless grep { defined $_ && $_ eq $dominio_dir } @INC;
}

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path);

use estructuras::modulos::Inventario;
use estructuras::modulos::GestorUsuarios;
use estructuras::modulos::GestorPermisos;
use estructuras::modulos::GestorColaboracion;
use estructuras::modulos::GestorMensajeria;
use estructuras::modulos::CargadorJSON;

sub new {
    my ($class, %args) = @_;

    my $base_path = $args{base_path} // _resolver_backend_path();

    my $self = {
        base_path      => $base_path,
        dominio_path   => File::Spec->catdir($base_path, 'dominio'),
        cargas_dir     => $args{cargas_dir}     // File::Spec->catdir($base_path, 'cargas'),
        chats_dir      => $args{chats_dir}      // File::Spec->catdir($base_path, 'chats'),
        reportes_dir   => $args{reportes_dir}   // File::Spec->catdir($base_path, 'reportesdot'),

        admin_user     => $args{admin_user} // $ENV{EDD_ADMIN_USER} // 'admin',
        admin_pass     => $args{admin_pass} // $ENV{EDD_ADMIN_PASS} // 'admin123',

        inventario          => undef,
        gestor_usuarios     => undef,
        gestor_permisos     => undef,
        gestor_colaboracion => undef,
        gestor_mensajeria   => undef,
        cargador_json       => undef,
    };

    bless $self, $class;

    $self->_asegurar_directorios();
    $self->_inicializar_servicios();

    if ($args{auto_cargar_datos}) {
        $self->cargarDatosIniciales();
    }

    if ($args{auto_sembrar_demo}) {
        $self->sembrarDatosDemo();
    }

    return $self;
}

# =========================================================
# Inicialización principal
# =========================================================
sub _inicializar_servicios {
    my ($self) = @_;

    # 1. Núcleo del inventario
    $self->{inventario} = estructuras::modulos::Inventario->new();

    # 2. Usuarios (AVL + Hash)
    $self->{gestor_usuarios} = estructuras::modulos::GestorUsuarios->new();

    # 3. Permisos
    $self->{gestor_permisos} = estructuras::modulos::GestorPermisos->new();

    # 4. Colaboración (grafo)
    $self->{gestor_colaboracion} = estructuras::modulos::GestorColaboracion->new(
        gestor_usuarios => $self->{gestor_usuarios},
    );

    # 5. Mensajería (usa colaboración + LZW)
    $self->{gestor_mensajeria} = estructuras::modulos::GestorMensajeria->new(
        gestor_colaboracion => $self->{gestor_colaboracion},
        base_dir            => $self->{chats_dir},
        auto_guardado       => 1,
    );

    # 6. Cargador JSON
    $self->{cargador_json} = $self->_crear_cargador_json();

    # 7. Sincronización inicial
    $self->sincronizarEstructuras();
}

sub _crear_cargador_json {
    my ($self) = @_;

    my @intentos = (
        sub {
            return estructuras::modulos::CargadorJSON->new(
                inventario      => $self->{inventario},
                gestor_usuarios => $self->{gestor_usuarios},
            );
        },
        sub {
            return estructuras::modulos::CargadorJSON->new(
                inventario  => $self->{inventario},
                usuarios    => $self->{gestor_usuarios},
            );
        },
        sub {
            return estructuras::modulos::CargadorJSON->new(
                $self->{inventario},
                $self->{gestor_usuarios},
            );
        },
        sub {
            return estructuras::modulos::CargadorJSON->new();
        },
    );

    foreach my $intento (@intentos) {
        my $obj = eval { $intento->() };
        return $obj if defined $obj;
    }

    die "No se pudo inicializar estructuras::modulos::CargadorJSON";
}

# =========================================================
# Getters de servicios
# =========================================================
sub getBasePath {
    my ($self) = @_;
    return $self->{base_path};
}

sub getDominioPath {
    my ($self) = @_;
    return $self->{dominio_path};
}

sub getCargasDir {
    my ($self) = @_;
    return $self->{cargas_dir};
}

sub getChatsDir {
    my ($self) = @_;
    return $self->{chats_dir};
}

sub getReportesDir {
    my ($self) = @_;
    return $self->{reportes_dir};
}

sub getInventario {
    my ($self) = @_;
    return $self->{inventario};
}

sub getGestorUsuarios {
    my ($self) = @_;
    return $self->{gestor_usuarios};
}

sub getGestorPermisos {
    my ($self) = @_;
    return $self->{gestor_permisos};
}

sub getGestorColaboracion {
    my ($self) = @_;
    return $self->{gestor_colaboracion};
}

sub getGestorMensajeria {
    my ($self) = @_;
    return $self->{gestor_mensajeria};
}

sub getCargadorJSON {
    my ($self) = @_;
    return $self->{cargador_json};
}

sub serviciosComoHash {
    my ($self) = @_;

    return {
        inventario          => $self->{inventario},
        gestor_usuarios     => $self->{gestor_usuarios},
        gestor_permisos     => $self->{gestor_permisos},
        gestor_colaboracion => $self->{gestor_colaboracion},
        gestor_mensajeria   => $self->{gestor_mensajeria},
        cargador_json       => $self->{cargador_json},
    };
}

# =========================================================
# Credenciales de admin
# =========================================================
sub obtenerCredencialesAdmin {
    my ($self) = @_;

    return {
        usuario => $self->{admin_user},
        clave   => $self->{admin_pass},
    };
}

sub validarCredencialesAdmin {
    my ($self, $usuario, $clave) = @_;

    return 0 if !defined $usuario || !defined $clave;

    return ($usuario eq $self->{admin_user} && $clave eq $self->{admin_pass}) ? 1 : 0;
}

# =========================================================
# Sincronización entre estructuras
# =========================================================
sub sincronizarEstructuras {
    my ($self) = @_;

    my %resultado = (
        ok                   => 1,
        mensajes             => [],
        sincronizacion_hash  => 0,
        sincronizacion_grafo => 0,
    );

    if ($self->{gestor_usuarios} && $self->{gestor_usuarios}->can('sincronizarTablaHash')) {
        my ($ok_hash, $msg_hash) = $self->{gestor_usuarios}->sincronizarTablaHash();
        $resultado{sincronizacion_hash} = $ok_hash ? 1 : 0;
        push @{ $resultado{mensajes} }, $msg_hash if defined $msg_hash;
        $resultado{ok} = 0 if !$ok_hash;
    }

    if ($self->{gestor_colaboracion} && $self->{gestor_colaboracion}->can('sincronizarDesdeGestorUsuarios')) {
        my ($ok_grafo, $msg_grafo) = $self->{gestor_colaboracion}->sincronizarDesdeGestorUsuarios();
        $resultado{sincronizacion_grafo} = $ok_grafo ? 1 : 0;
        push @{ $resultado{mensajes} }, $msg_grafo if defined $msg_grafo;
        $resultado{ok} = 0 if !$ok_grafo;
    }

    return \%resultado;
}

# =========================================================
# Carga inicial desde JSON
# =========================================================
sub cargarDatosIniciales {
    my ($self, %args) = @_;

    my $archivo_inventario = $args{archivo_inventario}
        // File::Spec->catfile($self->{cargas_dir}, 'inventario_masivo.json');

    my $archivo_usuarios = $args{archivo_usuarios}
        // File::Spec->catfile($self->{cargas_dir}, 'usuarios_departamentales.json');

    my %resultado = (
        ok                    => 1,
        inventario_cargado    => 0,
        usuarios_cargados     => 0,
        mensajes              => [],
        errores               => [],
    );

    # Carga de inventario
    if (-e $archivo_inventario) {
        my $res_inv = $self->_cargar_inventario_desde_archivo($archivo_inventario);
        if ($res_inv->{ok}) {
            $resultado{inventario_cargado} = 1;
            push @{ $resultado{mensajes} }, $res_inv->{mensaje};
        }
        else {
            $resultado{ok} = 0;
            push @{ $resultado{errores} }, $res_inv->{mensaje};
        }
    }
    else {
        push @{ $resultado{mensajes} }, "No se encontró $archivo_inventario";
    }

    # Carga de usuarios
    if (-e $archivo_usuarios) {
        my $res_usr = $self->_cargar_usuarios_desde_archivo($archivo_usuarios);
        if ($res_usr->{ok}) {
            $resultado{usuarios_cargados} = 1;
            push @{ $resultado{mensajes} }, $res_usr->{mensaje};
        }
        else {
            $resultado{ok} = 0;
            push @{ $resultado{errores} }, $res_usr->{mensaje};
        }
    }
    else {
        push @{ $resultado{mensajes} }, "No se encontró $archivo_usuarios";
    }

    # Sincronizar después de cargar
    my $sync = $self->sincronizarEstructuras();
    push @{ $resultado{mensajes} }, @{ $sync->{mensajes} || [] };

    return \%resultado;
}

sub _cargar_inventario_desde_archivo {
    my ($self, $archivo) = @_;

    my $cargador = $self->{cargador_json};

    if ($cargador->can('cargarInventarioDesdeArchivo')) {
        my $res = eval { $cargador->cargarInventarioDesdeArchivo($archivo) };
        return _normalizar_resultado_carga($res, "Inventario cargado desde $archivo", $@);
    }

    if ($cargador->can('cargarInventario')) {
        my $res = eval { $cargador->cargarInventario($archivo) };
        return _normalizar_resultado_carga($res, "Inventario cargado desde $archivo", $@);
    }

    return {
        ok      => 0,
        mensaje => 'El cargador JSON no soporta carga de inventario',
    };
}

sub _cargar_usuarios_desde_archivo {
    my ($self, $archivo) = @_;

    my $cargador = $self->{cargador_json};

    if ($cargador->can('cargarUsuariosDesdeArchivo')) {
        my $res = eval { $cargador->cargarUsuariosDesdeArchivo($archivo) };
        return _normalizar_resultado_carga($res, "Usuarios cargados desde $archivo", $@);
    }

    if ($cargador->can('cargarUsuarios')) {
        my $res = eval { $cargador->cargarUsuarios($archivo) };
        return _normalizar_resultado_carga($res, "Usuarios cargados desde $archivo", $@);
    }

    return {
        ok      => 0,
        mensaje => 'El cargador JSON no soporta carga de usuarios',
    };
}

# =========================================================
# Resumen útil para endpoints
# =========================================================
sub obtenerResumenSistema {
    my ($self) = @_;

    my $resumen = {
        usuarios     => 0,
        hash         => {},
        colaboracion => {},
        base_path    => $self->{base_path},
        cargas_dir   => $self->{cargas_dir},
        chats_dir    => $self->{chats_dir},
        reportes_dir => $self->{reportes_dir},
    };

    if ($self->{gestor_usuarios} && $self->{gestor_usuarios}->can('getCantidadUsuarios')) {
        $resumen->{usuarios} = $self->{gestor_usuarios}->getCantidadUsuarios();
    }

    if ($self->{gestor_usuarios} && $self->{gestor_usuarios}->can('obtenerResumenHash')) {
        $resumen->{hash} = $self->{gestor_usuarios}->obtenerResumenHash();
    }

    if ($self->{gestor_colaboracion} && $self->{gestor_colaboracion}->can('obtenerResumenRed')) {
        $resumen->{colaboracion} = $self->{gestor_colaboracion}->obtenerResumenRed();
    }

    return $resumen;
}

# =========================================================
# Helpers internos
# =========================================================
sub _asegurar_directorios {
    my ($self) = @_;

    foreach my $dir ($self->{cargas_dir}, $self->{chats_dir}, $self->{reportes_dir}) {
        make_path($dir) unless -d $dir;
    }
}

sub _resolver_backend_path {
    my $module_file = abs_path(__FILE__);
    my ($volume, $directories, undef) = File::Spec->splitpath($module_file);
    my $module_dir = File::Spec->catpath($volume, $directories, '');
    my $backend_dir = abs_path(File::Spec->catdir($module_dir, '..', '..', '..'));
    return $backend_dir;
}

sub _normalizar_resultado_carga {
    my ($res, $mensaje_exito, $error_eval) = @_;

    if ($error_eval) {
        return {
            ok      => 0,
            mensaje => "Error durante la carga: $error_eval",
        };
    }

    if (ref($res) eq 'HASH') {
        my $ok = exists $res->{ok} ? $res->{ok}
               : exists $res->{mensaje} ? 1
               : 1;

        my $msg = $res->{mensaje} // $mensaje_exito;

        return {
            ok      => $ok ? 1 : 0,
            mensaje => $msg,
            data    => $res,
        };
    }

    if (!defined $res) {
        return {
            ok      => 1,
            mensaje => $mensaje_exito,
        };
    }

    return {
        ok      => 1,
        mensaje => $mensaje_exito,
        data    => $res,
    };
}

sub sembrarDatosDemo {
    my ($self) = @_;

    my $gestor_usuarios = $self->{gestor_usuarios};
    my $gestor_colab    = $self->{gestor_colaboracion};
    my $gestor_msg      = $self->{gestor_mensajeria};

    return {
        ok      => 0,
        mensaje => 'No hay gestor_usuarios disponible',
    } if !defined $gestor_usuarios;

    return {
        ok      => 0,
        mensaje => 'No hay gestor_colaboracion disponible',
    } if !defined $gestor_colab;

    return {
        ok      => 0,
        mensaje => 'No hay gestor_mensajeria disponible',
    } if !defined $gestor_msg;

    # Asegura que hash/grafo estén sincronizados primero
    $self->sincronizarEstructuras();

    my $usuarios = $gestor_usuarios->listarUsuarios();
    return {
        ok      => 0,
        mensaje => 'No hay lista de usuarios disponible',
    } if ref($usuarios) ne 'ARRAY';

    my @ids = map { $self->_extraer_id($_) } @$usuarios;
    @ids = grep { defined $_ && $_ ne '' } @ids;

    my %visto;
    @ids = grep { !$visto{$_}++ } @ids;

    return {
        ok      => 0,
        mensaje => 'Se necesitan al menos 5 usuarios para sembrar demo',
    } if @ids < 5;

    # Tomamos los primeros 5 usuarios ordenados por AVL
    my ($u1, $u2, $u3, $u4, $u5) = @ids[0..4];

    my @mensajes;

    # =====================================================
    # Colaboraciones activas demo
    # Estructura elegida:
    # u1 <-> u2
    # u1 <-> u3
    # u2 <-> u4
    # u3 <-> u4
    #
    # Esto provoca que:
    # - u1 tenga colaboradores
    # - u4 aparezca como sugerencia para u1 (2 comunes: u2 y u3)
    # =====================================================
    my @activas = (
        [$u1, $u2],
        [$u1, $u3],
        [$u2, $u4],
        [$u3, $u4],
    );

    foreach my $par (@activas) {
        my ($a, $b) = @$par;

        next if $self->_son_colaboradores($gestor_colab, $a, $b);

        my ($ok, $msg) = $self->_registrar_colaboracion_activa($gestor_colab, $a, $b);
        push @mensajes, $msg if defined $msg;
    }

    # =====================================================
    # Solicitud pendiente demo: u5 -> u1
    # =====================================================
    if (!$self->_son_colaboradores($gestor_colab, $u5, $u1)) {
        my $ya_pendiente = 0;

        if ($gestor_colab->can('obtenerSolicitudesPendientesPara')) {
            my $pendientes = $gestor_colab->obtenerSolicitudesPendientesPara($u1);
            if (ref($pendientes) eq 'ARRAY') {
                foreach my $s (@$pendientes) {
                    next if ref($s) ne 'HASH';
                    if (($s->{solicitante} // '') eq $u5) {
                        $ya_pendiente = 1;
                        last;
                    }
                }
            }
        }

        if (!$ya_pendiente && $gestor_colab->can('enviarSolicitud')) {
            my ($ok, $msg) = $gestor_colab->enviarSolicitud($u5, $u1);
            push @mensajes, $msg if defined $msg;
        }
    }

    # =====================================================
    # Conversación demo entre u1 y u2
    # =====================================================
    my $conv = $gestor_msg->obtenerConversacion($u1, $u2);

    if (ref($conv) ne 'ARRAY' || !@$conv) {
        my @msgs_demo = (
            ['2026-05-10 08:00:00', 'Hola, ¿puede apoyarme con el paciente de la sala 2?'],
            ['2026-05-10 08:01:10', 'Sí, voy en camino.'],
            ['2026-05-10 08:02:20', 'Gracias, llevo el expediente.'],
        );

        my ($t1, $m1) = @{ $msgs_demo[0] };
        my ($t2, $m2) = @{ $msgs_demo[1] };
        my ($t3, $m3) = @{ $msgs_demo[2] };

        my ($ok1, $msg1) = $gestor_msg->enviarMensaje($u1, $u2, $m1, timestamp => $t1);
        push @mensajes, $msg1 if defined $msg1;

        my ($ok2, $msg2) = $gestor_msg->enviarMensaje($u2, $u1, $m2, timestamp => $t2);
        push @mensajes, $msg2 if defined $msg2;

        my ($ok3, $msg3) = $gestor_msg->enviarMensaje($u1, $u2, $m3, timestamp => $t3);
        push @mensajes, $msg3 if defined $msg3;
    }

    return {
        ok      => 1,
        mensaje => 'Datos demo de colaboración y mensajería sembrados correctamente',
        data    => {
            usuarios_demo => {
                principal      => $u1,
                colaborador_1  => $u2,
                colaborador_2  => $u3,
                sugerido       => $u4,
                solicitante    => $u5,
            },
            mensajes => \@mensajes,
        },
    };
}

sub _son_colaboradores {
    my ($self, $gestor_colab, $a, $b) = @_;

    return 0 if !defined $gestor_colab;
    return 0 if !defined $a || !defined $b || $a eq '' || $b eq '';

    if ($gestor_colab->can('sonColaboradores')) {
        return $gestor_colab->sonColaboradores($a, $b) ? 1 : 0;
    }

    if ($gestor_colab->can('getGrafo')) {
        my $grafo = $gestor_colab->getGrafo();
        if (defined $grafo && $grafo->can('sonColaboradores')) {
            return $grafo->sonColaboradores($a, $b) ? 1 : 0;
        }
    }

    return 0;
}

sub _registrar_colaboracion_activa {
    my ($self, $gestor_colab, $a, $b) = @_;

    if ($gestor_colab->can('registrarColaboracionActiva')) {
        return $gestor_colab->registrarColaboracionActiva($a, $b);
    }

    if ($gestor_colab->can('getGrafo')) {
        my $grafo = $gestor_colab->getGrafo();
        if (defined $grafo && $grafo->can('agregarColaboracion')) {
            return $grafo->agregarColaboracion($a, $b);
        }
    }

    return (0, "No se pudo registrar colaboración activa entre $a y $b");
}

sub _extraer_id {
    my ($self, $usuario) = @_;

    return undef if !defined $usuario;

    if (!ref($usuario)) {
        return $usuario;
    }

    if (ref($usuario) eq 'HASH') {
        return $usuario->{numero_colegio} if defined $usuario->{numero_colegio};
        return $usuario->{codigo} if defined $usuario->{codigo};
    }

    foreach my $getter (qw(getNumeroColegio numero_colegio getClave clave getCodigo codigo)) {
        if ($usuario->can($getter)) {
            my $valor = eval { $usuario->$getter() };
            return $valor if defined $valor;
        }
    }

    return undef;
}

1;