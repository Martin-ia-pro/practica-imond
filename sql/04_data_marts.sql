-- =====================================================================
-- 04_data_marts.sql — Capa de Data Marts para Power BI (Sin DAX)
-- Tablas pre-procesadas e independientes (sin FK) listas para visualizar
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Data Mart de Pedidos Efectivos (dm_orders)
-- Alimenta: Total Ventas, Ticket Promedio, Pedidos Vendidos y Mapa
-- ---------------------------------------------------------------------
CREATE TABLE dm_orders AS
SELECT 
    o.order_id,
    o.date_key,
    d.full_date,
    d.year,
    d.month,
    d.month_name,
    o.customer_key,
    o.channel_key,
    ch.name AS channel_name,
    o.location_key,
    l.province_name,
    o.store_key,
    st.store_name,
    o.subtotal AS ventas_sin_impuestos,
    o.tax_amount AS impuestos,
    (o.subtotal + o.tax_amount) AS ventas_sin_envio,
    o.shipping_fee AS costo_envio,
    o.total_amount AS ventas_totales
FROM fact_orders o
JOIN dim_date d ON o.date_key = d.date_key
JOIN dim_channel ch ON o.channel_key = ch.channel_key
JOIN dim_location l ON o.location_key = l.location_key
JOIN dim_store st ON o.store_key = st.store_key
WHERE o.status IN ('PAID', 'FULFILLED');

-- ---------------------------------------------------------------------
-- 2. Data Mart de Ventas por Producto (dm_sales_products)
-- Alimenta: Gráfico de anillo por Producto y Evolución Mensual
-- ---------------------------------------------------------------------
CREATE TABLE dm_sales_products AS
SELECT 
    s.order_item_id,
    s.order_id,
    s.date_key,
    d.full_date,
    d.year,
    d.month,
    d.month_name,
    s.product_key,
    p.name AS product_name,
    p.category AS product_category,
    s.customer_key,
    s.channel_key,
    ch.name AS channel_name,
    s.location_key,
    l.province_name,
    s.store_key,
    st.store_name,
    s.quantity AS unidades_vendidas,
    s.line_total AS ventas_producto
FROM fact_sales s
JOIN dim_date d ON s.date_key = d.date_key
JOIN dim_product p ON s.product_key = p.product_key
JOIN dim_channel ch ON s.channel_key = ch.channel_key
JOIN dim_location l ON s.location_key = l.location_key
JOIN dim_store st ON s.store_key = st.store_key
WHERE s.status IN ('PAID', 'FULFILLED');


-- ---------------------------------------------------------------------
-- 3. Data Mart de Usuarios Activos Web (dm_web_active_users)
-- Alimenta: Tarjeta Usuarios Activos y Evolución Mensual (Recuento distinto)
-- ---------------------------------------------------------------------
CREATE TABLE dm_web_active_users AS
SELECT 
    ws.session_id,
    ws.date_key,
    d.full_date,
    d.year,
    d.month,
    d.month_name,
    ws.customer_key,
    ws.source,
    ws.device,
    CASE 
        WHEN ws.customer_key != -1 THEN 'CUST-' || CAST(ws.customer_key AS VARCHAR)
        ELSE 'ANON-' || CAST(ws.session_id AS VARCHAR)
    END AS usuario_activo_id,
    CASE 
        WHEN ws.customer_key != -1 THEN 'Identificado'
        ELSE 'Anónimo'
    END AS tipo_usuario
FROM fact_web_session ws
JOIN dim_date d ON ws.date_key = d.date_key;


-- ---------------------------------------------------------------------
-- 4. Data Mart de Satisfacción NPS (dm_nps)
-- Alimenta: Medidor de Puntos NPS (usando Promedio de puntos_nps)
-- ---------------------------------------------------------------------
CREATE TABLE dm_nps AS
SELECT 
    n.nps_id,
    n.date_key,
    d.full_date,
    d.year,
    d.month,
    d.month_name,
    n.customer_key,
    n.channel_key,
    ch.name AS channel_name,
    n.score,
    n.nps_category,
    CASE 
        WHEN n.nps_category = 'Promotor' THEN 100.0
        WHEN n.nps_category = 'Pasivo' THEN 0.0
        WHEN n.nps_category = 'Detractor' THEN -100.0
    END AS puntos_nps
FROM fact_nps n
JOIN dim_date d ON n.date_key = d.date_key
JOIN dim_channel ch ON n.channel_key = ch.channel_key;