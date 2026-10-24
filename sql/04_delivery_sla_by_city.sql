-- 04 | Delivery SLA by city incl. median and P90 (SQLite has no PERCENTILE function, so we build it with window functions)
-- Concepts: ROW_NUMBER + COUNT window to pick percentile rows, CTEs, joins of two aggregates
WITH delivered AS (
    SELECT c.city, o.delivery_minutes
    FROM orders o JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'Delivered'
),
ranked AS (
    SELECT city, delivery_minutes,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY delivery_minutes) AS rn,
           COUNT(*)     OVER (PARTITION BY city)                           AS n
    FROM delivered
),
pctl AS (
    SELECT city,
           MIN(CASE WHEN rn >= 0.50 * n THEN delivery_minutes END) AS median_min,
           MIN(CASE WHEN rn >= 0.90 * n THEN delivery_minutes END) AS p90_min
    FROM ranked GROUP BY city
)
SELECT d.city, COUNT(*) AS delivered_orders, ROUND(AVG(d.delivery_minutes), 1) AS avg_min,
       p.median_min, p.p90_min,
       ROUND(100.0 * SUM(CASE WHEN d.delivery_minutes <= 40 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_40min
FROM delivered d JOIN pctl p ON p.city = d.city
GROUP BY d.city
ORDER BY avg_min DESC;
