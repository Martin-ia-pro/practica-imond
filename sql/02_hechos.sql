-- =====================================================================
-- 02_hechos.sql — Tablas de HECHOS del modelo estrella
-- =====================================================================
-- Este archivo se ejecuta después de 01_dimensiones.sql porque los hechos
-- apuntan a las dimensiones con FOREIGN KEY (REFERENCES).
--
-- Para cada tabla de hechos:
--   1. Definí el GRANO: ¿qué representa UNA fila?
--      (ej.: un producto dentro de un pedido, una sesión web, una respuesta NPS)
--   2. CREATE TABLE con:
--        - PRIMARY KEY
--        - una FOREIGN KEY por cada dimensión:  product_key INTEGER REFERENCES dim_product (product_key)
--        - las métricas (cantidades, importes, puntajes...)
--   3. INSERT INTO ... SELECT uniendo las tablas de origen (raw.) con las dimensiones
--      para obtener las claves.
--
-- Patrón para obtener la clave de una dimensión:
--
--   SELECT i.order_item_id, p.product_key, i.quantity, i.line_total
--   FROM raw.sales_order_item AS i
--   JOIN dim_product AS p ON p.product_id = i.product_id
--
-- Si una FOREIGN KEY apunta a una clave que no existe en la dimensión,
-- DuckDB rechaza la carga y run_sql.py te muestra el error.
-- =====================================================================


-- TU TURNO: creá acá las tablas de hechos.


-- ---------------------------------------------------------------------
-- 1. Hechos de Ventas Cabecera (fact_sales)
-- Grano: Una fila representa la cabecera de un pedido de venta.
-- ---------------------------------------------------------------------
CREATE TABLE fact_sales (
    sales_id INTEGER PRIMARY KEY,
    date_key INTEGER REFERENCES dim_date (date_key),
    customer_key INTEGER REFERENCES dim_customer (customer_key),
    channel_key INTEGER REFERENCES dim_channel (channel_key),
    location_key INTEGER REFERENCES dim_location (location_key),
    status VARCHAR,
    subtotal DECIMAL(12,2),
    tax_amount DECIMAL(12,2),
    shipping_fee DECIMAL(12,2),
    total_amount DECIMAL(12,2)
);

INSERT INTO fact_sales
SELECT 
    so.order_id AS sales_id,
    CAST(strftime(so.order_date, '%Y%m%d') AS INTEGER) AS date_key,
    COALESCE(dc.customer_key, -1) AS customer_key,
    COALESCE(dch.channel_key, -1) AS channel_key,
    COALESCE(dl.location_key, -1) AS location_key,
    so.status,
    so.subtotal,
    so.tax_amount,
    so.shipping_fee,
    so.total_amount
FROM raw.sales_order AS so
LEFT JOIN dim_customer AS dc ON so.customer_id = dc.customer_id
LEFT JOIN dim_channel AS dch ON so.channel_id = dch.channel_id
LEFT JOIN dim_location AS dl ON so.shipping_address_id = dl.address_id;


-- ---------------------------------------------------------------------
-- 2. Hechos de Ventas Detalle (fact_sales_item)
-- Grano: Una fila representa un producto específico dentro de un pedido.
-- ---------------------------------------------------------------------
CREATE TABLE fact_sales_item (
    order_item_id BIGINT PRIMARY KEY,
    sales_id INTEGER REFERENCES fact_sales (sales_id),
    date_key INTEGER REFERENCES dim_date (date_key),
    product_key INTEGER REFERENCES dim_product (product_key),
    quantity INTEGER,
    line_total DECIMAL(12,2),
    status VARCHAR
);

INSERT INTO fact_sales_item
SELECT 
    soi.order_item_id,
    so.order_id AS sales_id,
    CAST(strftime(so.order_date, '%Y%m%d') AS INTEGER) AS date_key,
    COALESCE(dp.product_key, -1) AS product_key,
    soi.quantity,
    soi.line_total,
    so.status 
FROM raw.sales_order_item AS soi
JOIN raw.sales_order AS so ON soi.order_id = so.order_id
LEFT JOIN dim_product AS dp ON soi.product_id = dp.product_id;


-- ---------------------------------------------------------------------
-- 3. Hechos de Sesiones Web (fact_web_session)
-- Grano: Una fila representa una sesión de navegación web.
-- ---------------------------------------------------------------------
CREATE TABLE fact_web_session (
    session_id BIGINT PRIMARY KEY,
    date_key INTEGER REFERENCES dim_date (date_key),
    customer_key INTEGER REFERENCES dim_customer (customer_key),
    source VARCHAR,
    device VARCHAR
);

INSERT INTO fact_web_session
SELECT 
    ws.session_id,
    CAST(strftime(ws.started_at, '%Y%m%d') AS INTEGER) AS date_key,
    COALESCE(dc.customer_key, -1) AS customer_key,
    ws.source,
    ws.device
FROM raw.web_session AS ws
LEFT JOIN dim_customer AS dc ON ws.customer_id = dc.customer_id;


-- ---------------------------------------------------------------------
-- 4. Hechos de Encuestas (fact_nps)
-- Grano: Una fila representa una respuesta a la encuesta de satisfacción.
-- ---------------------------------------------------------------------
CREATE TABLE fact_nps (
    nps_id BIGINT PRIMARY KEY,
    date_key INTEGER REFERENCES dim_date (date_key),
    customer_key INTEGER REFERENCES dim_customer (customer_key),
    channel_key INTEGER REFERENCES dim_channel (channel_key),
    score SMALLINT,
    nps_category VARCHAR
);

INSERT INTO fact_nps
SELECT 
    nps.nps_id,
    CAST(strftime(nps.responded_at, '%Y%m%d') AS INTEGER) AS date_key,
    COALESCE(dc.customer_key, -1) AS customer_key,
    COALESCE(dch.channel_key, -1) AS channel_key,
    nps.score,
    CASE 
        WHEN nps.score >= 9 THEN 'Promotor'
        WHEN nps.score BETWEEN 7 AND 8 THEN 'Pasivo'
        WHEN nps.score <= 6 THEN 'Detractor'
    END AS nps_category
FROM raw.nps_response AS nps
LEFT JOIN dim_customer AS dc ON nps.customer_id = dc.customer_id
LEFT JOIN dim_channel AS dch ON nps.channel_id = dch.channel_id;