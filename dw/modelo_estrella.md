# Modelo estrella

Generado por `run_sql.py` a partir de las tablas de `warehouse.duckdb`.

```mermaid
erDiagram
    dim_channel ||--o{ fact_nps : "channel_key"
    dim_channel ||--o{ fact_orders : "channel_key"
    dim_channel ||--o{ fact_payment : "channel_key"
    dim_channel ||--o{ fact_sales : "channel_key"
    dim_customer ||--o{ fact_nps : "customer_key"
    dim_customer ||--o{ fact_orders : "customer_key"
    dim_customer ||--o{ fact_payment : "customer_key"
    dim_customer ||--o{ fact_sales : "customer_key"
    dim_customer ||--o{ fact_shipment : "customer_key"
    dim_customer ||--o{ fact_web_session : "customer_key"
    dim_date ||--o{ fact_nps : "date_key"
    dim_date ||--o{ fact_orders : "date_key"
    dim_date ||--o{ fact_payment : "date_key"
    dim_date ||--o{ fact_sales : "date_key"
    dim_date ||--o{ fact_shipment : "date_key"
    dim_date ||--o{ fact_web_session : "date_key"
    dim_location ||--o{ fact_orders : "location_key"
    dim_location ||--o{ fact_sales : "location_key"
    dim_location ||--o{ fact_shipment : "location_key"
    dim_product ||--o{ fact_sales : "product_key"
    dim_store ||--o{ fact_orders : "store_key"
    dim_store ||--o{ fact_sales : "store_key"
    fact_orders ||--o{ fact_payment : "order_id"
    fact_orders ||--o{ fact_sales : "order_id"
    fact_orders ||--o{ fact_shipment : "order_id"
    dim_channel {
        INTEGER channel_key PK
        INTEGER channel_id
        VARCHAR code
        VARCHAR name
    }
    dim_customer {
        INTEGER customer_key PK
        INTEGER customer_id
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR full_name
        VARCHAR email
        VARCHAR status_desc
    }
    dim_date {
        INTEGER date_key PK
        DATE full_date
        INTEGER year
        INTEGER month
        VARCHAR month_name
        VARCHAR day_name
    }
    dim_location {
        INTEGER location_key PK
        INTEGER address_id
        VARCHAR city
        VARCHAR province_name
        VARCHAR province_code
    }
    dim_product {
        INTEGER product_key PK
        INTEGER product_id
        VARCHAR sku
        VARCHAR name
        VARCHAR category
        VARCHAR family
        DECIMAL list_price
    }
    dim_store {
        INTEGER store_key PK
        INTEGER store_id
        VARCHAR store_name
        VARCHAR city
        VARCHAR province_name
    }
    dm_nps {
        BIGINT nps_id
        INTEGER date_key
        DATE full_date
        INTEGER year
        INTEGER month
        VARCHAR month_name
        INTEGER customer_key
        INTEGER channel_key
        VARCHAR channel_name
        SMALLINT score
        VARCHAR nps_category
        DECIMAL puntos_nps
    }
    dm_orders {
        BIGINT order_id
        INTEGER date_key
        DATE full_date
        INTEGER year
        INTEGER month
        VARCHAR month_name
        INTEGER customer_key
        INTEGER channel_key
        VARCHAR channel_name
        INTEGER location_key
        VARCHAR province_name
        INTEGER store_key
        VARCHAR store_name
        DECIMAL ventas_sin_impuestos
        DECIMAL impuestos
        DECIMAL ventas_sin_envio
        DECIMAL costo_envio
        DECIMAL ventas_totales
    }
    dm_sales_products {
        BIGINT order_item_id
        BIGINT order_id
        INTEGER date_key
        DATE full_date
        INTEGER year
        INTEGER month
        VARCHAR month_name
        INTEGER product_key
        VARCHAR product_name
        VARCHAR product_category
        INTEGER customer_key
        INTEGER channel_key
        VARCHAR channel_name
        INTEGER location_key
        VARCHAR province_name
        INTEGER store_key
        VARCHAR store_name
        INTEGER unidades_vendidas
        DECIMAL ventas_producto
    }
    dm_web_active_users {
        BIGINT session_id
        INTEGER date_key
        DATE full_date
        INTEGER year
        INTEGER month
        VARCHAR month_name
        INTEGER customer_key
        VARCHAR source
        VARCHAR device
        VARCHAR usuario_activo_id
        VARCHAR tipo_usuario
    }
    fact_nps {
        BIGINT nps_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        SMALLINT score
        VARCHAR nps_category
    }
    fact_orders {
        BIGINT order_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER location_key FK
        INTEGER store_key FK
        VARCHAR status
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_fee
        DECIMAL total_amount
    }
    fact_payment {
        BIGINT payment_id PK
        BIGINT order_id FK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        VARCHAR status
        DECIMAL amount
    }
    fact_sales {
        BIGINT order_item_id PK
        BIGINT order_id FK
        INTEGER date_key FK
        INTEGER product_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER location_key FK
        INTEGER store_key FK
        INTEGER quantity
        DECIMAL line_total
        VARCHAR status
    }
    fact_shipment {
        BIGINT shipment_id PK
        BIGINT order_id FK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER location_key FK
        VARCHAR carrier
        VARCHAR status
        DECIMAL shipping_fee
    }
    fact_web_session {
        BIGINT session_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        VARCHAR source
        VARCHAR device
    }
```
