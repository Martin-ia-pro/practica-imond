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



-- =====================================================================
-- A. CONSULTAS DE VALIDACIÓN Y CALIDAD DE DATOS (RAW vs DW)
-- =====================================================================

-- Validación 1: Conteo de filas en las 6 tablas de hechos
SELECT '1. Pedidos (fact_orders)' AS tabla, (SELECT COUNT(*) FROM raw.sales_order) AS filas_raw, (SELECT COUNT(*) FROM fact_orders) AS filas_dw
UNION ALL
SELECT '2. Ventas Detalle (fact_sales)', (SELECT COUNT(*) FROM raw.sales_order_item), (SELECT COUNT(*) FROM fact_sales)
UNION ALL
SELECT '3. Sesiones Web (fact_web_session)', (SELECT COUNT(*) FROM raw.web_session), (SELECT COUNT(*) FROM fact_web_session)
UNION ALL
SELECT '4. Respuestas NPS (fact_nps)', (SELECT COUNT(*) FROM raw.nps_response), (SELECT COUNT(*) FROM fact_nps)
UNION ALL
SELECT '5. Pagos (fact_payment)', (SELECT COUNT(*) FROM raw.payment), (SELECT COUNT(*) FROM fact_payment)
UNION ALL
SELECT '6. Envíos (fact_shipment)', (SELECT COUNT(*) FROM raw.shipment), (SELECT COUNT(*) FROM fact_shipment);

-- Validación 2: Conciliación monetaria (subtotal + tax_amount + shipping_fee = total_amount)
SELECT 
    (SELECT SUM(total_amount) FROM raw.sales_order) AS total_en_raw,
    SUM(total_amount) AS total_en_dw,
    SUM(subtotal + tax_amount + shipping_fee) AS suma_componentes,
    SUM(total_amount) - SUM(subtotal + tax_amount + shipping_fee) AS diferencia
FROM fact_orders;

-- Validación 3: Control de claves foráneas nulas y registros anónimos/online (-1)
SELECT 
    COUNT(*) FILTER (
        WHERE customer_key IS NULL OR date_key IS NULL OR channel_key IS NULL 
           OR location_key IS NULL OR store_key IS NULL
    ) AS claves_foraneas_nulas,
    COUNT(*) FILTER (WHERE store_key = -1) AS pedidos_canal_online,
    COUNT(*) FILTER (WHERE store_key != -1) AS pedidos_tienda_fisica,
    (SELECT COUNT(*) FILTER (WHERE customer_key = -1) FROM fact_web_session) AS sesiones_web_anonimas
FROM fact_orders;


-- =====================================================================
-- B. CONSULTAS DE KPIS DEL DASHBOARD
-- =====================================================================

-- 1. Total Ventas ($M) Desglosado y Ticket Promedio ($K)
SELECT 
    SUM(subtotal) / 1000000.0 AS ventas_sin_impuestos_m,
    SUM(tax_amount) / 1000000.0 AS impuestos_m,
    SUM(subtotal + tax_amount) / 1000000.0 AS ventas_sin_envio_m,
    SUM(shipping_fee) / 1000000.0 AS costo_envio_m,
    SUM(total_amount) / 1000000.0 AS ventas_totales_m,
    SUM(total_amount) / COUNT(DISTINCT order_id) AS ticket_promedio
FROM fact_orders
WHERE status IN ('PAID', 'FULFILLED');

-- 2. Pedidos Vendidos
SELECT 
    COUNT(DISTINCT order_id) AS pedidos_vendidos
FROM fact_orders
WHERE status IN ('PAID', 'FULFILLED');

-- 3. Usuarios Activos Totales Desglosados
SELECT 
    COUNT(DISTINCT CASE WHEN customer_key != -1 THEN customer_key END) AS clientes_identificados,
    COUNT(DISTINCT CASE WHEN customer_key = -1 THEN session_id END) AS sesiones_anonimas,
    (
        COUNT(DISTINCT CASE WHEN customer_key != -1 THEN customer_key END) 
        + 
        COUNT(DISTINCT CASE WHEN customer_key = -1 THEN session_id END)
    ) AS usuarios_activos
FROM fact_web_session;

-- 4. Evolución Mensual de Usuarios Activos
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

-- 5. Puntos NPS
SELECT 
    (
        SUM(CASE WHEN nps_category = 'Promotor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
        - 
        SUM(CASE WHEN nps_category = 'Detractor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    ) AS nps_score
FROM fact_nps;

-- 6. Ventas por Provincia
SELECT 
    l.province_name,
    SUM(o.total_amount) AS total_ventas
FROM fact_orders AS o
JOIN dim_location AS l ON o.location_key = l.location_key
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY l.province_name
ORDER BY total_ventas DESC;

-- 7. Ranking Mensual por Producto
SELECT 
    d.year,
    d.month,
    d.month_name,
    p.name AS product_name,
    SUM(s.line_total) AS total_sales
FROM fact_sales AS s
JOIN dim_date AS d ON s.date_key = d.date_key
JOIN dim_product AS p ON s.product_key = p.product_key
WHERE s.status IN ('PAID', 'FULFILLED')
GROUP BY d.year, d.month, d.month_name, p.name
ORDER BY d.year, d.month, total_sales DESC;

-- 8. Ventas por Sucursal Física (dim_store)
SELECT 
    st.store_name,
    st.city,
    st.province_name,
    COUNT(DISTINCT o.order_id) AS pedidos,
    SUM(o.total_amount) AS total_ventas
FROM fact_orders AS o
JOIN dim_store AS st ON o.store_key = st.store_key
WHERE o.status IN ('PAID', 'FULFILLED') AND o.store_key != -1
GROUP BY st.store_name, st.city, st.province_name
ORDER BY total_ventas DESC;