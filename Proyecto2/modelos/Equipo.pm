package Equipo;
package modelos::Equipo;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

sub new {
    my ($class, @args) = @_;

    my %args = (@args == 1 && ref($args[0]) eq 'HASH')
        ? %{ $args[0] }
        : @args;

    my $self = {
        tipo            => 'EQUIPO',
        codigo          => $args{codigo}          // '',
        nombre          => $args{nombre}          // '',
        fabricante      => $args{fabricante}      // '',
        precio_unitario => $args{precio_unitario} // 0,
        cantidad        => $args{cantidad}        // 0,
        fecha_ingreso   => $args{fecha_ingreso}   // '',
        nivel_minimo    => $args{nivel_minimo}    // 0,
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters
# =========================
sub getTipo            { return $_[0]->{tipo}; }
sub getCodigo          { return $_[0]->{codigo}; }
sub getNombre          { return $_[0]->{nombre}; }
sub getFabricante      { return $_[0]->{fabricante}; }
sub getPrecioUnitario  { return $_[0]->{precio_unitario}; }
sub getCantidad        { return $_[0]->{cantidad}; }
sub getFechaIngreso    { return $_[0]->{fecha_ingreso}; }
sub getNivelMinimo     { return $_[0]->{nivel_minimo}; }

# Esta será la clave que usará el BST
sub getClave {
    return $_[0]->{codigo};
}

# =========================
# Setters
# =========================
sub setNombre {
    my ($self, $valor) = @_;
    $self->{nombre} = defined $valor ? $valor : '';
}

sub setFabricante {
    my ($self, $valor) = @_;
    $self->{fabricante} = defined $valor ? $valor : '';
}

sub setPrecioUnitario {
    my ($self, $valor) = @_;
    $self->{precio_unitario} = defined $valor ? $valor : 0;
}

sub setCantidad {
    my ($self, $valor) = @_;
    $self->{cantidad} = defined $valor ? $valor : 0;
}

sub setFechaIngreso {
    my ($self, $valor) = @_;
    $self->{fecha_ingreso} = defined $valor ? $valor : '';
}

sub setNivelMinimo {
    my ($self, $valor) = @_;
    $self->{nivel_minimo} = defined $valor ? $valor : 0;
}

# =========================
# Reglas de negocio básicas
# =========================
sub estaBajoMinimo {
    my ($self) = @_;
    return $self->{cantidad} <= $self->{nivel_minimo};
}

sub validar {
    my ($self) = @_;
    my @errores;

    if ($self->{codigo} eq '' || $self->{codigo} !~ /^EQU-\d+$/) {
        push @errores, "El codigo del equipo no es valido";
    }

    if ($self->{nombre} eq '') {
        push @errores, "El nombre del equipo es obligatorio";
    }

    if ($self->{fabricante} eq '') {
        push @errores, "El fabricante del equipo es obligatorio";
    }

    if (!looks_like_number($self->{precio_unitario}) || $self->{precio_unitario} <= 0) {
        push @errores, "El precio unitario debe ser mayor que 0";
    }

    if ($self->{cantidad} !~ /^\d+$/) {
        push @errores, "La cantidad debe ser un entero no negativo";
    }

    if ($self->{fecha_ingreso} eq '' || $self->{fecha_ingreso} !~ /^\d{4}-\d{2}-\d{2}$/) {
        push @errores, "La fecha de ingreso debe tener formato YYYY-MM-DD";
    }

    if ($self->{nivel_minimo} !~ /^\d+$/) {
        push @errores, "El nivel minimo debe ser un entero no negativo";
    }

    return @errores;
}

sub esValido {
    my ($self) = @_;
    my @errores = $self->validar();
    return scalar(@errores) == 0;
}

sub toHash {
    my ($self) = @_;

    return {
        tipo            => $self->{tipo},
        codigo          => $self->{codigo},
        nombre          => $self->{nombre},
        fabricante      => $self->{fabricante},
        precio_unitario => $self->{precio_unitario},
        cantidad        => $self->{cantidad},
        fecha_ingreso   => $self->{fecha_ingreso},
        nivel_minimo    => $self->{nivel_minimo},
    };
}

sub toString {
    my ($self) = @_;

    return "[$self->{codigo}] $self->{nombre} | Fabricante: $self->{fabricante} | Cantidad: $self->{cantidad}";
}

1;