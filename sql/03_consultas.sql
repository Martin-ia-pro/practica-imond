-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================
-- Cada SELECT de este archivo se muestra en la terminal al ejecutar
-- run_sql.py. Usalo para:
--   * comprobar que las tablas se cargaron bien (cantidad de filas, nulos...)
--   * escribir las consultas clave de los KPIs que pide la consigna
--     (ventas, usuarios activos, ticket promedio, NPS, ventas por provincia,
--     ranking mensual por producto) usando las tablas del modelo estrella.
-- =====================================================================


-- Ejemplo: revisar la dimensión producto
SELECT product_key, name, category, family, list_price
FROM dim_product
ORDER BY product_key;


-- TU TURNO: agregá acá tus consultas.

-- 1. Total Ventas ($M) y Ticket Promedio ($K)
-- Filtra estados PAID y FULFILLED, y divide para mostrar en millones y miles[cite: 5].
SELECT 
    SUM(total_amount) / 1000000 AS ventas_millones,
    SUM(total_amount) / COUNT(*) AS ticket_promedio
FROM fact_sales
WHERE status IN ('PAID', 'FULFILLED');

-- 2. Usuarios Activos (nK)
-- Cuenta las sesiones únicas (session_id) para contemplar tanto a usuarios logueados como anónimos[cite: 5].
SELECT 
    COUNT(DISTINCT session_id) / 1000.0 AS usuarios_activos_k
FROM fact_web_session;

-- 3. Ventas por Provincia
-- Agrupa el total de ventas cruzando con la dimensión de ubicación[cite: 5].
SELECT 
    l.province_name,
    SUM(s.total_amount) AS total_ventas
FROM fact_sales s
JOIN dim_location l ON s.location_key = l.location_key
WHERE s.status IN ('PAID', 'FULFILLED')
GROUP BY l.province_name
ORDER BY total_ventas DESC;

-- 4. Puntos NPS
-- Aplica la fórmula ((%9-10) - (%0-6)) * 100 sobre las categorías previamente calculadas en la tabla de hechos[cite: 5].
SELECT 
    (
        SUM(CASE WHEN nps_category = 'Promotor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        - 
        SUM(CASE WHEN nps_category = 'Detractor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    ) AS nps_score
FROM fact_nps;

-- 5. Ranking Mensual por Producto
-- Agrupa el monto de las líneas de detalle por mes y producto[cite: 5].
SELECT 
    d.year,
    d.month,
    d.month_name,
    p.name AS product_name,
    SUM(si.line_total) AS total_sales
FROM fact_sales_item si
JOIN dim_date d ON si.date_key = d.date_key
JOIN dim_product p ON si.product_key = p.product_key
WHERE si.status IN ('PAID', 'FULFILLED')
GROUP BY d.year, d.month, d.month_name, p.name
ORDER BY d.year, d.month, total_sales DESC;