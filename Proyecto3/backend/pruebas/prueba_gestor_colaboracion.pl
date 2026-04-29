use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use modelos::PersonalMedico;
use estructuras::modulos::GestorColaboracion;

print "=== INICIO PRUEBA GESTOR COLABORACION ===\n\n";

# =========================================================
# Crear gestor
# =========================================================
my $gestor = estructuras::modulos::GestorColaboracion->new();

# =========================================================
# Crear usuarios de prueba
# =========================================================
my $u1 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-100',
    nombre_completo => 'Dra. Ana Morales',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Medicina General',
    contrasena      => 'ana123',
);

my $u2 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-200',
    nombre_completo => 'Dr. Juan Perez',
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Cirugia',
    contrasena      => 'juan123',
);

my $u3 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-300',
    nombre_completo => 'Dr. Carlos Ramirez',
    tipo_usuario    => 'TIPO-04',
    departamento    => 'DEP-FAR',
    especialidad    => 'Farmacia Clinica',
    contrasena      => 'carlos123',
);

my $u4 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-400',
    nombre_completo => 'Lic. Sofia Herrera',
    tipo_usuario    => 'TIPO-03',
    departamento    => 'DEP-LAB',
    especialidad    => 'Laboratorio',
    contrasena      => 'sofia123',
);

my $u5 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-500',
    nombre_completo => 'Dr. Diego Castillo',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'SIN-DEP',
    especialidad    => 'Cardiologia',
    contrasena      => 'diego123',
);

# =========================================================
# Agregar usuarios al grafo
# =========================================================
print "=== AGREGANDO USUARIOS AL GRAFO ===\n";

foreach my $u ($u1, $u2, $u3, $u4, $u5) {
    my ($ok, $msg) = $gestor->agregarUsuarioAlGrafo($u);
    print "$msg\n";
}

print "\n";

# =========================================================
# Crear colaboraciones activas
# Estructura pensada:
# u1 conectado a u2 y u3
# u4 conectado a u2 y u3
# entonces u4 debe sugerirse a u1 (2 comunes)
# =========================================================
print "=== REGISTRANDO COLABORACIONES ACTIVAS ===\n";

my @activas = (
    ['COL-100', 'COL-200'],
    ['COL-100', 'COL-300'],
    ['COL-200', 'COL-300'],
    ['COL-200', 'COL-400'],
    ['COL-300', 'COL-400'],
);

foreach my $par (@activas) {
    my ($ok, $msg) = $gestor->registrarColaboracionActiva($par->[0], $par->[1]);
    print "$msg\n";
}

print "\n";

# =========================================================
# Ver colaboraciones activas
# =========================================================
print "=== COLABORACIONES ACTIVAS ===\n";
print $gestor->colaboracionesActivasComoTexto() . "\n\n";

# =========================================================
# Usuarios aislados
# =========================================================
print "=== USUARIOS AISLADOS ===\n";
my $aislados = $gestor->obtenerUsuariosAislados();

if (@$aislados) {
    foreach my $u (@$aislados) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios aislados\n";
}

print "\n";

# =========================================================
# Usuarios sin departamento
# =========================================================
print "=== USUARIOS SIN DEPARTAMENTO ===\n";
my $sin_dep = $gestor->obtenerUsuariosSinDepartamento();

if (@$sin_dep) {
    foreach my $u (@$sin_dep) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios sin departamento\n";
}

print "\n";

# =========================================================
# Sugerencias de colaboracion
# =========================================================
print "=== SUGERENCIAS PARA COL-100 ===\n";
print $gestor->sugerenciasComoTexto('COL-100', 2) . "\n\n";

# =========================================================
# Solicitudes pendientes
# =========================================================
print "=== ENVIANDO SOLICITUDES ===\n";

my ($ok1, $msg1) = $gestor->enviarSolicitud('COL-500', 'COL-100');
print "$msg1\n";

my ($ok2, $msg2) = $gestor->enviarSolicitud('COL-500', 'COL-400');
print "$msg2\n";

print "\n=== SOLICITUDES PENDIENTES ===\n";
print $gestor->solicitudesPendientesComoTexto() . "\n\n";

# =========================================================
# Aceptar y rechazar solicitudes
# =========================================================
print "=== ACEPTANDO SOLICITUD COL-500 -> COL-100 ===\n";
my ($ok3, $msg3) = $gestor->aceptarSolicitud('COL-500', 'COL-100');
print "$msg3\n\n";

print "=== RECHAZANDO SOLICITUD COL-500 -> COL-400 ===\n";
my ($ok4, $msg4) = $gestor->rechazarSolicitud('COL-500', 'COL-400');
print "$msg4\n\n";

print "=== SOLICITUDES PENDIENTES DESPUES DE PROCESAR ===\n";
print $gestor->solicitudesPendientesComoTexto() . "\n\n";

print "=== COLABORACIONES ACTIVAS DESPUES DE ACEPTAR ===\n";
print $gestor->colaboracionesActivasComoTexto() . "\n\n";

# =========================================================
# Reasignar departamento
# =========================================================
print "=== ASIGNANDO DEPARTAMENTO A COL-500 ===\n";
my ($ok5, $msg5) = $gestor->asignarDepartamento('COL-500', 'DEP-MED');
print "$msg5\n\n";

print "=== USUARIOS SIN DEPARTAMENTO DESPUES DE ASIGNAR ===\n";
my $sin_dep2 = $gestor->obtenerUsuariosSinDepartamento();

if (@$sin_dep2) {
    foreach my $u (@$sin_dep2) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios sin departamento\n";
}

print "\n";

# =========================================================
# Resumen general
# =========================================================
print "=== RESUMEN DE LA RED ===\n";
my $resumen = $gestor->obtenerResumenRed();

print "Usuarios: $resumen->{usuarios}\n";
print "Colaboraciones activas: $resumen->{colaboraciones_activas}\n";
print "Solicitudes pendientes: $resumen->{solicitudes_pendientes}\n";
print "Solicitudes rechazadas: $resumen->{solicitudes_rechazadas}\n";
print "Usuarios aislados: $resumen->{usuarios_aislados}\n";
print "Usuarios sin departamento: $resumen->{sin_departamento}\n\n";

# =========================================================
# Lista de adyacencia
# =========================================================
print "=== LISTA DE ADYACENCIA ===\n";
print $gestor->getGrafo()->listaAdyacenciaComoTexto() . "\n\n";

# =========================================================
# Generar reportes
# =========================================================
print "=== GENERANDO REPORTES GRAPHVIZ ===\n";

my ($okg, $msgg) = $gestor->generarReporteGrafo(
    "$FindBin::Bin/../reportesdot/grafo_colaboracion.dot",
    "$FindBin::Bin/../reportesdot/grafo_colaboracion.png"
);
print "$msgg\n";

my ($okl, $msgl) = $gestor->generarReporteListaAdyacencia(
    "$FindBin::Bin/../reportesdot/lista_adyacencia.dot",
    "$FindBin::Bin/../reportesdot/lista_adyacencia.png"
);
print "$msgl\n\n";

print "=== FIN PRUEBA GESTOR COLABORACION ===\n";