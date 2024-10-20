-- CLTV calculation query (from previous step)
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        COUNT(t.transaction_id) AS total_purchases,
        SUM(ti.quantity * p.price) AS total_revenue,
        MAX(t.transaction_date) AS last_purchase_date,
        MIN(t.transaction_date) AS first_purchase_date,
        COUNT(DISTINCT t.transaction_date) AS purchase_days
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
),
customer_metrics AS (
    SELECT 
        customer_id,
        customer_name,
        total_purchases,
        total_revenue,
        (total_revenue / total_purchases) AS avg_order_value,
        (total_purchases / NULLIF(DATEDIFF(day, first_purchase_date, last_purchase_date), 0)) AS purchase_frequency,
        DATEDIFF(day, last_purchase_date, CURRENT_DATE) AS recency
    FROM customer_revenue
),
customer_cltv AS (
    SELECT 
        customer_id,
        customer_name,
        total_revenue,
        avg_order_value,
        purchase_frequency,
        recency,
        (avg_order_value * purchase_frequency / NULLIF(recency, 0)) AS cltv
    FROM customer_metrics
)
SELECT 
    customer_id,
    customer_name,
    ROUND(cltv, 2) AS cltv,
    total_revenue,
    avg_order_value,
    purchase_frequency,
    recency
FROM customer_cltv
ORDER BY cltv DESC
LIMIT 10;
