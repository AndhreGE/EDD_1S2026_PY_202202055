use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin";

use Gtk3 -init;

use estructuras::modulos::Inventario;
use estructuras::modulos::GestorUsuarios;
use estructuras::modulos::CargadorJSON;
use ui::AdminWindow;

my $inventario = estructuras::modulos::Inventario->new();
my $gestor     = estructuras::modulos::GestorUsuarios->new();

my $cargador = estructuras::modulos::CargadorJSON->new(
    inventario      => $inventario,
    gestor_usuarios => $gestor,
);

my $admin = ui::AdminWindow->new(
    inventario      => $inventario,
    gestor_usuarios => $gestor,
    cargador_json   => $cargador,

    on_logout => sub {
        print "Logout ejecutado\n";
        Gtk3::main_quit();
    },
);

$admin->set_admin_name('Administrador del Sistema');
$admin->show();

Gtk3::main();