-- 06 | Which acquisition channel brings the best customers? (orders, spend, repeat rate per customer)
-- Concepts: LEFT JOIN, CTE per customer, aggregating an aggregate, repeat-rate ratio
WITH per_customer AS (
    SELECT c.customer_id, c.acquisition_channel,
           COUNT(o.order_id) AS orders,
           COALESCE(SUM(o.order_value - o.discount_amount + o.delivery_fee), 0) AS spend
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Delivered'
    GROUP BY c.customer_id
)
SELECT acquisition_channel,
       COUNT(*)                                                     AS customers,
       ROUND(AVG(orders), 2)                                        AS avg_orders,
       ROUND(AVG(spend), 0)                                         AS avg_ltv,
       ROUND(100.0 * SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN orders = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS never_delivered_pct
FROM per_customer
GROUP BY acquisition_channel
ORDER BY avg_ltv DESC;
