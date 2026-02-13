package Nodo;
use strict;
use warnings;

sub crear_medicamento {
    my ($class, $codigo, $nombre, $principio, $lab, $precio, $cant, $fecha, $nivel) = @_;
    return {
        codigo => $codigo, nombre => $nombre, principio => $principio,
        lab => $lab, precio => $precio, cantidad => $cant,
        fecha_venc => $fecha, nivel_min => $nivel,
        next => undef, prev => undef
    };
}

sub crear_proveedor {
    my ($class, $nit, $nombre, $contacto, $tel, $dir) = @_;
    return {
        nit => $nit, nombre => $nombre, contacto => $contacto,
        telefono => $tel, direccion => $dir,
        lista_entregas => undef, next => undef
    };
}

sub crear_entrega {
    my ($class, $fecha, $factura, $codigo, $cantidad) = @_;
    return {
        fecha => $fecha, factura => $factura,
        codigo => $codigo, cantidad => $cantidad,
        next => undef
    };
}


sub crear_solicitud {
    my ($class, $numero, $depto, $med, $cant, $prioridad) = @_;
    return {
        numero   => $numero,
        depto    => $depto,
        med      => $med,
        cantidad => $cant,
        prioridad => $prioridad,
        next     => undef,
        prev     => undef
    };
}

# Nodo para las cabeceras (Filas y Columnas)
sub crear_cabecera {
    my ($class, $id) = @_;
    return {
        id   => $id,
        next => undef,
        prev => undef,
        access => undef # Puntero hacia la fila o columna de datos
    };
}

# Nodo de Valor (La celda de la matriz)
sub crear_celda_matriz {
    my ($class, $codigo, $cantidad, $fecha, $precio) = @_;
    return {
        codigo   => $codigo,
        cantidad => $cantidad,
        fecha    => $fecha,
        precio   => $precio,
        up    => undef,
        down  => undef,
        left  => undef,
        right => undef
    };
}

1; # Obligatorio