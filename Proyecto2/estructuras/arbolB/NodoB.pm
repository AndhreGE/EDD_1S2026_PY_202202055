package estructuras::arbolB::NodoB;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    my $self = {
        claves  => $args{claves}  // [],
        valores => $args{valores} // [],
        hijos   => $args{hijos}   // [],
        hoja    => defined $args{hoja} ? $args{hoja} : 1,
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters
# =========================
sub esHoja {
    return $_[0]->{hoja};
}

sub setHoja {
    my ($self, $valor) = @_;
    $self->{hoja} = $valor;
}

sub getClaves {
    return $_[0]->{claves};
}

sub getValores {
    return $_[0]->{valores};
}

sub getHijos {
    return $_[0]->{hijos};
}

sub cantidadClaves {
    my ($self) = @_;
    return scalar @{ $self->{claves} };
}

sub getClaveEn {
    my ($self, $idx) = @_;
    return $self->{claves}->[$idx];
}

sub getValorEn {
    my ($self, $idx) = @_;
    return $self->{valores}->[$idx];
}

sub getHijoEn {
    my ($self, $idx) = @_;
    return $self->{hijos}->[$idx];
}

sub setHijoEn {
    my ($self, $idx, $hijo) = @_;
    $self->{hijos}->[$idx] = $hijo;
}

# =========================
# Inserciones y eliminaciones internas
# =========================
sub insertarClaveValorEn {
    my ($self, $idx, $clave, $valor) = @_;

    splice @{ $self->{claves} },  $idx, 0, $clave;
    splice @{ $self->{valores} }, $idx, 0, $valor;
}

sub eliminarClaveValorEn {
    my ($self, $idx) = @_;

    my $clave = splice @{ $self->{claves} },  $idx, 1;
    my $valor = splice @{ $self->{valores} }, $idx, 1;

    return ($clave, $valor);
}

sub insertarHijoEn {
    my ($self, $idx, $hijo) = @_;
    splice @{ $self->{hijos} }, $idx, 0, $hijo;
}

sub eliminarHijoEn {
    my ($self, $idx) = @_;

    my ($hijo) = splice @{ $self->{hijos} }, $idx, 1;
    return $hijo;
}

1;