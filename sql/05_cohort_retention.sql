-- 05 | Monthly signup-cohort retention (% of a cohort that orders again in month N after signup)
-- Concepts: multi-step CTEs, date arithmetic, COUNT(DISTINCT), self-referencing cohort sizes
WITH cohort AS (
    SELECT customer_id, strftime('%Y-%m', signup_date) AS cohort_month,
           CAST(strftime('%Y', signup_date) AS INT) * 12 + CAST(strftime('%m', signup_date) AS INT) AS cohort_idx
    FROM customers
),
activity AS (
    SELECT DISTINCT o.customer_id,
           CAST(strftime('%Y', o.order_ts) AS INT) * 12 + CAST(strftime('%m', o.order_ts) AS INT) AS order_idx
    FROM orders o WHERE o.status = 'Delivered'
),
cohort_activity AS (
    SELECT c.cohort_month, a.order_idx - c.cohort_idx AS month_number, COUNT(DISTINCT a.customer_id) AS active_customers
    FROM cohort c JOIN activity a ON a.customer_id = c.customer_id
    GROUP BY 1, 2
),
cohort_size AS (SELECT cohort_month, COUNT(*) AS cohort_customers FROM cohort GROUP BY 1)
SELECT ca.cohort_month, cs.cohort_customers, ca.month_number, ca.active_customers,
       ROUND(100.0 * ca.active_customers / cs.cohort_customers, 1) AS retention_pct
FROM cohort_activity ca JOIN cohort_size cs USING (cohort_month)
ORDER BY ca.cohort_month, ca.month_number;
