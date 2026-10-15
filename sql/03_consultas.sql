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



-- 1. Total Ventas ($M) Desglosado y Ticket Promedio
-- Validamos los componentes según la regla: total_amount = subtotal + tax_amount + shipping_fee
SELECT 
    SUM(so.subtotal) / 1000000.0 AS ventas_sin_impuestos,
    SUM(so.tax_amount) / 1000000.0 AS impuestos,
    (SUM(so.subtotal) + SUM(so.tax_amount)) / 1000000.0 AS ventas_sin_envio,
    SUM(so.shipping_fee) / 1000000.0 AS costo_envio,
    SUM(fs.total_amount) / 1000000.0 AS ventas_totales,
    SUM(fs.total_amount) / COUNT(fs.sales_id) AS ticket_promedio
FROM fact_sales fs
JOIN raw.sales_order so ON fs.sales_id = so.order_id
WHERE fs.status IN ('PAID', 'FULFILLED');



-- 2. Usuarios Activos Desglosados
-- Muestra el detalle de clientes logueados, sesiones anónimas y el total combinado
SELECT 
    COUNT(DISTINCT CASE WHEN customer_key != -1 THEN customer_key END) AS clientes_identificados,
    COUNT(DISTINCT CASE WHEN customer_key = -1 THEN session_id END) AS sesiones_anonimas,
    (
        COUNT(DISTINCT CASE WHEN customer_key != -1 THEN customer_key END) 
        + 
        COUNT(DISTINCT CASE WHEN customer_key = -1 THEN session_id END)
    ) AS usuarios_activos
FROM fact_web_session;



-- 3 Evolución Mensual de Usuarios Activos
SELECT 
    d.year,
    d.month,
    d.month_name,
    (
        COUNT(DISTINCT CASE WHEN ws.customer_key != -1 THEN ws.customer_key END) 
        + 
        COUNT(DISTINCT CASE WHEN ws.customer_key = -1 THEN ws.session_id END)
    ) AS usuarios_activos
FROM fact_web_session AS ws
JOIN dim_date AS d ON ws.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;



-- Usuarios Activos Totales (nK)
-- Combina clientes únicos logueados con sesiones únicas anónimas en un solo número
SELECT 
    (
        COUNT(DISTINCT CASE WHEN customer_key != -1 THEN customer_key END) 
        + 
        COUNT(DISTINCT CASE WHEN customer_key = -1 THEN session_id END)
    ) / 1000.0 AS usuarios_activos_k
FROM fact_web_session;



-- 4. Ventas por Provincia
-- Agrupa el total de ventas cruzando con la dimensión de ubicación[cite: 5].
SELECT 
    l.province_name,
    SUM(s.total_amount) AS total_ventas
FROM fact_sales s
JOIN dim_location l ON s.location_key = l.location_key
WHERE s.status IN ('PAID', 'FULFILLED')
GROUP BY l.province_name
ORDER BY total_ventas DESC;



-- 5. Puntos NPS
-- Aplica la fórmula ((%9-10) - (%0-6)) * 100 sobre las categorías previamente calculadas en la tabla de hechos[cite: 5].
SELECT 
    (
        SUM(CASE WHEN nps_category = 'Promotor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        - 
        SUM(CASE WHEN nps_category = 'Detractor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    ) AS nps_score
FROM fact_nps;



-- 6. Ranking Mensual por Producto
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



-- 7. Pedidos Vendidos
-- Cuenta la cantidad de facturas (tickets) cobradas o entregadas
SELECT 
    COUNT(DISTINCT sales_id) AS pedidos_vendidos
FROM fact_sales
WHERE status IN ('PAID', 'FULFILLED');