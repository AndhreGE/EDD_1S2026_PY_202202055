package modelos::Solicitud;

use estructuras::listaDobleCircular::ListaDobleCircular;

sub new {
    my ($class, $id, $codigo, $cantidad) = @_;

    my $self = {
        id       => $id,
        codigo   => $codigo,
        cantidad => $cantidad + 0,   # fuerza numérico
        estado   => "PENDIENTE"
    };

    bless $self, $class;
    return $self;
}

sub codigo   { return $_[0]->{codigo}; }
sub cantidad { return $_[0]->{cantidad}; }
sub estado   { return $_[0]->{estado}; }

sub aprobar {
    $_[0]->{estado} = "APROBADA";
}

sub rechazar {
    $_[0]->{estado} = "RECHAZADA";
}

sub to_string {
    my ($self) = @_;
    return "ID: $self->{id} | Codigo: $self->{codigo} | Cantidad: $self->{cantidad} | Estado: $self->{estado}";
}

sub generarReporteSolicitudesPendientes {
    my ($self) = @_;

    my $dot = "reportesDOT/solicitudes_pendientes.dot";
    my $png = "reportesDOT/solicitudes_pendientes.png";

    mkdir "reportesDOT" unless -d "reportesDOT";

    $self->{listaSolicitudes}->generarDotSolicitudesPendientes($dot);

    system("dot -Tpng $dot -o $png");

    print "Reporte de solicitudes pendientes generado correctamente.\n";
}

1;
