use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use estructuras::modulos::GestorUsuarios;
use modelos::PersonalMedico;

my $gestor = estructuras::modulos::GestorUsuarios->new();

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
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Cirugia',
    contrasena      => 'cir123'
);

my ($ok1, $msg1) = $gestor->registrarUsuario($u1);
print "$msg1\n";

my ($ok2, $msg2) = $gestor->registrarUsuario($u2);
print "$msg2\n";

print "\n=== USUARIOS ===\n";
$gestor->imprimirUsuarios();

print "\n=== LOGIN ===\n";
my ($login_ok, $login_msg, $usuario) = $gestor->autenticarUsuario('COL-200', 'cir123');
print "$login_msg\n";

if ($login_ok) {
    print "Bienvenido: " . $usuario->toString() . "\n";
}

my $resumen = $gestor->obtenerResumen();
print "\nTotal usuarios: $resumen->{total_usuarios}\n";

my ($rep_ok, $rep_msg) = $gestor->generarReporteUsuarios(
    'reportesdot/avl_usuarios_gestor.dot',
    'reportesdot/avl_usuarios_gestor.png'
);
print "$rep_msg\n";