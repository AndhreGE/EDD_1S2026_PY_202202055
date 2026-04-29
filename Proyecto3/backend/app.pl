#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/dominio";

use Mojolicious::Lite -signatures;

use EDDMedTrack::Services::AppContainer;
use EDDMedTrack::Routes;

# =========================================================
# Configuración base
# =========================================================
app->secrets(['edd-medtrack-fase3-secreto-cambiar-en-produccion']);
app->sessions->default_expiration(60 * 60 * 8); # 8 horas

# Sirve archivos estáticos desde backend/reportesdot
push @{ app->static->paths }, "$FindBin::Bin/reportesdot";

# =========================================================
# Contenedor principal del sistema
# =========================================================
my $container = EDDMedTrack::Services::AppContainer->new(
    base_path          => $FindBin::Bin,
    auto_cargar_datos  => 1,
    auto_sembrar_demo  => 1,
);

# Guardarlo como helper para usarlo luego si hace falta
helper app_container => sub { return $container };

# =========================================================
# Registrar rutas
# =========================================================
EDDMedTrack::Routes->register(app, $container);

# =========================================================
# Ruta simple raíz
# =========================================================
get '/' => sub ($c) {
    my $resumen = $container->obtenerResumenSistema();

    $c->render(
        json => {
            ok      => 1,
            mensaje => 'Backend EDD MedTrack ejecutándose',
            api     => {
                ping       => '/api/ping',
                auth_login => '/api/auth/login',
                auth_me    => '/api/auth/me',
            },
            resumen => $resumen,
        }
    );
};

app->start;