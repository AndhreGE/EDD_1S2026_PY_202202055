use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use modelos::PersonalMedico;
use estructuras::modulos::GestorColaboracion;
use estructuras::modulos::GestorMensajeria;

print "=== INICIO PRUEBA GESTOR MENSAJERIA ===\n\n";

# =========================================================
# Crear usuarios de prueba
# =========================================================
my $u1 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-7001',
    nombre_completo => 'Dra. Ana Morales',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Medicina General',
    contrasena      => 'ana123',
);

my $u2 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-7002',
    nombre_completo => 'Dr. Juan Perez',
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Cirugia',
    contrasena      => 'juan123',
);

my $u3 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-7003',
    nombre_completo => 'Lic. Sofia Herrera',
    tipo_usuario    => 'TIPO-03',
    departamento    => 'DEP-LAB',
    especialidad    => 'Laboratorio',
    contrasena      => 'sofia123',
);

# =========================================================
# Crear gestor de colaboración y registrar usuarios
# =========================================================
my $gestor_colab = estructuras::modulos::GestorColaboracion->new();

$gestor_colab->agregarUsuarioAlGrafo($u1);
$gestor_colab->agregarUsuarioAlGrafo($u2);
$gestor_colab->agregarUsuarioAlGrafo($u3);

# Solo COL-7001 y COL-7002 serán colaboradores
$gestor_colab->registrarColaboracionActiva('COL-7001', 'COL-7002');

# =========================================================
# Crear gestor de mensajería
# =========================================================
my $gestor_msg = estructuras::modulos::GestorMensajeria->new(
    gestor_colaboracion => $gestor_colab,
    base_dir            => "$FindBin::Bin/../chats",
    auto_guardado       => 1,
);

# Limpiar archivos previos de prueba si existen
unlink "$FindBin::Bin/../chats/COL-7001.lzw" if -e "$FindBin::Bin/../chats/COL-7001.lzw";
unlink "$FindBin::Bin/../chats/COL-7002.lzw" if -e "$FindBin::Bin/../chats/COL-7002.lzw";
unlink "$FindBin::Bin/../chats/COL-7003.lzw" if -e "$FindBin::Bin/../chats/COL-7003.lzw";

print "=== CARGA INICIAL DE HISTORIALES ===\n";
my ($ok_h1, $msg_h1) = $gestor_msg->cargarHistorialUsuario('COL-7001');
print "$msg_h1\n";
my ($ok_h2, $msg_h2) = $gestor_msg->cargarHistorialUsuario('COL-7002');
print "$msg_h2\n";
my ($ok_h3, $msg_h3) = $gestor_msg->cargarHistorialUsuario('COL-7003');
print "$msg_h3\n\n";

# =========================================================
# Envío de mensajes válidos
# =========================================================
print "=== ENVÍO DE MENSAJES ENTRE COLABORADORES ===\n";

my ($ok_m1, $msg_m1, $m1) = $gestor_msg->enviarMensaje(
    'COL-7001', 'COL-7002',
    'Hola doctor, ¿puede apoyarme con el paciente de la sala 4?',
    timestamp => '2026-05-02 08:00:00'
);
print "$msg_m1\n";

my ($ok_m2, $msg_m2, $m2) = $gestor_msg->enviarMensaje(
    'COL-7002', 'COL-7001',
    'Sí, voy en camino.',
    timestamp => '2026-05-02 08:01:10'
);
print "$msg_m2\n";

my ($ok_m3, $msg_m3, $m3) = $gestor_msg->enviarMensaje(
    'COL-7001', 'COL-7002',
    'Gracias, también lleve el expediente.',
    timestamp => '2026-05-02 08:02:30'
);
print "$msg_m3\n\n";

# =========================================================
# Intento inválido: no colaboradores
# =========================================================
print "=== INTENTO DE MENSAJE A NO COLABORADOR ===\n";
my ($ok_inv, $msg_inv) = $gestor_msg->enviarMensaje(
    'COL-7001', 'COL-7003',
    'Este mensaje no debería enviarse'
);
print "$msg_inv\n\n";

# =========================================================
# Conversación de un lado
# =========================================================
print "=== CONVERSACIÓN DESDE COL-7001 CON COL-7002 ===\n";
print $gestor_msg->obtenerConversacionComoTexto('COL-7001', 'COL-7002') . "\n\n";

print "=== CONVERSACIÓN DESDE COL-7002 CON COL-7001 ===\n";
print $gestor_msg->obtenerConversacionComoTexto('COL-7002', 'COL-7001') . "\n\n";

# =========================================================
# Listar conversaciones por usuario
# =========================================================
print "=== LISTADO DE CONVERSACIONES DE COL-7001 ===\n";
my $conv1 = $gestor_msg->listarConversacionesUsuario('COL-7001');
if (@$conv1) {
    foreach my $c (@$conv1) {
        print "Con: $c->{con_usuario} | mensajes: $c->{cantidad_mensajes} | último: $c->{ultimo_mensaje}\n";
    }
} else {
    print "Sin conversaciones\n";
}
print "\n";

# =========================================================
# Verificar archivos creados
# =========================================================
print "=== ARCHIVOS LZW GENERADOS ===\n";
my $ruta1 = $gestor_msg->obtenerRutaArchivoUsuario('COL-7001');
my $ruta2 = $gestor_msg->obtenerRutaArchivoUsuario('COL-7002');
my $ruta3 = $gestor_msg->obtenerRutaArchivoUsuario('COL-7003');

print "COL-7001: " . (-e $ruta1 ? "EXISTE" : "NO EXISTE") . " -> $ruta1\n";
print "COL-7002: " . (-e $ruta2 ? "EXISTE" : "NO EXISTE") . " -> $ruta2\n";
print "COL-7003: " . (-e $ruta3 ? "EXISTE" : "NO EXISTE") . " -> $ruta3\n";
print "\n";

# =========================================================
# Cerrar historial y recargar desde disco
# =========================================================
print "=== CERRANDO SESIONES Y RECARGANDO ===\n";
$gestor_msg->cerrarTodosLosHistoriales();

my $gestor_msg_2 = estructuras::modulos::GestorMensajeria->new(
    gestor_colaboracion => $gestor_colab,
    base_dir            => "$FindBin::Bin/../chats",
    auto_guardado       => 1,
);

my ($ok_r1, $msg_r1) = $gestor_msg_2->cargarHistorialUsuario('COL-7001');
print "$msg_r1\n";
my ($ok_r2, $msg_r2) = $gestor_msg_2->cargarHistorialUsuario('COL-7002');
print "$msg_r2\n\n";

print "=== CONVERSACIÓN RECUPERADA DESDE ARCHIVO (.lzw) ===\n";
print $gestor_msg_2->obtenerConversacionComoTexto('COL-7001', 'COL-7002') . "\n\n";

# =========================================================
# Eliminar conversación de un solo lado
# =========================================================
print "=== ELIMINAR CONVERSACIÓN DEL HISTORIAL DE COL-7001 ===\n";
my ($ok_elim, $msg_elim) = $gestor_msg_2->eliminarConversacion('COL-7001', 'COL-7002');
print "$msg_elim\n\n";

print "=== HISTORIAL DE COL-7001 DESPUÉS DE ELIMINAR ===\n";
print $gestor_msg_2->historialUsuarioComoTexto('COL-7001') . "\n\n";

print "=== HISTORIAL DE COL-7002 SE MANTIENE ===\n";
print $gestor_msg_2->historialUsuarioComoTexto('COL-7002') . "\n\n";

print "=== FIN PRUEBA GESTOR MENSAJERIA ===\n";