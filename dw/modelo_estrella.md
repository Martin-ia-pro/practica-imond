# Modelo estrella

Generado por `run_sql.py` a partir de las tablas de `warehouse.duckdb`.

```mermaid
erDiagram
    dim_channel ||--o{ fact_nps : "channel_key"
    dim_channel ||--o{ fact_sales : "channel_key"
    dim_customer ||--o{ fact_nps : "customer_key"
    dim_customer ||--o{ fact_sales : "customer_key"
    dim_customer ||--o{ fact_web_session : "customer_key"
    dim_date ||--o{ fact_nps : "date_key"
    dim_date ||--o{ fact_sales : "date_key"
    dim_date ||--o{ fact_sales_item : "date_key"
    dim_date ||--o{ fact_web_session : "date_key"
    dim_location ||--o{ fact_sales : "location_key"
    dim_product ||--o{ fact_sales_item : "product_key"
    fact_sales ||--o{ fact_sales_item : "sales_id"
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
    fact_nps {
        BIGINT nps_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        SMALLINT score
        VARCHAR nps_category
    }
    fact_sales {
        INTEGER sales_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER location_key FK
        VARCHAR status
        DECIMAL total_amount
    }
    fact_sales_item {
        BIGINT order_item_id PK
        INTEGER sales_id FK
        INTEGER date_key FK
        INTEGER product_key FK
        INTEGER quantity
        DECIMAL line_total
        VARCHAR status
    }
    fact_web_session {
        BIGINT session_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        VARCHAR source
        VARCHAR device
    }
```
