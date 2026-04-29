package modelos::Proveedor;

use estructuras::listaSimple::ListaSimple;

sub new {
    my ($class, %args) = @_;

    my $self = {
        nit               => $args{nit},
        nombre_empresa    => $args{nombre_empresa},
        contacto          => $args{contacto},
        telefono          => $args{telefono},
        direccion         => $args{direccion},
        entregas          => estructuras::listaSimple::ListaSimple->new()
    };

    bless $self, $class;
    return $self;
}

# Getters
sub nit            { $_[0]->{nit}; }
sub nombre_empresa { $_[0]->{nombre_empresa}; }
sub contacto       { $_[0]->{contacto}; }
sub telefono       { $_[0]->{telefono}; }
sub direccion      { $_[0]->{direccion}; }
sub entregas       { $_[0]->{entregas}; }

sub to_string {
    my ($self) = @_;

    return "NIT: $self->{nit} | "
         . "Empresa: $self->{nombre_empresa} | "
         . "Contacto: $self->{contacto} | "
         . "Telefono: $self->{telefono} | "
         . "Direccion: $self->{direccion}";
}

1;
