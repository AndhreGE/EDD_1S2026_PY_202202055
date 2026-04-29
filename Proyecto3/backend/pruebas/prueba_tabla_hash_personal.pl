use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use modelos::PersonalMedico;
use estructuras::hash::TablaHashPersonal;

print "=== INICIO PRUEBA TABLA HASH PERSONAL ===\n\n";

# =========================================================
# Crear tabla hash
# =========================================================
my $tabla = estructuras::hash::TablaHashPersonal->new();

# =========================================================
# Crear usuarios de prueba
# =========================================================
my $u1 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-101',
    nombre_completo => 'Dra. Ana Morales',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Medicina General',
    contrasena      => 'ana123',
);

my $u2 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-102',
    nombre_completo => 'Dr. Diego Castillo',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Cardiologia',
    contrasena      => 'diego123',
);

my $u3 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-201',
    nombre_completo => 'Dr. Juan Perez',
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Cirugia',
    contrasena      => 'juan123',
);

my $u4 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-301',
    nombre_completo => 'Lic. Sofia Herrera',
    tipo_usuario    => 'TIPO-03',
    departamento    => 'DEP-LAB',
    especialidad    => 'Laboratorio',
    contrasena      => 'sofia123',
);

my $u5 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-401',
    nombre_completo => 'Dr. Carlos Ramirez',
    tipo_usuario    => 'TIPO-04',
    departamento    => 'DEP-FAR',
    especialidad    => 'Farmacia Clinica',
    contrasena      => 'carlos123',
);

my $u6 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-501',
    nombre_completo => 'Lic. Elena Gomez',
    tipo_usuario    => 'TIPO-05',
    departamento    => 'DEP-ADM',
    especialidad    => 'Administracion',
    contrasena      => 'elena123',
);

# =========================================================
# Inserción
# =========================================================
print "=== INSERTANDO USUARIOS ===\n";
foreach my $u ($u1, $u2, $u3, $u4, $u5, $u6) {
    my ($ok, $msg) = $tabla->insertarUsuario($u);
    print "$msg\n";
}
print "\n";

# =========================================================
# Mostrar tabla completa
# =========================================================
print "=== TABLA HASH COMPLETA ===\n";
print $tabla->tablaComoTexto() . "\n\n";

# =========================================================
# Consultas por tipo
# =========================================================
print "=== USUARIOS TIPO-01 ===\n";
my $tipo1 = $tabla->obtenerUsuariosPorTipo('TIPO-01');
if (@$tipo1) {
    foreach my $u (@$tipo1) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios TIPO-01\n";
}
print "\n";

print "=== USUARIOS TIPO-02 ===\n";
my $tipo2 = $tabla->obtenerUsuariosPorTipo('TIPO-02');
if (@$tipo2) {
    foreach my $u (@$tipo2) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios TIPO-02\n";
}
print "\n";

# =========================================================
# Conteos por tipo
# =========================================================
print "=== CANTIDAD POR TIPO ===\n";
foreach my $tipo (@{ $tabla->obtenerTiposValidos() }) {
    my $cantidad = $tabla->cantidadPorTipo($tipo);
    print "$tipo: $cantidad\n";
}
print "\n";

# =========================================================
# Búsqueda específica
# =========================================================
print "=== BUSCANDO COL-102 EN TIPO-01 ===\n";
my $encontrado = $tabla->buscarUsuarioEnTipo('TIPO-01', 'COL-102');
if ($encontrado) {
    print "Encontrado: " . $encontrado->toString() . "\n";
} else {
    print "No encontrado\n";
}
print "\n";

print "=== BUSCANDO COL-102 EN TIPO-03 ===\n";
my $no_encontrado = $tabla->buscarUsuarioEnTipo('TIPO-03', 'COL-102');
if ($no_encontrado) {
    print "Encontrado: " . $no_encontrado->toString() . "\n";
} else {
    print "No encontrado\n";
}
print "\n";

# =========================================================
# Eliminación
# =========================================================
print "=== ELIMINANDO COL-301 ===\n";
my ($ok_del, $msg_del) = $tabla->eliminarUsuario('COL-301', 'TIPO-03');
print "$msg_del\n\n";

print "=== TABLA HASH DESPUÉS DE ELIMINAR ===\n";
print $tabla->tablaComoTexto() . "\n\n";

# =========================================================
# Resumen hash
# =========================================================
print "=== RESUMEN HASH ===\n";
my $resumen = $tabla->obtenerResumenHash();

print "Total usuarios: $resumen->{total_usuarios}\n";
print "Buckets totales: $resumen->{buckets_totales}\n";
print "Buckets utilizados: $resumen->{buckets_utilizados}\n";
print "Factor de carga: $resumen->{factor_carga}\n";
print "Total colisiones: $resumen->{total_colisiones}\n";

print "\n--- Usuarios por tipo ---\n";
foreach my $tipo (sort keys %{ $resumen->{por_tipo} }) {
    print "$tipo: $resumen->{por_tipo}{$tipo}\n";
}

print "\n--- Colisiones por tipo ---\n";
foreach my $tipo (sort keys %{ $resumen->{colisiones} }) {
    print "$tipo: $resumen->{colisiones}{$tipo}\n";
}
print "\n";

# =========================================================
# Reporte Graphviz
# =========================================================
print "=== GENERANDO REPORTE GRAPHVIZ ===\n";
my ($ok_rep, $msg_rep) = $tabla->generarPNG(
    "$FindBin::Bin/../reportesdot/tabla_hash_personal.dot",
    "$FindBin::Bin/../reportesdot/tabla_hash_personal.png"
);
print "$msg_rep\n\n";

print "=== FIN PRUEBA TABLA HASH PERSONAL ===\n";