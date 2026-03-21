package estructuras::listaDoble::NodoDoble;
use strict;
use warnings;
sub new {
    my ($class, $valor) = @_;
    my $self = {
        valor     => $valor,
        anterior  => undef,
        siguiente => undef
    };
    bless $self, $class;
    return $self;
}

1;
