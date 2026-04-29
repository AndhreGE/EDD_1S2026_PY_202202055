use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin";

use estructuras::modulos::Inventario;
use modelos::Equipo;

my $inventario = estructuras::modulos::Inventario->new();

my $e1 = modelos::Equipo->new(
    codigo          => 'EQU-003',
    nombre          => 'Ventilador',
    fabricante      => 'MedCorp',
    precio_unitario => 25000,
    cantidad        => 4,
    fecha_ingreso   => '2026-04-09',
    nivel_minimo    => 1
);

my $e2 = modelos::Equipo->new(
    codigo          => 'EQU-001',
    nombre          => 'Monitor',
    fabricante      => 'BioTech',
    precio_unitario => 4500,
    cantidad        => 10,
    fecha_ingreso   => '2026-04-09',
    nivel_minimo    => 2
);

my $e3 = modelos::Equipo->new(
    codigo          => 'EQU-005',
    nombre          => 'Bomba de infusion',
    fabricante      => 'MediFlow',
    precio_unitario => 3800,
    cantidad        => 8,
    fecha_ingreso   => '2026-04-09',
    nivel_minimo    => 3
);

print "=== REGISTRO ===\n";
my ($ok1, $msg1) = $inventario->registrarEquipo($e1, 'PROV-001');
print "$msg1\n";

my ($ok2, $msg2) = $inventario->registrarEquipo($e2, 'PROV-001');
print "$msg2\n";

my ($ok3, $msg3) = $inventario->registrarEquipo($e3, 'PROV-001');
print "$msg3\n";

print "\n=== BUSQUEDA ===\n";
my $encontrado = $inventario->buscarEquipo('EQU-001');
if ($encontrado) {
    print "Encontrado: " . $encontrado->toString() . "\n";
} else {
    print "No encontrado\n";
}

print "\n=== EDICION ===\n";
my ($edit_ok, $edit_msg) = $inventario->editarEquipo(
    'EQU-001',
    nombre          => 'Monitor Multiparametro',
    cantidad        => 15,
    precio_unitario => 5000,
);
print "$edit_msg\n";

my $editado = $inventario->buscarEquipo('EQU-001');
print "Editado: " . $editado->toString() . "\n";

print "\n=== RECORRIDOS ===\n";
print "--- INORDEN ---\n";
print $inventario->equiposComoTexto('INORDEN') . "\n";

print "\n--- PREORDEN ---\n";
print $inventario->equiposComoTexto('PREORDEN') . "\n";

print "\n--- POSTORDEN ---\n";
print $inventario->equiposComoTexto('POSTORDEN') . "\n";

print "\n=== ELIMINACION ===\n";
my ($elim_ok, $elim_msg) = $inventario->eliminarEquipo('EQU-003');
print "$elim_msg\n";

print "\n=== INORDEN DESPUES DE ELIMINAR ===\n";
print $inventario->equiposComoTexto('INORDEN') . "\n";