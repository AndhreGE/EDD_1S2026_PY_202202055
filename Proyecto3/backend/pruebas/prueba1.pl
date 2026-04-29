use strict;
use warnings;
use utf8;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

use FindBin;
use lib "$FindBin::Bin/../dominio";

use modelos::Equipo;
use estructuras::bst::ArbolBST;

my $arbol = estructuras::bst::ArbolBST->new();

# =========================
# Crear equipos de prueba
# =========================
my $e1 = modelos::Equipo->new(
    codigo          => 'EQU-003',
    nombre          => 'Ventilador',
    fabricante      => 'MedCorp',
    precio_unitario => 25000,
    cantidad        => 4,
    fecha_ingreso   => '2026-03-24',
    nivel_minimo    => 1
);

my $e2 = modelos::Equipo->new(
    codigo          => 'EQU-001',
    nombre          => 'Monitor',
    fabricante      => 'BioTech',
    precio_unitario => 4500,
    cantidad        => 10,
    fecha_ingreso   => '2026-03-20',
    nivel_minimo    => 2
);

my $e3 = modelos::Equipo->new(
    codigo          => 'EQU-005',
    nombre          => 'Bomba de infusion',
    fabricante      => 'MediFlow',
    precio_unitario => 3800,
    cantidad        => 8,
    fecha_ingreso   => '2026-03-18',
    nivel_minimo    => 3
);

my $e4 = modelos::Equipo->new(
    codigo          => 'EQU-002',
    nombre          => 'Electrocardiografo',
    fabricante      => 'CardioPlus',
    precio_unitario => 12000,
    cantidad        => 3,
    fecha_ingreso   => '2026-03-19',
    nivel_minimo    => 1
);

my $e5 = modelos::Equipo->new(
    codigo          => 'EQU-004',
    nombre          => 'Desfibrilador',
    fabricante      => 'HeartSafe',
    precio_unitario => 18000,
    cantidad        => 2,
    fecha_ingreso   => '2026-03-21',
    nivel_minimo    => 1
);

# =========================
# Insertar equipos
# =========================
print "=== INSERCION ===\n";

my ($ok1, $msg1) = $arbol->insertar($e1);
print "$msg1\n";

my ($ok2, $msg2) = $arbol->insertar($e2);
print "$msg2\n";

my ($ok3, $msg3) = $arbol->insertar($e3);
print "$msg3\n";

my ($ok4, $msg4) = $arbol->insertar($e4);
print "$msg4\n";

my ($ok5, $msg5) = $arbol->insertar($e5);
print "$msg5\n";

print "\nTamanio actual del arbol: " . $arbol->getSize() . "\n";

# =========================
# Recorridos
# =========================
print "\n=== INORDEN ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\n=== PREORDEN ===\n";
print $arbol->preOrdenComoTexto() . "\n";

print "\n=== POSTORDEN ===\n";
print $arbol->postOrdenComoTexto() . "\n";

# =========================
# Busqueda existente
# =========================
print "\n=== BUSQUEDA DE EQU-001 ===\n";
my $buscado1 = $arbol->buscar('EQU-001');

if ($buscado1) {
    print "Encontrado: " . $buscado1->toString() . "\n";
} else {
    print "No se encontro EQU-001\n";
}

# =========================
# Busqueda inexistente
# =========================
print "\n=== BUSQUEDA DE EQU-999 ===\n";
my $buscado2 = $arbol->buscar('EQU-999');

if ($buscado2) {
    print "Encontrado: " . $buscado2->toString() . "\n";
} else {
    print "No se encontro EQU-999\n";
}

# =========================
# Eliminacion de una hoja
# =========================
print "\n=== ELIMINACION DE EQU-004 (HOJA) ===\n";
my ($elim_ok1, $elim_msg1) = $arbol->eliminar('EQU-004');
print "$elim_msg1\n";

print "\n=== INORDEN DESPUES DE ELIMINAR EQU-004 ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\nTamanio actual del arbol: " . $arbol->getSize() . "\n";

# =========================
# Eliminacion de nodo con un hijo o dos hijos
# =========================
print "\n=== ELIMINACION DE EQU-003 ===\n";
my ($elim_ok2, $elim_msg2) = $arbol->eliminar('EQU-003');
print "$elim_msg2\n";

print "\n=== INORDEN DESPUES DE ELIMINAR EQU-003 ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\nTamanio actual del arbol: " . $arbol->getSize() . "\n";

# =========================
# Generar reporte Graphviz
# =========================
print "\n=== REPORTE GRAPHVIZ ===\n";

mkdir "reportesdot" unless -d "reportesdot";

my $ok_png = $arbol->generarPNG(
    "reportesdot/bst_equipos.dot",
    "reportesdot/bst_equipos.png"
);

if ($ok_png) {
    print "Reporte BST generado correctamente en reportesdot/bst_equipos.png\n";
} else {
    print "No se pudo generar el reporte BST\n";
}

print "\n=== FIN DE LA PRUEBA BST ===\n";