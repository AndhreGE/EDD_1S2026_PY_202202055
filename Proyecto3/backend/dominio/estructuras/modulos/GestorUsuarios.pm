package estructuras::modulos::GestorUsuarios;

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);

use estructuras::avl::ArbolAVL;
use estructuras::hash::TablaHashPersonal;
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
        arbol      => $args{arbol}      // estructuras::avl::ArbolAVL->new(),
        tabla_hash => $args{tabla_hash} // estructuras::hash::TablaHashPersonal->new(),
    };

    bless $self, $class;

    # Si el AVL ya trae usuarios, sincronizamos la hash
    $self->_reconstruir_hash_desde_avl();

    return $self;
}

# =========================================================
# Getters básicos
# =========================================================
sub getArbol {
    my ($self) = @_;
    return $self->{arbol};
}

sub getTablaHash {
    my ($self) = @_;
    return $self->{tabla_hash};
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

    # 1. Insertar en AVL
    my ($ok_avl, $msg_avl) = $self->{arbol}->insertar($usuario);
    return ($ok_avl, $msg_avl) if !$ok_avl;

    # 2. Insertar en hash
    if (defined $self->{tabla_hash}) {
        my ($ok_hash, $msg_hash) = $self->{tabla_hash}->insertarUsuario($usuario);

        if (!$ok_hash) {
            # rollback para mantener consistencia
            my $id = $self->_extraer_id($usuario);
            $self->{arbol}->eliminar($id) if defined $id && $id ne '';
            return (0, "Error al insertar en tabla hash: $msg_hash");
        }
    }

    return (1, 'Usuario insertado correctamente');
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

    # Buscar antes de eliminar para saber su tipo
    my $usuario = $self->buscarUsuario($numero_colegio);
    return (0, 'Usuario no encontrado') if !defined $usuario;

    my $tipo = $self->_extraer_tipo($usuario);

    # 1. Eliminar del AVL
    my ($ok_avl, $msg_avl) = $self->{arbol}->eliminar($numero_colegio);
    return ($ok_avl, $msg_avl) if !$ok_avl;

    # 2. Eliminar de la hash
    if (defined $self->{tabla_hash}) {
        my ($ok_hash, $msg_hash) = $self->{tabla_hash}->eliminarUsuario($numero_colegio, $tipo);

        if (!$ok_hash) {
            # Para no dejar inconsistencia, reconstruimos la hash desde el AVL
            $self->_reconstruir_hash_desde_avl();
            return (0, "Usuario eliminado del AVL, pero hubo un problema al sincronizar tabla hash: $msg_hash");
        }
    }

    return (1, 'Usuario eliminado correctamente');
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

    # En Fase 3 priorizamos la hash para esta búsqueda
    if (defined $self->{tabla_hash}) {
        return $self->{tabla_hash}->obtenerUsuariosPorTipo($tipo_usuario);
    }

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
# Consultas hash
# =========================================================
sub obtenerUsuariosPorTipo {
    my ($self, $tipo_usuario) = @_;

    return [] if !defined $tipo_usuario || $tipo_usuario eq '';

    if (defined $self->{tabla_hash}) {
        return $self->{tabla_hash}->obtenerUsuariosPorTipo($tipo_usuario);
    }

    return $self->filtrarPorTipoUsuario($tipo_usuario);
}

sub cantidadUsuariosPorTipo {
    my ($self, $tipo_usuario) = @_;

    return 0 if !defined $tipo_usuario || $tipo_usuario eq '';

    if (defined $self->{tabla_hash}) {
        return $self->{tabla_hash}->cantidadPorTipo($tipo_usuario);
    }

    my $lista = $self->filtrarPorTipoUsuario($tipo_usuario);
    return scalar(@$lista);
}

sub obtenerResumenHash {
    my ($self) = @_;

    if (defined $self->{tabla_hash}) {
        return $self->{tabla_hash}->obtenerResumenHash();
    }

    return {
        total_usuarios      => $self->getCantidadUsuarios(),
        buckets_totales     => 0,
        buckets_utilizados  => 0,
        factor_carga        => '0.00',
        total_colisiones    => 0,
        por_tipo            => {},
        colisiones          => {},
    };
}

sub tablaHashComoTexto {
    my ($self) = @_;

    return 'No hay tabla hash configurada'
        if !defined $self->{tabla_hash};

    return $self->{tabla_hash}->tablaComoTexto();
}

sub sincronizarTablaHash {
    my ($self) = @_;
    return $self->_reconstruir_hash_desde_avl();
}

# =========================================================
# Resumen general
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

    my $resumen = {
        total_usuarios   => scalar(@$usuarios),
        por_departamento => \%por_departamento,
        por_tipo         => \%por_tipo,
    };

    if (defined $self->{tabla_hash}) {
        $resumen->{hash} = $self->{tabla_hash}->obtenerResumenHash();
    }

    return $resumen;
}

# =========================================================
# Reportes
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

sub generarReporteTablaHash {
    my ($self, $ruta_dot, $ruta_png) = @_;

    return (0, 'No hay tabla hash configurada')
        if !defined $self->{tabla_hash};

    $ruta_dot ||= 'reportesdot/tabla_hash_personal.dot';
    $ruta_png ||= 'reportesdot/tabla_hash_personal.png';

    $self->_asegurar_directorio($ruta_dot);
    $self->_asegurar_directorio($ruta_png);

    return $self->{tabla_hash}->generarPNG($ruta_dot, $ruta_png);
}

# =========================================================
# Helpers internos
# =========================================================
sub _reconstruir_hash_desde_avl {
    my ($self) = @_;

    return (0, 'No hay tabla hash configurada')
        if !defined $self->{tabla_hash};

    $self->{tabla_hash}->limpiar();

    my $usuarios = $self->listarUsuarios();
    return (1, 'Tabla hash sincronizada: sin usuarios') if ref($usuarios) ne 'ARRAY' || !@$usuarios;

    my ($ok, $msg, $errores) = $self->{tabla_hash}->sincronizarDesdeListaUsuarios($usuarios);

    if ($ok) {
        return (1, $msg);
    }

    return (0, $msg);
}

sub _extraer_id {
    my ($self, $usuario) = @_;

    return undef if !defined $usuario;

    if (!ref($usuario)) {
        return $usuario;
    }

    if (ref($usuario) eq 'HASH') {
        return $usuario->{numero_colegio} if defined $usuario->{numero_colegio};
    }

    foreach my $getter (qw(getNumeroColegio numero_colegio getClave clave)) {
        if ($usuario->can($getter)) {
            my $valor = eval { $usuario->$getter() };
            return $valor if defined $valor;
        }
    }

    return undef;
}

sub _extraer_tipo {
    my ($self, $usuario) = @_;

    return undef if !defined $usuario;

    if (ref($usuario) eq 'HASH') {
        return $usuario->{tipo_usuario} if defined $usuario->{tipo_usuario};
    }

    foreach my $getter (qw(getTipoUsuario tipo_usuario)) {
        if ($usuario->can($getter)) {
            my $valor = eval { $usuario->$getter() };
            return $valor if defined $valor;
        }
    }

    return undef;
}

sub _asegurar_directorio {
    my ($self, $ruta) = @_;
    return if !defined $ruta || $ruta eq '';

    if ($ruta =~ m{^(.*)/[^/]+$}) {
        my $dir = $1;
        make_path($dir) unless -d $dir;
    }
}

1;