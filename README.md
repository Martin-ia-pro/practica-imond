# Proyecto Final: Data Warehouse & Dashboard - EcoBottle AR

**Universidad Austral - Licenciatura en Ciencia de Datos**
**Autor:** Martín

## Descripción del Proyecto
Este repositorio contiene el proceso completo de transformación de datos diseñado para analizar las métricas comerciales, el tráfico web y la satisfacción del cliente (NPS) de la empresa retail EcoBottle. El proyecto toma los datos transaccionales crudos, los modela en un Data Warehouse bajo un esquema estrella utilizando **DuckDB** mediante scripts SQL, y disponibiliza la información a través de un dashboard interactivo en **Power BI**.

## Instrucciones de Ejecución
1. **Entorno:** Asegurarse de tener Python instalado y activar el entorno virtual (`venv`) desde la terminal.
2. **Dependencias:** Verificar la instalación de DuckDB y utilidades requeridas.
3. **Ejecución del Pipeline:** Desde la raíz del proyecto en la consola, ejecutar el orquestador:
   ```bash
   python run_sql.py
   ```
   *Este script ejecutará secuencialmente `01_dimensiones.sql`, `02_hechos.sql` y `03_consultas.sql`, materializando los archivos CSV en la carpeta `/dw`.*
4. **Visualización:** Abrir el tablero en Power BI Desktop y actualizar los orígenes de datos para leer los nuevos archivos generados.

## Diccionario de Datos (Modelo Estrella)
El Data Warehouse está estructurado separando el contexto (dimensiones) de las métricas transaccionales (hechos):

**Tablas de Dimensiones:**
* `dim_customer`: Perfil de los clientes registrados en la plataforma.
* `dim_product`: Catálogo detallado de productos (ej. botellas Classic, Sport), familias y precios de lista.
* `dim_location`: Provincias de Argentina para análisis geográfico de envíos.
* `dim_channel`: Canales de venta y captación (Tienda Online, Tiendas Físicas).
* `dim_date`: Calendario estándar para análisis y segmentación temporal.

**Tablas de Hechos:**
* `fact_sales`: Cabecera de los pedidos comerciales. Granularidad: Un pedido completo por fila.
* `fact_sales_item`: Desglose de los pedidos. Granularidad: Un producto específico dentro de un pedido por fila.
* `fact_web_session`: Registro de tráfico y navegación. Granularidad: Una sesión web por fila.
* `fact_nps`: Resultados de encuestas de satisfacción. Granularidad: Una respuesta por fila.

## Supuestos y Decisiones Técnicas
* **Integridad Referencial (Claves -1):** Se utilizó la función `COALESCE(clave, -1)` durante las uniones en las tablas de hechos. Esto garantiza que las sesiones de usuarios anónimos o ventas sin una provincia asignada no rompan las relaciones del modelo de datos.
* **Filtro de Ventas Efectivas:** Para calcular el $M Total Ventas y el Ticket Promedio, el dashboard filtra exclusivamente los pedidos con estado `PAID` (Pagado) y `FULFILLED` (Entregado). Los pedidos cancelados o devueltos se excluyen.
* **Cálculo de Usuarios Activos:** Para reflejar el tráfico real, la métrica combina el recuento distintivo de clientes logueados con el recuento distintivo de sesiones anónimas (mediante una medida DAX).
* **Pre-Cálculo de NPS:** La segmentación de los puntajes de las encuestas en 'Promotor', 'Pasivo' y 'Detractor' se procesó directamente en la capa de SQL para optimizar y simplificar el cálculo porcentual final en la herramienta de visualización.

## Diagrama Entidad-Relación
*(Consultar el archivo `modelo_estrella.md` generado automáticamente en la carpeta `dw/` para observar la estructura de claves primarias y foráneas).*