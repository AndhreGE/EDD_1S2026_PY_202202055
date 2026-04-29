use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use modelos::PersonalMedico;
use estructuras::modulos::GestorUsuarios;

print "=== INICIO PRUEBA GESTOR USUARIOS + HASH ===\n\n";

# =========================================================
# Crear gestor de usuarios
# =========================================================
my $gestor = estructuras::modulos::GestorUsuarios->new();

# =========================================================
# Crear usuarios de prueba
# =========================================================
my $u1 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-1001',
    nombre_completo => 'Dra. Ana Morales',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Medicina General',
    contrasena      => 'ana123',
);

my $u2 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-1002',
    nombre_completo => 'Dr. Diego Castillo',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Cardiologia',
    contrasena      => 'diego123',
);

my $u3 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-2001',
    nombre_completo => 'Dr. Juan Perez',
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Cirugia',
    contrasena      => 'juan123',
);

my $u4 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-3001',
    nombre_completo => 'Lic. Sofia Herrera',
    tipo_usuario    => 'TIPO-03',
    departamento    => 'DEP-LAB',
    especialidad    => 'Laboratorio',
    contrasena      => 'sofia123',
);

my $u5 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-4001',
    nombre_completo => 'Dr. Carlos Ramirez',
    tipo_usuario    => 'TIPO-04',
    departamento    => 'DEP-FAR',
    especialidad    => 'Farmacia Clinica',
    contrasena      => 'carlos123',
);

# =========================================================
# Insertar usuarios
# =========================================================
print "=== REGISTRO DE USUARIOS ===\n";
foreach my $u ($u1, $u2, $u3, $u4, $u5) {
    my ($ok, $msg) = $gestor->registrarUsuario($u);
    print "$msg\n";
}
print "\n";

# =========================================================
# Mostrar usuarios desde AVL
# =========================================================
print "=== USUARIOS EN AVL (INORDEN) ===\n";
my $usuarios_avl = $gestor->listarUsuarios();
if (@$usuarios_avl) {
    foreach my $u (@$usuarios_avl) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios en AVL\n";
}
print "\n";

# =========================================================
# Mostrar usuarios por tipo desde HASH
# =========================================================
print "=== USUARIOS TIPO-01 DESDE HASH ===\n";
my $tipo1 = $gestor->obtenerUsuariosPorTipo('TIPO-01');
if (@$tipo1) {
    foreach my $u (@$tipo1) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios TIPO-01\n";
}
print "\n";

print "=== USUARIOS TIPO-02 DESDE HASH ===\n";
my $tipo2 = $gestor->obtenerUsuariosPorTipo('TIPO-02');
if (@$tipo2) {
    foreach my $u (@$tipo2) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios TIPO-02\n";
}
print "\n";

# =========================================================
# Cantidades por tipo
# =========================================================
print "=== CANTIDAD DE USUARIOS POR TIPO ===\n";
foreach my $tipo (qw(TIPO-01 TIPO-02 TIPO-03 TIPO-04 TIPO-05)) {
    my $cantidad = $gestor->cantidadUsuariosPorTipo($tipo);
    print "$tipo: $cantidad\n";
}
print "\n";

# =========================================================
# Búsqueda de usuario
# =========================================================
print "=== BÚSQUEDA EN AVL ===\n";
my $buscado = $gestor->buscarUsuario('COL-2001');
if ($buscado) {
    print "Encontrado: " . $buscado->toString() . "\n";
} else {
    print "No se encontró COL-2001\n";
}
print "\n";

# =========================================================
# Autenticación
# =========================================================
print "=== AUTENTICACIÓN ===\n";
my ($ok_auth, $msg_auth, $usuario_auth) = $gestor->autenticarUsuario('COL-1001', 'ana123');
print "$msg_auth\n";
if ($ok_auth && defined $usuario_auth) {
    print "Usuario autenticado: " . $usuario_auth->toString() . "\n";
}
print "\n";

# =========================================================
# Resumen general
# =========================================================
print "=== RESUMEN GENERAL ===\n";
my $resumen = $gestor->obtenerResumen();

print "Total usuarios: $resumen->{total_usuarios}\n";

print "--- Por departamento ---\n";
foreach my $dep (sort keys %{ $resumen->{por_departamento} }) {
    print "$dep: $resumen->{por_departamento}{$dep}\n";
}

print "--- Por tipo ---\n";
foreach my $tipo (sort keys %{ $resumen->{por_tipo} }) {
    print "$tipo: $resumen->{por_tipo}{$tipo}\n";
}
print "\n";

# =========================================================
# Resumen hash
# =========================================================
print "=== RESUMEN HASH ===\n";
my $hash_resumen = $gestor->obtenerResumenHash();

print "Total usuarios hash: $hash_resumen->{total_usuarios}\n";
print "Buckets totales: $hash_resumen->{buckets_totales}\n";
print "Buckets utilizados: $hash_resumen->{buckets_utilizados}\n";
print "Factor de carga: $hash_resumen->{factor_carga}\n";
print "Total colisiones: $hash_resumen->{total_colisiones}\n";

print "--- Usuarios por tipo (hash) ---\n";
foreach my $tipo (sort keys %{ $hash_resumen->{por_tipo} }) {
    print "$tipo: $hash_resumen->{por_tipo}{$tipo}\n";
}
print "\n";

# =========================================================
# Mostrar tabla hash como texto
# =========================================================
print "=== TABLA HASH DESDE GESTOR ===\n";
print $gestor->tablaHashComoTexto() . "\n\n";

# =========================================================
# Eliminar usuario y verificar sincronización AVL + HASH
# =========================================================
print "=== ELIMINACIÓN DE USUARIO COL-3001 ===\n";
my ($ok_del, $msg_del) = $gestor->eliminarUsuario('COL-3001');
print "$msg_del\n\n";

print "=== USUARIOS EN AVL DESPUÉS DE ELIMINAR ===\n";
my $usuarios_avl2 = $gestor->listarUsuarios();
if (@$usuarios_avl2) {
    foreach my $u (@$usuarios_avl2) {
        print $u->toString() . "\n";
    }
} else {
    print "No hay usuarios en AVL\n";
}
print "\n";

print "=== TABLA HASH DESPUÉS DE ELIMINAR ===\n";
print $gestor->tablaHashComoTexto() . "\n\n";

print "=== CANTIDADES POR TIPO DESPUÉS DE ELIMINAR ===\n";
foreach my $tipo (qw(TIPO-01 TIPO-02 TIPO-03 TIPO-04 TIPO-05)) {
    my $cantidad = $gestor->cantidadUsuariosPorTipo($tipo);
    print "$tipo: $cantidad\n";
}
print "\n";

# =========================================================
# Generar reportes AVL y HASH
# =========================================================
print "=== GENERANDO REPORTES ===\n";

my ($ok_rep1, $msg_rep1) = $gestor->generarReporteUsuarios(
    "$FindBin::Bin/../reportesdot/avl_personal_fase3.dot",
    "$FindBin::Bin/../reportesdot/avl_personal_fase3.png"
);
print "$msg_rep1\n";

my ($ok_rep2, $msg_rep2) = $gestor->generarReporteTablaHash(
    "$FindBin::Bin/../reportesdot/tabla_hash_personal_fase3.dot",
    "$FindBin::Bin/../reportesdot/tabla_hash_personal_fase3.png"
);
print "$msg_rep2\n\n";

print "=== FIN PRUEBA GESTOR USUARIOS + HASH ===\n";