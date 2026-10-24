-- =====================================================================
-- FILE 2 OF 2: 02_questions_views.sql
-- Matches: olist_analysis_questions.pdf (10 questions)
-- Run top to bottom. Then query each view, e.g.
--   SELECT * FROM vw_late_vs_review ORDER BY bucket;
-- =====================================================================

-- =====================================================================
-- SECTION 0: MASTER TABLES (identical in both files)
-- Stored tables, so joins run once and the tables can be indexed.
-- Requires MySQL 8.0+. Database: oilst
-- REBUILD this section whenever import.py reloads the raw tables.
-- Revenue = SUM(price) on delivered orders. No profit exists in Olist.
-- ID and text columns are cast to fixed-length CHAR so they can be
-- keys and indexes (the raw TEXT columns cannot).
-- =====================================================================
USE oilst;


-- =====================================================================
-- Q1. DOES LATE DELIVERY HURT REVIEW SCORES?
-- =====================================================================

-- One row: on time vs late counts
CREATE OR REPLACE VIEW vw_late_summary AS
SELECT
    SUM(days_late <= 0)                                              AS on_time_orders,
    SUM(days_late > 0)                                               AS late_orders,
    ROUND(AVG(days_late > 0) * 100, 1)                               AS late_pct,
    ROUND(AVG(CASE WHEN days_late > 0 THEN days_late END), 1)        AS avg_days_late_when_late
FROM master_orders
WHERE order_status = 'delivered' AND delivered_ts IS NOT NULL;

-- Review score by days-late bucket
CREATE OR REPLACE VIEW vw_late_vs_review AS
SELECT
    bucket,
    COUNT(*)                              AS orders,
    ROUND(AVG(review_score), 2)           AS avg_review,
    ROUND(AVG(review_score <= 2) * 100, 1) AS pct_low_scores
FROM (
    SELECT review_score,
           CASE WHEN days_late <= 0 THEN 'On time or early'
                WHEN days_late <= 3 THEN '1-3 days late'
                WHEN days_late <= 7 THEN '4-7 days late'
                ELSE '8+ days late' END AS bucket
    FROM master_orders
    WHERE order_status = 'delivered'
      AND delivered_ts IS NOT NULL
      AND review_score IS NOT NULL
) as t
GROUP BY bucket;

-- =====================================================================
-- Q2. MONTHLY REVENUE AND ORDER TREND (with month-over-month growth)
-- Note: 2016 and the last months of 2018 are partial, so treat their
-- growth figures with care.
-- =====================================================================
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
    order_month,
    orders,
    revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month))
          / LAG(revenue) OVER (ORDER BY order_month) * 100, 1) AS mom_growth_pct
FROM (
    SELECT DATE_FORMAT(purchase_ts, '%Y-%m')  AS order_month,
           COUNT(DISTINCT order_id)           AS orders,
           ROUND(SUM(price), 2)               AS revenue
    FROM master_items
    WHERE order_status = 'delivered'
    GROUP BY DATE_FORMAT(purchase_ts, '%Y-%m')
) m;

-- =====================================================================
-- Q3. REPEAT CUSTOMER RATE (customer_unique_id)
-- =====================================================================
CREATE OR REPLACE VIEW vw_customer_order_counts AS
SELECT customer_unique_id, COUNT(*) AS orders
FROM master_orders
WHERE order_status = 'delivered'
GROUP BY customer_unique_id;

CREATE OR REPLACE VIEW vw_repeat_rate AS
SELECT
    COUNT(*)                         AS customers,
    SUM(orders > 1)                  AS repeat_customers,
    ROUND(AVG(orders > 1) * 100, 2)  AS repeat_rate_pct
FROM vw_customer_order_counts;

-- Distribution: how many customers placed 1, 2, 3... orders
CREATE OR REPLACE VIEW vw_orders_per_customer AS
SELECT orders AS orders_placed, COUNT(*) AS customers
FROM vw_customer_order_counts
GROUP BY orders;

-- =====================================================================
-- Q4. SELLER CONCENTRATION (PARETO)
-- decile = 1 is the top 10% of sellers by revenue.
-- Top 10% share: SELECT MAX(cum_revenue_pct) FROM vw_seller_pareto WHERE decile = 1;
-- =====================================================================
CREATE OR REPLACE VIEW vw_seller_pareto AS
SELECT
    seller_id,
    revenue,
    NTILE(10) OVER (ORDER BY revenue DESC, seller_id) AS decile,
    ROW_NUMBER() OVER (ORDER BY revenue DESC, seller_id) AS revenue_rank,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC, seller_id
                             ROWS UNBOUNDED PRECEDING)
          / SUM(revenue) OVER () * 100, 2) AS cum_revenue_pct
FROM (
    SELECT seller_id, ROUND(SUM(price), 2) AS revenue
    FROM master_items
    WHERE order_status = 'delivered'
    GROUP BY seller_id
) s;

-- =====================================================================
-- Q5. PAYMENT BEHAVIOUR
-- =====================================================================
CREATE OR REPLACE VIEW vw_payment_types AS
SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id)                                   AS orders,
    ROUND(SUM(p.payment_value), 2)                               AS payment_value,
    ROUND(SUM(p.payment_value) / SUM(SUM(p.payment_value)) OVER () * 100, 1) AS value_share_pct,
    ROUND(AVG(p.payment_installments), 1)                        AS avg_installments
FROM order_payments p
JOIN master_orders o ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type;

-- =====================================================================
-- Q6. CANCELLED / UNAVAILABLE ORDERS
-- =====================================================================

-- Overall status mix
CREATE OR REPLACE VIEW vw_order_status_overall AS
SELECT
    order_status,
    COUNT(*)                                         AS orders,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_orders
FROM master_orders
GROUP BY order_status;

-- By customer state
CREATE OR REPLACE VIEW vw_unsuccessful_by_state AS
SELECT
    customer_state,
    COUNT(*)                                                         AS orders,
    SUM(order_status IN ('canceled', 'unavailable'))                 AS canceled_or_unavailable,
    ROUND(AVG(order_status IN ('canceled', 'unavailable')) * 100, 2) AS pct
FROM master_orders
GROUP BY customer_state;

-- By category (30+ orders)
CREATE OR REPLACE VIEW vw_unsuccessful_by_category AS
SELECT
    category,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT CASE WHEN order_status IN ('canceled', 'unavailable') THEN order_id END) AS canceled_or_unavailable,
    ROUND(COUNT(DISTINCT CASE WHEN order_status IN ('canceled', 'unavailable') THEN order_id END)
          / COUNT(DISTINCT order_id) * 100, 2) AS pct
FROM master_items
GROUP BY category
HAVING COUNT(DISTINCT order_id) >= 30;

-- =====================================================================
-- Q7. FREIGHT vs WEIGHT AND VOLUME
-- =====================================================================
CREATE OR REPLACE VIEW vw_freight_by_weight AS
SELECT
    weight_band,
    COUNT(*)                                   AS items,
    ROUND(AVG(freight_value), 2)               AS avg_freight,
    ROUND(SUM(freight_value) / SUM(price) * 100, 1) AS freight_pct_of_price
FROM (
    SELECT price, freight_value,
           CASE WHEN product_weight_g IS NULL  THEN '0. unknown'
                WHEN product_weight_g < 500    THEN '1. under 500 g'
                WHEN product_weight_g < 1000   THEN '2. 500 g - 1 kg'
                WHEN product_weight_g < 2000   THEN '3. 1 - 2 kg'
                WHEN product_weight_g < 5000   THEN '4. 2 - 5 kg'
                ELSE '5. 5 kg and over' END AS weight_band
    FROM master_items
    WHERE order_status = 'delivered'
) t
GROUP BY weight_band;

CREATE OR REPLACE VIEW vw_freight_by_volume AS
SELECT
    volume_band,
    COUNT(*)                                   AS items,
    ROUND(AVG(freight_value), 2)               AS avg_freight,
    ROUND(SUM(freight_value) / SUM(price) * 100, 1) AS freight_pct_of_price
FROM (
    SELECT price, freight_value,
           CASE WHEN volume_cm3 IS NULL    THEN '0. unknown'
                WHEN volume_cm3 < 2000     THEN '1. under 2,000 cm3'
                WHEN volume_cm3 < 5000     THEN '2. 2,000 - 5,000 cm3'
                WHEN volume_cm3 < 15000    THEN '3. 5,000 - 15,000 cm3'
                WHEN volume_cm3 < 50000    THEN '4. 15,000 - 50,000 cm3'
                ELSE '5. 50,000 cm3 and over' END AS volume_band
    FROM master_items
    WHERE order_status = 'delivered'
) t
GROUP BY volume_band;

-- =====================================================================
-- Q8. PRICE BANDS: SALES AND REVIEWS
-- avg_review is weighted by items (an order's score repeats per item).
-- =====================================================================
CREATE OR REPLACE VIEW vw_price_bands AS
SELECT
    price_band,
    COUNT(*)                                   AS items_sold,
    ROUND(SUM(price), 2)                       AS revenue,
    ROUND(AVG(review_score), 2)                AS avg_review
FROM (
    SELECT price, review_score,
           CASE WHEN price < 25   THEN '1. under 25'
                WHEN price < 50   THEN '2. 25 - 50'
                WHEN price < 100  THEN '3. 50 - 100'
                WHEN price < 200  THEN '4. 100 - 200'
                WHEN price < 500  THEN '5. 200 - 500'
                ELSE '6. 500 and over' END AS price_band
    FROM master_items
    WHERE order_status = 'delivered'
) t
GROUP BY price_band;

-- =====================================================================
-- Q9. WHEN DO PEOPLE BUY? (weekday x hour; weekday_no 0 = Monday)
-- =====================================================================
CREATE OR REPLACE VIEW vw_orders_by_weekday_hour AS
SELECT
    WEEKDAY(purchase_ts)   AS weekday_no,
    DAYNAME(purchase_ts)   AS weekday_name,
    HOUR(purchase_ts)      AS hour_of_day,
    COUNT(*)               AS orders
FROM master_orders
GROUP BY WEEKDAY(purchase_ts), DAYNAME(purchase_ts), HOUR(purchase_ts);

-- =====================================================================
-- Q10. SAME-STATE vs CROSS-STATE DELIVERY
-- Item level, so multi-seller orders are counted per seller route.
-- =====================================================================
CREATE OR REPLACE VIEW vw_route_summary AS
SELECT
    route,
    COUNT(*)                                        AS items,
    COUNT(DISTINCT order_id)                        AS orders,
    ROUND(AVG(delivery_days), 1)                    AS avg_delivery_days,
    ROUND(AVG(is_late) * 100, 1)                    AS late_pct,
    ROUND(SUM(freight_value) / SUM(price) * 100, 1) AS freight_pct_of_price
FROM (
    SELECT order_id, price, freight_value, delivery_days, is_late,
           CASE WHEN customer_state = seller_state THEN 'Same state'
                ELSE 'Cross state' END AS route
    FROM master_items
    WHERE order_status = 'delivered' AND delivered_ts IS NOT NULL
) t
GROUP BY route;

CREATE OR REPLACE VIEW vw_route_by_customer_state AS
SELECT
    customer_state,
    route,
    COUNT(*)                         AS items,
    ROUND(AVG(delivery_days), 1)     AS avg_delivery_days,
    ROUND(AVG(is_late) * 100, 1)     AS late_pct
FROM (
    SELECT customer_state, delivery_days, is_late,
           CASE WHEN customer_state = seller_state THEN 'Same state'
                ELSE 'Cross state' END AS route
    FROM master_items
    WHERE order_status = 'delivered' AND delivered_ts IS NOT NULL
) t
GROUP BY customer_state, route;

-- =====================================================================
-- CHECKS
-- =====================================================================
-- SELECT * FROM vw_late_summary;
-- SELECT * FROM vw_late_vs_review ORDER BY bucket;
-- SELECT * FROM vw_repeat_rate;
-- SELECT MAX(cum_revenue_pct) AS top_10pct_sellers_share FROM vw_seller_pareto WHERE decile = 1;
