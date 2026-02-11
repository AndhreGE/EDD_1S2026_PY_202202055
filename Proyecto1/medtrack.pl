#!/usr/bin/perl
use strict;
use warnings;
use lib '.'; 

require Nodo;
require Inventario;
require Proveedores;
require Reportes;
require Solicitudes;

print "--- EDD MedTrack: Sistema Iniciado ---\n";

# 1. Carga Masiva de Medicamentos [cite: 65, 227]
Inventario::cargar_csv("datos.csv");

# 2. Prueba de Proveedores [cite: 73]
my $p1 = Nodo->crear_proveedor("123-K", "Farmacia Central", "Ana", "5555", "Ciudad");
Proveedores->insertar_proveedor($p1);

# Agregar una entrega de prueba [cite: 91]
my $e1 = Nodo->crear_entrega("2026-02-10", "FAC-001", "MED001", 100);
Proveedores->registrar_entrega("123-K", $e1);

# 3. Impresión de Inventario en Consola [cite: 112]
print "\n--- INVENTARIO CARGADO ---\n";
my $aux = $Inventario::head; 
while(defined $aux) {
    print "ID: $aux->{codigo} | Nombre: $aux->{nombre} | Stock: $aux->{cantidad}\n";
    $aux = $aux->{next};
}

# 4. Generación de Reportes con Graphviz [cite: 148, 230]
Reportes->generar_inventario($Inventario::head);
Reportes->generar_proveedores($Proveedores::head_proveedores);

# Crear una solicitud de prueba
my $sol1 = Nodo->crear_solicitud(1, "Emergencias", "Tylenol", 20, "Alta");
Solicitudes->insertar_solicitud($sol1);

# Generar el reporte
Reportes->generar_solicitudes($Solicitudes::head_solicitudes);

print "\nProceso terminado. Revisa tus archivos .png\n";