use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Gtk3 -init;

use estructuras::modulos::GestorUsuarios;
use estructuras::modulos::GestorPermisos;
use modelos::PersonalMedico;
use ui::LoginWindow;

my $gestor_usuarios = estructuras::modulos::GestorUsuarios->new();
my $gestor_permisos = estructuras::modulos::GestorPermisos->new();

# Usuario de prueba
my $usuario = modelos::PersonalMedico->new(
    numero_colegio  => 'COL-10001',
    nombre_completo => 'Dr. Carlos Andres Mendez Torres',
    tipo_usuario    => 'TIPO-01',
    departamento    => 'DEP-MED',
    especialidad    => 'Medicina General',
    contrasena      => 'medgen2026A'
);

$gestor_usuarios->registrarUsuario($usuario);

my $login = ui::LoginWindow->new(
    gestor_usuarios => $gestor_usuarios,
    gestor_permisos => $gestor_permisos,

    admin_user     => 'admin',
    admin_password => 'admin123',

    on_admin_success => sub {
        my ($data) = @_;
        print "LOGIN ADMIN OK\n";
        print "Rol: $data->{rol}\n";
    },

    on_user_success => sub {
        my ($data) = @_;
        print "LOGIN USUARIO OK\n";
        print "Usuario: " . $data->{usuario}->toString() . "\n";
    },
);

$login->show();
Gtk3::main();