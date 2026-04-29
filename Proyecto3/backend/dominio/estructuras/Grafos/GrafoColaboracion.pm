package estructuras::Grafos::GrafoColaboracion;

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);

sub new {
    my ($class) = @_;

    my $self = {
        nodos      => {},   # id => metadata del usuario
        adyacencia => {},   # id => { vecino_id => 1, ... }
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Operaciones básicas del grafo
# =========================================================

sub agregarUsuario {
    my ($self, $usuario, %extra) = @_;

    my ($id, $metadata) = $self->_normalizar_usuario($usuario, %extra);
    return (0, 'No se pudo obtener el numero de colegio del usuario')
        if !defined $id || $id eq '';

    if (!exists $self->{nodos}{$id}) {
        $self->{nodos}{$id} = $metadata;
        $self->{adyacencia}{$id} ||= {};
        return (1, "Usuario $id agregado correctamente al grafo");
    }

    # Si ya existe, actualizamos metadata por si cambió nombre/depto/tipo
    $self->{nodos}{$id} = {
        %{ $self->{nodos}{$id} },
        %$metadata,
    };
    $self->{adyacencia}{$id} ||= {};

    return (1, "Usuario $id actualizado correctamente en el grafo");
}

sub actualizarUsuario {
    my ($self, $usuario, %extra) = @_;
    return $self->agregarUsuario($usuario, %extra);
}

sub eliminarUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar el numero de colegio del usuario')
        if !defined $id || $id eq '';
    return (0, "El usuario $id no existe en el grafo")
        if !exists $self->{nodos}{$id};

    # Eliminar las aristas que apuntan a este usuario
    foreach my $vecino (keys %{ $self->{adyacencia}{$id} || {} }) {
        delete $self->{adyacencia}{$vecino}{$id}
            if exists $self->{adyacencia}{$vecino};
    }

    delete $self->{adyacencia}{$id};
    delete $self->{nodos}{$id};

    return (1, "Usuario $id eliminado correctamente del grafo");
}

sub existeUsuario {
    my ($self, $usuario_o_id) = @_;
    my $id = $self->_extraer_id($usuario_o_id);
    return 0 if !defined $id || $id eq '';
    return exists $self->{nodos}{$id} ? 1 : 0;
}

sub cantidadUsuarios {
    my ($self) = @_;
    return scalar keys %{ $self->{nodos} };
}

sub cantidadColaboraciones {
    my ($self) = @_;

    my $total = 0;
    foreach my $id (keys %{ $self->{adyacencia} }) {
        $total += scalar keys %{ $self->{adyacencia}{$id} };
    }

    # Como es no dirigido, cada arista se cuenta 2 veces
    return int($total / 2);
}

# =========================================================
# Aristas / colaboraciones
# =========================================================

sub agregarColaboracion {
    my ($self, $usuario_a, $usuario_b) = @_;

    my $id_a = $self->_extraer_id($usuario_a);
    my $id_b = $self->_extraer_id($usuario_b);

    return (0, 'Debe indicar ambos usuarios')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';
    return (0, 'No se puede crear una colaboracion consigo mismo')
        if $id_a eq $id_b;
    return (0, "El usuario $id_a no existe en el grafo")
        if !$self->existeUsuario($id_a);
    return (0, "El usuario $id_b no existe en el grafo")
        if !$self->existeUsuario($id_b);

    if ($self->sonColaboradores($id_a, $id_b)) {
        return (0, "La colaboracion entre $id_a y $id_b ya existe");
    }

    $self->{adyacencia}{$id_a}{$id_b} = 1;
    $self->{adyacencia}{$id_b}{$id_a} = 1;

    return (1, "Colaboracion entre $id_a y $id_b agregada correctamente");
}

sub eliminarColaboracion {
    my ($self, $usuario_a, $usuario_b) = @_;

    my $id_a = $self->_extraer_id($usuario_a);
    my $id_b = $self->_extraer_id($usuario_b);

    return (0, 'Debe indicar ambos usuarios')
        if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';
    return (0, "La colaboracion entre $id_a y $id_b no existe")
        if !$self->sonColaboradores($id_a, $id_b);

    delete $self->{adyacencia}{$id_a}{$id_b};
    delete $self->{adyacencia}{$id_b}{$id_a};

    return (1, "Colaboracion entre $id_a y $id_b eliminada correctamente");
}

sub sonColaboradores {
    my ($self, $usuario_a, $usuario_b) = @_;

    my $id_a = $self->_extraer_id($usuario_a);
    my $id_b = $self->_extraer_id($usuario_b);

    return 0 if !defined $id_a || !defined $id_b || $id_a eq '' || $id_b eq '';
    return 0 if !exists $self->{adyacencia}{$id_a};

    return exists $self->{adyacencia}{$id_a}{$id_b} ? 1 : 0;
}

sub obtenerIdsColaboradores {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return [] if !defined $id || $id eq '';
    return [] if !exists $self->{adyacencia}{$id};

    my @ids = sort keys %{ $self->{adyacencia}{$id} };
    return \@ids;
}

sub obtenerColaboradores {
    my ($self, $usuario_o_id) = @_;

    my $ids = $self->obtenerIdsColaboradores($usuario_o_id);
    my @colaboradores = map { $self->_usuario_desde_id($_) } @$ids;

    return \@colaboradores;
}

sub gradoUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return 0 if !defined $id || $id eq '';
    return 0 if !exists $self->{adyacencia}{$id};

    return scalar keys %{ $self->{adyacencia}{$id} };
}

sub tieneColaboradores {
    my ($self, $usuario_o_id) = @_;
    return $self->gradoUsuario($usuario_o_id) > 0 ? 1 : 0;
}

sub obtenerUsuariosAislados {
    my ($self) = @_;

    my @aislados;
    foreach my $id (sort keys %{ $self->{nodos} }) {
        if ($self->gradoUsuario($id) == 0) {
            push @aislados, $self->_usuario_desde_id($id);
        }
    }

    return \@aislados;
}

sub obtenerUsuariosSinDepartamento {
    my ($self) = @_;

    my @sin_dep;
    foreach my $id (sort keys %{ $self->{nodos} }) {
        my $dep = $self->{nodos}{$id}{departamento};
        if (!defined $dep || $dep eq '' || $dep eq 'SIN-DEP') {
            push @sin_dep, $self->_usuario_desde_id($id);
        }
    }

    return \@sin_dep;
}

# =========================================================
# Sugerencias de colaboración
# BFS de dos saltos / colaboradores en común
# =========================================================

sub obtenerSugerenciasColaboracion {
    my ($self, $usuario_o_id, $minimo_comunes) = @_;

    $minimo_comunes = 2 if !defined $minimo_comunes;

    my $id = $self->_extraer_id($usuario_o_id);
    return [] if !defined $id || $id eq '';
    return [] if !$self->existeUsuario($id);

    my %directos = map { $_ => 1 } @{ $self->obtenerIdsColaboradores($id) };
    my %contador;
    my %mutuos;

    foreach my $colaborador (keys %directos) {
        foreach my $candidato (keys %{ $self->{adyacencia}{$colaborador} || {} }) {
            next if $candidato eq $id;
            next if exists $directos{$candidato};

            $contador{$candidato}++;
            push @{ $mutuos{$candidato} }, $colaborador;
        }
    }

    my @sugerencias;
    foreach my $candidato (keys %contador) {
        next if $contador{$candidato} < $minimo_comunes;

        push @sugerencias, {
            %{ $self->{nodos}{$candidato} },
            colaboradores_en_comun     => $contador{$candidato},
            ids_colaboradores_en_comun => [ sort @{ $mutuos{$candidato} || [] } ],
        };
    }

    @sugerencias = sort {
           $b->{colaboradores_en_comun} <=> $a->{colaboradores_en_comun}
        || ($a->{nombre_completo} // '') cmp ($b->{nombre_completo} // '')
        || ($a->{numero_colegio} // '') cmp ($b->{numero_colegio} // '')
    } @sugerencias;

    return \@sugerencias;
}

# =========================================================
# Carga / sincronización
# =========================================================

sub sincronizarDesdeListaUsuarios {
    my ($self, $lista_usuarios) = @_;

    return (0, 'Debe proporcionar una lista de usuarios')
        if ref($lista_usuarios) ne 'ARRAY';

    my $insertados = 0;

    foreach my $usuario (@$lista_usuarios) {
        my ($ok, $msg) = $self->agregarUsuario($usuario);
        $insertados++ if $ok;
    }

    return (1, "Sincronizacion completada: $insertados usuarios procesados");
}

sub cargarRelacionesIniciales {
    my ($self, $relaciones) = @_;

    return {
        ok                => 0,
        mensaje           => 'Debe proporcionar un arreglo de relaciones',
        relaciones_leidas => 0,
        activas_agregadas => 0,
        pendientes        => 0,
        rechazadas        => 0,
        errores           => [],
    } if ref($relaciones) ne 'ARRAY';

    my $resultado = {
        ok                => 1,
        mensaje           => 'Carga de relaciones completada',
        relaciones_leidas => scalar(@$relaciones),
        activas_agregadas => 0,
        pendientes        => 0,
        rechazadas        => 0,
        errores           => [],
    };

    foreach my $rel (@$relaciones) {
        my $solicitante = $rel->{solicitante} // '';
        my $receptor    = $rel->{receptor}    // '';
        my $estado      = uc($rel->{estado} // '');

        if ($solicitante eq '' || $receptor eq '' || $estado eq '') {
            push @{ $resultado->{errores} }, 'Relacion invalida: faltan campos requeridos';
            next;
        }

        if ($estado eq 'ACTIVA') {
            my ($ok, $msg) = $self->agregarColaboracion($solicitante, $receptor);
            if ($ok) {
                $resultado->{activas_agregadas}++;
            } else {
                push @{ $resultado->{errores} }, $msg;
            }
        }
        elsif ($estado eq 'PENDIENTE') {
            $resultado->{pendientes}++;
        }
        elsif ($estado eq 'RECHAZADA') {
            $resultado->{rechazadas}++;
        }
        else {
            push @{ $resultado->{errores} }, "Estado no reconocido: $estado";
        }
    }

    return $resultado;
}

# =========================================================
# Lista de adyacencia
# =========================================================

sub obtenerListaAdyacencia {
    my ($self) = @_;

    my %lista;

    foreach my $id (sort keys %{ $self->{nodos} }) {
        $lista{$id} = [ sort keys %{ $self->{adyacencia}{$id} || {} } ];
    }

    return \%lista;
}

sub listaAdyacenciaComoTexto {
    my ($self) = @_;

    my $lista = $self->obtenerListaAdyacencia();
    my @lineas;

    foreach my $id (sort keys %$lista) {
        my $vecinos = @{ $lista->{$id} } ? join(', ', @{ $lista->{$id} }) : 'Sin colaboradores';
        push @lineas, "$id -> [$vecinos]";
    }

    return join("\n", @lineas);
}

# =========================================================
# Reportes Graphviz
# =========================================================

sub generarDOTRed {
    my ($self, $ruta_dot) = @_;

    $ruta_dot ||= 'reportesdot/grafo_colaboracion.dot';
    $self->_asegurar_directorio($ruta_dot);

    open(my $fh, '>', $ruta_dot) or return (0, "No se pudo crear $ruta_dot");

    print $fh "graph GrafoColaboracion {\n";
    print $fh "    layout=neato;\n";
    print $fh "    overlap=false;\n";
    print $fh "    splines=true;\n";
    print $fh "    node [shape=ellipse, style=filled, fontname=\"Helvetica\"];\n";
    print $fh "    edge [color=\"gray40\"];\n";

    foreach my $id (sort keys %{ $self->{nodos} }) {
        my $nodo = $self->{nodos}{$id};

        my $nombre = $self->_escapar($nodo->{nombre_completo} // $id);
        my $dep    = $self->_escapar($nodo->{departamento} // 'SIN-DEP');
        my $tipo   = $self->_escapar($nodo->{tipo_usuario} // 'SIN-TIPO');

        my $label = "$id\\n$nombre\\n$dep\\n$tipo";
        my $fill  = $self->_color_departamento($nodo->{departamento});

        my $id_seguro = $self->_id_seguro($id);
        print $fh qq{    $id_seguro [label="$label", fillcolor="$fill"];\n};
    }

    my %vistos;
    foreach my $a (sort keys %{ $self->{adyacencia} }) {
        foreach my $b (sort keys %{ $self->{adyacencia}{$a} }) {
            my $clave = join('|', sort ($a, $b));
            next if $vistos{$clave};

            my $a_seg = $self->_id_seguro($a);
            my $b_seg = $self->_id_seguro($b);

            print $fh qq{    $a_seg -- $b_seg;\n};
            $vistos{$clave} = 1;
        }
    }

    print $fh "}\n";
    close($fh);

    return (1, "Archivo DOT del grafo generado correctamente en $ruta_dot");
}

sub generarPNGRed {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/grafo_colaboracion.dot';
    $ruta_png ||= 'reportesdot/grafo_colaboracion.png';

    my ($ok, $msg) = $self->generarDOTRed($ruta_dot);
    return (0, $msg) if !$ok;

    $self->_asegurar_directorio($ruta_png);

    my $resultado = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png);

    if ($resultado == 0) {
        return (1, "Reporte del grafo generado correctamente en $ruta_png");
    }

    return (0, 'Error al generar el PNG del grafo con Graphviz');
}

sub generarDOTListaAdyacencia {
    my ($self, $ruta_dot) = @_;

    $ruta_dot ||= 'reportesdot/lista_adyacencia.dot';
    $self->_asegurar_directorio($ruta_dot);

    open(my $fh, '>', $ruta_dot) or return (0, "No se pudo crear $ruta_dot");

    print $fh "digraph ListaAdyacencia {\n";
    print $fh "    rankdir=TB;\n";
    print $fh "    node [shape=record, style=filled, fillcolor=\"lightyellow\", fontname=\"Helvetica\"];\n";

    my $lista = $self->obtenerListaAdyacencia();

    if (!keys %$lista) {
        print $fh qq{    vacio [label="Grafo vacio"];\n};
    }
    else {
        my $i = 0;
        foreach my $id (sort keys %$lista) {
            my $vecinos = @{ $lista->{$id} } ? join(', ', @{ $lista->{$id} }) : 'Sin colaboradores';

            my $label_id      = $self->_escapar($id);
            my $label_vecinos = $self->_escapar($vecinos);

            print $fh qq{    nodo_$i [label="{ $label_id | $label_vecinos }"];\n};

            if ($i > 0) {
                my $prev = $i - 1;
                print $fh qq{    nodo_$prev -> nodo_$i [style=invis];\n};
            }

            $i++;
        }
    }

    print $fh "}\n";
    close($fh);

    return (1, "Archivo DOT de la lista de adyacencia generado correctamente en $ruta_dot");
}

sub generarPNGListaAdyacencia {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $ruta_dot ||= 'reportesdot/lista_adyacencia.dot';
    $ruta_png ||= 'reportesdot/lista_adyacencia.png';

    my ($ok, $msg) = $self->generarDOTListaAdyacencia($ruta_dot);
    return (0, $msg) if !$ok;

    $self->_asegurar_directorio($ruta_png);

    my $resultado = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png);

    if ($resultado == 0) {
        return (1, "Reporte de lista de adyacencia generado correctamente en $ruta_png");
    }

    return (0, 'Error al generar el PNG de la lista de adyacencia con Graphviz');
}

# =========================================================
# Helpers internos
# =========================================================

sub _normalizar_usuario {
    my ($self, $usuario, %extra) = @_;

    my $id = $self->_extraer_id($usuario);

    my $metadata = {
        numero_colegio => $id,
        nombre_completo => $self->_obtener_campo($usuario, 'nombre_completo') // ($extra{nombre_completo} // $id),
        departamento    => $self->_obtener_campo($usuario, 'departamento')    // ($extra{departamento} // 'SIN-DEP'),
        tipo_usuario    => $self->_obtener_campo($usuario, 'tipo_usuario')    // ($extra{tipo_usuario} // 'SIN-TIPO'),
        especialidad    => $self->_obtener_campo($usuario, 'especialidad')    // ($extra{especialidad} // ''),
        usuario_obj     => ref($usuario) ? $usuario : undef,
    };

    return ($id, $metadata);
}

sub _usuario_desde_id {
    my ($self, $id) = @_;

    return undef if !defined $id;
    return undef if !exists $self->{nodos}{$id};

    my $nodo = $self->{nodos}{$id};

    # Si existe el objeto original, devolvemos ese
    if (defined $nodo->{usuario_obj}) {
        return $nodo->{usuario_obj};
    }

    # Si no existe, devolvemos una copia del hash sin usuario_obj
    my %copia = %$nodo;
    delete $copia{usuario_obj};
    return \%copia;
}

sub _extraer_id {
    my ($self, $usuario) = @_;

    return undef if !defined $usuario;

    if (!ref($usuario)) {
        return $usuario;
    }

    if (ref($usuario) eq 'HASH') {
        return $usuario->{numero_colegio} if defined $usuario->{numero_colegio};
        return $usuario->{codigo}         if defined $usuario->{codigo};
    }

    foreach my $getter (qw(getNumeroColegio numero_colegio getCodigo codigo)) {
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

sub _camelizar {
    my ($self, $texto) = @_;
    $texto //= '';
    $texto =~ s/(^|_)([a-z])/\U$2/g;
    return $texto;
}

sub _color_departamento {
    my ($self, $dep) = @_;

    return 'gray80'         if !defined $dep || $dep eq '' || $dep eq 'SIN-DEP';
    return 'lightblue'      if $dep eq 'DEP-MED';
    return 'lightcoral'     if $dep eq 'DEP-CIR';
    return 'lightgoldenrod' if $dep eq 'DEP-FAR';
    return 'lightgreen'     if $dep eq 'DEP-LAB';
    return 'plum'           if $dep eq 'DEP-ADM';

    return 'gray80';
}

sub _id_seguro {
    my ($self, $texto) = @_;
    $texto //= 'nodo';
    $texto =~ s/[^A-Za-z0-9_]/_/g;
    return 'n_' . $texto;
}

sub _escapar {
    my ($self, $texto) = @_;
    $texto = '' if !defined $texto;
    $texto =~ s/\\/\\\\/g;
    $texto =~ s/"/\\"/g;
    $texto =~ s/\|/\\|/g;
    $texto =~ s/\{/\\{/g;
    $texto =~ s/\}/\\}/g;
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