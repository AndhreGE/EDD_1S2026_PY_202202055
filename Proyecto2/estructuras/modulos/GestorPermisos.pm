package estructuras::modulos::GestorPermisos;

use strict;
use warnings;

sub new {
    my ($class, @args) = @_;

    my %args;
    if (@args == 1 && ref($args[0]) eq 'HASH') {
        %args = %{ $args[0] };
    } else {
        %args = @args;
    }

    my $self = {
        tipos_inventario => $args{tipos_inventario} || [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
        reglas_tipo      => $args{reglas_tipo}      || _reglas_tipo_por_defecto(),
        reglas_departamento => $args{reglas_departamento} || _reglas_departamento_por_defecto(),
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Reglas por defecto
# =========================================================
sub _reglas_tipo_por_defecto {
    return {
        'TIPO-01' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
        },
        'TIPO-02' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
        },
        'TIPO-03' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [qw(SUMINISTRO)],
        },
        'TIPO-04' => {
            consulta => [qw(MEDICAMENTO SUMINISTRO)],
            solicitud => [qw(MEDICAMENTO SUMINISTRO)],
        },
        'TIPO-05' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [],
        },
    };
}

sub _reglas_departamento_por_defecto {
    return {
        'DEP-MED' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
        },
        'DEP-CIR' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
        },
        'DEP-FAR' => {
            consulta => [qw(MEDICAMENTO SUMINISTRO)],
            solicitud => [qw(MEDICAMENTO SUMINISTRO)],
        },
        'DEP-LAB' => {
            consulta => [qw(EQUIPO SUMINISTRO)],
            solicitud => [qw(SUMINISTRO)],
        },
        'DEP-ADM' => {
            consulta => [qw(MEDICAMENTO EQUIPO SUMINISTRO)],
            solicitud => [],
        },
    };
}

# =========================================================
# Getters básicos
# =========================================================
sub getTiposInventario {
    my ($self) = @_;
    return $self->{tipos_inventario};
}

sub getReglasTipo {
    my ($self) = @_;
    return $self->{reglas_tipo};
}

sub getReglasDepartamento {
    my ($self) = @_;
    return $self->{reglas_departamento};
}

# =========================================================
# Obtención de permisos efectivos
# =========================================================
sub obtenerPermisosUsuario {
    my ($self, $usuario) = @_;

    my $ctx = $self->_resolver_contexto_usuario($usuario);

    my $rol         = $ctx->{rol};
    my $tipo        = $ctx->{tipo_usuario};
    my $departamento= $ctx->{departamento};

    # Admin del sistema: acceso completo
    if (defined $rol && uc($rol) eq 'ADMIN') {
        my @todos = @{ $self->{tipos_inventario} };

        return {
            rol          => 'ADMIN',
            tipo_usuario => $tipo,
            departamento => $departamento,
            consulta     => \@todos,
            solicitud    => \@todos,
            es_admin     => 1,
        };
    }

    my $regla_tipo = $self->{reglas_tipo}{$tipo} || {
        consulta  => [],
        solicitud => [],
    };

    my $regla_depto = $self->{reglas_departamento}{$departamento} || {
        consulta  => [],
        solicitud => [],
    };

    my @consulta_efectiva  = $self->_interseccion($regla_tipo->{consulta},  $regla_depto->{consulta});
    my @solicitud_efectiva = $self->_interseccion($regla_tipo->{solicitud}, $regla_depto->{solicitud});

    return {
        rol          => $rol,
        tipo_usuario => $tipo,
        departamento => $departamento,
        consulta     => \@consulta_efectiva,
        solicitud    => \@solicitud_efectiva,
        es_admin     => 0,
    };
}

sub obtenerPermisosPorDatos {
    my ($self, %args) = @_;

    return $self->obtenerPermisosUsuario({
        rol          => $args{rol},
        tipo_usuario => $args{tipo_usuario},
        departamento => $args{departamento},
    });
}

# =========================================================
# Consultas de permisos
# =========================================================
sub puedeConsultarTipo {
    my ($self, $usuario, $tipo_inventario) = @_;

    my $tipo = $self->_normalizar_tipo_inventario($tipo_inventario);
    return 0 if $tipo eq '';

    my $permisos = $self->obtenerPermisosUsuario($usuario);
    return $self->_array_contiene($permisos->{consulta}, $tipo);
}

sub puedeSolicitarTipo {
    my ($self, $usuario, $tipo_inventario) = @_;

    my $tipo = $self->_normalizar_tipo_inventario($tipo_inventario);
    return 0 if $tipo eq '';

    my $permisos = $self->obtenerPermisosUsuario($usuario);
    return $self->_array_contiene($permisos->{solicitud}, $tipo);
}

sub puedeConsultarCodigo {
    my ($self, $usuario, $codigo) = @_;

    my $tipo = $self->_inferir_tipo_desde_codigo($codigo);
    return $self->puedeConsultarTipo($usuario, $tipo);
}

sub puedeSolicitarCodigo {
    my ($self, $usuario, $codigo) = @_;

    my $tipo = $self->_inferir_tipo_desde_codigo($codigo);
    return $self->puedeSolicitarTipo($usuario, $tipo);
}

sub listarTiposConsulta {
    my ($self, $usuario) = @_;
    my $permisos = $self->obtenerPermisosUsuario($usuario);
    return $permisos->{consulta};
}

sub listarTiposSolicitud {
    my ($self, $usuario) = @_;
    my $permisos = $self->obtenerPermisosUsuario($usuario);
    return $permisos->{solicitud};
}

# =========================================================
# Resúmenes y texto
# =========================================================
sub describirPermisos {
    my ($self, $usuario) = @_;

    my $permisos = $self->obtenerPermisosUsuario($usuario);

    my $tipo_usuario = $permisos->{tipo_usuario} || 'SIN_TIPO';
    my $departamento = $permisos->{departamento} || 'SIN_DEPTO';
    my $rol          = $permisos->{rol} || 'USUARIO';

    my $consulta  = @{ $permisos->{consulta} }  ? join(', ', @{ $permisos->{consulta} })  : 'Ninguno';
    my $solicitud = @{ $permisos->{solicitud} } ? join(', ', @{ $permisos->{solicitud} }) : 'Ninguno';

    return
        "Rol: $rol\n" .
        "Tipo usuario: $tipo_usuario\n" .
        "Departamento: $departamento\n" .
        "Puede consultar: $consulta\n" .
        "Puede solicitar: $solicitud";
}

sub obtenerResumenPermisos {
    my ($self, $usuario) = @_;

    my $permisos = $self->obtenerPermisosUsuario($usuario);

    return {
        rol                 => $permisos->{rol},
        tipo_usuario        => $permisos->{tipo_usuario},
        departamento        => $permisos->{departamento},
        consulta            => $permisos->{consulta},
        solicitud           => $permisos->{solicitud},
        cantidad_consulta   => scalar @{ $permisos->{consulta} },
        cantidad_solicitud  => scalar @{ $permisos->{solicitud} },
        es_admin            => $permisos->{es_admin},
    };
}

# =========================================================
# Validaciones de flujo
# =========================================================
sub validarOperacionConsulta {
    my ($self, $usuario, $tipo_inventario) = @_;

    if ($self->puedeConsultarTipo($usuario, $tipo_inventario)) {
        return (1, 'Consulta permitida');
    }

    return (0, 'Consulta no permitida para este usuario');
}

sub validarOperacionSolicitud {
    my ($self, $usuario, $tipo_inventario) = @_;

    if ($self->puedeSolicitarTipo($usuario, $tipo_inventario)) {
        return (1, 'Solicitud permitida');
    }

    return (0, 'Solicitud no permitida para este usuario');
}

# =========================================================
# Helpers internos
# =========================================================
sub _resolver_contexto_usuario {
    my ($self, $usuario) = @_;

    my $rol          = '';
    my $tipo_usuario = '';
    my $departamento = '';

    return {
        rol          => '',
        tipo_usuario => '',
        departamento => '',
    } if !defined $usuario;

    if (ref($usuario) eq 'HASH') {
        $rol          = defined $usuario->{rol}          ? uc($usuario->{rol})          : '';
        $tipo_usuario = defined $usuario->{tipo_usuario} ? uc($usuario->{tipo_usuario}) : '';
        $departamento = defined $usuario->{departamento} ? uc($usuario->{departamento}) : '';
    }
    else {
        $rol = uc($usuario->getRol()) if $usuario->can('getRol');
        $tipo_usuario = uc($usuario->getTipoUsuario()) if $usuario->can('getTipoUsuario');
        $departamento = uc($usuario->getDepartamento()) if $usuario->can('getDepartamento');
    }

    return {
        rol          => $rol,
        tipo_usuario => $tipo_usuario,
        departamento => $departamento,
    };
}

sub _normalizar_tipo_inventario {
    my ($self, $tipo) = @_;
    return '' if !defined $tipo;
    return uc($tipo);
}

sub _inferir_tipo_desde_codigo {
    my ($self, $codigo) = @_;

    return '' if !defined $codigo;

    return 'MEDICAMENTO' if $codigo =~ /^MED/i;
    return 'EQUIPO'      if $codigo =~ /^EQU/i;
    return 'SUMINISTRO'  if $codigo =~ /^SUM/i;

    return '';
}

sub _interseccion {
    my ($self, $arr1, $arr2) = @_;

    $arr1 ||= [];
    $arr2 ||= [];

    my %set2 = map { $_ => 1 } @$arr2;
    my @resultado = grep { $set2{$_} } @$arr1;

    return @resultado;
}

sub _array_contiene {
    my ($self, $arr, $valor) = @_;

    return 0 if !defined $arr || ref($arr) ne 'ARRAY';
    foreach my $item (@$arr) {
        return 1 if $item eq $valor;
    }

    return 0;
}

1;