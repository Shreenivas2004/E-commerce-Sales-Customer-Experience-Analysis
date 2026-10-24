-- =====================================================================
-- FILE 1 OF 2: 01_plan_views.sql
-- Matches: my_sql_plan.pdf (best performing, metrics, photos question)
-- Run top to bottom. Then query each view, e.g.
--   SELECT * FROM vw_best_states ORDER BY revenue DESC;
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

-- ---------------------------------------------------------------------
-- master_orders: one row per order.
-- Late = delivered on a later DATE than estimated.
-- ---------------------------------------------------------------------

-- Check now: master_orders = 99,441 rows; master_items = rows in order_items
-- SELECT COUNT(*) FROM master_orders;
-- SELECT COUNT(*) FROM master_items;  SELECT COUNT(*) FROM order_items;

-- =====================================================================
-- SECTION 1: BEST PERFORMING
-- Ranked by revenue. Sellers, categories and cities need 30+ orders.
-- =====================================================================

-- 1a. Product
CREATE OR REPLACE VIEW vw_best_products AS
SELECT
    product_id,
    category,
    COUNT(*)                     AS items_sold,
    COUNT(DISTINCT order_id)     AS orders,
    ROUND(SUM(price), 2)         AS revenue
FROM master_items
WHERE order_status = 'delivered'
GROUP BY product_id, category;

-- 1b. State (customer state)
CREATE OR REPLACE VIEW vw_best_states AS
SELECT
    i.customer_state,
    COUNT(DISTINCT i.order_id)                                   AS orders,
    ROUND(SUM(i.price), 2)                                       AS revenue,
    ROUND(SUM(i.price) / COUNT(DISTINCT i.order_id), 2)          AS aov,
    ROUND(SUM(i.freight_value) / SUM(i.price) * 100, 1)          AS freight_pct_of_price
FROM master_items i
WHERE i.order_status = 'delivered'
GROUP BY i.customer_state;

-- 1c. City (customer city)
CREATE OR REPLACE VIEW vw_best_cities AS
SELECT
    customer_state,
    customer_city,
    COUNT(DISTINCT order_id)                            AS orders,
    ROUND(SUM(price), 2)                                AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)     AS aov
FROM master_items
WHERE order_status = 'delivered'
GROUP BY customer_state, customer_city
HAVING COUNT(DISTINCT order_id) >= 30;

-- 1d. Customers (customer_unique_id, not customer_id)
CREATE OR REPLACE VIEW vw_best_customers AS
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id)                            AS orders,
    ROUND(SUM(price), 2)                                AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)     AS aov
FROM master_items
WHERE order_status = 'delivered'
GROUP BY customer_unique_id;

-- 1e. Seller (with average review, one score per order-seller pair)
CREATE OR REPLACE VIEW vw_best_sellers AS
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    s.orders,
    s.items_sold,
    s.revenue,
    s.aov,
    r.avg_review
FROM (
    SELECT seller_id, seller_city, seller_state,
           COUNT(DISTINCT order_id)                        AS orders,
           COUNT(*)                                        AS items_sold,
           ROUND(SUM(price), 2)                            AS revenue,
           ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS aov
    FROM master_items
    WHERE order_status = 'delivered'
    GROUP BY seller_id, seller_city, seller_state
    HAVING COUNT(DISTINCT order_id) >= 30
) s
LEFT JOIN (
    SELECT seller_id, ROUND(AVG(review_score), 2) AS avg_review
    FROM (SELECT DISTINCT seller_id, order_id, review_score
          FROM master_items WHERE order_status = 'delivered') d
    GROUP BY seller_id
) r ON r.seller_id = s.seller_id;

-- 1f. Seller city
CREATE OR REPLACE VIEW vw_best_seller_cities AS
SELECT
    seller_state,
    seller_city,
    COUNT(DISTINCT seller_id)                           AS sellers,
    COUNT(DISTINCT order_id)                            AS orders,
    ROUND(SUM(price), 2)                                AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)     AS aov
FROM master_items
WHERE order_status = 'delivered'
GROUP BY seller_state, seller_city
HAVING COUNT(DISTINCT order_id) >= 30;

-- 1g. Category (with average review, one score per order-category pair)
CREATE OR REPLACE VIEW vw_best_categories AS
SELECT
    c.category,
    c.orders,
    c.items_sold,
    c.revenue,
    c.aov,
    r.avg_review
FROM (
    SELECT category,
           COUNT(DISTINCT order_id)                        AS orders,
           COUNT(*)                                        AS items_sold,
           ROUND(SUM(price), 2)                            AS revenue,
           ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS aov
    FROM master_items
    WHERE order_status = 'delivered'
    GROUP BY category
    HAVING COUNT(DISTINCT order_id) >= 30
) c
LEFT JOIN (
    SELECT category, ROUND(AVG(review_score), 2) AS avg_review
    FROM (SELECT DISTINCT category, order_id, review_score
          FROM master_items WHERE order_status = 'delivered') d
    GROUP BY category
) r ON r.category = c.category;

-- =====================================================================
-- SECTION 2: METRICS
-- (AOV per customer, seller, city is inside the views above.)
-- Profit is replaced by revenue and freight % of price.
-- =====================================================================

-- 2a. Average review score per state (order level, so no double counting)
CREATE OR REPLACE VIEW vw_review_by_state AS
SELECT
    customer_state,
    COUNT(*)                          AS orders,
    ROUND(AVG(review_score), 2)       AS avg_review,
    ROUND(AVG(delivery_days), 1)      AS avg_delivery_days,
    ROUND(AVG(is_late) * 100, 1)      AS late_pct
FROM master_orders
WHERE order_status = 'delivered' AND delivered_ts IS NOT NULL
GROUP BY customer_state;

-- 2b. One-row summary: average revenue per customer and per seller
CREATE OR REPLACE VIEW vw_avg_revenue_summary AS
SELECT
    ROUND(SUM(price) / COUNT(DISTINCT customer_unique_id), 2) AS avg_revenue_per_customer,
    ROUND(SUM(price) / COUNT(DISTINCT seller_id), 2)          AS avg_revenue_per_seller,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)           AS overall_aov,
    ROUND(SUM(freight_value) / SUM(price) * 100, 1)           AS freight_pct_of_price
FROM master_items
WHERE order_status = 'delivered';


-- 3a. Photos
CREATE OR REPLACE VIEW vw_photos_vs_sales AS
SELECT
    product_photos_qty,
    COUNT(*)                          AS products,
    SUM(items_sold)                   AS items_sold,
    ROUND(AVG(items_sold), 2)         AS avg_sales_per_product,
    ROUND(AVG(items_sold > 0) * 100, 1) AS pct_products_sold
FROM master_product_sales
WHERE product_photos_qty IS NOT NULL
GROUP BY product_photos_qty;

-- 3b. Product name length (10-character buckets)
CREATE OR REPLACE VIEW vw_name_length_vs_sales AS
SELECT
    FLOOR(product_name_lenght / 10) * 10 AS name_length_from,
    COUNT(*)                          AS products,
    SUM(items_sold)                   AS items_sold,
    ROUND(AVG(items_sold), 2)         AS avg_sales_per_product,
    ROUND(AVG(items_sold > 0) * 100, 1) AS pct_products_sold
FROM master_product_sales
WHERE product_name_lenght IS NOT NULL
GROUP BY FLOOR(product_name_lenght / 10) * 10;

-- 3c. Description length (500-character buckets)
CREATE OR REPLACE VIEW vw_description_length_vs_sales AS
SELECT
    FLOOR(product_description_lenght / 500) * 500 AS description_length_from,
    COUNT(*)                          AS products,
    SUM(items_sold)                   AS items_sold,
    ROUND(AVG(items_sold), 2)         AS avg_sales_per_product,
    ROUND(AVG(items_sold > 0) * 100, 1) AS pct_products_sold
FROM master_product_sales
WHERE product_description_lenght IS NOT NULL
GROUP BY FLOOR(product_description_lenght / 500) * 500;

-- 3d. Dimensions: weight bands
CREATE OR REPLACE VIEW vw_weight_vs_sales AS
SELECT
    weight_band,
    COUNT(*)                          AS products,
    SUM(items_sold)                   AS items_sold,
    ROUND(AVG(items_sold), 2)         AS avg_sales_per_product
FROM (
    SELECT items_sold,
           CASE WHEN product_weight_g IS NULL  THEN '0. unknown'
                WHEN product_weight_g < 500    THEN '1. under 500 g'
                WHEN product_weight_g < 1000   THEN '2. 500 g - 1 kg'
                WHEN product_weight_g < 2000   THEN '3. 1 - 2 kg'
                WHEN product_weight_g < 5000   THEN '4. 2 - 5 kg'
                ELSE '5. 5 kg and over' END AS weight_band
    FROM master_product_sales
) t
GROUP BY weight_band;

-- 3e. Dimensions: volume bands (length x height x width)
CREATE OR REPLACE VIEW vw_volume_vs_sales AS
SELECT
    volume_band,
    COUNT(*)                          AS products,
    SUM(items_sold)                   AS items_sold,
    ROUND(AVG(items_sold), 2)         AS avg_sales_per_product
FROM (
    SELECT items_sold,
           CASE WHEN volume_cm3 IS NULL    THEN '0. unknown'
                WHEN volume_cm3 < 2000     THEN '1. under 2,000 cm3'
                WHEN volume_cm3 < 5000     THEN '2. 2,000 - 5,000 cm3'
                WHEN volume_cm3 < 15000    THEN '3. 5,000 - 15,000 cm3'
                WHEN volume_cm3 < 50000    THEN '4. 15,000 - 50,000 cm3'
                ELSE '5. 50,000 cm3 and over' END AS volume_band
    FROM master_product_sales
) t
GROUP BY volume_band;

-- =====================================================================
-- CHECKS (run these before Power BI)
-- =====================================================================
-- SELECT COUNT(*) FROM master_orders;                                   -- expect 99,441
-- SELECT COUNT(*) FROM master_items;                              -- must equal COUNT(*) FROM order_items
-- SELECT ROUND(SUM(price),2) FROM master_items WHERE order_status='delivered';
--   -- must equal SUM(revenue) from vw_best_products
-- SELECT * FROM vw_best_states ORDER BY revenue DESC;
