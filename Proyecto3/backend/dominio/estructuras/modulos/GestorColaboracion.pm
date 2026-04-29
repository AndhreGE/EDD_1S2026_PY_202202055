package estructuras::modulos::GestorColaboracion;

use strict;
use warnings;
use utf8;

use estructuras::Grafos::GrafoColaboracion;

sub new {
    my ($class, %args) = @_;

    my $self = {
        grafo => $args{grafo} // estructuras::Grafos::GrafoColaboracion->new(),

        gestor_usuarios => $args{gestor_usuarios},

        colaboraciones_activas => {},   # clave no dirigida: A|B
        solicitudes_pendientes => {},   # clave dirigida: A|B
        solicitudes_rechazadas => {},   # clave dirigida: A|B
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Getters básicos
# =========================================================

sub getGrafo {
    my ($self) = @_;
    return $self->{grafo};
}

sub getGestorUsuarios {
    my ($self) = @_;
    return $self->{gestor_usuarios};
}

# =========================================================
# Sincronización con usuarios
# =========================================================

sub sincronizarDesdeGestorUsuarios {
    my ($self) = @_;

    return (0, 'No hay gestor de usuarios configurado')
        if !defined $self->{gestor_usuarios};

    return (0, 'El gestor de usuarios no expone listarUsuarios()')
        if !$self->{gestor_usuarios}->can('listarUsuarios');

    my $usuarios = $self->{gestor_usuarios}->listarUsuarios();
    return (0, 'El gestor de usuarios no devolvió una lista válida')
        if ref($usuarios) ne 'ARRAY';

    my ($ok, $msg) = $self->{grafo}->sincronizarDesdeListaUsuarios($usuarios);
    return ($ok, $msg);
}

sub agregarUsuarioAlGrafo {
    my ($self, $usuario, %extra) = @_;
    return $self->{grafo}->agregarUsuario($usuario, %extra);
}

sub actualizarUsuarioEnGrafo {
    my ($self, $usuario, %extra) = @_;
    return $self->{grafo}->actualizarUsuario($usuario, %extra);
}

sub eliminarUsuarioDelGrafo {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar un usuario válido') if !defined $id || $id eq '';

    # Eliminar solicitudes pendientes / rechazadas asociadas
    foreach my $clave (keys %{ $self->{solicitudes_pendientes} }) {
        my $r = $self->{solicitudes_pendientes}{$clave};
        delete $self->{solicitudes_pendientes}{$clave}
            if $r->{solicitante} eq $id || $r->{receptor} eq $id;
    }

    foreach my $clave (keys %{ $self->{solicitudes_rechazadas} }) {
        my $r = $self->{solicitudes_rechazadas}{$clave};
        delete $self->{solicitudes_rechazadas}{$clave}
            if $r->{solicitante} eq $id || $r->{receptor} eq $id;
    }

    # Eliminar colaboraciones activas asociadas
    foreach my $clave (keys %{ $self->{colaboraciones_activas} }) {
        my $r = $self->{colaboraciones_activas}{$clave};
        delete $self->{colaboraciones_activas}{$clave}
            if $r->{usuario_a} eq $id || $r->{usuario_b} eq $id;
    }

    return $self->{grafo}->eliminarUsuario($id);
}

# =========================================================
# Colaboraciones activas
# =========================================================

sub registrarColaboracionActiva {
    my ($self, $usuario_a, $usuario_b) = @_;

    my $id_a = $self->_extraer_id($usuario_a);
    my $id_b = $self->_extraer_id($usuario_b);

    return (0, 'Debe indicar ambos usuarios')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';

    my ($ok, $msg) = $self->{grafo}->agregarColaboracion($id_a, $id_b);
    return ($ok, $msg) if !$ok;

    my $clave = $self->_clave_no_dirigida($id_a, $id_b);

    $self->{colaboraciones_activas}{$clave} = {
        usuario_a => (sort ($id_a, $id_b))[0],
        usuario_b => (sort ($id_a, $id_b))[1],
        estado    => 'ACTIVA',
    };

    # Si ya había solicitudes pendientes o rechazadas entre ambos, se limpian
    delete $self->{solicitudes_pendientes}{ $self->_clave_dirigida($id_a, $id_b) };
    delete $self->{solicitudes_pendientes}{ $self->_clave_dirigida($id_b, $id_a) };
    delete $self->{solicitudes_rechazadas}{ $self->_clave_dirigida($id_a, $id_b) };
    delete $self->{solicitudes_rechazadas}{ $self->_clave_dirigida($id_b, $id_a) };

    return (1, "Colaboración activa registrada entre $id_a y $id_b");
}

sub eliminarColaboracion {
    my ($self, $usuario_a, $usuario_b) = @_;

    my $id_a = $self->_extraer_id($usuario_a);
    my $id_b = $self->_extraer_id($usuario_b);

    return (0, 'Debe indicar ambos usuarios')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';

    my ($ok, $msg) = $self->{grafo}->eliminarColaboracion($id_a, $id_b);
    return ($ok, $msg) if !$ok;

    my $clave = $self->_clave_no_dirigida($id_a, $id_b);
    delete $self->{colaboraciones_activas}{$clave};

    return (1, "Colaboración eliminada entre $id_a y $id_b");
}

sub listarColaboracionesActivas {
    my ($self) = @_;

    my @lista = map { $self->{colaboraciones_activas}{$_} }
                sort keys %{ $self->{colaboraciones_activas} };

    return \@lista;
}

sub colaboracionesActivasComoTexto {
    my ($self) = @_;

    my $lista = $self->listarColaboracionesActivas();
    return 'Sin colaboraciones activas' if !@$lista;

    my @lineas;
    foreach my $r (@$lista) {
        push @lineas, "$r->{usuario_a} <-> $r->{usuario_b} [$r->{estado}]";
    }

    return join("\n", @lineas);
}

# =========================================================
# Solicitudes de colaboración
# =========================================================

sub enviarSolicitud {
    my ($self, $solicitante, $receptor) = @_;

    my $id_a = $self->_extraer_id($solicitante);
    my $id_b = $self->_extraer_id($receptor);

    return (0, 'Debe indicar solicitante y receptor')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';

    return (0, 'No se puede enviar una solicitud a sí mismo')
        if $id_a eq $id_b;

    return (0, "El usuario $id_a no existe en el grafo")
        if !$self->{grafo}->existeUsuario($id_a);

    return (0, "El usuario $id_b no existe en el grafo")
        if !$self->{grafo}->existeUsuario($id_b);

    return (0, "Los usuarios $id_a y $id_b ya son colaboradores")
        if $self->{grafo}->sonColaboradores($id_a, $id_b);

    my $clave_ab = $self->_clave_dirigida($id_a, $id_b);
    my $clave_ba = $self->_clave_dirigida($id_b, $id_a);

    return (0, 'Ya existe una solicitud pendiente entre esos usuarios')
        if exists $self->{solicitudes_pendientes}{$clave_ab}
        || exists $self->{solicitudes_pendientes}{$clave_ba};

    $self->{solicitudes_pendientes}{$clave_ab} = {
        solicitante => $id_a,
        receptor    => $id_b,
        estado      => 'PENDIENTE',
    };

    return (1, "Solicitud enviada de $id_a hacia $id_b");
}

sub aceptarSolicitud {
    my ($self, $solicitante, $receptor) = @_;

    my $id_a = $self->_extraer_id($solicitante);
    my $id_b = $self->_extraer_id($receptor);

    return (0, 'Debe indicar solicitante y receptor')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';

    my $clave = $self->_clave_dirigida($id_a, $id_b);

    return (0, "No existe una solicitud pendiente de $id_a hacia $id_b")
        if !exists $self->{solicitudes_pendientes}{$clave};

    delete $self->{solicitudes_pendientes}{$clave};

    return $self->registrarColaboracionActiva($id_a, $id_b);
}

sub rechazarSolicitud {
    my ($self, $solicitante, $receptor) = @_;

    my $id_a = $self->_extraer_id($solicitante);
    my $id_b = $self->_extraer_id($receptor);

    return (0, 'Debe indicar solicitante y receptor')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';

    my $clave = $self->_clave_dirigida($id_a, $id_b);

    return (0, "No existe una solicitud pendiente de $id_a hacia $id_b")
        if !exists $self->{solicitudes_pendientes}{$clave};

    delete $self->{solicitudes_pendientes}{$clave};

    $self->{solicitudes_rechazadas}{$clave} = {
        solicitante => $id_a,
        receptor    => $id_b,
        estado      => 'RECHAZADA',
    };

    return (1, "Solicitud de $id_a hacia $id_b rechazada");
}

sub existeSolicitudPendiente {
    my ($self, $solicitante, $receptor) = @_;

    my $id_a = $self->_extraer_id($solicitante);
    my $id_b = $self->_extraer_id($receptor);

    return 0 if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';

    my $clave = $self->_clave_dirigida($id_a, $id_b);
    return exists $self->{solicitudes_pendientes}{$clave} ? 1 : 0;
}

sub obtenerSolicitudesPendientesPara {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return [] if !defined $id || $id eq '';

    my @lista;
    foreach my $clave (sort keys %{ $self->{solicitudes_pendientes} }) {
        my $r = $self->{solicitudes_pendientes}{$clave};
        push @lista, $r if $r->{receptor} eq $id;
    }

    return \@lista;
}

sub obtenerSolicitudesEnviadasPor {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return [] if !defined $id || $id eq '';

    my @lista;
    foreach my $clave (sort keys %{ $self->{solicitudes_pendientes} }) {
        my $r = $self->{solicitudes_pendientes}{$clave};
        push @lista, $r if $r->{solicitante} eq $id;
    }

    return \@lista;
}

sub obtenerTodasLasSolicitudesPendientes {
    my ($self) = @_;

    my @lista = map { $self->{solicitudes_pendientes}{$_} }
                sort keys %{ $self->{solicitudes_pendientes} };

    return \@lista;
}

sub solicitudesPendientesComoTexto {
    my ($self) = @_;

    my $lista = $self->obtenerTodasLasSolicitudesPendientes();
    return 'Sin solicitudes pendientes' if !@$lista;

    my @lineas;
    foreach my $r (@$lista) {
        push @lineas, "$r->{solicitante} -> $r->{receptor} [$r->{estado}]";
    }

    return join("\n", @lineas);
}

# =========================================================
# Relaciones desde JSON o arreglos
# =========================================================

sub cargarRelacionesDesdeArreglo {
    my ($self, $relaciones) = @_;

    return {
        ok                   => 0,
        mensaje              => 'Debe proporcionar un arreglo de relaciones',
        relaciones_leidas    => 0,
        activas_agregadas    => 0,
        pendientes_agregadas => 0,
        rechazadas_cargadas  => 0,
        errores              => [],
    } if ref($relaciones) ne 'ARRAY';

    my $resultado = {
        ok                   => 1,
        mensaje              => 'Carga de relaciones completada',
        relaciones_leidas    => scalar(@$relaciones),
        activas_agregadas    => 0,
        pendientes_agregadas => 0,
        rechazadas_cargadas  => 0,
        errores              => [],
    };

    foreach my $rel (@$relaciones) {
        my $solicitante = $rel->{solicitante} // '';
        my $receptor    = $rel->{receptor}    // '';
        my $estado      = uc($rel->{estado} // '');

        if ($solicitante eq '' || $receptor eq '' || $estado eq '') {
            push @{ $resultado->{errores} }, 'Relación inválida: faltan campos requeridos';
            next;
        }

        if ($estado eq 'ACTIVA') {
            my ($ok, $msg) = $self->registrarColaboracionActiva($solicitante, $receptor);
            if ($ok) {
                $resultado->{activas_agregadas}++;
            } else {
                push @{ $resultado->{errores} }, $msg;
            }
        }
        elsif ($estado eq 'PENDIENTE') {
            my ($ok, $msg) = $self->enviarSolicitud($solicitante, $receptor);
            if ($ok) {
                $resultado->{pendientes_agregadas}++;
            } else {
                push @{ $resultado->{errores} }, $msg;
            }
        }
        elsif ($estado eq 'RECHAZADA') {
            my $clave = $self->_clave_dirigida($solicitante, $receptor);
            $self->{solicitudes_rechazadas}{$clave} = {
                solicitante => $solicitante,
                receptor    => $receptor,
                estado      => 'RECHAZADA',
            };
            $resultado->{rechazadas_cargadas}++;
        }
        else {
            push @{ $resultado->{errores} }, "Estado no reconocido: $estado";
        }
    }

    return $resultado;
}

# =========================================================
# Consultas útiles
# =========================================================

sub obtenerColaboradores {
    my ($self, $usuario_o_id) = @_;
    return $self->{grafo}->obtenerColaboradores($usuario_o_id);
}

sub obtenerSugerenciasColaboracion {
    my ($self, $usuario_o_id, $minimo_comunes) = @_;
    return $self->{grafo}->obtenerSugerenciasColaboracion($usuario_o_id, $minimo_comunes);
}

sub sugerenciasComoTexto {
    my ($self, $usuario_o_id, $minimo_comunes) = @_;

    my $sugerencias = $self->obtenerSugerenciasColaboracion($usuario_o_id, $minimo_comunes);
    return 'Sin sugerencias de colaboración' if !@$sugerencias;

    my @lineas;
    foreach my $s (@$sugerencias) {
        my $comunes = $s->{colaboradores_en_comun} // 0;
        my $ids     = join(', ', @{ $s->{ids_colaboradores_en_comun} || [] });

        push @lineas,
            "$s->{numero_colegio} | $s->{nombre_completo} | comunes: $comunes | via: [$ids]";
    }

    return join("\n", @lineas);
}

sub obtenerUsuariosAislados {
    my ($self) = @_;
    return $self->{grafo}->obtenerUsuariosAislados();
}

sub obtenerUsuariosSinDepartamento {
    my ($self) = @_;
    return $self->{grafo}->obtenerUsuariosSinDepartamento();
}

sub obtenerResumenRed {
    my ($self) = @_;

    return {
        usuarios                => $self->{grafo}->cantidadUsuarios(),
        colaboraciones_activas  => $self->{grafo}->cantidadColaboraciones(),
        solicitudes_pendientes  => scalar keys %{ $self->{solicitudes_pendientes} },
        solicitudes_rechazadas  => scalar keys %{ $self->{solicitudes_rechazadas} },
        usuarios_aislados       => scalar @{ $self->obtenerUsuariosAislados() },
        sin_departamento        => scalar @{ $self->obtenerUsuariosSinDepartamento() },
    };
}

# =========================================================
# Asignación y reasignación de departamento
# =========================================================

sub asignarDepartamento {
    my ($self, $usuario_o_id, $nuevo_departamento) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar el usuario') if !defined $id || $id eq '';
    return (0, 'Debe indicar el nuevo departamento') if !defined $nuevo_departamento || $nuevo_departamento eq '';

    return (0, "El usuario $id no existe en el grafo")
        if !$self->{grafo}->existeUsuario($id);

    my $obj_usuario = $self->_buscar_usuario_obj($id);

    if (defined $obj_usuario) {
        my $ok_set = $self->_set_usuario_campo($obj_usuario, 'departamento', $nuevo_departamento);
        # aunque no se logre setear en el objeto, igual actualizamos metadata del grafo
    }

    # Actualizar metadata en el grafo
    if (exists $self->{grafo}{nodos}{$id}) {
        $self->{grafo}{nodos}{$id}{departamento} = $nuevo_departamento;
    }

    return (1, "Departamento de $id actualizado a $nuevo_departamento");
}

sub reasignarDepartamento {
    my ($self, $usuario_o_id, $nuevo_departamento) = @_;
    return $self->asignarDepartamento($usuario_o_id, $nuevo_departamento);
}

# =========================================================
# Reportes
# =========================================================

sub generarReporteGrafo {
    my ($self, $ruta_dot, $ruta_png) = @_;
    return $self->{grafo}->generarPNGRed($ruta_dot, $ruta_png);
}

sub generarReporteListaAdyacencia {
    my ($self, $ruta_dot, $ruta_png) = @_;
    return $self->{grafo}->generarPNGListaAdyacencia($ruta_dot, $ruta_png);
}

# =========================================================
# Helpers internos
# =========================================================

sub _extraer_id {
    my ($self, $usuario) = @_;
    return undef if !defined $usuario;

    if (!ref($usuario)) {
        return $usuario;
    }

    if (ref($usuario) eq 'HASH') {
        return $usuario->{numero_colegio} if defined $usuario->{numero_colegio};
    }

    foreach my $getter (qw(getNumeroColegio numero_colegio)) {
        if ($usuario->can($getter)) {
            my $valor = eval { $usuario->$getter() };
            return $valor if defined $valor;
        }
    }

    return undef;
}

sub _clave_no_dirigida {
    my ($self, $a, $b) = @_;
    return join('|', sort ($a, $b));
}

sub _clave_dirigida {
    my ($self, $a, $b) = @_;
    return "$a|$b";
}

sub _buscar_usuario_obj {
    my ($self, $id) = @_;

    # Intentar desde metadata del grafo
    if (exists $self->{grafo}{nodos}{$id} && defined $self->{grafo}{nodos}{$id}{usuario_obj}) {
        return $self->{grafo}{nodos}{$id}{usuario_obj};
    }

    # Intentar desde gestor_usuarios
    if (defined $self->{gestor_usuarios} && $self->{gestor_usuarios}->can('buscarUsuario')) {
        my $obj = eval { $self->{gestor_usuarios}->buscarUsuario($id) };
        return $obj if defined $obj;
    }

    return undef;
}

sub _set_usuario_campo {
    my ($self, $obj, $campo, $valor) = @_;

    return 0 if !defined $obj;

    my $setter = 'set' . $self->_camelizar($campo);

    if ($obj->can($setter)) {
        eval { $obj->$setter($valor); };
        return $@ ? 0 : 1;
    }

    if (ref($obj) eq 'HASH') {
        $obj->{$campo} = $valor;
        return 1;
    }

    eval {
        $obj->{$campo} = $valor;
    };
    return $@ ? 0 : 1;
}

sub _camelizar {
    my ($self, $texto) = @_;
    $texto //= '';
    $texto =~ s/(^|_)([a-z])/\U$2/g;
    return $texto;
}

1;