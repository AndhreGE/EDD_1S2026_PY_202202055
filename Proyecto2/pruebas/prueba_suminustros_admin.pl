use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin";

use estructuras::modulos::Inventario;
use modelos::Suministro;

my $inventario = estructuras::modulos::Inventario->new();

my $s1 = modelos::Suministro->new(
    codigo            => 'SUM-003',
    nombre            => 'Guantes de latex',
    fabricante        => 'SafeHands',
    precio_unitario   => 2,
    cantidad          => 100,
    fecha_vencimiento => '2027-05-10',
    nivel_minimo      => 20
);

my $s2 = modelos::Suministro->new(
    codigo            => 'SUM-001',
    nombre            => 'Gasas esteriles',
    fabricante        => 'MediTex',
    precio_unitario   => 1,
    cantidad          => 80,
    fecha_vencimiento => '2027-03-20',
    nivel_minimo      => 15
);

my $s3 = modelos::Suministro->new(
    codigo            => 'SUM-005',
    nombre            => 'Jeringas',
    fabricante        => 'BioSupply',
    precio_unitario   => 3,
    cantidad          => 60,
    fecha_vencimiento => '2027-08-01',
    nivel_minimo      => 10
);

print "=== REGISTRO ===\n";
my ($ok1, $msg1) = $inventario->registrarSuministro($s1, 'PROV-001');
print "$msg1\n";

my ($ok2, $msg2) = $inventario->registrarSuministro($s2, 'PROV-001');
print "$msg2\n";

my ($ok3, $msg3) = $inventario->registrarSuministro($s3, 'PROV-001');
print "$msg3\n";

print "\n=== BUSQUEDA ===\n";
my $encontrado = $inventario->buscarSuministro('SUM-001');
if ($encontrado) {
    print "Encontrado: " . $encontrado->toString() . "\n";
} else {
    print "No encontrado\n";
}

print "\n=== EDICION ===\n";
my ($edit_ok, $edit_msg) = $inventario->editarSuministro(
    'SUM-001',
    nombre            => 'Gasas esteriles premium',
    cantidad          => 120,
    precio_unitario   => 2,
    fecha_vencimiento => '2027-12-31',
);
print "$edit_msg\n";

my $editado = $inventario->buscarSuministro('SUM-001');
print "Editado: " . $editado->toString() . "\n";

print "\n=== RECORRIDOS ===\n";
print "--- INORDEN ---\n";
print $inventario->suministrosComoTexto('INORDEN') . "\n";

print "\n--- PREORDEN ---\n";
print $inventario->suministrosComoTexto('PREORDEN') . "\n";

print "\n--- POSTORDEN ---\n";
print $inventario->suministrosComoTexto('POSTORDEN') . "\n";

print "\n=== ELIMINACION ===\n";
my ($elim_ok, $elim_msg) = $inventario->eliminarSuministro('SUM-003');
print "$elim_msg\n";

print "\n=== INORDEN DESPUES DE ELIMINAR ===\n";
print $inventario->suministrosComoTexto('INORDEN') . "\n";