-- 07 | Customer value tiers using NTILE and the revenue share of the top decile
-- Concepts: NTILE, window SUM for share of total, CASE tiers
WITH spend AS (
    SELECT customer_id, COUNT(*) AS orders, SUM(order_value - discount_amount + delivery_fee) AS spend
    FROM orders WHERE status = 'Delivered' GROUP BY customer_id
),
tiered AS (
    SELECT *, NTILE(10) OVER (ORDER BY spend DESC) AS decile FROM spend
)
SELECT decile, COUNT(*) AS customers, ROUND(AVG(orders), 1) AS avg_orders, ROUND(SUM(spend), 0) AS total_spend,
       ROUND(100.0 * SUM(spend) / SUM(SUM(spend)) OVER (), 1) AS pct_of_revenue,
       ROUND(100.0 * SUM(SUM(spend)) OVER (ORDER BY decile) / SUM(SUM(spend)) OVER (), 1) AS cumulative_pct
FROM tiered
GROUP BY decile
ORDER BY decile;
