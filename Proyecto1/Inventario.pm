package Inventario;
use strict;
use warnings;

our $head = undef; # 'our' permite que sea vista desde afuera

sub insertar_ordenado {
    my ($nodo) = @_;
    if (!defined $head) {
        $head = $nodo;
        return;
    }
    if ($nodo->{codigo} lt $head->{codigo}) {
        $nodo->{next} = $head;
        $head->{prev} = $nodo;
        $head = $nodo;
        return;
    }
    my $actual = $head;
    while (defined $actual->{next} && $actual->{next}->{codigo} lt $nodo->{codigo}) {
        $actual = $actual->{next};
    }
    $nodo->{next} = $actual->{next};
    $actual->{next}->{prev} = $nodo if defined $actual->{next};
    $actual->{next} = $nodo;
    $nodo->{prev} = $actual;
}

sub cargar_csv {
    my ($ruta) = @_;
    open(my $fh, '<', $ruta) or return;
    <$fh>; # Saltar encabezado
    while (my $line = <$fh>) {
        chomp $line;
        my @d = split(',', $line);
        foreach (@d) { s/^\s+|\s+$//g; }
        my $nuevo = Nodo->crear_medicamento(@d);
        insertar_ordenado($nuevo);
    }
    close($fh);
}
1;