use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use modelos::Suministro;
use estructuras::arbolB::ArbolB;

my $arbol = estructuras::arbolB::ArbolB->new();

# =========================
# Crear suministros de prueba
# =========================
my @suministros = (
    modelos::Suministro->new(
        codigo            => 'SUM-300',
        nombre            => 'Jeringas',
        fabricante        => 'MedSupply',
        precio_unitario   => 5,
        cantidad          => 50,
        fecha_vencimiento => '2027-01-01',
        nivel_minimo      => 10
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-100',
        nombre            => 'Guantes',
        fabricante        => 'SafeHands',
        precio_unitario   => 2,
        cantidad          => 200,
        fecha_vencimiento => '2027-02-01',
        nivel_minimo      => 50
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-200',
        nombre            => 'Mascarillas',
        fabricante        => 'CleanAir',
        precio_unitario   => 1,
        cantidad          => 150,
        fecha_vencimiento => '2027-03-01',
        nivel_minimo      => 30
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-400',
        nombre            => 'Gasas',
        fabricante        => 'MedTex',
        precio_unitario   => 3,
        cantidad          => 120,
        fecha_vencimiento => '2027-04-01',
        nivel_minimo      => 20
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-500',
        nombre            => 'Sueros',
        fabricante        => 'BioFluid',
        precio_unitario   => 12,
        cantidad          => 90,
        fecha_vencimiento => '2027-05-01',
        nivel_minimo      => 15
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-250',
        nombre            => 'Vendas',
        fabricante        => 'WrapCare',
        precio_unitario   => 4,
        cantidad          => 80,
        fecha_vencimiento => '2027-06-01',
        nivel_minimo      => 10
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-350',
        nombre            => 'Alcohol',
        fabricante        => 'SteriLab',
        precio_unitario   => 6,
        cantidad          => 60,
        fecha_vencimiento => '2027-07-01',
        nivel_minimo      => 10
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-450',
        nombre            => 'Cateter',
        fabricante        => 'FlexMed',
        precio_unitario   => 15,
        cantidad          => 40,
        fecha_vencimiento => '2027-08-01',
        nivel_minimo      => 5
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-150',
        nombre            => 'Algodon',
        fabricante        => 'SoftCare',
        precio_unitario   => 3,
        cantidad          => 70,
        fecha_vencimiento => '2027-09-01',
        nivel_minimo      => 10
    ),
    modelos::Suministro->new(
        codigo            => 'SUM-050',
        nombre            => 'Curitas',
        fabricante        => 'QuickAid',
        precio_unitario   => 1,
        cantidad          => 300,
        fecha_vencimiento => '2027-10-01',
        nivel_minimo      => 60
    ),
);

# =========================
# Inserción
# =========================
print "=== INSERCION ARBOL B ===\n";

foreach my $suministro (@suministros) {
    my ($ok, $msg) = $arbol->insertar($suministro);
    print $msg . "\n";
}

print "\nTamanio actual del arbol B: " . $arbol->getSize() . "\n";

# =========================
# Recorridos
# =========================
print "\n=== INORDEN ARBOL B ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\n=== PREORDEN ARBOL B ===\n";
print $arbol->preOrdenComoTexto() . "\n";

print "\n=== POSTORDEN ARBOL B ===\n";
print $arbol->postOrdenComoTexto() . "\n";

# =========================
# Búsqueda existente
# =========================
print "\n=== BUSQUEDA DE SUM-250 ===\n";
my $buscado1 = $arbol->buscar('SUM-250');

if ($buscado1) {
    print "Encontrado: " . $buscado1->toString() . "\n";
}
else {
    print "No se encontro SUM-250\n";
}

# =========================
# Búsqueda inexistente
# =========================
print "\n=== BUSQUEDA DE SUM-999 ===\n";
my $buscado2 = $arbol->buscar('SUM-999');

if ($buscado2) {
    print "Encontrado: " . $buscado2->toString() . "\n";
}
else {
    print "No se encontro SUM-999\n";
}

# =========================
# Eliminaciones
# =========================
print "\n=== ELIMINACION DE SUM-050 ===\n";
my ($elim_ok1, $elim_msg1) = $arbol->eliminar('SUM-050');
print $elim_msg1 . "\n";

print "\n=== ELIMINACION DE SUM-200 ===\n";
my ($elim_ok2, $elim_msg2) = $arbol->eliminar('SUM-200');
print $elim_msg2 . "\n";

print "\n=== ELIMINACION DE SUM-300 ===\n";
my ($elim_ok3, $elim_msg3) = $arbol->eliminar('SUM-300');
print $elim_msg3 . "\n";

print "\n=== ELIMINACION DE SUM-500 ===\n";
my ($elim_ok4, $elim_msg4) = $arbol->eliminar('SUM-500');
print $elim_msg4 . "\n";

print "\n=== INORDEN DESPUES DE ELIMINAR ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\nTamanio actual del arbol B: " . $arbol->getSize() . "\n";

# =========================
# Inserción duplicada
# =========================
print "\n=== INSERCION DUPLICADA DE SUM-250 ===\n";

my $duplicado = modelos::Suministro->new(
    codigo            => 'SUM-250',
    nombre            => 'Suministro Duplicado',
    fabricante        => 'DupLab',
    precio_unitario   => 9,
    cantidad          => 10,
    fecha_vencimiento => '2027-11-01',
    nivel_minimo      => 2
);

my ($dup_ok, $dup_msg) = $arbol->insertar($duplicado);
print $dup_msg . "\n";

# =========================
# Inserción inválida
# =========================
print "\n=== INSERCION INVALIDA ===\n";

my $invalido = modelos::Suministro->new(
    codigo            => 'SUM-INVALID',
    nombre            => '',
    fabricante        => '',
    precio_unitario   => 0,
    cantidad          => -5,
    fecha_vencimiento => 'fecha-mala',
    nivel_minimo      => -1
);

my ($inv_ok, $inv_msg) = $arbol->insertar($invalido);
print $inv_msg . "\n";

# =========================
# Reporte Graphviz
# =========================
print "\n=== REPORTE GRAPHVIZ ARBOL B ===\n";

mkdir "reportesdot" unless -d "reportesdot";

my $ok_png = $arbol->generarPNG(
    "reportesdot/arbol_b_suministros.dot",
    "reportesdot/arbol_b_suministros.png"
);

if ($ok_png) {
    print "Reporte Arbol B generado correctamente en reportesdot/arbol_b_suministros.png\n";
}
else {
    print "No se pudo generar el reporte del Arbol B\n";
}

print "\n=== FIN DE LA PRUEBA ARBOL B ===\n";