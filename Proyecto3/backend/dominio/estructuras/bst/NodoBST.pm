package estructuras::bst::NodoBST;

use strict;
use warnings;

sub new {
    my ($class, $equipo) = @_;

    my $self = {
        equipo    => $equipo,
        izquierdo => undef,
        derecho   => undef,
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters
# =========================
sub getEquipo    { return $_[0]->{equipo}; }
sub getIzquierdo { return $_[0]->{izquierdo}; }
sub getDerecho   { return $_[0]->{derecho}; }

sub getClave {
    my ($self) = @_;
    return $self->{equipo}->getClave();
}

# =========================
# Setters
# =========================
sub setEquipo {
    my ($self, $equipo) = @_;
    $self->{equipo} = $equipo;
}

sub setIzquierdo {
    my ($self, $nodo) = @_;
    $self->{izquierdo} = $nodo;
}

sub setDerecho {
    my ($self, $nodo) = @_;
    $self->{derecho} = $nodo;
}

1;