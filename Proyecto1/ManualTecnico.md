# Manual Técnico: Sistema MedTrack EDD 2026
**Estudiante:** Fernando Andhre Gonzalez Espinoza
**Curso:** Estructuras de Datos
**Fecha:** 20 de febrero de 2026

## 1. Introducción
MedTrack es una solución integral desarrollada en Perl para la gestión de suministros médicos. El sistema destaca por el uso de estructuras de datos dinámicas y visualización automatizada mediante Graphviz, permitiendo un control preciso sobre el inventario y las solicitudes departamentales.

---

## 2. Especificaciones de las Estructuras de Datos

### A. Lista Doblemente Enlazada (Inventario)
Esta estructura almacena el catálogo de medicamentos. Se eligió por su capacidad de navegación bidireccional (`next` y `prev`), facilitando la edición y consulta de datos.
* **Ordenamiento:** Los nodos se insertan de forma ordenada por código para optimizar las búsquedas.
* **Validación:** Se implementó una función de verificación de tipos para asegurar que campos como `precio` y `stock` sean numéricos antes de la inserción.
* **Visualización:** Nodos con `shape=record`. El sistema cambia el `fillcolor` a **rojo** si el stock es menor al nivel mínimo, generando una alerta visual inmediata.



### B. Lista Circular de Listas (Proveedores)
Estructura compuesta para la gestión de proveedores (lista circular simple) y sus entregas (sub-listas simples).
* **Navegación:** El último proveedor apunta al primero, permitiendo recorridos cíclicos.
* **Jerarquía:** Cada nodo de proveedor funciona como una cabecera para una lista de entregas de medicamentos.
* **Visualización:** Se utiliza el atributo `constraint=false` en Graphviz para representar el cierre del círculo de forma limpia.

### C. Lista Circular Doblemente Enlazada (Solicitudes)
Utilizada para manejar las colas de reabastecimiento solicitadas por los usuarios departamentales.
* **Conectividad:** Cada solicitud está enlazada con la anterior y la siguiente; el cierre del círculo es bidireccional.
* **Flujo:** Funciona bajo un esquema de atención de solicitudes donde el Administrador procesa los nodos desde el frente de la cola.



### D. Matriz Dispersa (Precios de Laboratorio)
Estructura ortogonal que relaciona medicamentos con laboratorios fabricantes y sus respectivos precios.
* **Cabeceras:** Posee punteros de control para filas (Laboratorios) y columnas (Medicamentos)