use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use estructuras::modulos::Inventario;
use estructuras::modulos::GestorUsuarios;
use estructuras::modulos::CargadorJSON;

my $inventario = estructuras::modulos::Inventario->new();
my $gestor     = estructuras::modulos::GestorUsuarios->new();

my $cargador = estructuras::modulos::CargadorJSON->new(
    inventario      => $inventario,
    gestor_usuarios => $gestor,
);

my $ruta_inventario = "$FindBin::Bin/cargas/inventario_masivo.json";
my $ruta_usuarios   = "$FindBin::Bin/cargas/usuarios_departamentales.json";

my $resultado = $cargador->cargarTodo(
    inventario => $ruta_inventario,
    usuarios   => $ruta_usuarios,
);

print "=== RESULTADO INVENTARIO ===\n";
if ($resultado->{inventario}) {
    print "Mensaje: " . ($resultado->{inventario}->{mensaje} // '') . "\n";
    print "Proveedores leidos: " . ($resultado->{inventario}->{proveedores_leidos} // 0) . "\n";
    print "Proveedores registrados: " . ($resultado->{inventario}->{proveedores_registrados} // 0) . "\n";
    print "Items leidos: " . ($resultado->{inventario}->{items_leidos} // 0) . "\n";
    print "Medicamentos cargados: " . ($resultado->{inventario}->{medicamentos_ok} // 0) . "\n";
    print "Equipos cargados: " . ($resultado->{inventario}->{equipos_ok} // 0) . "\n";
    print "Suministros cargados: " . ($resultado->{inventario}->{suministros_ok} // 0) . "\n";

    print "\nErrores de inventario:\n";
    if (
        defined $resultado->{inventario}->{errores}
        && ref($resultado->{inventario}->{errores}) eq 'ARRAY'
        && @{ $resultado->{inventario}->{errores} }
    ) {
        print " - $_\n" for @{ $resultado->{inventario}->{errores} };
    } else {
        print " - Sin errores\n";
    }
}

print "\n=== RESULTADO USUARIOS ===\n";
if ($resultado->{usuarios}) {
    print "Mensaje: " . ($resultado->{usuarios}->{mensaje} // '') . "\n";
    print "Usuarios leidos: " . ($resultado->{usuarios}->{usuarios_leidos} // 0) . "\n";
    print "Usuarios registrados: " . ($resultado->{usuarios}->{usuarios_registrados} // 0) . "\n";

    print "\nErrores de usuarios:\n";
    if (
        defined $resultado->{usuarios}->{errores}
        && ref($resultado->{usuarios}->{errores}) eq 'ARRAY'
        && @{ $resultado->{usuarios}->{errores} }
    ) {
        print " - $_\n" for @{ $resultado->{usuarios}->{errores} };
    } else {
        print " - Sin errores\n";
    }
}

print "\n=== RESUMEN GENERAL ===\n";
my $resumen_inv = $inventario->obtenerResumenGeneral();
print "Medicamentos: " . ($resumen_inv->{medicamentos} // 0) . "\n";
print "Equipos: " . ($resumen_inv->{equipos} // 0) . "\n";
print "Suministros: " . ($resumen_inv->{suministros} // 0) . "\n";
print "Proveedores: " . ($resumen_inv->{proveedores} // 0) . "\n";
print "Total items: " . ($resumen_inv->{total_items} // 0) . "\n";

my $resumen_usr = $gestor->obtenerResumen();
print "Total usuarios: " . ($resumen_usr->{total_usuarios} // 0) . "\n";

print "\n=== PRUEBA LOGIN ===\n";
my ($ok_login, $msg_login, $usuario) = $gestor->autenticarUsuario('COL-10001', 'medgen2026A');
print "$msg_login\n";
if ($ok_login && $usuario) {
    print "Usuario autenticado: " . $usuario->toString() . "\n";
}