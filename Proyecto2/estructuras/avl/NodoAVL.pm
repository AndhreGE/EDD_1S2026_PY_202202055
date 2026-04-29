package estructuras::avl::NodoAVL;

use strict;
use warnings;

sub new {
    my ($class, $personal) = @_;

    my $self = {
        personal   => $personal,
        izquierdo  => undef,
        derecho    => undef,
        altura     => 1,
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters
# =========================
sub getPersonal   { return $_[0]->{personal}; }
sub getIzquierdo  { return $_[0]->{izquierdo}; }
sub getDerecho    { return $_[0]->{derecho}; }
sub getAltura     { return $_[0]->{altura}; }

sub getClave {
    my ($self) = @_;
    return $self->{personal}->getClave();
}

# =========================
# Setters
# =========================
sub setPersonal {
    my ($self, $personal) = @_;
    $self->{personal} = $personal;
}

sub setIzquierdo {
    my ($self, $nodo) = @_;
    $self->{izquierdo} = $nodo;
}

sub setDerecho {
    my ($self, $nodo) = @_;
    $self->{derecho} = $nodo;
}

sub setAltura {
    my ($self, $altura) = @_;
    $self->{altura} = $altura;
}

1;