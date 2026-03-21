package modelos::Entrega;

sub new {
    my ($class, %args) = @_;

    my $self = {
        fecha              => $args{fecha},
        factura            => $args{numero_factura},
        codigo_medicamento => $args{codigo_medicamento},
        cantidad           => $args{cantidad}
    };

    bless $self, $class;
    return $self;
}



sub to_string {
    my ($self) = @_;
    return "Factura: $self->{numero_factura} | "
         . "Fecha: $self->{fecha} | "
         . "Medicamento: $self->{codigo_medicamento} | "
         . "Cantidad: $self->{cantidad}";
}

1;
