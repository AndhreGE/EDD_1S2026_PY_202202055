# Manual de Usuario: Sistema MedTrack
**Desarrollado por:** Fernando Andhre Gonzalez Espinoza

## 1. Introducción
Bienvenido al sistema **MedTrack**, una herramienta diseñada para la gestión eficiente de inventarios médicos y solicitudes departamentales. Este manual te guiará a través de las funciones principales del software.

---

## 2. Acceso al Sistema
Al ejecutar el programa, verás el menú principal. El sistema cuenta con dos perfiles de acceso:

### A. Perfil Administrador
1. Selecciona la opción **1. Menu Administrador**.
2. Ingresa las siguientes credenciales:
   * **Usuario:** `Admin`
   * **Contraseña:** `1234`
3. Tras un inicio de sesión exitoso, tendrás acceso a la gestión de inventario, proveedores y procesamiento de solicitudes.

### B. Perfil Usuario Departamental
1. Selecciona la opción **2. Menu Usuario**.
2. Ingresa tu **Código de Departamento** (ej. `Zacapa`, `Guatemala`, `Escuintla`) y una contraseña.
3. Este perfil permite buscar medicamentos y generar solicitudes de reabastecimiento.

---

## 3. Funciones Principales (Administrador)

### Carga Masiva de Datos
* **Acción:** Selecciona la **Opción 2**.
* **Resultado:** El sistema leerá automáticamente el archivo `datos.csv` y poblará el inventario de forma ordenada.

### Generación de Reportes
* **Acción:** Selecciona la **Opción 4**.
* **Resultado:** Se crearán 4 archivos de imagen en la carpeta del proyecto:
  * `reporte_inventario.png`
  * `reporte_proveedores.png`
  * `reporte_solicitudes.png`
  * `reporte_matriz.png`

> **Nota Visual:** En el reporte de inventario, los nodos de color **Rojo** indican que el medicamento está por debajo del nivel mínimo de stock. Los nodos **Verdes** indican stock suficiente.



---

## 4. Funciones de Usuario Departamental

### Consultar Disponibilidad
* Permite buscar un medicamento por su nombre o código. El sistema informará la cantidad disponible y si es necesario solicitar más.

### Solicitar Reabastecimiento
1. Ingresa el código del medicamento.
2. Define la cantidad necesaria.
3. Selecciona la prioridad (Urgente, Alta, Media, Baja).
4. El sistema generará un ticket que será procesado por el administrador.

---

## 5. Solución de Problemas
* **El reporte no se genera:** Asegúrate de tener instalado **Graphviz** en tu computadora y que el comando `dot` sea reconocido en la terminal.
* **Error de Carga Masiva:** Verifica que el archivo `datos.csv` no esté abierto en otro programa (como Excel) y que los campos estén separados por comas sin espacios adicionales.

---

