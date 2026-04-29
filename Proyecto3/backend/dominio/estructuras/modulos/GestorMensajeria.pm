package estructuras::modulos::GestorMensajeria;

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use JSON::PP;
use POSIX qw(strftime);

use estructuras::compresion::LZW;

sub new {
    my ($class, %args) = @_;

    my $self = {
        gestor_colaboracion => $args{gestor_colaboracion},
        lzw                 => $args{lzw} // estructuras::compresion::LZW->new(),
        base_dir            => $args{base_dir} // 'chats',
        auto_guardado       => exists $args{auto_guardado} ? $args{auto_guardado} : 1,

        # cache en memoria por usuario
        historiales => {},   # usuario_id => { propietario => id, conversaciones => { otro_id => [ mensajes... ] } }
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Getters básicos
# =========================================================
sub getBaseDir {
    my ($self) = @_;
    return $self->{base_dir};
}

sub getLZW {
    my ($self) = @_;
    return $self->{lzw};
}

sub getGestorColaboracion {
    my ($self) = @_;
    return $self->{gestor_colaboracion};
}

# =========================================================
# Rutas y carga/guardado
# =========================================================
sub obtenerRutaArchivoUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return undef if !defined $id || $id eq '';

    return $self->{base_dir} . '/' . $id . '.lzw';
}

sub cargarHistorialUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar un usuario válido', undef) if !defined $id || $id eq '';

    my $ruta = $self->obtenerRutaArchivoUsuario($id);

    # Si no existe archivo, se inicializa historial vacío
    if (!-e $ruta) {
        $self->{historiales}{$id} = {
            propietario   => $id,
            conversaciones => {},
        };

        return (1, "No existe historial previo para $id; se inicializó vacío", $self->{historiales}{$id});
    }

    my ($ok_carga, $msg_carga, $texto, $stats) = $self->{lzw}->cargarArchivoLZW($ruta);
    return (0, $msg_carga, undef) if !$ok_carga;

    my $estructura;
    eval {
        my $json = JSON::PP->new->utf8(0);
        $estructura = $json->decode($texto);
    };
    if ($@ || ref($estructura) ne 'HASH') {
        return (0, "No se pudo interpretar el historial JSON de $id", undef);
    }

    $estructura->{propietario} = $id if !defined $estructura->{propietario};
    $estructura->{conversaciones} ||= {};

    # Normalización mínima
    foreach my $otro_id (keys %{ $estructura->{conversaciones} }) {
        if (ref($estructura->{conversaciones}{$otro_id}) ne 'ARRAY') {
            $estructura->{conversaciones}{$otro_id} = [];
        }
    }

    $self->{historiales}{$id} = $estructura;

    return (1, "Historial de $id cargado correctamente", $self->{historiales}{$id});
}

sub guardarHistorialUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar un usuario válido', undef) if !defined $id || $id eq '';

    $self->_asegurar_historial($id);

    my $estructura = $self->{historiales}{$id};

    my $json_texto;
    eval {
        my $json = JSON::PP->new->utf8(0)->canonical(1)->pretty(1);
        $json_texto = $json->encode($estructura);
    };
    if ($@) {
        return (0, "No se pudo serializar el historial de $id", undef);
    }

    my $ruta = $self->obtenerRutaArchivoUsuario($id);
    my ($ok_guardar, $msg_guardar, $stats) = $self->{lzw}->guardarArchivoLZW($ruta, $json_texto);

    return (0, $msg_guardar, undef) if !$ok_guardar;
    return (1, "Historial de $id guardado correctamente", $stats);
}

sub guardarTodosLosHistoriales {
    my ($self) = @_;

    my @ids = sort keys %{ $self->{historiales} };
    my @errores;
    my $guardados = 0;

    foreach my $id (@ids) {
        my ($ok, $msg) = $self->guardarHistorialUsuario($id);
        if ($ok) {
            $guardados++;
        } else {
            push @errores, $msg;
        }
    }

    return {
        ok        => @errores ? 0 : 1,
        guardados => $guardados,
        errores   => \@errores,
        mensaje   => @errores
            ? "Se guardaron $guardados historiales con errores parciales"
            : "Se guardaron $guardados historiales correctamente",
    };
}

sub cerrarSesionUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return (0, 'Debe indicar un usuario válido') if !defined $id || $id eq '';

    my ($ok, $msg) = $self->guardarHistorialUsuario($id);
    delete $self->{historiales}{$id};

    return ($ok, $msg);
}

sub cerrarTodosLosHistoriales {
    my ($self) = @_;

    my $resultado = $self->guardarTodosLosHistoriales();
    $self->{historiales} = {};

    return $resultado;
}

# =========================================================
# Mensajes
# =========================================================
sub enviarMensaje {
    my ($self, $emisor_o_id, $receptor_o_id, $texto, %opts) = @_;

    my $emisor   = $self->_extraer_id($emisor_o_id);
    my $receptor = $self->_extraer_id($receptor_o_id);

    return (0, 'Debe indicar emisor y receptor válidos', undef)
        if !defined $emisor || !defined $receptor || $emisor eq '' || $receptor eq '';

    return (0, 'No se puede enviar un mensaje a sí mismo', undef)
        if $emisor eq $receptor;

    return (0, 'El mensaje no puede estar vacío', undef)
        if !defined $texto || $texto eq '';

    if (!$self->_pueden_comunicarse($emisor, $receptor)) {
        return (0, "Los usuarios $emisor y $receptor no son colaboradores activos", undef);
    }

    $self->_asegurar_historial($emisor);
    $self->_asegurar_historial($receptor);

    my $timestamp = defined $opts{timestamp} && $opts{timestamp} ne ''
        ? $opts{timestamp}
        : $self->_timestamp_actual();

    my $mensaje = {
        id        => $self->_generar_id_mensaje(),
        de        => $emisor,
        para      => $receptor,
        timestamp => $timestamp,
        texto     => $texto,
    };

    push @{ $self->{historiales}{$emisor}{conversaciones}{$receptor} }, { %$mensaje };
    push @{ $self->{historiales}{$receptor}{conversaciones}{$emisor} }, { %$mensaje };

    if ($self->{auto_guardado}) {
        my ($ok1, $msg1) = $self->guardarHistorialUsuario($emisor);
        return (0, "Mensaje agregado, pero no se pudo guardar historial del emisor: $msg1", undef) if !$ok1;

        my ($ok2, $msg2) = $self->guardarHistorialUsuario($receptor);
        return (0, "Mensaje agregado, pero no se pudo guardar historial del receptor: $msg2", undef) if !$ok2;
    }

    return (1, "Mensaje enviado correctamente de $emisor a $receptor", $mensaje);
}

sub obtenerConversacion {
    my ($self, $usuario_o_id, $otro_usuario_o_id) = @_;

    my $id1 = $self->_extraer_id($usuario_o_id);
    my $id2 = $self->_extraer_id($otro_usuario_o_id);

    return [] if !defined $id1 || !defined $id2 || $id1 eq '' || $id2 eq '';

    $self->_asegurar_historial($id1);

    my $conv = $self->{historiales}{$id1}{conversaciones}{$id2};
    return [] if !defined $conv;

    my @lista = @$conv;
    @lista = sort {
           ($a->{timestamp} // '') cmp ($b->{timestamp} // '')
        || ($a->{id} // '') cmp ($b->{id} // '')
    } @lista;

    return \@lista;
}

sub obtenerConversacionComoTexto {
    my ($self, $usuario_o_id, $otro_usuario_o_id) = @_;

    my $conv = $self->obtenerConversacion($usuario_o_id, $otro_usuario_o_id);
    return 'Sin mensajes' if !@$conv;

    my @lineas;
    foreach my $m (@$conv) {
        push @lineas, "[$m->{timestamp}] $m->{de} -> $m->{para}: $m->{texto}";
    }

    return join("\n", @lineas);
}

sub listarConversacionesUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return [] if !defined $id || $id eq '';

    $self->_asegurar_historial($id);

    my @lista;
    foreach my $otro_id (sort keys %{ $self->{historiales}{$id}{conversaciones} }) {
        my $mensajes = $self->{historiales}{$id}{conversaciones}{$otro_id} || [];
        my $cantidad = scalar(@$mensajes);

        my $ultimo = $cantidad > 0 ? $mensajes->[-1] : undef;

        push @lista, {
            con_usuario       => $otro_id,
            cantidad_mensajes => $cantidad,
            ultimo_mensaje    => defined $ultimo ? $ultimo->{texto} : '',
            timestamp_ultimo  => defined $ultimo ? $ultimo->{timestamp} : '',
        };
    }

    @lista = sort {
           ($b->{timestamp_ultimo} // '') cmp ($a->{timestamp_ultimo} // '')
        || ($a->{con_usuario} // '') cmp ($b->{con_usuario} // '')
    } @lista;

    return \@lista;
}

sub eliminarConversacion {
    my ($self, $usuario_o_id, $otro_usuario_o_id) = @_;

    my $id1 = $self->_extraer_id($usuario_o_id);
    my $id2 = $self->_extraer_id($otro_usuario_o_id);

    return (0, 'Debe indicar ambos usuarios') if !defined $id1 || !defined $id2 || $id1 eq '' || $id2 eq '';

    $self->_asegurar_historial($id1);

    if (!exists $self->{historiales}{$id1}{conversaciones}{$id2}) {
        return (0, "No existe conversación entre $id1 y $id2 en el historial de $id1");
    }

    delete $self->{historiales}{$id1}{conversaciones}{$id2};

    if ($self->{auto_guardado}) {
        my ($ok, $msg) = $self->guardarHistorialUsuario($id1);
        return (0, "Conversación eliminada en memoria, pero no se pudo guardar: $msg") if !$ok;
    }

    return (1, "Conversación eliminada del historial de $id1 con $id2");
}

# =========================================================
# Historiales completos
# =========================================================
sub obtenerHistorialUsuario {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return undef if !defined $id || $id eq '';

    $self->_asegurar_historial($id);
    return $self->{historiales}{$id};
}

sub historialUsuarioComoTexto {
    my ($self, $usuario_o_id) = @_;

    my $id = $self->_extraer_id($usuario_o_id);
    return 'Usuario inválido' if !defined $id || $id eq '';

    my $conversaciones = $self->listarConversacionesUsuario($id);
    return "Sin conversaciones para $id" if !@$conversaciones;

    my @bloques;
    foreach my $c (@$conversaciones) {
        push @bloques, "=== Conversación con $c->{con_usuario} ===";
        push @bloques, $self->obtenerConversacionComoTexto($id, $c->{con_usuario});
        push @bloques, '';
    }

    return join("\n", @bloques);
}

# =========================================================
# Helpers internos
# =========================================================
sub _asegurar_historial {
    my ($self, $id) = @_;
    return if exists $self->{historiales}{$id};

    my ($ok, $msg, $hist) = $self->cargarHistorialUsuario($id);

    if (!$ok || !defined $hist) {
        $self->{historiales}{$id} = {
            propietario    => $id,
            conversaciones => {},
        };
    }
}

sub _pueden_comunicarse {
    my ($self, $id1, $id2) = @_;

    return 0 if !defined $self->{gestor_colaboracion};

    if ($self->{gestor_colaboracion}->can('getGrafo')) {
        my $grafo = $self->{gestor_colaboracion}->getGrafo();
        return $grafo->sonColaboradores($id1, $id2) ? 1 : 0 if defined $grafo;
    }

    if ($self->{gestor_colaboracion}->can('sonColaboradores')) {
        return $self->{gestor_colaboracion}->sonColaboradores($id1, $id2) ? 1 : 0;
    }

    return 0;
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

    foreach my $getter (qw(getNumeroColegio numero_colegio getClave clave getCodigo codigo)) {
        if ($usuario->can($getter)) {
            my $valor = eval { $usuario->$getter() };
            return $valor if defined $valor;
        }
    }

    return undef;
}

sub _timestamp_actual {
    my ($self) = @_;
    return strftime('%Y-%m-%d %H:%M:%S', localtime());
}

sub _generar_id_mensaje {
    my ($self) = @_;
    my $base = time();
    my $rand = int(rand(1_000_000));
    return 'MSG-' . $base . '-' . $rand;
}

1;