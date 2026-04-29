use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin";

use Gtk3 -init;

use estructuras::modulos::Inventario;
use estructuras::modulos::GestorUsuarios;
use estructuras::modulos::GestorPermisos;
use estructuras::modulos::CargadorJSON;

use ui::LoginWindow;

# ==========================================
# Crear módulos principales del sistema
# ==========================================
my $inventario = estructuras::modulos::Inventario->new();
my $gestor_usuarios = estructuras::modulos::GestorUsuarios->new();
my $gestor_permisos = estructuras::modulos::GestorPermisos->new();

my $cargador_json = estructuras::modulos::CargadorJSON->new(
    inventario      => $inventario,
    gestor_usuarios => $gestor_usuarios,
);

# ==========================================
# (Opcional pero recomendado)
# Cargar datos iniciales desde los JSON
# ==========================================
my $ruta_inventario = "$FindBin::Bin/cargas/inventario_masivo.json";
my $ruta_usuarios   = "$FindBin::Bin/cargas/usuarios_departamentales.json";

if (-e $ruta_inventario && -e $ruta_usuarios) {
    my $resultado = $cargador_json->cargarTodo(
        inventario => $ruta_inventario,
        usuarios   => $ruta_usuarios,
    );

    print "Datos iniciales cargados.\n";
}

# ==========================================
# Crear ventana login
# ==========================================
my $login = ui::LoginWindow->new(
    inventario       => $inventario,
    gestor_usuarios  => $gestor_usuarios,
    gestor_permisos  => $gestor_permisos,
    cargador_json    => $cargador_json,

    admin_user       => 'admin',
    admin_password   => 'admin123',

    datos_personales => {
        nombre    => 'Fernando Andhre Gonzalez Espinoza',
        carnet    => '202202055',
        curso     => 'Estructuras de Datos',
        seccion   => 'SECCION C',
        proyecto  => 'EDD MedTrack',
        fase      => 'Fase 2',
        semestre  => '2026',
    },

    on_exit => sub {
        Gtk3::main_quit();
    },
);

$login->show();
Gtk3::main();