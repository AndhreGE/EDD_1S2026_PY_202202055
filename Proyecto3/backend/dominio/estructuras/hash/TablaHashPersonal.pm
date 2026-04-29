package estructuras::hash::TablaHashPersonal;

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);

sub new {
    my ($class, %args) = @_;

    my $tipos = $args{tipos_validos} || [qw(TIPO-01 TIPO-02 TIPO-03 TIPO-04 TIPO-05)];

    my $self = {
        tipos_validos => [@$tipos],
        buckets       => {},   # tipo => [ usuarios... ]
        indice        => {},   # tipo => { numero_colegio => usuario }
        colisiones    => {},   # tipo => entero
    };

    foreach my $tipo (@$tipos) {
        $self->{buckets}{$tipo}    = [];
        $self->{indice}{$tipo}     = {};
        $self->{colisiones}{$tipo} = 0;
    }

    bless $self, $class;
    return $self;
}

# =========================================================
# Operaciones básicas
# =========================================================

sub insertarUsuario {
    my ($self, $usuario) = @_;

    my $id   = $self->_extraer_id($usuario);
    my $tipo = $self->_extraer_tipo($usuario);

    return (0, 'No se pudo obtener el numero de colegio del usuario')
        if !defined $id || $id eq '';

    return (0, 'No se pudo obtener el tipo del usuario')
        if !defined $tipo || $tipo eq '';

    $self->_asegurar_tipo($tipo);

    if (exists $self->{indice}{$tipo}{$id}) {
        return (0, "Ya existe un usuario con numero de colegio $id en el bucket $tipo");
    }

    if (@{ $self->{buckets}{$tipo} } > 0) {
        $self->{colisiones}{$tipo}++;
    }

    push @{ $self->{buckets}{$tipo} }, $usuario;
    $self->{indice}{$tipo}{$id} = $usuario;

    return (1, "Usuario $id insertado correctamente en el bucket $tipo");
}

sub actualizarUsuario {
    my ($self, $usuario) = @_;

    my $id   = $self->_extraer_id($usuario);
    my $tipo = $self->_extraer_tipo($usuario);

    return (0, 'No se pudo obtener el numero de colegio del usuario')
        if !defined $id || $id eq '';

    return (0, 'No se pudo obtener el tipo del usuario')
        if !defined $tipo || $tipo eq '';

    $self->_asegurar_tipo($tipo);

    if (exists $self->{indice}{$tipo}{$id}) {
        $self->{indice}{$tipo}{$id} = $usuario;

        for (my $i = 0; $i < @{ $self->{buckets}{$tipo} }; $i++) {
            my $actual_id = $self->_extraer_id($self->{buckets}{$tipo}[$i]);
            if (defined $actual_id && $actual_id eq $id) {
                $self->{buckets}{$tipo}[$i] = $usuario;
                last;
            }
        }

        return (1, "Usuario $id actualizado correctamente en el bucket $tipo");
    }

    return $self->insertarUsuario($usuario);
}

sub eliminarUsuario {
    my ($self, $usuario_o_id, $tipo_opcional) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar un usuario válido')
        if !defined $id || $id eq '';

    if (defined $tipo_opcional && $tipo_opcional ne '') {
        $self->_asegurar_tipo($tipo_opcional);
        return $self->_eliminar_usuario_en_tipo($id, $tipo_opcional);
    }

    foreach my $tipo (@{ $self->{tipos_validos} }) {
        if (exists $self->{indice}{$tipo}{$id}) {
            return $self->_eliminar_usuario_en_tipo($id, $tipo);
        }
    }

    return (0, "No existe el usuario $id en la tabla hash");
}

sub buscarUsuarioEnTipo {
    my ($self, $tipo, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return undef if !defined $id || $id eq '';
    return undef if !defined $tipo || $tipo eq '';

    $self->_asegurar_tipo($tipo);

    return $self->{indice}{$tipo}{$id};
}

sub existeUsuarioEnTipo {
    my ($self, $tipo, $usuario_o_id) = @_;
    return defined $self->buscarUsuarioEnTipo($tipo, $usuario_o_id) ? 1 : 0;
}

# =========================================================
# Consultas por tipo
# =========================================================

sub obtenerUsuariosPorTipo {
    my ($self, $tipo) = @_;

    return [] if !defined $tipo || $tipo eq '';
    $self->_asegurar_tipo($tipo);

    my @lista = sort {
        ($self->_extraer_id($a) // '') cmp ($self->_extraer_id($b) // '')
    } @{ $self->{buckets}{$tipo} };

    return \@lista;
}

sub cantidadPorTipo {
    my ($self, $tipo) = @_;

    return 0 if !defined $tipo || $tipo eq '';
    $self->_asegurar_tipo($tipo);

    return scalar @{ $self->{buckets}{$tipo} };
}

sub obtenerTiposValidos {
    my ($self) = @_;
    return [ @{ $self->{tipos_validos} } ];
}

sub cantidadTotalUsuarios {
    my ($self) = @_;

    my $total = 0;
    foreach my $tipo (@{ $self->{tipos_validos} }) {
        $total += scalar @{ $self->{buckets}{$tipo} };
    }

    return $total;
}

sub bucketsUtilizados {
    my ($self) = @_;

    my $usados = 0;
    foreach my $tipo (@{ $self->{tipos_validos} }) {
        $usados++ if @{ $self->{buckets}{$tipo} } > 0;
    }

    return $usados;
}

sub cantidadBuckets {
    my ($self) = @_;
    return scalar @{ $self->{tipos_validos} };
}

sub obtenerResumenHash {
    my ($self) = @_;

    my %por_tipo;
    my %colisiones;
    my $total_colisiones = 0;

    foreach my $tipo (@{ $self->{tipos_validos} }) {
        $por_tipo{$tipo}   = scalar @{ $self->{buckets}{$tipo} };
        $colisiones{$tipo} = $self->{colisiones}{$tipo} || 0;
        $total_colisiones += $colisiones{$tipo};
    }

    my $buckets = $self->cantidadBuckets();
    my $total   = $self->cantidadTotalUsuarios();

    my $factor_carga = $buckets > 0 ? sprintf('%.2f', $total / $buckets) : '0.00';

    return {
        total_usuarios     => $total,
        buckets_totales    => $buckets,
        buckets_utilizados => $self->bucketsUtilizados(),
        factor_carga       => $factor_carga,
        total_colisiones   => $total_colisiones,
        por_tipo           => \%por_tipo,
        colisiones         => \%colisiones,
    };
}

sub tablaComoTexto {
    my ($self) = @_;

    my @lineas;

    foreach my $tipo (@{ $self->{tipos_validos} }) {
        my $usuarios = $self->obtenerUsuariosPorTipo($tipo);

        push @lineas, "[$tipo]";

        if (!@$usuarios) {
            push @lineas, "  (vacio)";
            next;
        }

        foreach my $u (@$usuarios) {
            push @lineas, '  - ' . $self->_usuario_a_texto($u);
        }
    }

    return join("\n", @lineas);
}

# =========================================================
# Sincronización masiva
# =========================================================

sub sincronizarDesdeListaUsuarios {
    my ($self, $lista_usuarios) = @_;

    return (0, 'Debe proporcionar una lista de usuarios')
        if ref($lista_usuarios) ne 'ARRAY';

    my $procesados = 0;
    my @errores;

    foreach my $usuario (@$lista_usuarios) {
        my ($ok, $msg) = $self->insertarUsuario($usuario);
        if ($ok) {
            $procesados++;
        } else {
            push @errores, $msg;
        }
    }

    my $mensaje = "Sincronizacion completada: $procesados usuarios insertados";
    if (@errores) {
        $mensaje .= ' | errores: ' . scalar(@errores);
    }

    return (1, $mensaje, \@errores);
}

sub limpiar {
    my ($self) = @_;

    foreach my $tipo (@{ $self->{tipos_validos} }) {
        $self->{buckets}{$tipo}    = [];
        $self->{indice}{$tipo}     = {};
        $self->{colisiones}{$tipo} = 0;
    }

    return (1, 'Tabla hash limpiada correctamente');
}

# =========================================================
# Reportes Graphviz
# =========================================================

sub generarDOT {
    my ($self, $ruta_dot) = @_;

    $ruta_dot ||= 'reportesdot/tabla_hash_personal.dot';
    $self->_asegurar_directorio($ruta_dot);

    open(my $fh, '>', $ruta_dot) or return (0, "No se pudo crear $ruta_dot");

    print $fh "digraph TablaHashPersonal {\n";
    print $fh "    graph [charset=\"UTF-8\", rankdir=LR];\n";
    print $fh "    node [fontname=\"DejaVu Sans\"];\n";
    print $fh "    edge [fontname=\"DejaVu Sans\"];\n";

    # Nodo principal de la tabla hash como record, con puertos por bucket
    my @partes;
    for (my $i = 0; $i < @{ $self->{tipos_validos} }; $i++) {
        my $tipo = $self->{tipos_validos}[$i];
        push @partes, "<b$i> $tipo";
    }
    my $label_tabla = "{Tabla Hash Personal|" . join('|', @partes) . "}";

    print $fh qq{    tabla [shape=record, style=filled, fillcolor="lightcyan", label="$label_tabla"];\n};

    # Buckets como cajas normales para evitar problemas con labels record
    for (my $i = 0; $i < @{ $self->{tipos_validos} }; $i++) {
        my $tipo = $self->{tipos_validos}[$i];
        my $usuarios = $self->obtenerUsuariosPorTipo($tipo);

        if (!@$usuarios) {
            my $label = $self->_escapar("$tipo\n(vacio)");
            print $fh qq{    bucket_$i [shape=box, style=filled, fillcolor="gray95", label="$label"];\n};
            print $fh qq{    tabla:b$i -> bucket_$i;\n};
            next;
        }

        for (my $j = 0; $j < @$usuarios; $j++) {
            my $u = $usuarios->[$j];
            my $id   = $self->_escapar($self->_extraer_id($u) // 'SIN-ID');
            my $nom  = $self->_escapar($self->_obtener_campo($u, 'nombre_completo') // 'Sin nombre');
            my $dep  = $self->_escapar($self->_obtener_campo($u, 'departamento') // 'SIN-DEP');

            my $label = "$id\\n$nom\\n$dep";
            print $fh qq{    bucket_${i}_$j [shape=box, style=filled, fillcolor="lightyellow", label="$label"];\n};

            if ($j == 0) {
                print $fh qq{    tabla:b$i -> bucket_${i}_$j;\n};
            } else {
                my $prev = $j - 1;
                print $fh qq{    bucket_${i}_$prev -> bucket_${i}_$j;\n};
            }
        }
    }

    print $fh "}\n";
    close($fh);

    return (1, "Archivo DOT de la tabla hash generado correctamente en $ruta_dot");
}

sub generarPNG {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/tabla_hash_personal.dot';
    $ruta_png ||= 'reportesdot/tabla_hash_personal.png';

    my ($ok, $msg) = $self->generarDOT($ruta_dot);
    return (0, $msg) if !$ok;

    $self->_asegurar_directorio($ruta_png);

    my $resultado = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png);

    if ($resultado == 0) {
        return (1, "Reporte de tabla hash generado correctamente en $ruta_png");
    }

    return (0, 'Error al generar el PNG de la tabla hash con Graphviz');
}

# =========================================================
# Helpers internos
# =========================================================

sub _eliminar_usuario_en_tipo {
    my ($self, $id, $tipo) = @_;

    return (0, "No existe el usuario $id en el bucket $tipo")
        if !exists $self->{indice}{$tipo}{$id};

    delete $self->{indice}{$tipo}{$id};

    my @nueva_lista = grep {
        my $actual_id = $self->_extraer_id($_);
        !(defined $actual_id && $actual_id eq $id)
    } @{ $self->{buckets}{$tipo} };

    $self->{buckets}{$tipo} = \@nueva_lista;

    return (1, "Usuario $id eliminado correctamente del bucket $tipo");
}

sub _asegurar_tipo {
    my ($self, $tipo) = @_;

    if (!exists $self->{buckets}{$tipo}) {
        push @{ $self->{tipos_validos} }, $tipo;
        $self->{buckets}{$tipo}    = [];
        $self->{indice}{$tipo}     = {};
        $self->{colisiones}{$tipo} = 0;
    }
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

    foreach my $getter (qw(getNumeroColegio numero_colegio getCodigo codigo)) {
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

sub _obtener_campo {
    my ($self, $obj, $campo) = @_;

    return undef if !defined $obj || !ref($obj);

    if (ref($obj) eq 'HASH') {
        return $obj->{$campo} if exists $obj->{$campo};
    }

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

    return undef;
}

sub _usuario_a_texto {
    my ($self, $usuario) = @_;

    return '' if !defined $usuario;

    return $usuario->toString() if ref($usuario) && $usuario->can('toString');

    my $id    = $self->_extraer_id($usuario) // 'SIN-ID';
    my $nom   = $self->_obtener_campo($usuario, 'nombre_completo') // 'Sin nombre';
    my $tipo  = $self->_extraer_tipo($usuario) // 'SIN-TIPO';
    my $depto = $self->_obtener_campo($usuario, 'departamento') // 'SIN-DEP';

    return "[$id] $nom | $tipo | $depto";
}

sub _camelizar {
    my ($self, $texto) = @_;
    $texto //= '';
    $texto =~ s/(^|_)([a-z])/\U$2/g;
    return $texto;
}

sub _escapar {
    my ($self, $texto) = @_;
    $texto = '' if !defined $texto;
    $texto =~ s/\\/\\\\/g;
    $texto =~ s/"/\\"/g;
    return $texto;
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