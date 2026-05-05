package EDDMedTrack::Routes;

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Temp qw(tempfile);

sub register {
    my ($class, $app, $container) = @_;

    die "Se requiere una app de Mojolicious" if !defined $app;
    die "Se requiere un AppContainer" if !defined $container;

    my $r = $app->routes;

    my $guardar_upload_temp = sub {
        my ($upload, $suffix) = @_;

        my ($fh, $ruta) = tempfile(SUFFIX => ($suffix || '.json'), UNLINK => 1);
        binmode($fh, ':raw');
        print {$fh} $upload->asset->slurp;
        close($fh);

        return $ruta;
    };

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
                        ok          => 1,
                        autenticado => 0,
                        usuario     => undef,
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
            my $usuario_obj = $gestor->buscarUsuario($numero);

            if (!$usuario_obj) {
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
                    usuario => _serializar_usuario($usuario_obj),
                }
            );
        }
    );

    $admin->post('/usuarios/manual')->to(
        cb => sub {
            my $c = shift;
            my $body = $c->req->json || {};

            my $res = $container->registrarUsuarioManual(
                numero_colegio  => $body->{numero_colegio},
                nombre_completo => $body->{nombre_completo},
                tipo_usuario    => $body->{tipo_usuario},
                departamento    => $body->{departamento},
                especialidad    => $body->{especialidad},
                clave           => $body->{clave},
            );

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
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

    $admin->get('/colaboracion/solicitudes-pendientes')->to(
        cb => sub {
            my $c = shift;

            my $lista = $container->listarSolicitudesColaboracionPendientesGlobales();

            $c->render(
                json => {
                    ok          => 1,
                    solicitudes => $lista,
                }
            );
        }
    );

    $admin->post('/colaboracion/solicitudes/aprobar')->to(
        cb => sub {
            my $c = shift;
            my $body = $c->req->json || {};

            my ($ok, $msg, $lista) = $container->aprobarSolicitudColaboracionComoAdmin(
                solicitante => $body->{solicitante} // '',
                receptor    => $body->{receptor} // '',
            );

            $c->render(
                status => $ok ? 200 : 400,
                json   => {
                    ok          => $ok ? 1 : 0,
                    mensaje     => $msg,
                    solicitudes => $lista || [],
                }
            );
        }
    );

    $admin->post('/colaboracion/solicitudes/rechazar')->to(
        cb => sub {
            my $c = shift;
            my $body = $c->req->json || {};

            my ($ok, $msg, $lista) = $container->rechazarSolicitudColaboracionComoAdmin(
                solicitante => $body->{solicitante} // '',
                receptor    => $body->{receptor} // '',
            );

            $c->render(
                status => $ok ? 200 : 400,
                json   => {
                    ok          => $ok ? 1 : 0,
                    mensaje     => $msg,
                    solicitudes => $lista || [],
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

    # ---------------------------------------------
    # Cargas automáticas desde backend/cargas
    # ---------------------------------------------
    $admin->post('/cargas/usuarios')->to(
        cb => sub {
            my $c = shift;

            my $res = $container->cargarUsuariosDesdeJSON();
            my $status = $res->{ok} ? 200 : 400;

            $c->render(
                status => $status,
                json   => $res
            );
        }
    );

    $admin->post('/cargas/inventario')->to(
        cb => sub {
            my $c = shift;

            my $res = $container->cargarInventarioDesdeJSON();
            my $status = $res->{ok} ? 200 : 400;

            $c->render(
                status => $status,
                json   => $res
            );
        }
    );

    $admin->post('/cargas/colaboraciones')->to(
        cb => sub {
            my $c = shift;

            my $res = $container->cargarColaboracionesDesdeJSON();
            my $status = $res->{ok} ? 200 : 400;

            $c->render(
                status => $status,
                json   => $res
            );
        }
    );

    # ---------------------------------------------
    # Cargas manuales por upload
    # ---------------------------------------------
    $admin->post('/cargas/usuarios/upload')->to(
        cb => sub {
            my $c = shift;

            my $upload = $c->req->upload('archivo');
            return $c->render(
                status => 400,
                json   => { ok => 0, mensaje => 'Debe seleccionar un archivo JSON de usuarios' }
            ) if !$upload;

            my $ruta_temp = $guardar_upload_temp->($upload, '.json');
            my $res = $container->cargarUsuariosDesdeJSON(
                archivo         => $ruta_temp,
                nombre_original => $upload->filename,
                forzar          => 1,
            );

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
            );
        }
    );

    $admin->post('/cargas/inventario/upload')->to(
        cb => sub {
            my $c = shift;

            my $upload = $c->req->upload('archivo');
            return $c->render(
                status => 400,
                json   => { ok => 0, mensaje => 'Debe seleccionar un archivo JSON de inventario' }
            ) if !$upload;

            my $ruta_temp = $guardar_upload_temp->($upload, '.json');
            my $res = $container->cargarInventarioDesdeJSON(
                archivo         => $ruta_temp,
                nombre_original => $upload->filename,
            );

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
            );
        }
    );

    $admin->post('/cargas/colaboraciones/upload')->to(
        cb => sub {
            my $c = shift;

            my $upload = $c->req->upload('archivo');
            return $c->render(
                status => 400,
                json   => { ok => 0, mensaje => 'Debe seleccionar un archivo JSON de colaboraciones' }
            ) if !$upload;

            my $ruta_temp = $guardar_upload_temp->($upload, '.json');
            my $res = $container->cargarColaboracionesDesdeJSON(
                archivo         => $ruta_temp,
                nombre_original => $upload->filename,
            );

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
            );
        }
    );

    # ---------------------------------------------
    # Reportes
    # ---------------------------------------------
    $admin->get('/reportes/grafo')->to(
        cb => sub {
            my $c = shift;

            my $res = $container->generarReporteGrafo();
            my $status = $res->{ok} ? 200 : 400;

            $res->{image_url} = "/api/admin/reportes/archivo/$res->{filename}?ts=" . time
                if $res->{ok} && $res->{filename};

            $c->render(
                status => $status,
                json   => $res
            );
        }
    );

    $admin->get('/reportes/lista-adyacencia')->to(
        cb => sub {
            my $c = shift;

            my $res = $container->generarReporteListaAdyacencia();
            my $status = $res->{ok} ? 200 : 400;

            $res->{image_url} = "/api/admin/reportes/archivo/$res->{filename}?ts=" . time
                if $res->{ok} && $res->{filename};

            $c->render(
                status => $status,
                json   => $res
            );
        }
    );

    $admin->get('/reportes/hash')->to(
        cb => sub {
            my $c = shift;

            my $res = $container->generarReporteTablaHash();
            my $status = $res->{ok} ? 200 : 400;

            $res->{image_url} = "/api/admin/reportes/archivo/$res->{filename}?ts=" . time
                if $res->{ok} && $res->{filename};

            $c->render(
                status => $status,
                json   => $res
            );
        }
    );

    $admin->get('/reportes/archivo/*filename')->to(
        format => undef,
        cb => sub {
            my $c = shift;

            my $filename = $c->stash('filename') // '';
            if ($filename eq '' || $filename =~ m![\\/]!) {
                return $c->render(
                    status => 400,
                    text   => 'Nombre de archivo inválido'
                );
            }

            my $ruta = File::Spec->catfile($container->getReportesDir(), $filename);

            return $c->render(
                status => 404,
                text   => "Reporte no encontrado: $filename"
            ) if !-e $ruta;

            return $c->reply->file($ruta);
        }
    );

    # ---------------------------------------------
    # Reabastecimiento (admin)
    # ---------------------------------------------
    $admin->get('/reabastecimiento')->to(
        cb => sub {
            my $c = shift;

            my $lista = $container->listarSolicitudesReabastecimiento();

            $c->render(
                json => {
                    ok          => 1,
                    solicitudes => $lista,
                }
            );
        }
    );

    $admin->post('/reabastecimiento/:id/aprobar')->to(
        cb => sub {
            my $c = shift;

            my $id = $c->param('id') // '';
            my $body = $c->req->json || {};

            my ($ok, $msg, $solicitud) = $container->cambiarEstadoSolicitudReabastecimiento(
                id                => $id,
                estado            => 'APROBADA',
                admin_actor       => 'ADMIN',
                observacion_admin => $body->{observacion} // '',
            );

            $c->render(
                status => $ok ? 200 : 400,
                json   => {
                    ok        => $ok ? 1 : 0,
                    mensaje   => $msg,
                    solicitud => $solicitud,
                }
            );
        }
    );

    $admin->post('/reabastecimiento/:id/rechazar')->to(
        cb => sub {
            my $c = shift;

            my $id = $c->param('id') // '';
            my $body = $c->req->json || {};

            my ($ok, $msg, $solicitud) = $container->cambiarEstadoSolicitudReabastecimiento(
                id                => $id,
                estado            => 'RECHAZADA',
                admin_actor       => 'ADMIN',
                observacion_admin => $body->{observacion} // '',
            );

            $c->render(
                status => $ok ? 200 : 400,
                json   => {
                    ok        => $ok ? 1 : 0,
                    mensaje   => $msg,
                    solicitud => $solicitud,
                }
            );
        }
    );

    $admin->post('/reabastecimiento/:id/atender')->to(
        cb => sub {
            my $c = shift;

            my $id = $c->param('id') // '';
            my $body = $c->req->json || {};

            my ($ok, $msg, $solicitud) = $container->cambiarEstadoSolicitudReabastecimiento(
                id                => $id,
                estado            => 'ATENDIDA',
                admin_actor       => 'ADMIN',
                observacion_admin => $body->{observacion} // '',
            );

            $c->render(
                status => $ok ? 200 : 400,
                json   => {
                    ok        => $ok ? 1 : 0,
                    mensaje   => $msg,
                    solicitud => $solicitud,
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

    $usuario->get('/insumos-solicitables')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $lista = $container->obtenerSuministrosSolicitables($numero);

            $c->render(
                json => {
                    ok      => 1,
                    insumos => $lista,
                }
            );
        }
    );

    $usuario->post('/reabastecimiento')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $body = $c->req->json || {};

            my ($ok, $msg, $solicitud) = $container->crearSolicitudReabastecimiento(
                numero_colegio => $numero,
                codigo         => $body->{codigo} // '',
                cantidad       => $body->{cantidad} // 0,
                observacion    => $body->{observacion} // '',
            );

            my $status = $ok ? 200 : 400;

            $c->render(
                status => $status,
                json   => {
                    ok        => $ok ? 1 : 0,
                    mensaje   => $msg,
                    solicitud => $solicitud,
                }
            );
        }
    );

    $usuario->get('/reabastecimiento/mis-solicitudes')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $lista = $container->listarSolicitudesReabastecimientoUsuario($numero);

            $c->render(
                json => {
                    ok          => 1,
                    solicitudes => $lista,
                }
            );
        }
    );

    $usuario->get('/lzw/estado')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $res = $container->obtenerEstadoLZWUsuario($numero);

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
            );
        }
    );

    $usuario->post('/lzw/guardar')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $res = $container->guardarHistorialLZWUsuario($numero);

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
            );
        }
    );

    $usuario->post('/lzw/recargar')->to(
        cb => sub {
            my $c = shift;

            my $numero = $c->session('numero_colegio');
            my $res = $container->recargarHistorialLZWUsuario($numero);

            $c->render(
                status => $res->{ok} ? 200 : 400,
                json   => $res,
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
        numero_colegio  => [qw(getNumeroColegio numero_colegio getCodigo codigo)],
        nombre_completo => [qw(getNombreCompleto nombre_completo)],
        tipo_usuario    => [qw(getTipoUsuario tipo_usuario)],
        departamento    => [qw(getDepartamento departamento)],
        especialidad    => [qw(getEspecialidad especialidad)],
    );

    foreach my $getter (@{ $getters{$campo} || [] }) {
        if (ref($obj) && $obj->can($getter)) {
            my $valor = eval { $obj->$getter() };
            return $valor if defined $valor;
        }
    }

    my $valor = eval { $obj->{$campo} };
    return $valor if defined $valor;

    return undef;
}

1;