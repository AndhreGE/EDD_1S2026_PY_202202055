#!/usr/bin/perl
use strict;
use warnings;
use lib '.'; 

# 1. CARGA DE MÓDULOS (Esto ya lo tienes)
require Nodo;
require Inventario;
require Proveedores;
require Reportes;
require Solicitudes;
require Matriz;

# 2. DECLARACIÓN DE VARIABLES PARA EVITAR WARNINGS (Opcional para limpiar terminal)
#use vars qw($Inventario::head $Proveedores::head_proveedores $Solicitudes::head_solicitudes $Matriz::root_filas);

# =========================================================
# 3. AQUÍ PONES LAS NUEVAS FUNCIONES DE LOGIN Y MENÚS
# =========================================================

sub iniciar_sesion_admin {
    print "\n============================\n";
    print "    SISTEMA EDD MEDTRACK    \n";
    print "============================\n";
    print "\n--- AUTENTICACION DE ADMINISTRADOR ---\n";
    print "Usuario: ";
    my $user = <STDIN>; chomp($user);
    print "Contrasena: ";
    my $pass = <STDIN>; chomp($pass);

    if ($user eq "Admin" && $pass eq "1234") {
        return 1;
    } else {
        print "\nAcceso denegado.\n";
        return 0;
    }
}

sub menu_administrador {
    my $op = 0;
    while ($op != 9) {
        print "\n============================\n";
        print "    SISTEMA EDD MEDTRACK    \n";
        print "============================\n";
        print "\n--- MENU ADMINISTRADOR ---\n";
        print "1. Registrar Medicamento\n";
        print "2. Carga Masiva de Medicamentos\n";
        print "3. Gestionar Proveedores\n";
        print "4. Generar Reporte\n";
        print "5. Procesar Solicitudes de Reabastecimiento\n";
        print "6. Visualizar Inventario Completo\n";
        print "7. Consultar precios (Matriz)\n";
        print "8. Consultar inventario\n";
        print "9. Volver\n";
        print "Seleccione: ";
        $op = <STDIN>; chomp($op);

        if ($op == 1) {
            # Opción 1: Registro manual con validación de datos
            print "Codigo: "; my $cod = <STDIN>; chomp($cod);
            print "Nombre: "; my $nom = <STDIN>; chomp($nom);
            print "Principio Activo: "; my $pa = <STDIN>; chomp($pa);
            print "Laboratorio: "; my $lab = <STDIN>; chomp($lab);

            # Validación de Precio (Solo una vez)
            my $pre;
            while (1) {
                print "Precio unitario: "; $pre = <STDIN>; chomp($pre);
                last if es_numero_valido($pre);
                print "¡Error! Ingrese un numero decimal valido (ej: 10.50).\n";
            }

            # Validación de Cantidad (Solo una vez)
            my $can;
            while (1) {
                print "Cantidad: "; $can = <STDIN>; chomp($can);
                last if es_numero_valido($can);
                print "¡Error! Ingrese un numero entero positivo para la cantidad.\n";
            }

            print "Vencimiento (YYYY-MM-DD): "; my $fec = <STDIN>; chomp($fec);
            print "Nivel Minimo: "; my $niv = <STDIN>; chomp($niv);
            
            my $nuevo = Nodo->crear_medicamento($cod, $nom, $pa, $lab, $pre, $can, $fec, $niv);
            Inventario::insertar_ordenado($nuevo);
            print "\nMedicamento registrado con exito.\n";

        } elsif ($op == 2) { 
            # Opción 2: Carga desde CSV [cite: 65, 67]
            Inventario::cargar_csv("datos.csv"); 
            print "\nCarga masiva finalizada.\n";

        } elsif ($op == 3) {
            # Opción 3: Registro en la Lista Circular de Listas [cite: 72, 74]
            print "NIT: "; my $nit = <STDIN>; chomp($nit);
            print "Empresa: "; my $emp = <STDIN>; chomp($emp);
            print "Contacto: "; my $con = <STDIN>; chomp($con);
            print "Telefono: "; my $tel = <STDIN>; chomp($tel);
            print "Direccion: "; my $dir = <STDIN>; chomp($dir);
            
            my $prov = Nodo->crear_proveedor($nit, $emp, $con, $tel, $dir);
            Proveedores->insertar_proveedor($prov);
            print "\nProveedor registrado.\n";

        } elsif ($op == 4) {
            # Generar Reportes y Actualizar archivos PNG [cite: 148, 149]
            Reportes->generar_inventario($Inventario::head);
            Reportes->generar_proveedores($Proveedores::head_proveedores);
            Reportes->generar_solicitudes($Solicitudes::head_solicitudes);
            Reportes->generar_matriz($Matriz::root_filas, $Matriz::root_columnas);
            print "\nReportes Graphviz generados con exito.\n";

        } elsif ($op == 5) {
            # Opción 5: Atender la Lista Circular Doblemente Enlazada [cite: 98, 101]
            procesar_solicitudes_pendientes(); 

        } elsif ($op == 6) {
            # Opción 6: Mostrar inventario en consola [cite: 110, 112]
            Inventario->visualizar_consola();
        } elsif ($op == 7) {
            # Opción 7: Búsqueda en Matriz Dispersa [cite: 114, 117]
            print "Ingrese el nombre del medicamento a consultar: ";
            my $med_consulta = <STDIN>; chomp($med_consulta);
            Matriz->consultar_precios_medicamento($med_consulta);
        }elsif ($op == 8) {
            print "\n--- CONSULTA FILTRADA ---\n";
            print "Ingrese nombre del Medicamento: "; my $med = <STDIN>; chomp($med);
            print "Ingrese nombre del Laboratorio: "; my $lab = <STDIN>; chomp($lab);
    
            # Esta función buscará el nodo exacto en la intersección
            Matriz->consultar_especifico($med, $lab);
        }
    }
}

sub menu_usuario_departamental {
    my ($codigo_depto) = @_; # Recibimos el código para filtrar su historial
    my $op = 0;
    
    while ($op != 4) {
        print "\n--- MENU USUARIO (Depto: $codigo_depto) ---\n";
        print "1. Consultar Disponibilidad de Medicamentos\n";
        print "2. Solicitar Reabastecimiento\n";
        print "3. Visualizar Historial de Solicitudes\n";
        print "4. Cerrar Sesion\n";
        print "Seleccione: ";
        $op = <STDIN>; chomp($op);

        if ($op == 1) {
            if ($op == 1) {
            print "Ingrese nombre o codigo: ";
            my $busqueda = <STDIN>; chomp($busqueda);
            # Llamamos a la función del módulo Inventario
            Inventario::buscar_medicamento($busqueda); 
        }
        } elsif ($op == 2) {
            crear_solicitud_interactiva($codigo_depto);
        }
    }
}

sub crear_solicitud_interactiva {
    my ($depto) = @_;
    
    print "\n--- NUEVA SOLICITUD DE REABASTECIMIENTO ---\n";
    print "Codigo de Medicamento: ";
    my $med = <STDIN>; chomp($med);
    
    print "Cantidad Requerida: ";
    my $cant = <STDIN>; chomp($cant);
    
    print "Prioridad (1. Urgente, 2. Alta, 3. Media, 4. Baja): ";
    my $p_op = <STDIN>; chomp($p_op);
    
    # Mapeo de prioridad según el enunciado
    my %prioridades = (1 => "Urgente", 2 => "Alta", 3 => "Media", 4 => "Baja");
    my $prioridad = $prioridades{$p_op} // "Baja";
    
    print "Justificacion: ";
    my $just = <STDIN>; chomp($just);

    # Generamos un número de solicitud basado en el contador actual
    my $no_solicitud = $Solicitudes::contador_solicitudes + 1;

    # Creamos el nodo usando el módulo Nodo
    my $nueva_sol = Nodo->crear_solicitud(
        $no_solicitud, 
        $depto, 
        $med, 
        $cant, 
        $prioridad
    );

    # Lo insertamos en la lista circular doblemente enlazada
    Solicitudes->insertar_solicitud($nueva_sol);

    print "\nSolicitud No. $no_solicitud creada exitosamente y enviada a Farmacia.\n";
    
    # Actualizamos el reporte de Graphviz automáticamente
    Reportes->generar_solicitudes($Solicitudes::head_solicitudes);
}

sub iniciar_sesion_usuario {
    print "\n--- INICIO DE SESION DEPARTAMENTAL ---\n";
    print "Codigo de Departamento: ";
    my $depto = <STDIN>; chomp($depto);
    print "Contrasena: ";
    my $pass = <STDIN>; chomp($pass);

    # Validación simple: puedes mejorarla conectándola a una lista de usuarios
    if ($depto ne "" && $pass ne "") {
        print "\nBienvenido, personal de $depto.\n";
        return $depto; # Retornamos el depto para saber quién está logueado
    } else {
        print "\nDatos invalidos.\n";
        return undef;
    }
}

sub es_numero_valido {
    my ($valor) = @_;
    # Expresión regular: permite números enteros y decimales positivos
    if ($valor =~ /^\d+(\.\d+)?$/) {
        return 1;
    }
    return 0;
}

# =========================================================
# 4. EL "MAIN" (El código que arranca todo)
# =========================================================

print "--- EDD MedTrack: Sistema Iniciado ---\n";

# Llamamos al menú principal para que el programa empiece a correr
my $opcion_principal = 0;
print "\n============================\n";
print "    SISTEMA EDD MEDTRACK    \n";
print "============================\n";
while ($opcion_principal != 3) {
    print "\n1. Menu Administrador\n2. Menu Usuario\n3. Salir\nSeleccione: ";
    $opcion_principal = <STDIN>; chomp($opcion_principal);

    if ($opcion_principal == 1) {
        if (iniciar_sesion_admin()) {
            menu_administrador();
        }
    }
    elsif ($opcion_principal == 2) { # Cambiado de 'else' a 'elsif'
        my $depto_logueado = iniciar_sesion_usuario();
        if (defined $depto_logueado) {
            menu_usuario_departamental($depto_logueado);
        }
    }
}

print "\nPrograma finalizado \n";
