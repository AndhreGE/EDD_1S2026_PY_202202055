package estructuras::compresion::LZW;

use strict;
use warnings;
use utf8;

use Encode qw(encode decode FB_CROAK);
use File::Path qw(make_path);

sub new {
    my ($class, %args) = @_;

    my $self = {
        firma_archivo => 'LZW1',
    };

    bless $self, $class;
    return $self;
}

# =========================================================
# Compresión LZW
# =========================================================
sub comprimirTexto {
    my ($self, $texto) = @_;

    $texto = '' if !defined $texto;

    # Convertimos a bytes UTF-8 para que el algoritmo trabaje de forma estable
    my $datos = encode('UTF-8', $texto);
    my $bytes_originales = length($datos);

    # Caso especial: texto vacío
    if ($datos eq '') {
        my $stats = {
            bytes_originales   => 0,
            cantidad_codigos   => 0,
            bytes_serializados => length($self->{firma_archivo}),
            factor_compresion  => '0.00',
        };

        return (1, 'Texto vacío comprimido correctamente', [], $stats);
    }

    # Diccionario inicial: 0..255
    my %diccionario;
    for my $i (0 .. 255) {
        $diccionario{pack('C', $i)} = $i;
    }

    my $siguiente_codigo = 256;
    my $w = '';
    my @codigos;

    for (my $i = 0; $i < length($datos); $i++) {
        my $c = substr($datos, $i, 1);
        my $wc = $w . $c;

        if (exists $diccionario{$wc}) {
            $w = $wc;
        }
        else {
            push @codigos, $diccionario{$w} if $w ne '';
            $diccionario{$wc} = $siguiente_codigo++;
            $w = $c;
        }
    }

    push @codigos, $diccionario{$w} if $w ne '';

    my $bytes_serializados = length($self->{firma_archivo}) + (4 * scalar(@codigos));
    my $factor_compresion  = $bytes_originales > 0
        ? sprintf('%.2f', $bytes_serializados / $bytes_originales)
        : '0.00';

    my $stats = {
        bytes_originales   => $bytes_originales,
        cantidad_codigos   => scalar(@codigos),
        bytes_serializados => $bytes_serializados,
        factor_compresion  => $factor_compresion,
    };

    return (1, 'Texto comprimido correctamente', \@codigos, $stats);
}

# =========================================================
# Descompresión LZW
# =========================================================
sub descomprimirCodigos {
    my ($self, $codigos) = @_;

    return (0, 'Debe proporcionar un arreglo de códigos', undef)
        if ref($codigos) ne 'ARRAY';

    if (!@$codigos) {
        return (1, 'Sin códigos para descomprimir', '');
    }

    # Diccionario inicial: 0..255
    my %diccionario;
    for my $i (0 .. 255) {
        $diccionario{$i} = pack('C', $i);
    }

    my @entrada = @$codigos;
    my $primer_codigo = shift @entrada;

    return (0, "Código inicial inválido: $primer_codigo", undef)
        if !exists $diccionario{$primer_codigo};

    my $siguiente_codigo = 256;
    my $w = $diccionario{$primer_codigo};
    my $resultado = $w;

    foreach my $k (@entrada) {
        my $entrada_actual;

        if (exists $diccionario{$k}) {
            $entrada_actual = $diccionario{$k};
        }
        elsif ($k == $siguiente_codigo) {
            $entrada_actual = $w . substr($w, 0, 1);
        }
        else {
            return (0, "Secuencia LZW inválida: código $k fuera del diccionario", undef);
        }

        $resultado .= $entrada_actual;
        $diccionario{$siguiente_codigo++} = $w . substr($entrada_actual, 0, 1);
        $w = $entrada_actual;
    }

    my $texto;
    eval {
        $texto = decode('UTF-8', $resultado, FB_CROAK);
    };

    if ($@) {
        return (0, 'No se pudo decodificar el resultado UTF-8 descomprimido', undef);
    }

    return (1, 'Códigos descomprimidos correctamente', $texto);
}

# =========================================================
# Serialización binaria de códigos
# Formato:
#   4 bytes firma: LZW1
#   resto: enteros unsigned de 32 bits (N*)
# =========================================================
sub serializarCodigos {
    my ($self, $codigos) = @_;

    return (0, 'Debe proporcionar un arreglo de códigos', undef)
        if ref($codigos) ne 'ARRAY';

    my $binario = $self->{firma_archivo} . pack('N*', @$codigos);
    return (1, 'Códigos serializados correctamente', $binario);
}

sub deserializarCodigos {
    my ($self, $binario) = @_;

    return (0, 'Debe proporcionar contenido binario', undef)
        if !defined $binario;

    my $firma = $self->{firma_archivo};
    my $tam_firma = length($firma);

    return (0, 'Archivo demasiado corto o inválido', undef)
        if length($binario) < $tam_firma;

    my $firma_leida = substr($binario, 0, $tam_firma);
    return (0, 'Firma de archivo LZW inválida', undef)
        if $firma_leida ne $firma;

    my $resto = substr($binario, $tam_firma);
    my @codigos = length($resto) ? unpack('N*', $resto) : ();

    return (1, 'Códigos deserializados correctamente', \@codigos);
}

# =========================================================
# Guardar / cargar archivo .lzw
# =========================================================
sub guardarArchivoLZW {
    my ($self, $ruta_archivo, $texto) = @_;

    return (0, 'Debe indicar la ruta del archivo', undef)
        if !defined $ruta_archivo || $ruta_archivo eq '';

    my ($ok_comp, $msg_comp, $codigos, $stats) = $self->comprimirTexto($texto);
    return (0, $msg_comp, undef) if !$ok_comp;

    my ($ok_ser, $msg_ser, $binario) = $self->serializarCodigos($codigos);
    return (0, $msg_ser, undef) if !$ok_ser;

    $self->_asegurar_directorio($ruta_archivo);

    open(my $fh, '>:raw', $ruta_archivo)
        or return (0, "No se pudo crear el archivo $ruta_archivo", undef);

    print $fh $binario;
    close($fh);

    $stats->{ruta_archivo} = $ruta_archivo;
    $stats->{bytes_archivo} = -s $ruta_archivo;

    return (1, "Archivo LZW guardado correctamente en $ruta_archivo", $stats);
}

sub cargarArchivoLZW {
    my ($self, $ruta_archivo) = @_;

    return (0, 'Debe indicar la ruta del archivo', undef, undef)
        if !defined $ruta_archivo || $ruta_archivo eq '';

    return (0, "El archivo $ruta_archivo no existe", undef, undef)
        if !-e $ruta_archivo;

    open(my $fh, '<:raw', $ruta_archivo)
        or return (0, "No se pudo abrir el archivo $ruta_archivo", undef, undef);

    local $/;
    my $binario = <$fh>;
    close($fh);

    my ($ok_des, $msg_des, $codigos) = $self->deserializarCodigos($binario);
    return (0, $msg_des, undef, undef) if !$ok_des;

    my ($ok_txt, $msg_txt, $texto) = $self->descomprimirCodigos($codigos);
    return (0, $msg_txt, undef, undef) if !$ok_txt;

    my $stats = {
        ruta_archivo      => $ruta_archivo,
        bytes_archivo     => length($binario),
        cantidad_codigos  => scalar(@$codigos),
        bytes_reconstruidos => length(encode('UTF-8', $texto)),
    };

    return (1, "Archivo LZW cargado correctamente desde $ruta_archivo", $texto, $stats);
}

# =========================================================
# Método de conveniencia
# =========================================================
sub probarIntegridadTexto {
    my ($self, $texto_original) = @_;

    my ($ok_comp, $msg_comp, $codigos, $stats_comp) = $self->comprimirTexto($texto_original);
    return (0, $msg_comp, undef) if !$ok_comp;

    my ($ok_desc, $msg_desc, $texto_recuperado) = $self->descomprimirCodigos($codigos);
    return (0, $msg_desc, undef) if !$ok_desc;

    my $iguales = defined $texto_original && defined $texto_recuperado && $texto_original eq $texto_recuperado ? 1 : 0;

    return ($iguales, $iguales ? 'Integridad verificada correctamente' : 'El texto recuperado no coincide', {
        texto_original   => $texto_original,
        texto_recuperado => $texto_recuperado,
        stats            => $stats_comp,
    });
}

# =========================================================
# Helpers internos
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