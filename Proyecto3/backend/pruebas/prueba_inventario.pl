use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use estructuras::modulos::Inventario;
use modelos::Equipo;
use modelos::Suministro;

my $inventario = estructuras::modulos::Inventario->new();

my $equipo = modelos::Equipo->new(
    codigo          => 'EQU-001',
    nombre          => 'Monitor',
    fabricante      => 'BioTech',
    precio_unitario => 4500,
    cantidad        => 10,
    fecha_ingreso   => '2026-04-09',
    nivel_minimo    => 2
);

my $suministro = modelos::Suministro->new(
    codigo            => 'SUM-001',
    nombre            => 'Guantes',
    fabricante        => 'SafeHands',
    precio_unitario   => 2,
    cantidad          => 200,
    fecha_vencimiento => '2027-02-01',
    nivel_minimo      => 50
);

my ($ok1, $msg1) = $inventario->registrarEquipo($equipo, 'PROV-001');
print "$msg1\n";

my ($ok2, $msg2) = $inventario->registrarSuministro($suministro, 'PROV-001');
print "$msg2\n";

print "\n=== EQUIPOS ===\n";
$inventario->imprimirEquipos();

print "\n=== SUMINISTROS ===\n";
$inventario->imprimirSuministros();

my $resumen = $inventario->obtenerResumenGeneral();
print "\nTotal items: $resumen->{total_items}\n";