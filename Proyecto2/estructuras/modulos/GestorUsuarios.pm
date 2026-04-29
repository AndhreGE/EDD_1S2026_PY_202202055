package estructuras::modulos::GestorUsuarios;

use strict;
use warnings;

use File::Path qw(make_path);

use estructuras::avl::ArbolAVL;
use modelos::PersonalMedico;

sub new {
    my ($class, @args) = @_;

    my %args;

    # Compatibilidad:
    # 1) new({ ... })
    # 2) new(clave => valor, ...)
    # 3) new($arbol_avl)
    if (@args == 1 && ref($args[0]) eq 'HASH') {
        %args = %{ $args[0] };
    }
    elsif (@args == 1 && ref($args[0])) {
        $args{arbol} = $args[0];
    }
    else {
        %args = @args;
    }

    my $self = {
        arbol => $args{arbol} // estructuras::avl::ArbolAVL->new(),
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Getters básicos
# =========================================================
sub getArbol {
    my ($self) = @_;
    return $self->{arbol};
}

sub getCantidadUsuarios {
    my ($self) = @_;
    return $self->{arbol}->getSize();
}

sub estaVacio {
    my ($self) = @_;
    return $self->{arbol}->estaVacio();
}

# =========================================================
# Registro de usuarios
# =========================================================
sub registrarUsuario {
    my ($self, $usuario) = @_;

    if (!defined $usuario) {
        return (0, 'No se puede registrar un usuario indefinido');
    }

    if (!$usuario->can('getClave')) {
        return (0, 'El objeto no tiene metodo getClave');
    }

    my ($ok, $msg) = $self->{arbol}->insertar($usuario);
    return ($ok, $msg);
}

sub registrarUsuarioDesdeHash {
    my ($self, $data) = @_;

    if (!defined $data || ref($data) ne 'HASH') {
        return (0, 'Debe proporcionar un HASH con los datos del usuario');
    }

    my $usuario = modelos::PersonalMedico->new(%$data);
    return $self->registrarUsuario($usuario);
}

# =========================================================
# Búsqueda
# =========================================================
sub buscarUsuario {
    my ($self, $numero_colegio) = @_;

    return undef if !defined $numero_colegio || $numero_colegio eq '';
    return $self->{arbol}->buscar($numero_colegio);
}

sub existeUsuario {
    my ($self, $numero_colegio) = @_;
    return defined $self->buscarUsuario($numero_colegio);
}

# =========================================================
# Eliminación
# =========================================================
sub eliminarUsuario {
    my ($self, $numero_colegio) = @_;

    if (!defined $numero_colegio || $numero_colegio eq '') {
        return (0, 'Debe indicar el numero de colegio');
    }

    return $self->{arbol}->eliminar($numero_colegio);
}

# =========================================================
# Login / autenticación
# =========================================================
sub autenticarUsuario {
    my ($self, $numero_colegio, $contrasena) = @_;

    if (!defined $numero_colegio || $numero_colegio eq '') {
        return (0, 'Debe indicar el numero de colegio', undef);
    }

    if (!defined $contrasena) {
        return (0, 'Debe indicar la contrasena', undef);
    }

    my $usuario = $self->buscarUsuario($numero_colegio);

    if (!$usuario) {
        return (0, 'Usuario no encontrado', undef);
    }

    if (!$usuario->can('verificarContrasena')) {
        return (0, 'El modelo de usuario no permite verificar contrasena', undef);
    }

    if (!$usuario->verificarContrasena($contrasena)) {
        return (0, 'Contrasena incorrecta', undef);
    }

    return (1, 'Autenticacion exitosa', $usuario);
}

sub cambiarContrasena {
    my ($self, $numero_colegio, $contrasena_actual, $contrasena_nueva) = @_;

    if (!defined $numero_colegio || $numero_colegio eq '') {
        return (0, 'Debe indicar el numero de colegio');
    }

    if (!defined $contrasena_actual) {
        return (0, 'Debe indicar la contrasena actual');
    }

    if (!defined $contrasena_nueva || $contrasena_nueva eq '') {
        return (0, 'La nueva contrasena no puede estar vacia');
    }

    my $usuario = $self->buscarUsuario($numero_colegio);

    if (!$usuario) {
        return (0, 'Usuario no encontrado');
    }

    if (!$usuario->verificarContrasena($contrasena_actual)) {
        return (0, 'La contrasena actual es incorrecta');
    }

    if (!$usuario->can('setContrasena')) {
        return (0, 'El modelo de usuario no permite cambiar contrasena');
    }

    $usuario->setContrasena($contrasena_nueva);
    return (1, 'Contrasena actualizada correctamente');
}

# =========================================================
# Listados y recorridos
# =========================================================
sub listarUsuarios {
    my ($self) = @_;
    return $self->{arbol}->inOrden();
}

sub listarUsuariosPreOrden {
    my ($self) = @_;
    return $self->{arbol}->preOrden();
}

sub listarUsuariosPostOrden {
    my ($self) = @_;
    return $self->{arbol}->postOrden();
}

sub imprimirUsuarios {
    my ($self) = @_;
    print $self->{arbol}->inOrdenComoTexto() . "\n";
}

sub imprimirUsuariosPreOrden {
    my ($self) = @_;
    print $self->{arbol}->preOrdenComoTexto() . "\n";
}

sub imprimirUsuariosPostOrden {
    my ($self) = @_;
    print $self->{arbol}->postOrdenComoTexto() . "\n";
}

# =========================================================
# Filtros
# =========================================================
sub filtrarPorDepartamento {
    my ($self, $departamento) = @_;

    return [] if !defined $departamento || $departamento eq '';

    my $usuarios = $self->listarUsuarios();
    my @resultado = grep {
        defined $_
        && $_->can('getDepartamento')
        && defined $_->getDepartamento()
        && $_->getDepartamento() eq $departamento
    } @$usuarios;

    return \@resultado;
}

sub filtrarPorTipoUsuario {
    my ($self, $tipo_usuario) = @_;

    return [] if !defined $tipo_usuario || $tipo_usuario eq '';

    my $usuarios = $self->listarUsuarios();
    my @resultado = grep {
        defined $_
        && $_->can('getTipoUsuario')
        && defined $_->getTipoUsuario()
        && $_->getTipoUsuario() eq $tipo_usuario
    } @$usuarios;

    return \@resultado;
}

# =========================================================
# Resumen
# =========================================================
sub obtenerResumen {
    my ($self) = @_;

    my $usuarios = $self->listarUsuarios();

    my %por_departamento;
    my %por_tipo;

    foreach my $usuario (@$usuarios) {
        next if !defined $usuario;

        my $depto = $usuario->can('getDepartamento') ? $usuario->getDepartamento() : 'SIN_DEPTO';
        my $tipo  = $usuario->can('getTipoUsuario')  ? $usuario->getTipoUsuario()  : 'SIN_TIPO';

        $depto = 'SIN_DEPTO' if !defined $depto || $depto eq '';
        $tipo  = 'SIN_TIPO'  if !defined $tipo  || $tipo eq '';

        $por_departamento{$depto}++;
        $por_tipo{$tipo}++;
    }

    return {
        total_usuarios   => scalar(@$usuarios),
        por_departamento => \%por_departamento,
        por_tipo         => \%por_tipo,
    };
}

# =========================================================
# Reporte AVL
# =========================================================
sub generarReporteUsuarios {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/avl_personal.dot';
    $ruta_png ||= 'reportesdot/avl_personal.png';

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    my $ok = $self->{arbol}->generarPNG($ruta_dot, $ruta_png);

    if ($ok) {
        return (1, 'Reporte de usuarios generado correctamente');
    }

    return (0, 'No se pudo generar el reporte de usuarios');
}

# =========================================================
# Helper
# =========================================================
sub _asegurar_directorio {
    my ($self, $ruta) = @_;
    return if !defined $ruta || $ruta eq '';

    if ($ruta =~ m{^(.*)/[^/]+$}) {
        my $dir = $1;
        make_path($dir) unless -d $dir;
    }
}

1;