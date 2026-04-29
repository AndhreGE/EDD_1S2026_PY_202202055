package PersonalMedico;
package modelos::PersonalMedico;

use strict;
use warnings;

sub new {
    my ($class, @args) = @_;

    my %args = (@args == 1 && ref($args[0]) eq 'HASH')
        ? %{ $args[0] }
        : @args;

    my $self = {
        numero_colegio  => $args{numero_colegio}  // '',
        nombre_completo => $args{nombre_completo} // '',
        tipo_usuario    => $args{tipo_usuario}    // '',
        departamento    => $args{departamento}    // '',
        especialidad    => defined $args{especialidad} ? $args{especialidad} : '',
        contrasena      => $args{contrasena}      // '',
    };

    bless $self, $class;
    return $self;
}

# =========================
# Getters
# =========================
sub getNumeroColegio  { return $_[0]->{numero_colegio}; }
sub getNombreCompleto { return $_[0]->{nombre_completo}; }
sub getTipoUsuario    { return $_[0]->{tipo_usuario}; }
sub getDepartamento   { return $_[0]->{departamento}; }
sub getEspecialidad   { return $_[0]->{especialidad}; }
sub getContrasena     { return $_[0]->{contrasena}; }

# Esta será la clave que usará el AVL
sub getClave {
    return $_[0]->{numero_colegio};
}

# =========================
# Setters
# =========================
sub setNombreCompleto {
    my ($self, $valor) = @_;
    $self->{nombre_completo} = defined $valor ? $valor : '';
}

sub setTipoUsuario {
    my ($self, $valor) = @_;
    $self->{tipo_usuario} = defined $valor ? $valor : '';
}

sub setDepartamento {
    my ($self, $valor) = @_;
    $self->{departamento} = defined $valor ? $valor : '';
}

sub setEspecialidad {
    my ($self, $valor) = @_;
    $self->{especialidad} = defined $valor ? $valor : '';
}

sub setContrasena {
    my ($self, $valor) = @_;
    $self->{contrasena} = defined $valor ? $valor : '';
}

# =========================
# Reglas de negocio básicas
# =========================
sub verificarContrasena {
    my ($self, $contrasena_ingresada) = @_;
    return $self->{contrasena} eq ($contrasena_ingresada // '');
}

sub esTipoValido {
    my ($self) = @_;
    my %tipos_validos = map { $_ => 1 } qw(TIPO-01 TIPO-02 TIPO-03 TIPO-04 TIPO-05);
    return exists $tipos_validos{$self->{tipo_usuario}};
}

sub esDepartamentoValido {
    my ($self) = @_;
    my %departamentos_validos = map { $_ => 1 } qw(DEP-MED DEP-CIR DEP-FAR DEP-LAB DEP-ADM);
    return exists $departamentos_validos{$self->{departamento}};
}

sub validar {
    my ($self) = @_;
    my @errores;

    if ($self->{numero_colegio} eq '' || $self->{numero_colegio} !~ /^COL-\d+$/) {
        push @errores, "El numero de colegio no es valido";
    }

    if ($self->{nombre_completo} eq '') {
        push @errores, "El nombre completo es obligatorio";
    }

    if (!$self->esTipoValido()) {
        push @errores, "El tipo de usuario no es valido";
    }

    if (!$self->esDepartamentoValido()) {
        push @errores, "El departamento no es valido";
    }

    if ($self->{contrasena} eq '') {
        push @errores, "La contrasena no puede estar vacia";
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
        numero_colegio  => $self->{numero_colegio},
        nombre_completo => $self->{nombre_completo},
        tipo_usuario    => $self->{tipo_usuario},
        departamento    => $self->{departamento},
        especialidad    => $self->{especialidad},
        contrasena      => $self->{contrasena},
    };
}

sub toString {
    my ($self) = @_;

    my $especialidad = $self->{especialidad} ne '' ? $self->{especialidad} : 'Sin especialidad';

    return "[$self->{numero_colegio}] $self->{nombre_completo} | $self->{tipo_usuario} | $self->{departamento} | $especialidad";
}

1;