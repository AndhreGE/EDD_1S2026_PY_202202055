use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use estructuras::compresion::LZW;

print "=== INICIO PRUEBA LZW ===\n\n";

my $lzw = estructuras::compresion::LZW->new();

# =========================================================
# Texto de prueba tipo historial de chat
# =========================================================
my $texto = join("\n",
    "COL-1001|COL-2001|2026-05-01 08:00:00|Hola doctor, necesito apoyo con el paciente de la sala 3.",
    "COL-2001|COL-1001|2026-05-01 08:01:10|Claro, voy en camino.",
    "COL-1001|COL-2001|2026-05-01 08:02:03|También necesito revisión de medicamentos.",
    "COL-2001|COL-1001|2026-05-01 08:03:22|Entendido, llevo el expediente.",
    "COL-1001|COL-2001|2026-05-01 08:04:10|Gracias.",
);

print "=== TEXTO ORIGINAL ===\n";
print "$texto\n\n";

# =========================================================
# Compresión
# =========================================================
print "=== COMPRESIÓN ===\n";
my ($ok_comp, $msg_comp, $codigos, $stats_comp) = $lzw->comprimirTexto($texto);
print "$msg_comp\n";

if ($ok_comp) {
    print "Bytes originales: $stats_comp->{bytes_originales}\n";
    print "Cantidad de códigos: $stats_comp->{cantidad_codigos}\n";
    print "Bytes serializados estimados: $stats_comp->{bytes_serializados}\n";
    print "Factor de compresión: $stats_comp->{factor_compresion}\n";

    print "Primeros códigos: ";
    my $limite = @$codigos < 20 ? scalar(@$codigos) : 20;
    for (my $i = 0; $i < $limite; $i++) {
        print $codigos->[$i];
        print ", " if $i < $limite - 1;
    }
    print "\n";
}
print "\n";

# =========================================================
# Descompresión
# =========================================================
print "=== DESCOMPRESIÓN ===\n";
my ($ok_desc, $msg_desc, $texto_recuperado) = $lzw->descomprimirCodigos($codigos);
print "$msg_desc\n";

if ($ok_desc) {
    print "Texto recuperado:\n";
    print "$texto_recuperado\n";
}
print "\n";

# =========================================================
# Verificación de integridad
# =========================================================
print "=== VERIFICACIÓN DE INTEGRIDAD ===\n";
my ($ok_int, $msg_int, $info_int) = $lzw->probarIntegridadTexto($texto);
print "$msg_int\n";
print "¿Coincide exactamente?: " . ($ok_int ? "SI" : "NO") . "\n\n";

# =========================================================
# Guardar archivo .lzw
# =========================================================
print "=== GUARDAR ARCHIVO LZW ===\n";
my $ruta_archivo = "$FindBin::Bin/../chats/prueba_chat_COL-1001.lzw";

my ($ok_guardar, $msg_guardar, $stats_guardar) = $lzw->guardarArchivoLZW($ruta_archivo, $texto);
print "$msg_guardar\n";

if ($ok_guardar) {
    print "Ruta: $stats_guardar->{ruta_archivo}\n";
    print "Bytes del archivo: $stats_guardar->{bytes_archivo}\n";
}
print "\n";

# =========================================================
# Cargar archivo .lzw
# =========================================================
print "=== CARGAR ARCHIVO LZW ===\n";
my ($ok_cargar, $msg_cargar, $texto_cargado, $stats_cargar) = $lzw->cargarArchivoLZW($ruta_archivo);
print "$msg_cargar\n";

if ($ok_cargar) {
    print "Bytes del archivo leído: $stats_cargar->{bytes_archivo}\n";
    print "Cantidad de códigos recuperados: $stats_cargar->{cantidad_codigos}\n";
    print "Bytes reconstruidos: $stats_cargar->{bytes_reconstruidos}\n";

    print "\nTexto cargado desde archivo:\n";
    print "$texto_cargado\n";
}
print "\n";

# =========================================================
# Validar coincidencia final
# =========================================================
print "=== VALIDACIÓN FINAL ===\n";
if (defined $texto_cargado && $texto_cargado eq $texto) {
    print "El texto cargado desde .lzw coincide exactamente con el original\n";
} else {
    print "El texto cargado NO coincide con el original\n";
}
print "\n";

# =========================================================
# Caso vacío
# =========================================================
print "=== PRUEBA CON TEXTO VACÍO ===\n";
my ($ok_vacio, $msg_vacio, $codigos_vacios, $stats_vacios) = $lzw->comprimirTexto('');
print "$msg_vacio\n";
print "Códigos generados: " . scalar(@$codigos_vacios) . "\n";

my ($ok_vacio_desc, $msg_vacio_desc, $texto_vacio) = $lzw->descomprimirCodigos($codigos_vacios);
print "$msg_vacio_desc\n";
print "Texto recuperado vacío: [" . $texto_vacio . "]\n\n";

print "=== FIN PRUEBA LZW ===\n";