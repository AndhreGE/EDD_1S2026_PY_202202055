package estructuras::avl::ArbolAVL;

use strict;
use warnings;
use estructuras::avl::NodoAVL;

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
# Utilidades AVL
# =========================
sub _altura {
    my ($self, $nodo) = @_;
    return defined $nodo ? $nodo->getAltura() : 0;
}

sub _max {
    my ($self, $a, $b) = @_;
    return ($a > $b) ? $a : $b;
}

sub _actualizar_altura {
    my ($self, $nodo) = @_;
    return if !defined $nodo;

    my $altura_izq = $self->_altura($nodo->getIzquierdo());
    my $altura_der = $self->_altura($nodo->getDerecho());

    $nodo->setAltura(1 + $self->_max($altura_izq, $altura_der));
}

sub _obtener_balance {
    my ($self, $nodo) = @_;
    return 0 if !defined $nodo;

    return $self->_altura($nodo->getIzquierdo()) - $self->_altura($nodo->getDerecho());
}

# =========================
# Rotaciones
# =========================
sub _rotacion_derecha {
    my ($self, $y) = @_;

    my $x  = $y->getIzquierdo();
    my $t2 = $x->getDerecho();

    $x->setDerecho($y);
    $y->setIzquierdo($t2);

    $self->_actualizar_altura($y);
    $self->_actualizar_altura($x);

    return $x;
}

sub _rotacion_izquierda {
    my ($self, $x) = @_;

    my $y  = $x->getDerecho();
    my $t2 = $y->getIzquierdo();

    $y->setIzquierdo($x);
    $x->setDerecho($t2);

    $self->_actualizar_altura($x);
    $self->_actualizar_altura($y);

    return $y;
}

# =========================
# Inserción
# =========================
sub insertar {
    my ($self, $personal) = @_;

    if (!defined $personal) {
        return (0, "No se puede insertar un usuario indefinido");
    }

    if (!$personal->can('getClave')) {
        return (0, "El objeto no tiene metodo getClave");
    }

    if ($personal->can('esValido') && !$personal->esValido()) {
        my @errores = $personal->validar();
        return (0, "Usuario invalido: " . join(", ", @errores));
    }

    my ($nueva_raiz, $insertado, $mensaje) = $self->_insertar_recursivo($self->{raiz}, $personal);
    $self->{raiz} = $nueva_raiz;

    if ($insertado) {
        $self->{size}++;
    }

    return ($insertado, $mensaje);
}

sub _insertar_recursivo {
    my ($self, $nodo, $personal) = @_;

    if (!defined $nodo) {
        my $nuevo = estructuras::avl::NodoAVL->new($personal);
        return ($nuevo, 1, "Usuario insertado correctamente");
    }

    my $clave_nueva  = $personal->getClave();
    my $clave_actual = $nodo->getClave();

    if ($clave_nueva lt $clave_actual) {
        my ($nuevo_izq, $insertado, $mensaje) =
            $self->_insertar_recursivo($nodo->getIzquierdo(), $personal);

        $nodo->setIzquierdo($nuevo_izq);

        return ($nodo, $insertado, $mensaje) if !$insertado;

    } elsif ($clave_nueva gt $clave_actual) {
        my ($nuevo_der, $insertado, $mensaje) =
            $self->_insertar_recursivo($nodo->getDerecho(), $personal);

        $nodo->setDerecho($nuevo_der);

        return ($nodo, $insertado, $mensaje) if !$insertado;

    } else {
        return ($nodo, 0, "Ya existe un usuario con numero de colegio $clave_nueva");
    }

    $self->_actualizar_altura($nodo);
    my $balance = $self->_obtener_balance($nodo);

    # Caso Izquierda-Izquierda
    if ($balance > 1 && $clave_nueva lt $nodo->getIzquierdo()->getClave()) {
        return ($self->_rotacion_derecha($nodo), 1, "Usuario insertado correctamente");
    }

    # Caso Derecha-Derecha
    if ($balance < -1 && $clave_nueva gt $nodo->getDerecho()->getClave()) {
        return ($self->_rotacion_izquierda($nodo), 1, "Usuario insertado correctamente");
    }

    # Caso Izquierda-Derecha
    if ($balance > 1 && $clave_nueva gt $nodo->getIzquierdo()->getClave()) {
        $nodo->setIzquierdo($self->_rotacion_izquierda($nodo->getIzquierdo()));
        return ($self->_rotacion_derecha($nodo), 1, "Usuario insertado correctamente");
    }

    # Caso Derecha-Izquierda
    if ($balance < -1 && $clave_nueva lt $nodo->getDerecho()->getClave()) {
        $nodo->setDerecho($self->_rotacion_derecha($nodo->getDerecho()));
        return ($self->_rotacion_izquierda($nodo), 1, "Usuario insertado correctamente");
    }

    return ($nodo, 1, "Usuario insertado correctamente");
}

# =========================
# Búsqueda
# =========================
sub buscar {
    my ($self, $numero_colegio) = @_;
    my $nodo = $self->_buscar_nodo($self->{raiz}, $numero_colegio);
    return defined $nodo ? $nodo->getPersonal() : undef;
}

sub _buscar_nodo {
    my ($self, $nodo, $clave) = @_;

    return undef if !defined $nodo;

    my $clave_actual = $nodo->getClave();

    if ($clave eq $clave_actual) {
        return $nodo;
    }
    elsif ($clave lt $clave_actual) {
        return $self->_buscar_nodo($nodo->getIzquierdo(), $clave);
    }
    else {
        return $self->_buscar_nodo($nodo->getDerecho(), $clave);
    }
}

sub existe {
    my ($self, $numero_colegio) = @_;
    return defined $self->buscar($numero_colegio);
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
    push @$resultado, $nodo->getPersonal();
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

    push @$resultado, $nodo->getPersonal();
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
    push @$resultado, $nodo->getPersonal();
}

# =========================
# Eliminación
# =========================
sub eliminar {
    my ($self, $numero_colegio) = @_;

    my ($nueva_raiz, $eliminado, $mensaje) =
        $self->_eliminar_recursivo($self->{raiz}, $numero_colegio);

    $self->{raiz} = $nueva_raiz;

    if ($eliminado) {
        $self->{size}--;
    }

    return ($eliminado, $mensaje);
}

sub _eliminar_recursivo {
    my ($self, $nodo, $clave) = @_;

    if (!defined $nodo) {
        return (undef, 0, "No existe un usuario con numero de colegio $clave");
    }

    my $clave_actual = $nodo->getClave();
    my $eliminado = 0;
    my $mensaje   = "No existe un usuario con numero de colegio $clave";

    if ($clave lt $clave_actual) {
        my ($nuevo_izq, $elim, $msg) =
            $self->_eliminar_recursivo($nodo->getIzquierdo(), $clave);

        $nodo->setIzquierdo($nuevo_izq);
        $eliminado = $elim;
        $mensaje   = $msg;

    } elsif ($clave gt $clave_actual) {
        my ($nuevo_der, $elim, $msg) =
            $self->_eliminar_recursivo($nodo->getDerecho(), $clave);

        $nodo->setDerecho($nuevo_der);
        $eliminado = $elim;
        $mensaje   = $msg;

    } else {
        $eliminado = 1;
        $mensaje   = "Usuario eliminado correctamente";

        # Sin hijos
        if (!defined $nodo->getIzquierdo() && !defined $nodo->getDerecho()) {
            return (undef, 1, $mensaje);
        }

        # Un hijo derecho
        if (!defined $nodo->getIzquierdo()) {
            return ($nodo->getDerecho(), 1, $mensaje);
        }

        # Un hijo izquierdo
        if (!defined $nodo->getDerecho()) {
            return ($nodo->getIzquierdo(), 1, $mensaje);
        }

        # Dos hijos
        my $sucesor = $self->_obtener_minimo($nodo->getDerecho());
        $nodo->setPersonal($sucesor->getPersonal());

        my ($nuevo_der, $elim2, $msg2) =
            $self->_eliminar_recursivo($nodo->getDerecho(), $sucesor->getClave());

        $nodo->setDerecho($nuevo_der);

        # elim2 debe ser 1, pero no decrementamos size aquí porque eso solo se hace una vez arriba
    }

    return ($nodo, $eliminado, $mensaje) if !defined $nodo;
    return ($nodo, $eliminado, $mensaje) if !$eliminado;

    $self->_actualizar_altura($nodo);
    my $balance = $self->_obtener_balance($nodo);

    # Caso Izquierda-Izquierda
    if ($balance > 1 && $self->_obtener_balance($nodo->getIzquierdo()) >= 0) {
        return ($self->_rotacion_derecha($nodo), $eliminado, $mensaje);
    }

    # Caso Izquierda-Derecha
    if ($balance > 1 && $self->_obtener_balance($nodo->getIzquierdo()) < 0) {
        $nodo->setIzquierdo($self->_rotacion_izquierda($nodo->getIzquierdo()));
        return ($self->_rotacion_derecha($nodo), $eliminado, $mensaje);
    }

    # Caso Derecha-Derecha
    if ($balance < -1 && $self->_obtener_balance($nodo->getDerecho()) <= 0) {
        return ($self->_rotacion_izquierda($nodo), $eliminado, $mensaje);
    }

    # Caso Derecha-Izquierda
    if ($balance < -1 && $self->_obtener_balance($nodo->getDerecho()) > 0) {
        $nodo->setDerecho($self->_rotacion_derecha($nodo->getDerecho()));
        return ($self->_rotacion_izquierda($nodo), $eliminado, $mensaje);
    }

    return ($nodo, $eliminado, $mensaje);
}

sub _obtener_minimo {
    my ($self, $nodo) = @_;

    while (defined $nodo && defined $nodo->getIzquierdo()) {
        $nodo = $nodo->getIzquierdo();
    }

    return $nodo;
}

# =========================
# Texto de recorridos
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

    return "Arbol AVL vacio" if !defined $lista || scalar(@$lista) == 0;

    my @lineas;
    foreach my $usuario (@$lista) {
        push @lineas, $usuario->toString();
    }

    return join("\n", @lineas);
}

# =========================
# Reporte Graphviz
# =========================
sub generarDOT {
    my ($self, $ruta_dot) = @_;

    open(my $fh, '>', $ruta_dot) or die "No se pudo crear el archivo DOT: $!";

    print $fh "digraph AVL {\n";
    print $fh "    rankdir=TB;\n";
    print $fh "    node [shape=record, style=filled, fillcolor=lightgoldenrod1];\n";
    print $fh "    edge [color=gray30];\n";

    if (!defined $self->{raiz}) {
        print $fh "    arbol_vacio [label=\"Arbol AVL vacio\"];\n";
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

    my $usuario = $nodo->getPersonal();
    my $colegio = _escapar_texto($usuario->getNumeroColegio());
    my $nombre  = _escapar_texto($usuario->getNombreCompleto());
    my $depto   = _escapar_texto($usuario->getDepartamento());
    my $altura  = $nodo->getAltura();
    my $balance = $self->_obtener_balance($nodo);

    print $fh "    $id_actual [label=\"{Colegio: $colegio|Nombre: $nombre|Depto: $depto|Altura: $altura|Balance: $balance}\"];\n";

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