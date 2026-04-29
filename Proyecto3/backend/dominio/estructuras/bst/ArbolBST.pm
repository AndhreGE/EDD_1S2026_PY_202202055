package estructuras::bst::ArbolBST;

use strict;
use warnings;
use estructuras::bst::NodoBST;

sub new {
    my ($class) = @_;

    my $self = {
        raiz => undef,
        size => 0,
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters básicos
# =========================
sub getRaiz {
    my ($self) = @_;
    return $self->{raiz};
}

sub estaVacio {
    my ($self) = @_;
    return !defined $self->{raiz};
}

sub getSize {
    my ($self) = @_;
    return $self->{size};
}

# =========================
# Inserción
# =========================
sub insertar {
    my ($self, $equipo) = @_;

    if (!defined $equipo) {
        return (0, "No se puede insertar un equipo indefinido");
    }

    if (!$equipo->can('getClave')) {
        return (0, "El objeto no tiene metodo getClave");
    }

    if ($equipo->can('esValido') && !$equipo->esValido()) {
        my @errores = $equipo->validar();
        return (0, "Equipo invalido: " . join(", ", @errores));
    }

    my ($nueva_raiz, $insertado, $mensaje) = $self->_insertar_recursivo($self->{raiz}, $equipo);
    $self->{raiz} = $nueva_raiz;

    if ($insertado) {
        $self->{size}++;
    }

    return ($insertado, $mensaje);
}

sub _insertar_recursivo {
    my ($self, $nodo_actual, $equipo) = @_;

    if (!defined $nodo_actual) {
        my $nuevo_nodo = estructuras::bst::NodoBST->new($equipo);
        return ($nuevo_nodo, 1, "Equipo insertado correctamente");
    }

    my $clave_nueva  = $equipo->getClave();
    my $clave_actual = $nodo_actual->getClave();

    if ($clave_nueva lt $clave_actual) {
        my ($nuevo_izq, $insertado, $mensaje) =
            $self->_insertar_recursivo($nodo_actual->getIzquierdo(), $equipo);

        $nodo_actual->setIzquierdo($nuevo_izq);
        return ($nodo_actual, $insertado, $mensaje);
    }
    elsif ($clave_nueva gt $clave_actual) {
        my ($nuevo_der, $insertado, $mensaje) =
            $self->_insertar_recursivo($nodo_actual->getDerecho(), $equipo);

        $nodo_actual->setDerecho($nuevo_der);
        return ($nodo_actual, $insertado, $mensaje);
    }
    else {
        return ($nodo_actual, 0, "Ya existe un equipo con el codigo $clave_nueva");
    }
}

# =========================
# Búsqueda
# =========================
sub buscar {
    my ($self, $codigo) = @_;
    my $nodo = $self->_buscar_nodo($self->{raiz}, $codigo);
    return defined $nodo ? $nodo->getEquipo() : undef;
}

sub _buscar_nodo {
    my ($self, $nodo_actual, $codigo) = @_;

    return undef if !defined $nodo_actual;

    my $clave_actual = $nodo_actual->getClave();

    if ($codigo eq $clave_actual) {
        return $nodo_actual;
    }
    elsif ($codigo lt $clave_actual) {
        return $self->_buscar_nodo($nodo_actual->getIzquierdo(), $codigo);
    }
    else {
        return $self->_buscar_nodo($nodo_actual->getDerecho(), $codigo);
    }
}

sub existe {
    my ($self, $codigo) = @_;
    return defined $self->buscar($codigo);
}

# =========================
# Recorridos
# =========================
sub inOrden {
    my ($self) = @_;
    my @resultado;
    $self->_in_orden_recursivo($self->{raiz}, \@resultado);
    return \@resultado;
}

sub _in_orden_recursivo {
    my ($self, $nodo, $resultado) = @_;
    return if !defined $nodo;

    $self->_in_orden_recursivo($nodo->getIzquierdo(), $resultado);
    push @$resultado, $nodo->getEquipo();
    $self->_in_orden_recursivo($nodo->getDerecho(), $resultado);
}

sub preOrden {
    my ($self) = @_;
    my @resultado;
    $self->_pre_orden_recursivo($self->{raiz}, \@resultado);
    return \@resultado;
}

sub _pre_orden_recursivo {
    my ($self, $nodo, $resultado) = @_;
    return if !defined $nodo;

    push @$resultado, $nodo->getEquipo();
    $self->_pre_orden_recursivo($nodo->getIzquierdo(), $resultado);
    $self->_pre_orden_recursivo($nodo->getDerecho(), $resultado);
}

sub postOrden {
    my ($self) = @_;
    my @resultado;
    $self->_post_orden_recursivo($self->{raiz}, \@resultado);
    return \@resultado;
}

sub _post_orden_recursivo {
    my ($self, $nodo, $resultado) = @_;
    return if !defined $nodo;

    $self->_post_orden_recursivo($nodo->getIzquierdo(), $resultado);
    $self->_post_orden_recursivo($nodo->getDerecho(), $resultado);
    push @$resultado, $nodo->getEquipo();
}

# =========================
# Eliminación
# =========================
sub eliminar {
    my ($self, $codigo) = @_;

    my ($nueva_raiz, $eliminado, $mensaje) = $self->_eliminar_recursivo($self->{raiz}, $codigo);
    $self->{raiz} = $nueva_raiz;

    if ($eliminado) {
        $self->{size}--;
    }

    return ($eliminado, $mensaje);
}

sub _eliminar_recursivo {
    my ($self, $nodo_actual, $codigo) = @_;

    if (!defined $nodo_actual) {
        return (undef, 0, "No existe un equipo con codigo $codigo");
    }

    my $clave_actual = $nodo_actual->getClave();

    if ($codigo lt $clave_actual) {
        my ($nuevo_izq, $eliminado, $mensaje) =
            $self->_eliminar_recursivo($nodo_actual->getIzquierdo(), $codigo);

        $nodo_actual->setIzquierdo($nuevo_izq);
        return ($nodo_actual, $eliminado, $mensaje);
    }
    elsif ($codigo gt $clave_actual) {
        my ($nuevo_der, $eliminado, $mensaje) =
            $self->_eliminar_recursivo($nodo_actual->getDerecho(), $codigo);

        $nodo_actual->setDerecho($nuevo_der);
        return ($nodo_actual, $eliminado, $mensaje);
    }
    else {
        if (!defined $nodo_actual->getIzquierdo() && !defined $nodo_actual->getDerecho()) {
            return (undef, 1, "Equipo eliminado correctamente");
        }

        if (!defined $nodo_actual->getIzquierdo()) {
            return ($nodo_actual->getDerecho(), 1, "Equipo eliminado correctamente");
        }

        if (!defined $nodo_actual->getDerecho()) {
            return ($nodo_actual->getIzquierdo(), 1, "Equipo eliminado correctamente");
        }

        my $sucesor = $self->_obtener_minimo($nodo_actual->getDerecho());

        $nodo_actual->setEquipo($sucesor->getEquipo());

        my ($nuevo_der, $eliminado, $mensaje) =
            $self->_eliminar_recursivo($nodo_actual->getDerecho(), $sucesor->getClave());

        $nodo_actual->setDerecho($nuevo_der);

        return ($nodo_actual, 1, "Equipo eliminado correctamente");
    }
}

sub _obtener_minimo {
    my ($self, $nodo) = @_;

    while (defined $nodo && defined $nodo->getIzquierdo()) {
        $nodo = $nodo->getIzquierdo();
    }

    return $nodo;
}

# =========================
# Utilidades para mostrar recorridos
# =========================
sub inOrdenComoTexto {
    my ($self) = @_;
    return $self->_lista_a_texto($self->inOrden());
}

sub preOrdenComoTexto {
    my ($self) = @_;
    return $self->_lista_a_texto($self->preOrden());
}

sub postOrdenComoTexto {
    my ($self) = @_;
    return $self->_lista_a_texto($self->postOrden());
}

sub _lista_a_texto {
    my ($self, $lista) = @_;

    return "Arbol vacio" if !defined $lista || scalar(@$lista) == 0;

    my @lineas;
    foreach my $equipo (@$lista) {
        push @lineas, $equipo->toString();
    }

    return join("\n", @lineas);
}

# =========================
# Reporte Graphviz
# =========================
sub generarDOT {
    my ($self, $ruta_dot) = @_;

    open(my $fh, '>', $ruta_dot) or die "No se pudo crear el archivo DOT: $!";

    print $fh "digraph BST {\n";
    print $fh "    rankdir=TB;\n";
    print $fh "    node [shape=record, style=filled, fillcolor=lightblue];\n";
    print $fh "    edge [color=gray30];\n";

    if (!defined $self->{raiz}) {
        print $fh "    arbol_vacio [label=\"Arbol BST vacio\"];\n";
    } else {
        my $contador = 0;
        $self->_generar_dot_recursivo($fh, $self->{raiz}, \$contador);
    }

    print $fh "}\n";
    close($fh);

    return 1;
}

sub _generar_dot_recursivo {
    my ($self, $fh, $nodo, $contador_ref) = @_;

    return undef if !defined $nodo;

    my $id_actual = "nodo_" . $$contador_ref;
    $$contador_ref++;

    my $equipo = $nodo->getEquipo();
    my $codigo = _escapar_texto($equipo->getCodigo());
    my $nombre = _escapar_texto($equipo->getNombre());
    my $cantidad = _escapar_texto($equipo->getCantidad());

    print $fh "    $id_actual [label=\"{Codigo: $codigo|Nombre: $nombre|Cantidad: $cantidad}\"];\n";

    if (defined $nodo->getIzquierdo()) {
        my $id_izq = $self->_generar_dot_recursivo($fh, $nodo->getIzquierdo(), $contador_ref);
        print $fh "    $id_actual -> $id_izq;\n";
    }

    if (defined $nodo->getDerecho()) {
        my $id_der = $self->_generar_dot_recursivo($fh, $nodo->getDerecho(), $contador_ref);
        print $fh "    $id_actual -> $id_der;\n";
    }

    return $id_actual;
}

sub generarPNG {
    my ($self, $ruta_dot, $ruta_png) = @_;

    $self->generarDOT($ruta_dot);

    my $resultado = system('dot', '-Tpng', $ruta_dot, '-o', $ruta_png);

    return $resultado == 0;
}

sub _escapar_texto {
    my ($texto) = @_;
    $texto = '' if !defined $texto;
    $texto =~ s/"/\\"/g;
    $texto =~ s/\|/\\|/g;
    $texto =~ s/\{/\\{/g;
    $texto =~ s/\}/\\}/g;
    return $texto;
}

1;