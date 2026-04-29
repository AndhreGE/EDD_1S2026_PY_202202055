package EDDMedTrack::Routes;

use strict;
use warnings;
use utf8;

sub register {
    my ($class, $app, $container) = @_;

    die "Se requiere una app de Mojolicious" if !defined $app;
    die "Se requiere un AppContainer" if !defined $container;

    my $r = $app->routes;

    # =====================================================
    # Ruta simple de prueba
    # =====================================================
    $r->get('/api/ping')->to(
        cb => sub {
            my $c = shift;

            $c->render(
                json => {
                    ok      => 1,
                    mensaje => 'Backend EDD MedTrack activo',
                }
            );
        }
    );

    # =====================================================
    # AUTH
    # =====================================================
    $r->post('/api/auth/login')->to(
        cb => sub {
            my $c = shift;

            my $body = $c->req->json || {};

            my $usuario = $body->{usuario} // $body->{numero_colegio} // '';
            my $clave   = $body->{clave}   // $body->{contrasena}     // $body->{password} // '';

            if ($usuario eq '' || $clave eq '') {
                return $c->render(
                    status => 400,
                    json   => {
                        ok      => 0,
                        mensaje => 'Debe enviar usuario y clave',
                    }
                );
            }

            # 1. Probar credenciales de admin
            if ($container->validarCredencialesAdmin($usuario, $clave)) {
                $c->session(
                    rol             => 'ADMIN',
                    numero_colegio  => undef,
                    nombre_completo => 'Administrador del Sistema',
                    tipo_usuario    => 'ADMIN',
                    departamento    => 'ADMIN',
                );

                return $c->render(
                    json => {
                        ok      => 1,
                        mensaje => 'Autenticación de administrador exitosa',
                        rol     => 'ADMIN',
                        usuario => {
                            numero_colegio  => undef,
                            nombre_completo => 'Administrador del Sistema',
                            tipo_usuario    => 'ADMIN',
                            departamento    => 'ADMIN',
                        },
                    }
                );
            }

            # 2. Probar usuario normal
            my $gestor_usuarios = $container->getGestorUsuarios();
            my ($ok, $msg, $obj_usuario) = $gestor_usuarios->autenticarUsuario($usuario, $clave);

            if (!$ok || !defined $obj_usuario) {
                return $c->render(
                    status => 401,
                    json   => {
                        ok      => 0,
                        mensaje => $msg || 'Credenciales inválidas',
                    }
                );
            }

            my $usuario_hash = _serializar_usuario($obj_usuario);

            $c->session(
                rol             => 'USUARIO',
                numero_colegio  => $usuario_hash->{numero_colegio},
                nombre_completo => $usuario_hash->{nombre_completo},
                tipo_usuario    => $usuario_hash->{tipo_usuario},
                departamento    => $usuario_hash->{departamento},
            );

            return $c->render(
                json => {
                    ok      => 1,
                    mensaje => 'Autenticación exitosa',
                    rol     => 'USUARIO',
                    usuario => $usuario_hash,
                }
            );
        }
    );

    $r->get('/api/auth/me')->to(
        cb => sub {
            my $c = shift;

            my $rol = $c->session('rol');

            if (!$rol) {
                return $c->render(
                    json => {
                        ok            => 1,
                        autenticado   => 0,
                        usuario       => undef,
                    }
                );
            }

            return $c->render(
                json => {
                    ok          => 1,
                    autenticado => 1,
                    rol         => $rol,
                    usuario     => {
                        numero_colegio  => $c->session('numero_colegio'),
                        nombre_completo => $c->session('nombre_completo'),
                        tipo_usuario    => $c->session('tipo_usuario'),
                        departamento    => $c->session('departamento'),
                    },
                }
            );
        }
    );

    $r->post('/api/auth/logout')->to(
        cb => sub {
            my $c = shift;

            # Si es usuario normal, intenta guardar historial de chat al cerrar sesión
            my $rol = $c->session('rol');
            my $numero_colegio = $c->session('numero_colegio');

            if (defined $rol && $rol eq 'USUARIO' && defined $numero_colegio) {
                my $gestor_msg = $container->getGestorMensajeria();
                $gestor_msg->cerrarSesionUsuario($numero_colegio) if defined $gestor_msg;
            }

            delete $c->session->{rol};
            delete $c->session->{numero_colegio};
            delete $c->session->{nombre_completo};
            delete $c->session->{tipo_usuario};
            delete $c->session->{departamento};

            return $c->render(
                json => {
                    ok      => 1,
                    mensaje => 'Sesión cerrada correctamente',
                }
            );
        }
    );

    # =====================================================
    # Middleware: autenticado
    # =====================================================
    my $auth = $r->under('/api' => sub {
        my $c = shift;

        if (!$c->session('rol')) {
            $c->render(
                status => 401,
                json   => {
                    ok      => 0,
                    mensaje => 'No autenticado',
                }
            );
            return undef;
        }

        return 1;
    });

    # =====================================================
    # Middleware: admin
    # =====================================================
    my $admin = $auth->under('/admin' => sub {
        my $c = shift;

        if (($c->session('rol') // '') ne 'ADMIN') {
            $c->render(
                status => 403,
                json   => {
                    ok      => 0,
                    mensaje => 'Acceso restringido a administradores',
                }
            );
            return undef;
        }

        return 1;
    });

    # =====================================================
    # Middleware: usuario normal
    # =====================================================
    my $usuario = $auth->under('/usuario' => sub {
        my $c = shift;

        if (($c->session('rol') // '') ne 'USUARIO') {
            $c->render(
                status => 403,
                json   => {
                    ok      => 0,
                    mensaje => 'Acceso restringido a usuarios autenticados',
                }
            );
            return undef;
        }

        return 1;
    });

    # =====================================================
    # RUTAS ADMIN
    # =====================================================

    $admin->get('/resumen')->to(
        cb => sub {
            my $c = shift;
            my $resumen = $container->obtenerResumenSistema();

            $c->render(
                json => {
                    ok      => 1,
                    resumen => $resumen,
                }
            );
        }
    );

    $admin->get('/usuarios')->to(
        cb => sub {
            my $c = shift;

            my $gestor = $container->getGestorUsuarios();
            my $usuarios = $gestor->listarUsuarios();

            $c->render(
                json => {
                    ok       => 1,
                    usuarios => _serializar_usuarios($usuarios),
                }
            );
        }
    );

    $admin->get('/usuarios/tipo/:tipo')->to(
        cb => sub {
            my $c = shift;

            my $tipo = $c->param('tipo') // '';
            my $gestor = $container->getGestorUsuarios();
            my $usuarios = $gestor->obtenerUsuariosPorTipo($tipo);

            $c->render(
                json => {
                    ok       => 1,
                    tipo     => $tipo,
                    cantidad => scalar(@$usuarios),
                    usuarios => _serializar_usuarios($usuarios),
                }
            );
        }
    );

    $admin->get('/usuarios/:numero_colegio')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->param('numero_colegio') // '';
            my $gestor = $container->getGestorUsuarios();
            my $usuario = $gestor->buscarUsuario($numero);

            if (!$usuario) {
                return $c->render(
                    status => 404,
                    json   => {
                        ok      => 0,
                        mensaje => 'Usuario no encontrado',
                    }
                );
            }

            $c->render(
                json => {
                    ok      => 1,
                    usuario => _serializar_usuario($usuario),
                }
            );
        }
    );

    $admin->get('/hash/resumen')->to(
        cb => sub {
            my $c = shift;

            my $gestor = $container->getGestorUsuarios();
            my $resumen = $gestor->obtenerResumenHash();

            $c->render(
                json => {
                    ok      => 1,
                    resumen => $resumen,
                }
            );
        }
    );

    $admin->get('/colaboracion/resumen')->to(
        cb => sub {
            my $c = shift;

            my $gestor = $container->getGestorColaboracion();
            my $resumen = $gestor->obtenerResumenRed();

            $c->render(
                json => {
                    ok      => 1,
                    resumen => $resumen,
                }
            );
        }
    );

    $admin->get('/colaboracion/aislados')->to(
        cb => sub {
            my $c = shift;

            my $gestor = $container->getGestorColaboracion();
            my $usuarios = $gestor->obtenerUsuariosAislados();

            $c->render(
                json => {
                    ok       => 1,
                    cantidad => scalar(@$usuarios),
                    usuarios => _serializar_usuarios($usuarios),
                }
            );
        }
    );

    $admin->get('/colaboracion/sin-departamento')->to(
        cb => sub {
            my $c = shift;

            my $gestor = $container->getGestorColaboracion();
            my $usuarios = $gestor->obtenerUsuariosSinDepartamento();

            $c->render(
                json => {
                    ok       => 1,
                    cantidad => scalar(@$usuarios),
                    usuarios => _serializar_usuarios($usuarios),
                }
            );
        }
    );

    $admin->post('/usuarios/:numero_colegio/departamento')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->param('numero_colegio') // '';
            my $body = $c->req->json || {};
            my $departamento = $body->{departamento} // '';

            if ($numero eq '' || $departamento eq '') {
                return $c->render(
                    status => 400,
                    json   => {
                        ok      => 0,
                        mensaje => 'Debe indicar numero_colegio y departamento',
                    }
                );
            }

            my $gestor = $container->getGestorColaboracion();
            my ($ok, $msg) = $gestor->asignarDepartamento($numero, $departamento);

            my $status = $ok ? 200 : 400;

            $c->render(
                status => $status,
                json   => {
                    ok      => $ok ? 1 : 0,
                    mensaje => $msg,
                }
            );
        }
    );

    # =====================================================
    # RUTAS USUARIO
    # =====================================================

    $usuario->get('/perfil')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $gestor_usuarios = $container->getGestorUsuarios();
            my $gestor_permisos = $container->getGestorPermisos();

            my $obj = $gestor_usuarios->buscarUsuario($numero);

            if (!$obj) {
                return $c->render(
                    status => 404,
                    json   => {
                        ok      => 0,
                        mensaje => 'Usuario no encontrado en el sistema',
                    }
                );
            }

            my $permisos = $gestor_permisos->obtenerPermisosUsuario($obj);

            $c->render(
                json => {
                    ok       => 1,
                    usuario  => _serializar_usuario($obj),
                    permisos => $permisos,
                }
            );
        }
    );

    $usuario->get('/colaboradores')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $gestor = $container->getGestorColaboracion();
            my $lista = $gestor->obtenerColaboradores($numero);

            $c->render(
                json => {
                    ok            => 1,
                    colaboradores => _serializar_usuarios($lista),
                }
            );
        }
    );

    $usuario->get('/sugerencias')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $gestor = $container->getGestorColaboracion();
            my $lista = $gestor->obtenerSugerenciasColaboracion($numero, 2);

            $c->render(
                json => {
                    ok          => 1,
                    sugerencias => $lista,
                }
            );
        }
    );

    $usuario->get('/solicitudes')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $gestor = $container->getGestorColaboracion();

            my $recibidas = $gestor->obtenerSolicitudesPendientesPara($numero);
            my $enviadas  = $gestor->obtenerSolicitudesEnviadasPor($numero);

            $c->render(
                json => {
                    ok        => 1,
                    recibidas => $recibidas,
                    enviadas  => $enviadas,
                }
            );
        }
    );

    $usuario->post('/solicitudes')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $body = $c->req->json || {};
            my $destino = $body->{destino} // $body->{receptor} // '';

            if ($destino eq '') {
                return $c->render(
                    status => 400,
                    json   => {
                        ok      => 0,
                        mensaje => 'Debe indicar el usuario destino',
                    }
                );
            }

            my $gestor = $container->getGestorColaboracion();
            my ($ok, $msg) = $gestor->enviarSolicitud($numero, $destino);

            my $status = $ok ? 200 : 400;

            $c->render(
                status => $status,
                json   => {
                    ok      => $ok ? 1 : 0,
                    mensaje => $msg,
                }
            );
        }
    );

    $usuario->post('/solicitudes/aceptar')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $body = $c->req->json || {};
            my $solicitante = $body->{solicitante} // '';

            if ($solicitante eq '') {
                return $c->render(
                    status => 400,
                    json   => {
                        ok      => 0,
                        mensaje => 'Debe indicar el solicitante',
                    }
                );
            }

            my $gestor = $container->getGestorColaboracion();
            my ($ok, $msg) = $gestor->aceptarSolicitud($solicitante, $numero);

            my $status = $ok ? 200 : 400;

            $c->render(
                status => $status,
                json   => {
                    ok      => $ok ? 1 : 0,
                    mensaje => $msg,
                }
            );
        }
    );

    $usuario->post('/solicitudes/rechazar')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $body = $c->req->json || {};
            my $solicitante = $body->{solicitante} // '';

            if ($solicitante eq '') {
                return $c->render(
                    status => 400,
                    json   => {
                        ok      => 0,
                        mensaje => 'Debe indicar el solicitante',
                    }
                );
            }

            my $gestor = $container->getGestorColaboracion();
            my ($ok, $msg) = $gestor->rechazarSolicitud($solicitante, $numero);

            my $status = $ok ? 200 : 400;

            $c->render(
                status => $status,
                json   => {
                    ok      => $ok ? 1 : 0,
                    mensaje => $msg,
                }
            );
        }
    );

    $usuario->get('/chat/conversaciones')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $gestor = $container->getGestorMensajeria();
            my $lista = $gestor->listarConversacionesUsuario($numero);

            $c->render(
                json => {
                    ok             => 1,
                    conversaciones => $lista,
                }
            );
        }
    );

    $usuario->get('/chat/:otro_id')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $otro   = $c->param('otro_id') // '';

            my $gestor = $container->getGestorMensajeria();
            my $conv = $gestor->obtenerConversacion($numero, $otro);

            $c->render(
                json => {
                    ok          => 1,
                    con_usuario => $otro,
                    mensajes    => $conv,
                }
            );
        }
    );

    $usuario->post('/chat/:otro_id')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $otro   = $c->param('otro_id') // '';
            my $body   = $c->req->json || {};
            my $texto  = $body->{texto} // '';

            if ($otro eq '' || $texto eq '') {
                return $c->render(
                    status => 400,
                    json   => {
                        ok      => 0,
                        mensaje => 'Debe indicar destinatario y texto',
                    }
                );
            }

            my $gestor = $container->getGestorMensajeria();
            my ($ok, $msg, $mensaje_obj) = $gestor->enviarMensaje($numero, $otro, $texto);

            my $status = $ok ? 200 : 400;

            $c->render(
                status => $status,
                json   => {
                    ok      => $ok ? 1 : 0,
                    mensaje => $msg,
                    data    => $mensaje_obj,
                }
            );
        }
    );
}

# =========================================================
# Helpers privados
# =========================================================
sub _serializar_usuarios {
    my ($lista) = @_;

    return [] if ref($lista) ne 'ARRAY';

    my @salida;
    foreach my $u (@$lista) {
        push @salida, _serializar_usuario($u);
    }

    return \@salida;
}

sub _serializar_usuario {
    my ($u) = @_;

    return undef if !defined $u;

    # Si ya viene como hash
    if (ref($u) eq 'HASH') {
        return {
            numero_colegio  => _obtener_campo($u, 'numero_colegio'),
            nombre_completo => _obtener_campo($u, 'nombre_completo'),
            tipo_usuario    => _obtener_campo($u, 'tipo_usuario'),
            departamento    => _obtener_campo($u, 'departamento'),
            especialidad    => _obtener_campo($u, 'especialidad'),
        };
    }

    return {
        numero_colegio  => _obtener_campo($u, 'numero_colegio'),
        nombre_completo => _obtener_campo($u, 'nombre_completo'),
        tipo_usuario    => _obtener_campo($u, 'tipo_usuario'),
        departamento    => _obtener_campo($u, 'departamento'),
        especialidad    => _obtener_campo($u, 'especialidad'),
    };
}

sub _obtener_campo {
    my ($obj, $campo) = @_;

    return undef if !defined $obj;

    if (ref($obj) eq 'HASH') {
        return $obj->{$campo} if exists $obj->{$campo};
    }

    my %getters = (
        numero_colegio  => [qw(getNumeroColegio numero_colegio getClave clave)],
        nombre_completo => [qw(getNombreCompleto nombre_completo)],
        tipo_usuario    => [qw(getTipoUsuario tipo_usuario)],
        departamento    => [qw(getDepartamento departamento)],
        especialidad    => [qw(getEspecialidad especialidad)],
    );

    foreach my $getter (@{ $getters{$campo} || [] }) {
        if ($obj->can($getter)) {
            my $valor = eval { $obj->$getter() };
            return $valor if defined $valor;
        }
    }

    my $valor = eval { $obj->{$campo} };
    return $valor if defined $valor;

    return undef;
}

1;