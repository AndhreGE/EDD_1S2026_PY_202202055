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
use JSON::PP;
use POSIX qw(strftime);

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

        solicitudes_reabastecimiento => [],
        secuencia_reabastecimiento   => 1,
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

sub cargarUsuariosDesdeJSON {
    my ($self, %args) = @_;

    my $archivo = $args{archivo}
        // File::Spec->catfile($self->{cargas_dir}, 'usuarios_departamentales.json');

    return {
        ok      => 0,
        mensaje => "No existe el archivo de usuarios: $archivo",
    } if !-e $archivo;

    my $cantidad_actual = 0;
    if ($self->{gestor_usuarios} && $self->{gestor_usuarios}->can('getCantidadUsuarios')) {
        $cantidad_actual = $self->{gestor_usuarios}->getCantidadUsuarios();
    }

    if ($cantidad_actual > 0 && !$args{forzar}) {
        return {
            ok             => 1,
            mensaje        => 'Los usuarios ya están cargados en memoria; no se duplicaron registros',
            archivo        => $archivo,
            cantidad_actual => $cantidad_actual,
        };
    }

    my $res = $self->_cargar_usuarios_desde_archivo($archivo);
    my $sync = $self->sincronizarEstructuras();

    return {
        ok           => ($res->{ok} && $sync->{ok}) ? 1 : 0,
        mensaje      => $res->{mensaje} // 'Carga de usuarios finalizada',
        archivo      => $archivo,
        detalle      => $res,
        sincronizado => $sync,
    };
}

sub cargarColaboracionesDesdeJSON {
    my ($self, %args) = @_;

    my $archivo = $args{archivo}
        // File::Spec->catfile($self->{cargas_dir}, 'colaboraciones_activas.json');

    return {
        ok      => 0,
        mensaje => "No existe el archivo de colaboraciones: $archivo",
    } if !-e $archivo;

    open(my $fh, '<:encoding(UTF-8)', $archivo)
        or return {
            ok      => 0,
            mensaje => "No se pudo abrir el archivo: $archivo",
        };

    local $/;
    my $json_text = <$fh>;
    close($fh);

    my $data;
    eval {
        my $json = JSON::PP->new->utf8(0);
        $data = $json->decode($json_text);
    };

    if ($@) {
        return {
            ok      => 0,
            mensaje => "No se pudo parsear el JSON de colaboraciones: $@",
        };
    }

    my $lista = ref($data) eq 'ARRAY'
        ? $data
        : (ref($data) eq 'HASH' ? ($data->{colaboraciones} || []) : []);

    return {
        ok      => 0,
        mensaje => 'El archivo de colaboraciones no contiene una lista válida',
    } if ref($lista) ne 'ARRAY';

    my $gestor_colab = $self->{gestor_colaboracion};

    my $procesadas = 0;
    my $nuevas     = 0;
    my $omitidas   = 0;
    my @errores;

    foreach my $item (@$lista) {
        next if ref($item) ne 'HASH';

        my $a = $item->{usuario1} // $item->{origen} // $item->{de} // '';
        my $b = $item->{usuario2} // $item->{destino} // $item->{para} // '';

        if ($a eq '' || $b eq '') {
            push @errores, 'Registro inválido en colaboraciones JSON';
            next;
        }

        $procesadas++;

        if ($self->_son_colaboradores($gestor_colab, $a, $b)) {
            $omitidas++;
            next;
        }

        my ($ok, $msg) = $self->_registrar_colaboracion_activa($gestor_colab, $a, $b);

        if ($ok) {
            $nuevas++;
        } else {
            push @errores, $msg;
        }
    }

    return {
        ok         => @errores ? 0 : 1,
        mensaje    => @errores
            ? 'Colaboraciones procesadas con algunos errores'
            : 'Colaboraciones cargadas correctamente',
        archivo    => $archivo,
        procesadas => $procesadas,
        nuevas     => $nuevas,
        omitidas   => $omitidas,
        errores    => \@errores,
    };
}

sub generarReporteGrafo {
    my ($self) = @_;

    my $gestor = $self->{gestor_colaboracion};

    my $dot = File::Spec->catfile($self->{reportes_dir}, 'grafo_colaboracion_backend.dot');
    my $png = File::Spec->catfile($self->{reportes_dir}, 'grafo_colaboracion_backend.png');

    my ($ok, $msg) = (0, 'No se pudo generar el reporte del grafo');

    if ($gestor && $gestor->can('generarReporteGrafo')) {
        ($ok, $msg) = $gestor->generarReporteGrafo($dot, $png);
    }

    return {
        ok       => $ok ? 1 : 0,
        mensaje  => $msg,
        filename => 'grafo_colaboracion_backend.png',
        dotfile  => 'grafo_colaboracion_backend.dot',
    };
}

sub generarReporteListaAdyacencia {
    my ($self) = @_;

    my $gestor = $self->{gestor_colaboracion};

    my $dot = File::Spec->catfile($self->{reportes_dir}, 'lista_adyacencia_backend.dot');
    my $png = File::Spec->catfile($self->{reportes_dir}, 'lista_adyacencia_backend.png');

    my ($ok, $msg) = (0, 'No se pudo generar el reporte de lista de adyacencia');

    if ($gestor && $gestor->can('generarReporteListaAdyacencia')) {
        ($ok, $msg) = $gestor->generarReporteListaAdyacencia($dot, $png);
    }

    return {
        ok       => $ok ? 1 : 0,
        mensaje  => $msg,
        filename => 'lista_adyacencia_backend.png',
        dotfile  => 'lista_adyacencia_backend.dot',
    };
}

sub generarReporteTablaHash {
    my ($self) = @_;

    my $gestor = $self->{gestor_usuarios};

    my $dot = File::Spec->catfile($self->{reportes_dir}, 'tabla_hash_backend.dot');
    my $png = File::Spec->catfile($self->{reportes_dir}, 'tabla_hash_backend.png');

    my ($ok, $msg) = (0, 'No se pudo generar el reporte de tabla hash');

    if ($gestor && $gestor->can('generarReporteTablaHash')) {
        ($ok, $msg) = $gestor->generarReporteTablaHash($dot, $png);
    }

    return {
        ok       => $ok ? 1 : 0,
        mensaje  => $msg,
        filename => 'tabla_hash_backend.png',
        dotfile  => 'tabla_hash_backend.dot',
    };
}

sub obtenerSuministrosSolicitables {
    my ($self, $numero_colegio) = @_;

    my $usuario = $self->{gestor_usuarios}->buscarUsuario($numero_colegio);
    return [] if !$usuario;

    my $permisos = {};
    if ($self->{gestor_permisos} && $self->{gestor_permisos}->can('obtenerPermisosUsuario')) {
        $permisos = $self->{gestor_permisos}->obtenerPermisosUsuario($usuario) || {};
    }

    my %permitidos = map { uc($_) => 1 } @{ $permisos->{solicitud} || [] };
    return [] if !$permitidos{SUMINISTRO};

    my $lista = $self->_listar_suministros();
    my @salida = map { $self->_serializar_suministro($_) } @$lista;

    @salida = grep { defined $_->{codigo} && $_->{codigo} ne '' } @salida;

    return \@salida;
}

sub crearSolicitudReabastecimiento {
    my ($self, %args) = @_;

    my $numero_colegio = $args{numero_colegio} // '';
    my $codigo         = $args{codigo} // '';
    my $cantidad       = $args{cantidad} // 0;
    my $observacion    = $args{observacion} // '';

    return (0, 'Debe indicar el usuario solicitante', undef) if $numero_colegio eq '';
    return (0, 'Debe indicar el código del insumo', undef) if $codigo eq '';
    return (0, 'La cantidad debe ser mayor que 0', undef) if $cantidad !~ /^\d+$/ || $cantidad <= 0;

    my $usuario = $self->{gestor_usuarios}->buscarUsuario($numero_colegio);
    return (0, 'Usuario no encontrado', undef) if !$usuario;

    my $suministro = $self->_buscar_suministro_por_codigo($codigo);
    return (0, "No se encontró el insumo $codigo", undef) if !$suministro;

    my $u = $self->_serializar_usuario_generico($usuario);
    my $s = $self->_serializar_suministro($suministro);

    my $id = sprintf('REB-%04d', $self->{secuencia_reabastecimiento}++);
    my $timestamp = _ahora();

    my $solicitud = {
        id                  => $id,
        estado              => 'PENDIENTE',
        numero_colegio      => $u->{numero_colegio},
        nombre_completo     => $u->{nombre_completo},
        tipo_usuario        => $u->{tipo_usuario},
        departamento        => $u->{departamento},
        codigo_insumo       => $s->{codigo},
        nombre_insumo       => $s->{nombre},
        fabricante          => $s->{fabricante},
        cantidad_solicitada => int($cantidad),
        observacion         => $observacion,
        timestamp_creacion  => $timestamp,
        timestamp_actualizacion => $timestamp,
        admin_actor         => undef,
        observacion_admin   => undef,
        historial           => [
            {
                estado    => 'PENDIENTE',
                timestamp => $timestamp,
                actor     => $u->{numero_colegio},
                detalle   => 'Solicitud creada por el usuario',
            }
        ],
    };

    push @{ $self->{solicitudes_reabastecimiento} }, $solicitud;

    return (1, "Solicitud $id creada correctamente", $solicitud);
}

sub listarSolicitudesReabastecimiento {
    my ($self, %args) = @_;

    my $estado = $args{estado};
    my @lista = map { { %$_ } } @{ $self->{solicitudes_reabastecimiento} || [] };

    if (defined $estado && $estado ne '') {
        @lista = grep { ($_->{estado} // '') eq $estado } @lista;
    }

    @lista = sort {
        ($b->{timestamp_creacion} // '') cmp ($a->{timestamp_creacion} // '')
    } @lista;

    return \@lista;
}

sub listarSolicitudesReabastecimientoUsuario {
    my ($self, $numero_colegio) = @_;

    my @lista = grep {
        ($_->{numero_colegio} // '') eq $numero_colegio
    } @{ $self->{solicitudes_reabastecimiento} || [] };

    @lista = map { { %$_ } } @lista;

    @lista = sort {
        ($b->{timestamp_creacion} // '') cmp ($a->{timestamp_creacion} // '')
    } @lista;

    return \@lista;
}

sub cambiarEstadoSolicitudReabastecimiento {
    my ($self, %args) = @_;

    my $id               = $args{id} // '';
    my $estado           = uc($args{estado} // '');
    my $admin_actor      = $args{admin_actor} // 'ADMIN';
    my $observacion_admin = $args{observacion_admin} // '';

    return (0, 'Debe indicar el id de la solicitud', undef) if $id eq '';
    return (0, 'Estado inválido', undef)
        if !$estado || $estado !~ /^(APROBADA|RECHAZADA|ATENDIDA)$/;

    foreach my $s (@{ $self->{solicitudes_reabastecimiento} || [] }) {
        next if ($s->{id} // '') ne $id;

        $s->{estado} = $estado;
        $s->{admin_actor} = $admin_actor;
        $s->{observacion_admin} = $observacion_admin if defined $observacion_admin && $observacion_admin ne '';
        $s->{timestamp_actualizacion} = _ahora();

        push @{ $s->{historial} }, {
            estado    => $estado,
            timestamp => $s->{timestamp_actualizacion},
            actor     => $admin_actor,
            detalle   => $observacion_admin ne '' ? $observacion_admin : "Estado actualizado a $estado",
        };

        return (1, "Solicitud $id actualizada a $estado", { %$s });
    }

    return (0, "No se encontró la solicitud $id", undef);
}

sub _listar_suministros {
    my ($self) = @_;

    my $inv = $self->{inventario};
    return [] if !$inv;

    foreach my $metodo (qw(
        listarSuministros
        obtenerSuministros
        getSuministros
        listarInsumos
        obtenerInsumos
    )) {
        if ($inv->can($metodo)) {
            my $res = eval { $inv->$metodo() };
            return $res if ref($res) eq 'ARRAY';
        }
    }

    return [];
}

sub _buscar_suministro_por_codigo {
    my ($self, $codigo) = @_;

    my $inv = $self->{inventario};
    return undef if !$inv || !$codigo;

    foreach my $metodo (qw(
        buscarSuministro
        obtenerSuministro
        getSuministro
    )) {
        if ($inv->can($metodo)) {
            my $res = eval { $inv->$metodo($codigo) };
            return $res if defined $res;
        }
    }

    my $lista = $self->_listar_suministros();
    foreach my $item (@$lista) {
        my $serial = $self->_serializar_suministro($item);
        return $item if ($serial->{codigo} // '') eq $codigo;
    }

    return undef;
}

sub _serializar_suministro {
    my ($self, $item) = @_;

    return {} if !defined $item;

    if (ref($item) eq 'HASH') {
        return {
            codigo        => $item->{codigo},
            nombre        => $item->{nombre},
            fabricante    => $item->{fabricante},
            cantidad      => $item->{cantidad},
            nivel_minimo  => $item->{nivel_minimo},
        };
    }

    return {
        codigo       => _extraer_campo_objeto($item, qw(getCodigo codigo)),
        nombre       => _extraer_campo_objeto($item, qw(getNombre nombre)),
        fabricante   => _extraer_campo_objeto($item, qw(getFabricante fabricante)),
        cantidad     => _extraer_campo_objeto($item, qw(getCantidad cantidad)),
        nivel_minimo => _extraer_campo_objeto($item, qw(getNivelMinimo nivel_minimo)),
    };
}

sub _serializar_usuario_generico {
    my ($self, $u) = @_;

    return {} if !defined $u;

    if (ref($u) eq 'HASH') {
        return {
            numero_colegio  => $u->{numero_colegio},
            nombre_completo => $u->{nombre_completo},
            tipo_usuario    => $u->{tipo_usuario},
            departamento    => $u->{departamento},
            especialidad    => $u->{especialidad},
        };
    }

    return {
        numero_colegio  => _extraer_campo_objeto($u, qw(getNumeroColegio numero_colegio getCodigo codigo)),
        nombre_completo => _extraer_campo_objeto($u, qw(getNombreCompleto nombre_completo)),
        tipo_usuario    => _extraer_campo_objeto($u, qw(getTipoUsuario tipo_usuario)),
        departamento    => _extraer_campo_objeto($u, qw(getDepartamento departamento)),
        especialidad    => _extraer_campo_objeto($u, qw(getEspecialidad especialidad)),
    };
}

sub _extraer_campo_objeto {
    my ($obj, @getters) = @_;
    return undef if !defined $obj;

    foreach my $getter (@getters) {
        if (ref($obj) eq 'HASH' && exists $obj->{$getter}) {
            return $obj->{$getter};
        }

        if (ref($obj) && $obj->can($getter)) {
            my $valor = eval { $obj->$getter() };
            return $valor if defined $valor;
        }

        if (ref($obj) eq 'HASH') {
            my $alt = $getter;
            $alt =~ s/^get//;
            $alt = lcfirst($alt);
            return $obj->{$alt} if exists $obj->{$alt};
        }
    }

    return undef;
}

sub _ahora {
    return strftime('%Y-%m-%d %H:%M:%S', localtime);
}

sub obtenerEstadoLZWUsuario {
    my ($self, $numero_colegio) = @_;

    return {
        ok      => 0,
        mensaje => 'Debe indicar el número de colegio',
    } if !defined $numero_colegio || $numero_colegio eq '';

    my $gestor = $self->{gestor_mensajeria};
    return {
        ok      => 0,
        mensaje => 'No hay gestor de mensajería disponible',
    } if !defined $gestor;

    my $ruta_archivo = File::Spec->catfile($self->{chats_dir}, "$numero_colegio.lzw");
    my $existe = -e $ruta_archivo ? 1 : 0;
    my $size_bytes = $existe ? (-s $ruta_archivo || 0) : 0;

    my $conversaciones = [];
    if ($gestor->can('listarConversacionesUsuario')) {
        $conversaciones = $gestor->listarConversacionesUsuario($numero_colegio) || [];
    }

    my $cantidad_conversaciones = ref($conversaciones) eq 'ARRAY' ? scalar(@$conversaciones) : 0;

    my $mensajes_totales = 0;
    if (ref($conversaciones) eq 'ARRAY' && $gestor->can('obtenerConversacion')) {
        foreach my $conv (@$conversaciones) {
            next if ref($conv) ne 'HASH';
            my $otro = $conv->{con_usuario} // '';
            next if $otro eq '';

            my $mensajes = $gestor->obtenerConversacion($numero_colegio, $otro);
            if (ref($mensajes) eq 'ARRAY') {
                $mensajes_totales += scalar(@$mensajes);
            }
        }
    }

    return {
        ok                     => 1,
        mensaje                => 'Estado LZW obtenido correctamente',
        numero_colegio         => $numero_colegio,
        archivo_lzw            => "$numero_colegio.lzw",
        ruta_archivo           => $ruta_archivo,
        existe_archivo         => $existe,
        size_bytes             => $size_bytes,
        conversaciones_memoria => $cantidad_conversaciones,
        mensajes_totales       => $mensajes_totales,
        chats_dir              => $self->{chats_dir},
    };
}

sub guardarHistorialLZWUsuario {
    my ($self, $numero_colegio) = @_;

    return {
        ok      => 0,
        mensaje => 'Debe indicar el número de colegio',
    } if !defined $numero_colegio || $numero_colegio eq '';

    my $gestor = $self->{gestor_mensajeria};
    return {
        ok      => 0,
        mensaje => 'No hay gestor de mensajería disponible',
    } if !defined $gestor;

    my ($ok, $msg) = (0, 'No se pudo guardar el historial');

    if ($gestor->can('cerrarSesionUsuario')) {
        ($ok, $msg) = $gestor->cerrarSesionUsuario($numero_colegio);
    } elsif ($gestor->can('guardarHistorialUsuario')) {
        ($ok, $msg) = $gestor->guardarHistorialUsuario($numero_colegio);
    } else {
        return {
            ok      => 0,
            mensaje => 'El gestor de mensajería no soporta guardado manual',
        };
    }

    my $estado = $self->obtenerEstadoLZWUsuario($numero_colegio);
    $estado->{ok} = $ok ? 1 : 0;
    $estado->{mensaje} = $msg if defined $msg;

    return $estado;
}

sub recargarHistorialLZWUsuario {
    my ($self, $numero_colegio) = @_;

    return {
        ok      => 0,
        mensaje => 'Debe indicar el número de colegio',
    } if !defined $numero_colegio || $numero_colegio eq '';

    my $gestor = $self->{gestor_mensajeria};
    return {
        ok      => 0,
        mensaje => 'No hay gestor de mensajería disponible',
    } if !defined $gestor;

    my ($ok, $msg) = (0, 'No se pudo recargar el historial');

    if ($gestor->can('cargarHistorialUsuario')) {
        ($ok, $msg) = $gestor->cargarHistorialUsuario($numero_colegio);
    } elsif ($gestor->can('abrirSesionUsuario')) {
        ($ok, $msg) = $gestor->abrirSesionUsuario($numero_colegio);
    } elsif ($gestor->can('cargarSesionUsuario')) {
        ($ok, $msg) = $gestor->cargarSesionUsuario($numero_colegio);
    } else {
        return {
            ok      => 0,
            mensaje => 'El gestor de mensajería no soporta recarga manual',
        };
    }

    my $estado = $self->obtenerEstadoLZWUsuario($numero_colegio);
    $estado->{ok} = $ok ? 1 : 0;
    $estado->{mensaje} = $msg if defined $msg;

    return $estado;
}

sub listarSolicitudesColaboracionPendientesGlobales {
    my ($self) = @_;

    my $gestor = $self->{gestor_colaboracion};

    return [] if !defined $gestor;

    my @salida;

    # Caso ideal: el gestor ya sabe listar todas las pendientes
    if ($gestor->can('obtenerSolicitudesPendientesGlobales')) {
        my $lista = $gestor->obtenerSolicitudesPendientesGlobales();
        return $self->_normalizar_solicitudes_colaboracion_globales($lista);
    }

    # Caso alterno: recorremos usuarios y pedimos pendientes por destinatario
    my $usuarios = [];
    if ($self->{gestor_usuarios} && $self->{gestor_usuarios}->can('listarUsuarios')) {
        $usuarios = $self->{gestor_usuarios}->listarUsuarios() || [];
    }

    my %vistas;

    foreach my $u (@$usuarios) {
        my $destino = $self->_extraer_id($u);
        next if !defined $destino || $destino eq '';

        my $pendientes = [];

        if ($gestor->can('obtenerSolicitudesPendientesPara')) {
            $pendientes = $gestor->obtenerSolicitudesPendientesPara($destino) || [];
        } elsif ($gestor->can('obtenerSolicitudesPendientesUsuario')) {
            $pendientes = $gestor->obtenerSolicitudesPendientesUsuario($destino) || [];
        } else {
            next;
        }

        next if ref($pendientes) ne 'ARRAY';

        foreach my $s (@$pendientes) {
            next if ref($s) ne 'HASH';

            my $solicitante = $s->{solicitante} // $s->{de} // '';
            my $receptor    = $s->{receptor} // $s->{para} // $destino;
            my $estado      = $s->{estado} // 'PENDIENTE';

            next if $solicitante eq '' || $receptor eq '';

            my $clave = join('|', $solicitante, $receptor, $estado);
            next if $vistas{$clave}++;

            my $u_sol = $self->{gestor_usuarios}->buscarUsuario($solicitante);
            my $u_rec = $self->{gestor_usuarios}->buscarUsuario($receptor);

            push @salida, {
                solicitante           => $solicitante,
                receptor              => $receptor,
                estado                => $estado,
                solicitante_nombre    => $self->_nombre_usuario($u_sol),
                solicitante_tipo      => $self->_tipo_usuario($u_sol),
                solicitante_depto     => $self->_departamento_usuario($u_sol),
                receptor_nombre       => $self->_nombre_usuario($u_rec),
                receptor_tipo         => $self->_tipo_usuario($u_rec),
                receptor_depto        => $self->_departamento_usuario($u_rec),
            };
        }
    }

    @salida = sort {
        ($a->{receptor} // '') cmp ($b->{receptor} // '')
            ||
        ($a->{solicitante} // '') cmp ($b->{solicitante} // '')
    } @salida;

    return \@salida;
}

sub aprobarSolicitudColaboracionComoAdmin {
    my ($self, %args) = @_;

    my $solicitante = $args{solicitante} // '';
    my $receptor    = $args{receptor} // '';

    return (0, 'Debe indicar solicitante', undef) if $solicitante eq '';
    return (0, 'Debe indicar receptor', undef) if $receptor eq '';

    my $gestor = $self->{gestor_colaboracion};
    return (0, 'No hay gestor de colaboración disponible', undef) if !defined $gestor;

    my ($ok, $msg) = (0, 'No se pudo aprobar la solicitud');

    if ($gestor->can('aceptarSolicitud')) {
        ($ok, $msg) = $gestor->aceptarSolicitud($solicitante, $receptor);
    } elsif ($gestor->can('aprobarSolicitud')) {
        ($ok, $msg) = $gestor->aprobarSolicitud($solicitante, $receptor);
    } else {
        return (0, 'El gestor de colaboración no soporta aprobación de solicitudes', undef);
    }

    my $lista = $self->listarSolicitudesColaboracionPendientesGlobales();

    return ($ok ? 1 : 0, $msg, $lista);
}

sub rechazarSolicitudColaboracionComoAdmin {
    my ($self, %args) = @_;

    my $solicitante = $args{solicitante} // '';
    my $receptor    = $args{receptor} // '';

    return (0, 'Debe indicar solicitante', undef) if $solicitante eq '';
    return (0, 'Debe indicar receptor', undef) if $receptor eq '';

    my $gestor = $self->{gestor_colaboracion};
    return (0, 'No hay gestor de colaboración disponible', undef) if !defined $gestor;

    my ($ok, $msg) = (0, 'No se pudo rechazar la solicitud');

    if ($gestor->can('rechazarSolicitud')) {
        ($ok, $msg) = $gestor->rechazarSolicitud($solicitante, $receptor);
    } else {
        return (0, 'El gestor de colaboración no soporta rechazo de solicitudes', undef);
    }

    my $lista = $self->listarSolicitudesColaboracionPendientesGlobales();

    return ($ok ? 1 : 0, $msg, $lista);
}

sub _normalizar_solicitudes_colaboracion_globales {
    my ($self, $lista) = @_;

    return [] if ref($lista) ne 'ARRAY';

    my @salida;

    foreach my $s (@$lista) {
        next if ref($s) ne 'HASH';

        my $solicitante = $s->{solicitante} // $s->{de} // '';
        my $receptor    = $s->{receptor} // $s->{para} // '';
        my $estado      = $s->{estado} // 'PENDIENTE';

        next if $solicitante eq '' || $receptor eq '';

        my $u_sol = $self->{gestor_usuarios}->buscarUsuario($solicitante);
        my $u_rec = $self->{gestor_usuarios}->buscarUsuario($receptor);

        push @salida, {
            solicitante           => $solicitante,
            receptor              => $receptor,
            estado                => $estado,
            solicitante_nombre    => $self->_nombre_usuario($u_sol),
            solicitante_tipo      => $self->_tipo_usuario($u_sol),
            solicitante_depto     => $self->_departamento_usuario($u_sol),
            receptor_nombre       => $self->_nombre_usuario($u_rec),
            receptor_tipo         => $self->_tipo_usuario($u_rec),
            receptor_depto        => $self->_departamento_usuario($u_rec),
        };
    }

    return \@salida;
}

sub _nombre_usuario {
    my ($self, $u) = @_;
    return '' if !defined $u;

    if (ref($u) eq 'HASH') {
        return $u->{nombre_completo} // '';
    }

    foreach my $getter (qw(getNombreCompleto nombre_completo)) {
        if ($u->can($getter)) {
            my $v = eval { $u->$getter() };
            return $v if defined $v;
        }
    }

    return '';
}

sub _tipo_usuario {
    my ($self, $u) = @_;
    return '' if !defined $u;

    if (ref($u) eq 'HASH') {
        return $u->{tipo_usuario} // '';
    }

    foreach my $getter (qw(getTipoUsuario tipo_usuario)) {
        if ($u->can($getter)) {
            my $v = eval { $u->$getter() };
            return $v if defined $v;
        }
    }

    return '';
}

sub _departamento_usuario {
    my ($self, $u) = @_;
    return '' if !defined $u;

    if (ref($u) eq 'HASH') {
        return $u->{departamento} // '';
    }

    foreach my $getter (qw(getDepartamento departamento)) {
        if ($u->can($getter)) {
            my $v = eval { $u->$getter() };
            return $v if defined $v;
        }
    }

    return '';
}

sub cargarInventarioDesdeJSON {
    my ($self, %args) = @_;

    my $archivo = $args{archivo}
        // File::Spec->catfile($self->{cargas_dir}, 'inventario_masivo.json');

    my $nombre_original = $args{nombre_original} // $archivo;

    return {
        ok      => 0,
        mensaje => "No existe el archivo de inventario: $archivo",
    } if !-e $archivo;

    my $res = $self->_cargar_inventario_desde_archivo($archivo);
    my $sync = $self->sincronizarEstructuras();

    return {
        ok           => ($res->{ok} && $sync->{ok}) ? 1 : 0,
        mensaje      => $res->{mensaje} // 'Carga de inventario finalizada',
        archivo      => $nombre_original,
        detalle      => $res,
        sincronizado => $sync,
    };
}

sub _cargar_inventario_desde_archivo {
    my ($self, $archivo) = @_;

    my @objetos = grep { defined } (
        $self->{cargador_json},
        $self->{inventario},
    );

    my @metodos = qw(
        cargarInventarioDesdeArchivo
        cargarInventarioDesdeJSON
        cargarInventario
        cargarArchivoInventario
        procesarInventario
        cargar_json_inventario
    );

    foreach my $obj (@objetos) {
        foreach my $metodo (@metodos) {
            next if !$obj->can($metodo);

            my ($ok, $msg, $extra);
            my $worked = eval {
                my @r = $obj->$metodo($archivo);

                if (@r >= 2) {
                    ($ok, $msg, $extra) = @r;
                }
                elsif (@r == 1 && ref($r[0]) eq 'HASH') {
                    $ok    = $r[0]{ok};
                    $msg   = $r[0]{mensaje} // $r[0]{message};
                    $extra = $r[0];
                }
                elsif (@r == 1) {
                    $ok  = $r[0] ? 1 : 0;
                    $msg = $ok ? 'Inventario cargado correctamente' : 'No se pudo cargar el inventario';
                }
                else {
                    $ok  = 1;
                    $msg = 'Inventario cargado correctamente';
                }

                1;
            };

            if ($worked && defined $ok) {
                return {
                    ok     => $ok ? 1 : 0,
                    mensaje => $msg,
                    extra   => $extra,
                    metodo  => $metodo,
                };
            }
        }
    }

    return {
        ok      => 0,
        mensaje => 'No se encontró un método compatible para cargar inventario JSON. Revisa CargadorJSON.pm o Inventario.pm.',
    };
}

sub registrarUsuarioManual {
    my ($self, %args) = @_;

    my $numero_colegio   = _trim($args{numero_colegio}  // '');
    my $nombre_completo  = _trim($args{nombre_completo} // '');
    my $tipo_usuario     = uc _trim($args{tipo_usuario} // '');
    my $departamento_in  = _trim($args{departamento}    // '');
    my $especialidad     = _trim($args{especialidad}    // '');
    my $clave            = _trim($args{clave} // $args{contrasena} // $args{contrasenia} // '');

    my @faltan;
    push @faltan, 'numero_colegio'  if $numero_colegio eq '';
    push @faltan, 'nombre_completo' if $nombre_completo eq '';
    push @faltan, 'tipo_usuario'    if $tipo_usuario eq '';
    push @faltan, 'especialidad'    if $especialidad eq '';
    push @faltan, 'clave'           if $clave eq '';

    if (@faltan) {
        return {
            ok      => 0,
            mensaje => 'Faltan campos obligatorios: ' . join(', ', @faltan),
        };
    }

    my $gestor = $self->{gestor_usuarios};

    return {
        ok      => 0,
        mensaje => 'No hay gestor de usuarios disponible',
    } if !defined $gestor;

    # Si viene vacío o como SIN-DEP, realmente queremos dejarlo pendiente
    my $quiere_pendiente = 0;
    if (
        !defined $departamento_in
        || $departamento_in eq ''
        || uc($departamento_in) eq 'NULL'
        || uc($departamento_in) eq 'SIN-DEP'
        || uc($departamento_in) eq 'SIN_DEP'
    ) {
        $quiere_pendiente = 1;
    }

    # Para pasar la validación del modelo, registramos con un departamento válido temporal
    my $departamento_registro = $quiere_pendiente ? 'DEP-MED' : uc($departamento_in);

    # Validar duplicado antes de registrar
    if ($gestor->can('buscarUsuario')) {
        my $existente = $gestor->buscarUsuario($numero_colegio);
        if ($existente) {
            return {
                ok      => 0,
                mensaje => "Ya existe un usuario con número de colegio $numero_colegio",
            };
        }
    }

    my %payload = (
        numero_colegio  => $numero_colegio,
        nombre_completo => $nombre_completo,
        tipo_usuario    => $tipo_usuario,
        departamento    => $departamento_registro,
        especialidad    => $especialidad,
        clave           => $clave,
        contrasena      => $clave,
        contrasenia     => $clave,
        password        => $clave,
    );

    my $ultimo_msg = 'No se encontró un método compatible para registrar el usuario manualmente';

    # Intento principal: este es el que sí encaja con tu GestorUsuarios
    if ($gestor->can('registrarUsuarioDesdeHash')) {
        my ($ok, $msg) = eval {
            $gestor->registrarUsuarioDesdeHash(\%payload);
        };

        if ($@) {
            $ultimo_msg = $@;
        } else {
            $ultimo_msg = $msg if defined $msg && $msg ne '';

            if ($ok && $gestor->can('buscarUsuario')) {
                my $insertado = $gestor->buscarUsuario($numero_colegio);

                if ($insertado) {
                    if ($quiere_pendiente) {
                        $self->_forzar_usuario_sin_departamento($insertado);
                    }

                    my $sync = $self->sincronizarEstructuras();

                    my $usuario_hash = $self->_serializar_usuario_generico($insertado);
                    $usuario_hash->{departamento} = 'SIN-DEP' if $quiere_pendiente;

                    return {
                        ok           => 1,
                        mensaje      => $quiere_pendiente
                            ? 'Usuario registrado correctamente en estado pendiente de asignación'
                            : ($ultimo_msg || 'Usuario registrado correctamente'),
                        usuario      => $usuario_hash,
                        sincronizado => $sync,
                    };
                }
            }
        }
    }

    # Intentos alternos, por si existiera otra firma en tu gestor
    my @intentos;

    if ($gestor->can('registrarUsuarioDepartamental')) {
        push @intentos,
            sub { $gestor->registrarUsuarioDepartamental(\%payload) },
            sub { $gestor->registrarUsuarioDepartamental(%payload) };
    }

    if ($gestor->can('agregarUsuario')) {
        push @intentos,
            sub { $gestor->agregarUsuario(\%payload) },
            sub { $gestor->agregarUsuario(%payload) };
    }

    if ($gestor->can('insertarUsuario')) {
        push @intentos,
            sub { $gestor->insertarUsuario(\%payload) },
            sub { $gestor->insertarUsuario(%payload) };
    }

    foreach my $try (@intentos) {
        my ($ok, $msg);
        my $worked = eval {
            my @r = $try->();

            if (@r >= 2) {
                ($ok, $msg) = @r[0,1];
            } elsif (@r == 1 && ref($r[0]) eq 'HASH') {
                $ok  = $r[0]{ok};
                $msg = $r[0]{mensaje} // $r[0]{message};
            } elsif (@r == 1) {
                $ok  = $r[0] ? 1 : 0;
                $msg = $ok ? 'Usuario registrado correctamente' : 'No se pudo registrar usuario';
            } else {
                $ok  = 1;
                $msg = 'Usuario registrado correctamente';
            }

            1;
        };

        if (!$worked) {
            $ultimo_msg = $@ || 'Error interno al registrar usuario';
            next;
        }

        $ultimo_msg = $msg if defined $msg && $msg ne '';

        if ($gestor->can('buscarUsuario')) {
            my $insertado = $gestor->buscarUsuario($numero_colegio);

            if ($insertado) {
                if ($quiere_pendiente) {
                    $self->_forzar_usuario_sin_departamento($insertado);
                }

                my $sync = $self->sincronizarEstructuras();

                my $usuario_hash = $self->_serializar_usuario_generico($insertado);
                $usuario_hash->{departamento} = 'SIN-DEP' if $quiere_pendiente;

                return {
                    ok           => 1,
                    mensaje      => $quiere_pendiente
                        ? 'Usuario registrado correctamente en estado pendiente de asignación'
                        : ($ultimo_msg || 'Usuario registrado correctamente'),
                    usuario      => $usuario_hash,
                    sincronizado => $sync,
                };
            }
        }
    }

    return {
        ok      => 0,
        mensaje => $ultimo_msg || 'El backend reportó éxito, pero el usuario no quedó insertado realmente',
    };
}

sub _forzar_usuario_sin_departamento {
    my ($self, $usuario) = @_;

    return 0 if !defined $usuario;

    # Intentar setter si existe
    foreach my $setter (qw(setDepartamento departamento)) {
        if (ref($usuario) && $usuario->can($setter)) {
            my $ok = eval {
                $usuario->$setter('SIN-DEP');
                1;
            };
            return 1 if $ok;
        }
    }

    # Si es hash
    if (ref($usuario) eq 'HASH') {
        $usuario->{departamento} = 'SIN-DEP';
        return 1;
    }

    # Si es un objeto basado en hash, esto normalmente funciona en Perl
    my $ok_hash = eval {
        $usuario->{departamento} = 'SIN-DEP';
        1;
    };

    return $ok_hash ? 1 : 0;
}

sub _trim {
    my ($v) = @_;
    $v = '' if !defined $v;
    $v =~ s/^\s+//;
    $v =~ s/\s+$//;
    return $v;
}

1;