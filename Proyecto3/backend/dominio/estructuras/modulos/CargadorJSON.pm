package estructuras::modulos::CargadorJSON;

use strict;
use warnings;

use JSON::PP qw(decode_json);

use modelos::Proveedor;
use modelos::Medicamento;
use modelos::Equipo;
use modelos::Suministro;
use modelos::PersonalMedico;

sub new {
    my ($class, @args) = @_;

    my %args;

    # Compatibilidad:
    # 1) new({ ... })
    # 2) new(clave => valor, ...)
    if (@args == 1 && ref($args[0]) eq 'HASH') {
        %args = %{ $args[0] };
    } else {
        %args = @args;
    }

    my $self = {
        inventario      => $args{inventario},
        gestor_usuarios => $args{gestor_usuarios},
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Getters
# =========================================================
sub getInventario {
    my ($self) = @_;
    return $self->{inventario};
}

sub getGestorUsuarios {
    my ($self) = @_;
    return $self->{gestor_usuarios};
}

# =========================================================
# Carga de inventario
# =========================================================
sub cargarInventarioDesdeArchivo {
    my ($self, $ruta) = @_;

    if (!defined $self->{inventario}) {
        return {
            ok => 0,
            mensaje => 'No se ha configurado el inventario en el cargador',
            errores => ['Falta la instancia de Inventario.pm'],
        };
    }

    my $data = eval { $self->_leer_json($ruta) };
    if ($@) {
        return {
            ok => 0,
            mensaje => "No se pudo leer el archivo de inventario: $@",
            errores => ["Error de lectura/parsing en $ruta"],
        };
    }

    if (ref($data) ne 'HASH' || ref($data->{proveedor}) ne 'ARRAY') {
        return {
            ok => 0,
            mensaje => 'El JSON de inventario no tiene la estructura esperada',
            errores => ['Se esperaba una clave "proveedor" con un arreglo'],
        };
    }

    my $resumen = {
        ok                      => 1,
        mensaje                 => 'Carga de inventario completada',
        archivo                 => $ruta,
        proveedores_leidos      => 0,
        proveedores_registrados => 0,
        items_leidos            => 0,
        medicamentos_ok         => 0,
        equipos_ok              => 0,
        suministros_ok          => 0,
        errores                 => [],
    };

    foreach my $registro_proveedor (@{ $data->{proveedor} }) {
        $resumen->{proveedores_leidos}++;

        if (ref($registro_proveedor) ne 'HASH') {
            push @{ $resumen->{errores} }, "Registro de proveedor invalido en posicion $resumen->{proveedores_leidos}";
            next;
        }

        my $nit = $self->_normalizar($registro_proveedor->{nit});
        my $nombre = $self->_normalizar($registro_proveedor->{nombre});
        my $telefono = $self->_normalizar($registro_proveedor->{telefono});
        my $direccion = $self->_normalizar($registro_proveedor->{direccion});

        my $proveedor = modelos::Proveedor->new(
            nit            => $nit,
            nombre_empresa => $nombre,
            contacto       => 'Carga JSON',
            telefono       => $telefono,
            direccion      => $direccion,
        );

        my ($ok_prov, $msg_prov) = $self->{inventario}->registrarProveedor($proveedor);

        if ($ok_prov) {
            $resumen->{proveedores_registrados}++;
        } else {
            # si ya existía, seguimos cargando sus ítems de todos modos
            push @{ $resumen->{errores} }, "Proveedor $nit: $msg_prov";
        }

        my $entregas = $registro_proveedor->{entrega};

        if (ref($entregas) ne 'ARRAY') {
            push @{ $resumen->{errores} }, "Proveedor $nit no tiene un arreglo valido en 'entrega'";
            next;
        }

        foreach my $item (@$entregas) {
            $resumen->{items_leidos}++;

            if (ref($item) ne 'HASH') {
                push @{ $resumen->{errores} }, "Item invalido en proveedor $nit";
                next;
            }

            my $tipo = uc($self->_normalizar($item->{tipo}));

            my ($obj, $tipo_real, $error_creacion) = $self->_crear_objeto_inventario($item);

            if (!$obj) {
                push @{ $resumen->{errores} }, "Proveedor $nit, item sin codigo o invalido: $error_creacion";
                next;
            }

            my ($ok_item, $msg_item) = $self->{inventario}->registrarItem(
                $obj,
                nit_proveedor => $nit,
                tipo          => $tipo_real,
            );

            if ($ok_item) {
                if ($tipo_real eq 'MEDICAMENTO') {
                    $resumen->{medicamentos_ok}++;
                }
                elsif ($tipo_real eq 'EQUIPO') {
                    $resumen->{equipos_ok}++;
                }
                elsif ($tipo_real eq 'SUMINISTRO') {
                    $resumen->{suministros_ok}++;
                }
            } else {
                my $codigo = $self->_normalizar($item->{codigo});
                push @{ $resumen->{errores} }, "Proveedor $nit, item $codigo ($tipo): $msg_item";
            }
        }
    }

    return $resumen;
}

# =========================================================
# Carga de usuarios
# =========================================================
sub cargarUsuariosDesdeArchivo {
    my ($self, $ruta) = @_;

    if (!defined $self->{gestor_usuarios}) {
        return {
            ok => 0,
            mensaje => 'No se ha configurado el gestor de usuarios en el cargador',
            errores => ['Falta la instancia de GestorUsuarios.pm'],
        };
    }

    my $data = eval { $self->_leer_json($ruta) };
    if ($@) {
        return {
            ok => 0,
            mensaje => "No se pudo leer el archivo de usuarios: $@",
            errores => ["Error de lectura/parsing en $ruta"],
        };
    }

    if (ref($data) ne 'HASH' || ref($data->{usuarios}) ne 'ARRAY') {
        return {
            ok => 0,
            mensaje => 'El JSON de usuarios no tiene la estructura esperada',
            errores => ['Se esperaba una clave "usuarios" con un arreglo'],
        };
    }

    my $resumen = {
        ok                  => 1,
        mensaje             => 'Carga de usuarios completada',
        archivo             => $ruta,
        usuarios_leidos     => 0,
        usuarios_registrados=> 0,
        errores             => [],
    };

    foreach my $registro (@{ $data->{usuarios} }) {
        $resumen->{usuarios_leidos}++;

        if (ref($registro) ne 'HASH') {
            push @{ $resumen->{errores} }, "Registro de usuario invalido en posicion $resumen->{usuarios_leidos}";
            next;
        }

        my $usuario = modelos::PersonalMedico->new(
            numero_colegio  => $self->_normalizar($registro->{numero_colegio}),
            nombre_completo => $self->_normalizar($registro->{nombre_completo}),
            tipo_usuario    => $self->_normalizar($registro->{tipo_usuario}),
            departamento    => $self->_normalizar($registro->{departamento}),
            especialidad    => defined $registro->{especialidad} ? $registro->{especialidad} : '',
            contrasena      => $self->_normalizar($registro->{contrasena}),
        );

        my ($ok, $msg) = $self->{gestor_usuarios}->registrarUsuario($usuario);

        if ($ok) {
            $resumen->{usuarios_registrados}++;
        } else {
            my $colegio = $self->_normalizar($registro->{numero_colegio});
            push @{ $resumen->{errores} }, "Usuario $colegio: $msg";
        }
    }

    return $resumen;
}

# =========================================================
# Carga completa
# =========================================================
sub cargarTodo {
    my ($self, %args) = @_;

    my $ruta_inventario = $args{inventario};
    my $ruta_usuarios   = $args{usuarios};

    my $resultado = {
        inventario => undef,
        usuarios   => undef,
    };

    if (defined $ruta_inventario && $ruta_inventario ne '') {
        $resultado->{inventario} = $self->cargarInventarioDesdeArchivo($ruta_inventario);
    }

    if (defined $ruta_usuarios && $ruta_usuarios ne '') {
        $resultado->{usuarios} = $self->cargarUsuariosDesdeArchivo($ruta_usuarios);
    }

    return $resultado;
}

# =========================================================
# Helpers internos
# =========================================================
sub _leer_json {
    my ($self, $ruta) = @_;

    die "Debe indicar la ruta del archivo JSON" if !defined $ruta || $ruta eq '';
    open(my $fh, '<:raw', $ruta) or die "No se pudo abrir $ruta: $!";

    local $/;
    my $contenido = <$fh>;
    close($fh);

    my $data = decode_json($contenido);
    return $data;
}

sub _crear_objeto_inventario {
    my ($self, $item) = @_;

    my $tipo = uc($self->_normalizar($item->{tipo}));

    if ($tipo eq 'MEDICAMENTO') {
        my $obj = modelos::Medicamento->new(
            codigo            => $self->_normalizar($item->{codigo}),
            nombre            => $self->_normalizar($item->{nombre}),
            principio_activo  => $self->_normalizar($item->{principio_activo}),
            laboratorio       => $self->_normalizar($item->{fabricante}),
            precio_unitario   => $item->{precio_unitario},
            cantidad          => $item->{cantidad},
            fecha_vencimiento => $self->_normalizar($item->{fecha_vencimiento}),
            nivel_minimo      => $item->{nivel_minimo},
        );

        return ($obj, 'MEDICAMENTO', undef);
    }
    elsif ($tipo eq 'EQUIPO') {
        my $obj = modelos::Equipo->new(
            codigo          => $self->_normalizar($item->{codigo}),
            nombre          => $self->_normalizar($item->{nombre}),
            fabricante      => $self->_normalizar($item->{fabricante}),
            precio_unitario => $item->{precio_unitario},
            cantidad        => $item->{cantidad},
            fecha_ingreso   => $self->_normalizar($item->{fecha_ingreso}),
            nivel_minimo    => $item->{nivel_minimo},
        );

        return ($obj, 'EQUIPO', undef);
    }
    elsif ($tipo eq 'SUMINISTRO') {
        my $obj = modelos::Suministro->new(
            codigo            => $self->_normalizar($item->{codigo}),
            nombre            => $self->_normalizar($item->{nombre}),
            fabricante        => $self->_normalizar($item->{fabricante}),
            precio_unitario   => $item->{precio_unitario},
            cantidad          => $item->{cantidad},
            fecha_vencimiento => $self->_normalizar($item->{fecha_vencimiento}),
            nivel_minimo      => $item->{nivel_minimo},
        );

        return ($obj, 'SUMINISTRO', undef);
    }

    return (undef, undef, "Tipo de item no soportado: $tipo");
}

sub _normalizar {
    my ($self, $valor) = @_;
    return '' if !defined $valor;
    return $valor;
}

1;