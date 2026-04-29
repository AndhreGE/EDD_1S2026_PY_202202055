package estructuras::arbolB::ArbolB;

use strict;
use warnings;
use estructuras::arbolB::NodoB;

sub new {
    my ($class) = @_;

    my $self = {
        raiz         => estructuras::arbolB::NodoB->new(hoja => 1),
        orden        => 4,
        grado_minimo => 2,
        max_claves   => 3,
        size         => 0,
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters básicos
# =========================
sub getRaiz {
    return $_[0]->{raiz};
}

sub getSize {
    return $_[0]->{size};
}

sub estaVacio {
    return $_[0]->{size} == 0;
}

sub getOrden {
    return $_[0]->{orden};
}

# =========================
# Búsqueda
# =========================
sub buscar {
    my ($self, $clave) = @_;

    return undef if !defined $clave || $clave eq '';
    return $self->_buscar_en_nodo($self->{raiz}, $clave);
}

sub _buscar_en_nodo {
    my ($self, $nodo, $clave) = @_;

    my $i = 0;

    while ($i < $nodo->cantidadClaves() && $clave gt $nodo->getClaveEn($i)) {
        $i++;
    }

    if ($i < $nodo->cantidadClaves() && $clave eq $nodo->getClaveEn($i)) {
        return $nodo->getValorEn($i);
    }

    return undef if $nodo->esHoja();

    return $self->_buscar_en_nodo($nodo->getHijoEn($i), $clave);
}

sub existe {
    my ($self, $clave) = @_;
    return defined $self->buscar($clave);
}

# =========================
# Inserción
# =========================
sub insertar {
    my ($self, $obj) = @_;

    if (!defined $obj) {
        return (0, 'No se puede insertar un suministro indefinido');
    }

    if (!$obj->can('getClave')) {
        return (0, 'El objeto no tiene metodo getClave');
    }

    if ($obj->can('esValido') && !$obj->esValido()) {
        my @errores = $obj->validar();
        return (0, 'Suministro invalido: ' . join(', ', @errores));
    }

    my $clave = $obj->getClave();

    if ($self->existe($clave)) {
        return (0, "Ya existe un suministro con codigo $clave");
    }

    my $raiz = $self->{raiz};

    if ($raiz->cantidadClaves() == $self->{max_claves}) {
        my $nueva_raiz = estructuras::arbolB::NodoB->new(hoja => 0);
        $nueva_raiz->insertarHijoEn(0, $raiz);

        $self->_dividir_hijo($nueva_raiz, 0);
        $self->{raiz} = $nueva_raiz;
    }

    $self->_insertar_no_lleno($self->{raiz}, $obj);
    $self->{size}++;

    return (1, 'Suministro insertado correctamente');
}

sub _insertar_no_lleno {
    my ($self, $nodo, $obj) = @_;

    my $clave = $obj->getClave();
    my $i = $nodo->cantidadClaves() - 1;

    if ($nodo->esHoja()) {
        while ($i >= 0 && $clave lt $nodo->getClaveEn($i)) {
            $i--;
        }

        $nodo->insertarClaveValorEn($i + 1, $clave, $obj);
        return;
    }

    while ($i >= 0 && $clave lt $nodo->getClaveEn($i)) {
        $i--;
    }

    $i++;

    my $hijo = $nodo->getHijoEn($i);

    if ($hijo->cantidadClaves() == $self->{max_claves}) {
        $self->_dividir_hijo($nodo, $i);

        if ($clave gt $nodo->getClaveEn($i)) {
            $i++;
        }
    }

    $self->_insertar_no_lleno($nodo->getHijoEn($i), $obj);
}

sub _dividir_hijo {
    my ($self, $padre, $idx_hijo) = @_;

    my $t = $self->{grado_minimo};

    my $hijo_lleno   = $padre->getHijoEn($idx_hijo);
    my $nuevo_derecho = estructuras::arbolB::NodoB->new(
        hoja => $hijo_lleno->esHoja()
    );

    my @claves_hijo  = @{ $hijo_lleno->getClaves() };
    my @valores_hijo = @{ $hijo_lleno->getValores() };
    my @hijos_hijo   = @{ $hijo_lleno->getHijos() };

    my $clave_media = $claves_hijo[$t - 1];
    my $valor_medio = $valores_hijo[$t - 1];

    my @claves_izq  = @claves_hijo[0 .. $t - 2];
    my @valores_izq = @valores_hijo[0 .. $t - 2];

    my @claves_der  = @claves_hijo[$t .. $#claves_hijo];
    my @valores_der = @valores_hijo[$t .. $#valores_hijo];

    @{ $hijo_lleno->getClaves() }  = @claves_izq;
    @{ $hijo_lleno->getValores() } = @valores_izq;

    @{ $nuevo_derecho->getClaves() }  = @claves_der;
    @{ $nuevo_derecho->getValores() } = @valores_der;

    if (!$hijo_lleno->esHoja()) {
        my @hijos_izq = @hijos_hijo[0 .. $t - 1];
        my @hijos_der = @hijos_hijo[$t .. $#hijos_hijo];

        @{ $hijo_lleno->getHijos() }   = @hijos_izq;
        @{ $nuevo_derecho->getHijos() } = @hijos_der;
    }

    $padre->insertarClaveValorEn($idx_hijo, $clave_media, $valor_medio);
    $padre->insertarHijoEn($idx_hijo + 1, $nuevo_derecho);
}

# =========================
# Recorridos
# =========================
sub inOrden {
    my ($self) = @_;

    my @resultado;
    $self->_in_orden_nodo($self->{raiz}, \@resultado) if defined $self->{raiz};

    return \@resultado;
}

sub _in_orden_nodo {
    my ($self, $nodo, $resultado) = @_;

    my $n = $nodo->cantidadClaves();

    for (my $i = 0; $i < $n; $i++) {
        if (!$nodo->esHoja()) {
            $self->_in_orden_nodo($nodo->getHijoEn($i), $resultado);
        }

        push @$resultado, $nodo->getValorEn($i);
    }

    if (!$nodo->esHoja()) {
        $self->_in_orden_nodo($nodo->getHijoEn($n), $resultado);
    }
}

sub preOrden {
    my ($self) = @_;

    my @resultado;
    $self->_pre_orden_nodo($self->{raiz}, \@resultado) if defined $self->{raiz};

    return \@resultado;
}

sub _pre_orden_nodo {
    my ($self, $nodo, $resultado) = @_;

    my $n = $nodo->cantidadClaves();

    for (my $i = 0; $i < $n; $i++) {
        push @$resultado, $nodo->getValorEn($i);
    }

    if (!$nodo->esHoja()) {
        for (my $i = 0; $i <= $n; $i++) {
            $self->_pre_orden_nodo($nodo->getHijoEn($i), $resultado);
        }
    }
}

sub postOrden {
    my ($self) = @_;

    my @resultado;
    $self->_post_orden_nodo($self->{raiz}, \@resultado) if defined $self->{raiz};

    return \@resultado;
}

sub _post_orden_nodo {
    my ($self, $nodo, $resultado) = @_;

    my $n = $nodo->cantidadClaves();

    if (!$nodo->esHoja()) {
        for (my $i = 0; $i <= $n; $i++) {
            $self->_post_orden_nodo($nodo->getHijoEn($i), $resultado);
        }
    }

    for (my $i = 0; $i < $n; $i++) {
        push @$resultado, $nodo->getValorEn($i);
    }
}

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

    return 'Arbol B vacio' if !defined $lista || scalar(@$lista) == 0;

    my @lineas;
    foreach my $obj (@$lista) {
        push @lineas, $obj->toString();
    }

    return join("\n", @lineas);
}

# =========================
# Eliminación
# =========================
sub eliminar {
    my ($self, $clave) = @_;

    if (!defined $clave || $clave eq '') {
        return (0, 'Debe indicar una clave para eliminar');
    }

    if (!$self->existe($clave)) {
        return (0, "No existe un suministro con codigo $clave");
    }

    $self->_eliminar_de_nodo($self->{raiz}, $clave);

    if ($self->{raiz}->cantidadClaves() == 0 && !$self->{raiz}->esHoja()) {
        $self->{raiz} = $self->{raiz}->getHijoEn(0);
    }

    $self->{size}--;

    return (1, 'Suministro eliminado correctamente');
}

sub _eliminar_de_nodo {
    my ($self, $nodo, $clave) = @_;

    my $t = $self->{grado_minimo};
    my $idx = 0;

    while ($idx < $nodo->cantidadClaves() && $clave gt $nodo->getClaveEn($idx)) {
        $idx++;
    }

    # Caso 1: la clave está en este nodo
    if ($idx < $nodo->cantidadClaves() && $clave eq $nodo->getClaveEn($idx)) {
        # 1A: si es hoja, se elimina directo
        if ($nodo->esHoja()) {
            $nodo->eliminarClaveValorEn($idx);
            return;
        }

        # 1B: si es interno
        my $hijo_izq = $nodo->getHijoEn($idx);
        my $hijo_der = $nodo->getHijoEn($idx + 1);

        if ($hijo_izq->cantidadClaves() >= $t) {
            my ($pred_clave, $pred_valor) = $self->_obtener_predecesor($hijo_izq);

            $nodo->getClaves()->[$idx]  = $pred_clave;
            $nodo->getValores()->[$idx] = $pred_valor;

            $self->_eliminar_de_nodo($hijo_izq, $pred_clave);
        }
        elsif ($hijo_der->cantidadClaves() >= $t) {
            my ($succ_clave, $succ_valor) = $self->_obtener_sucesor($hijo_der);

            $nodo->getClaves()->[$idx]  = $succ_clave;
            $nodo->getValores()->[$idx] = $succ_valor;

            $self->_eliminar_de_nodo($hijo_der, $succ_clave);
        }
        else {
            $self->_fusionar_hijos($nodo, $idx);
            $self->_eliminar_de_nodo($hijo_izq, $clave);
        }

        return;
    }

    # Caso 2: no está en este nodo
    return if $nodo->esHoja();

    my $hijo = $nodo->getHijoEn($idx);

    # Antes de bajar, garantizamos que tenga al menos t claves si es posible
    if ($hijo->cantidadClaves() == $t - 1) {
        my $hijo_izq = $idx > 0 ? $nodo->getHijoEn($idx - 1) : undef;
        my $hijo_der = $idx < $nodo->cantidadClaves() ? $nodo->getHijoEn($idx + 1) : undef;

        if (defined $hijo_izq && $hijo_izq->cantidadClaves() >= $t) {
            $self->_prestar_desde_izquierdo($nodo, $idx);
        }
        elsif (defined $hijo_der && $hijo_der->cantidadClaves() >= $t) {
            $self->_prestar_desde_derecho($nodo, $idx);
        }
        else {
            if (defined $hijo_der) {
                $self->_fusionar_hijos($nodo, $idx);
            }
            else {
                $self->_fusionar_hijos($nodo, $idx - 1);
                $idx--;
            }
        }
    }

    my $nuevo_hijo = $nodo->getHijoEn($idx);
    $self->_eliminar_de_nodo($nuevo_hijo, $clave);
}

sub _obtener_predecesor {
    my ($self, $nodo) = @_;

    my $actual = $nodo;

    while (!$actual->esHoja()) {
        $actual = $actual->getHijoEn($actual->cantidadClaves());
    }

    my $i = $actual->cantidadClaves() - 1;
    return ($actual->getClaveEn($i), $actual->getValorEn($i));
}

sub _obtener_sucesor {
    my ($self, $nodo) = @_;

    my $actual = $nodo;

    while (!$actual->esHoja()) {
        $actual = $actual->getHijoEn(0);
    }

    return ($actual->getClaveEn(0), $actual->getValorEn(0));
}

sub _prestar_desde_izquierdo {
    my ($self, $padre, $idx_hijo) = @_;

    my $hijo        = $padre->getHijoEn($idx_hijo);
    my $hermano_izq = $padre->getHijoEn($idx_hijo - 1);

    unshift @{ $hijo->getClaves() },  $padre->getClaveEn($idx_hijo - 1);
    unshift @{ $hijo->getValores() }, $padre->getValorEn($idx_hijo - 1);

    if (!$hijo->esHoja()) {
        my $ultimo_hijo_izq = pop @{ $hermano_izq->getHijos() };
        unshift @{ $hijo->getHijos() }, $ultimo_hijo_izq;
    }

    my $clave_prestada = pop @{ $hermano_izq->getClaves() };
    my $valor_prestado = pop @{ $hermano_izq->getValores() };

    $padre->getClaves()->[$idx_hijo - 1]  = $clave_prestada;
    $padre->getValores()->[$idx_hijo - 1] = $valor_prestado;
}

sub _prestar_desde_derecho {
    my ($self, $padre, $idx_hijo) = @_;

    my $hijo        = $padre->getHijoEn($idx_hijo);
    my $hermano_der = $padre->getHijoEn($idx_hijo + 1);

    push @{ $hijo->getClaves() },  $padre->getClaveEn($idx_hijo);
    push @{ $hijo->getValores() }, $padre->getValorEn($idx_hijo);

    if (!$hijo->esHoja()) {
        my $primer_hijo_der = shift @{ $hermano_der->getHijos() };
        push @{ $hijo->getHijos() }, $primer_hijo_der;
    }

    my $clave_prestada = shift @{ $hermano_der->getClaves() };
    my $valor_prestado = shift @{ $hermano_der->getValores() };

    $padre->getClaves()->[$idx_hijo]  = $clave_prestada;
    $padre->getValores()->[$idx_hijo] = $valor_prestado;
}

sub _fusionar_hijos {
    my ($self, $padre, $idx) = @_;

    my $hijo_izq = $padre->getHijoEn($idx);
    my $hijo_der = $padre->getHijoEn($idx + 1);

    push @{ $hijo_izq->getClaves() },  $padre->getClaveEn($idx);
    push @{ $hijo_izq->getValores() }, $padre->getValorEn($idx);

    push @{ $hijo_izq->getClaves() },  @{ $hijo_der->getClaves() };
    push @{ $hijo_izq->getValores() }, @{ $hijo_der->getValores() };

    if (!$hijo_izq->esHoja()) {
        push @{ $hijo_izq->getHijos() }, @{ $hijo_der->getHijos() };
    }

    $padre->eliminarClaveValorEn($idx);
    $padre->eliminarHijoEn($idx + 1);

    return $hijo_izq;
}

# =========================
# Reporte Graphviz
# =========================
sub generarDOT {
    my ($self, $ruta_dot) = @_;

    open(my $fh, '>', $ruta_dot) or die "No se pudo crear el archivo DOT: $!";

    print $fh "digraph ArbolB {\n";
    print $fh "    rankdir=TB;\n";
    print $fh "    node [shape=record, style=filled, fillcolor=lightcyan2];\n";
    print $fh "    edge [color=gray30];\n";

    if ($self->{size} == 0 || !defined $self->{raiz} || $self->{raiz}->cantidadClaves() == 0) {
        print $fh "    arbol_vacio [label=\"Arbol B vacio\"];\n";
    }
    else {
        my $contador = 0;
        $self->_generar_dot_nodo($fh, $self->{raiz}, \$contador);
    }

    print $fh "}\n";
    close($fh);

    return 1;
}

sub _generar_dot_nodo {
    my ($self, $fh, $nodo, $contador_ref) = @_;

    my $id_actual = 'nodo_' . $$contador_ref;
    $$contador_ref++;

    my @partes;

    for (my $i = 0; $i < $nodo->cantidadClaves(); $i++) {
        my $obj = $nodo->getValorEn($i);

        my $texto = $self->_escapar_texto(
            $obj->getCodigo() . "\\n" .
            $obj->getNombre() . "\\n" .
            "Cant: " . $obj->getCantidad()
        );

        push @partes, $texto;
    }

    my $label = join('|', @partes);

    print $fh qq{    $id_actual [label="{$label}"];\n};

    if (!$nodo->esHoja()) {
        for (my $i = 0; $i <= $nodo->cantidadClaves(); $i++) {
            my $hijo = $nodo->getHijoEn($i);
            next if !defined $hijo;

            my $id_hijo = $self->_generar_dot_nodo($fh, $hijo, $contador_ref);
            print $fh "    $id_actual -> $id_hijo;\n";
        }
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
    my ($self, $texto) = @_;

    $texto = '' if !defined $texto;
    $texto =~ s/"/\\"/g;
    $texto =~ s/\|/\\|/g;
    $texto =~ s/\{/\\{/g;
    $texto =~ s/\}/\\}/g;

    return $texto;
}

1;