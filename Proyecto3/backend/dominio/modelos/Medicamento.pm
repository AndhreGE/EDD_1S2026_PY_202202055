package modelos::Medicamento;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    # Validación mínima obligatoria
    die "Codigo requerido"           unless defined $args{codigo};
    die "Nombre requerido"           unless defined $args{nombre};
    die "Cantidad requerida"         unless defined $args{cantidad};
    die "Precio unitario requerido"  unless defined $args{precio_unitario};

    my $self = {
        codigo            => $args{codigo},
        nombre            => $args{nombre},
        principio_activo  => $args{principio_activo}  // '',
        laboratorio       => $args{laboratorio}       // '',
        precio_unitario   => $args{precio_unitario}   + 0,
        cantidad          => $args{cantidad}          + 0,
        fecha_vencimiento => $args{fecha_vencimiento} // '',
        nivel_minimo      => $args{nivel_minimo}      + 0,
    };

    bless $self, $class;
    return $self;
}

# GETTERS

sub codigo            { return $_[0]->{codigo}; }
sub nombre            { return $_[0]->{nombre}; }
sub principio_activo  { return $_[0]->{principio_activo}; }
sub laboratorio       { return $_[0]->{laboratorio}; }
sub precio_unitario   { return $_[0]->{precio_unitario}; }
sub cantidad          { return $_[0]->{cantidad}; }
sub fecha_vencimiento { return $_[0]->{fecha_vencimiento}; }
sub nivel_minimo      { return $_[0]->{nivel_minimo}; }

# MÉTODOS de reduccion y aumento de stock, y verificación de estado

sub reducir_stock {
    my ($self, $cantidad) = @_;

    $cantidad = $cantidad + 0;

    if ($cantidad <= $self->{cantidad}) {
        $self->{cantidad} -= $cantidad;
        return 1;
    }
    return 0;
}

use Time::Piece;

sub esta_proximo_vencer {
    my ($self) = @_;

    return 0 unless $self->{fecha_vencimiento};

    my $hoy = localtime;
    my $vencimiento = Time::Piece->strptime($self->{fecha_vencimiento}, "%Y-%m-%d");

    my $diferencia = ($vencimiento - $hoy)->days;

    return $diferencia <= 30 && $diferencia >= 0;
}

sub estado_alerta {
    my ($self) = @_;

    return "BAJO_MINIMO" if $self->esta_bajo_minimo();
    return "PROXIMO_VENCER" if $self->esta_proximo_vencer();

    return "NORMAL";
}

sub esta_bajo_minimo {
    my ($self) = @_;
    return $self->{cantidad} <= $self->{nivel_minimo};
}


sub aumentar_stock {
    my ($self, $cantidad) = @_;
    return 0 if $cantidad <= 0;

    $self->{cantidad} += $cantidad;
    return 1;
}


# REPRESENTACIÓN TEXTO

sub to_string {
    my ($self) = @_;

    return "Codigo: $self->{codigo} | "
         . "Nombre: $self->{nombre} | "
         . "Stock: $self->{cantidad} | "
         . "Precio: Q$self->{precio_unitario}";
}

1;
