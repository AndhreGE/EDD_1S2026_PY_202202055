use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use modelos::PersonalMedico;
use estructuras::avl::ArbolAVL;

my $arbol = estructuras::avl::ArbolAVL->new();

# =========================
# Crear usuarios de prueba
# =========================
my $u1 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-300',
    nombre_completo => 'Dra. Maria Lopez',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Medicina General',
    contrasena      => 'med123'
);

my $u2 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-200',
    nombre_completo => 'Dr. Juan Perez',
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Cirugia',
    contrasena      => 'cir123'
);

my $u3 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-100',
    nombre_completo => 'Lic. Ana Morales',
    tipo_usuario    => 'TIPO-03',
    departamento    => 'DEP-LAB',
    especialidad    => '',
    contrasena      => 'lab123'
);

my $u4 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-250',
    nombre_completo => 'Dr. Carlos Ramirez',
    tipo_usuario    => 'TIPO-04',
    departamento    => 'DEP-FAR',
    especialidad    => 'Farmacia Clinica',
    contrasena      => 'far123'
);

my $u5 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-400',
    nombre_completo => 'Lic. Sofia Herrera',
    tipo_usuario    => 'TIPO-05',
    departamento    => 'DEP-ADM',
    especialidad    => '',
    contrasena      => 'adm123'
);

my $u6 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-350',
    nombre_completo => 'Dr. Diego Castillo',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Cardiologia',
    contrasena      => 'cardio123'
);

my $u7 = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-450',
    nombre_completo => 'Dra. Elena Gomez',
    tipo_usuario    => 'TIPO-02',
    departamento    => 'DEP-CIR',
    especialidad    => 'Traumatologia',
    contrasena      => 'trauma123'
);

# =========================
# Insercion
# =========================
print "=== INSERCION AVL ===\n";

foreach my $usuario ($u1, $u2, $u3, $u4, $u5, $u6, $u7) {
    my ($ok, $msg) = $arbol->insertar($usuario);
    print $msg . "\n";
}

print "\nTamanio actual del arbol AVL: " . $arbol->getSize() . "\n";

# =========================
# Recorridos
# =========================
print "\n=== INORDEN AVL ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\n=== PREORDEN AVL ===\n";
print $arbol->preOrdenComoTexto() . "\n";

print "\n=== POSTORDEN AVL ===\n";
print $arbol->postOrdenComoTexto() . "\n";

# =========================
# Busqueda existente
# =========================
print "\n=== BUSQUEDA DE COL-250 ===\n";
my $buscado1 = $arbol->buscar('COL-250');

if ($buscado1) {
    print "Encontrado: " . $buscado1->toString() . "\n";
} else {
    print "No se encontro COL-250\n";
}

# =========================
# Busqueda inexistente
# =========================
print "\n=== BUSQUEDA DE COL-999 ===\n";
my $buscado2 = $arbol->buscar('COL-999');

if ($buscado2) {
    print "Encontrado: " . $buscado2->toString() . "\n";
} else {
    print "No se encontro COL-999\n";
}

# =========================
# Probar login simple con password
# =========================
print "\n=== VERIFICACION DE CONTRASENA ===\n";
my $usuario_login = $arbol->buscar('COL-300');

if ($usuario_login) {
    if ($usuario_login->verificarContrasena('med123')) {
        print "Contrasena correcta para COL-300\n";
    } else {
        print "Contrasena incorrecta para COL-300\n";
    }
}

# =========================
# Eliminacion de una hoja
# =========================
print "\n=== ELIMINACION DE COL-450 (HOJA) ===\n";
my ($elim_ok1, $elim_msg1) = $arbol->eliminar('COL-450');
print $elim_msg1 . "\n";

print "\n=== INORDEN DESPUES DE ELIMINAR COL-450 ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\nTamanio actual del arbol AVL: " . $arbol->getSize() . "\n";

# =========================
# Eliminacion de nodo intermedio
# =========================
print "\n=== ELIMINACION DE COL-300 ===\n";
my ($elim_ok2, $elim_msg2) = $arbol->eliminar('COL-300');
print $elim_msg2 . "\n";

print "\n=== INORDEN DESPUES DE ELIMINAR COL-300 ===\n";
print $arbol->inOrdenComoTexto() . "\n";

print "\n=== PREORDEN DESPUES DE ELIMINAR COL-300 ===\n";
print $arbol->preOrdenComoTexto() . "\n";

print "\nTamanio actual del arbol AVL: " . $arbol->getSize() . "\n";

# =========================
# Intento de insercion duplicada
# =========================
print "\n=== INSERCION DUPLICADA DE COL-250 ===\n";
my $duplicado = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-250',
    nombre_completo => 'Usuario Duplicado',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Duplicada',
    contrasena      => 'dup123'
);

my ($dup_ok, $dup_msg) = $arbol->insertar($duplicado);
print $dup_msg . "\n";

# =========================
# Intento de insercion invalida
# =========================
print "\n=== INSERCION INVALIDA ===\n";
my $invalido = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-XYZ',
    nombre_completo => 'Usuario Invalido',
    tipo_usuario    => 'TIPO-99',
    departamento    => 'DEP-XYZ',
    especialidad    => '',
    contrasena      => ''
);

my ($inv_ok, $inv_msg) = $arbol->insertar($invalido);
print $inv_msg . "\n";

# =========================
# Reporte Graphviz
# =========================
print "\n=== REPORTE GRAPHVIZ AVL ===\n";

mkdir "reportesdot" unless -d "reportesdot";

my $ok_png = $arbol->generarPNG(
    "reportesdot/avl_personal.dot",
    "reportesdot/avl_personal.png"
);

if ($ok_png) {
    print "Reporte AVL generado correctamente en reportesdot/avl_personal.png\n";
} else {
    print "No se pudo generar el reporte AVL\n";
}

print "\n=== FIN DE LA PRUEBA AVL ===\n";