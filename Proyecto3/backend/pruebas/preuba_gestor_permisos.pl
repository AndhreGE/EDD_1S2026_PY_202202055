use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use estructuras::modulos::GestorPermisos;
use modelos::PersonalMedico;

my $gestor = estructuras::modulos::GestorPermisos->new();

my $u1 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-100',
    nombre_completo => 'Lic. Ana Morales',
    tipo_usuario    => 'TIPO-03',
    departamento    => 'DEP-LAB',
    especialidad    => '',
    contrasena      => 'lab123'
);

my $u2 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-200',
    nombre_completo => 'Dr. Juan Perez',
    tipo_usuario    => 'TIPO-04',
    departamento    => 'DEP-FAR',
    especialidad    => 'Farmacia Clinica',
    contrasena      => 'far123'
);

print "=== PERMISOS U1 ===\n";
print $gestor->describirPermisos($u1) . "\n\n";

print "=== PERMISOS U2 ===\n";
print $gestor->describirPermisos($u2) . "\n\n";

print "=== VALIDACIONES ===\n";

print "U1 puede consultar EQUIPO: "
    . ($gestor->puedeConsultarTipo($u1, 'EQUIPO') ? "SI" : "NO") . "\n";

print "U1 puede solicitar MEDICAMENTO: "
    . ($gestor->puedeSolicitarTipo($u1, 'MEDICAMENTO') ? "SI" : "NO") . "\n";

print "U1 puede solicitar SUMINISTRO: "
    . ($gestor->puedeSolicitarTipo($u1, 'SUMINISTRO') ? "SI" : "NO") . "\n";

print "U2 puede consultar MEDICAMENTO: "
    . ($gestor->puedeConsultarTipo($u2, 'MEDICAMENTO') ? "SI" : "NO") . "\n";

print "U2 puede solicitar EQUIPO: "
    . ($gestor->puedeSolicitarTipo($u2, 'EQUIPO') ? "SI" : "NO") . "\n";

print "U2 puede solicitar SUMINISTRO: "
    . ($gestor->puedeSolicitarTipo($u2, 'SUMINISTRO') ? "SI" : "NO") . "\n";

print "\n=== PRUEBA ADMIN ===\n";
my $admin = {
    rol => 'ADMIN',
};

print $gestor->describirPermisos($admin) . "\n";