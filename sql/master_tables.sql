use oilst;
DROP TABLE IF EXISTS master_orders;
CREATE TABLE master_orders AS
SELECT
    t.*,
    DATEDIFF(delivered_ts, estimated_ts) AS days_late,
    DATEDIFF(delivered_ts, purchase_ts)  AS delivery_days,
    CASE WHEN delivered_ts IS NULL THEN NULL
         WHEN DATEDIFF(delivered_ts, estimated_ts) > 0 THEN 1
         ELSE 0 END AS is_late
FROM (
    SELECT
        CAST(o.order_id           AS CHAR(32))  AS order_id,
        CAST(c.customer_unique_id AS CHAR(32))  AS customer_unique_id,
        CAST(c.customer_state     AS CHAR(2))   AS customer_state,
        CAST(c.customer_city      AS CHAR(100)) AS customer_city,
        CAST(o.order_status       AS CHAR(20))  AS order_status,
        CAST(o.order_purchase_timestamp      AS DATETIME) AS purchase_ts,
        CAST(o.order_delivered_customer_date AS DATETIME) AS delivered_ts,
        CAST(o.order_estimated_delivery_date AS DATETIME) AS estimated_ts,
        r.review_score,
        p.payment_value
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score
               FROM order_reviews GROUP BY order_id) r ON r.order_id = o.order_id
    LEFT JOIN (SELECT order_id, SUM(payment_value) AS payment_value
               FROM order_payments GROUP BY order_id) p ON p.order_id = o.order_id
) t;

ALTER TABLE master_orders
    ADD PRIMARY KEY (order_id),
    ADD INDEX idx_mo_customer (customer_unique_id),
    ADD INDEX idx_mo_state    (customer_state),
    ADD INDEX idx_mo_status   (order_status),
    ADD INDEX idx_mo_purchase (purchase_ts);

-- ---------------------------------------------------------------------
-- master_items: one row per order item, with product, seller, customer
-- and order fields.
-- Note: review_score and delivery fields repeat for each item of an
-- order, so never SUM them. AVG over this table is weighted by items.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS master_items;
CREATE TABLE master_items AS
SELECT
    o.order_id,
    oi.order_item_id,
    CAST(oi.product_id AS CHAR(32)) AS product_id,
    CAST(oi.seller_id  AS CHAR(32)) AS seller_id,
    oi.price,
    oi.freight_value,
    CAST(COALESCE(ct.product_category_name_english,
                  pr.product_category_name, 'unknown') AS CHAR(80)) AS category,
    pr.product_photos_qty,
    pr.product_name_lenght,
    pr.product_description_lenght,
    pr.product_weight_g,
    pr.product_length_cm * pr.product_height_cm * pr.product_width_cm AS volume_cm3,
    CAST(s.seller_city  AS CHAR(100)) AS seller_city,
    CAST(s.seller_state AS CHAR(2))   AS seller_state,
    o.order_status,
    o.customer_unique_id,
    o.customer_state,
    o.customer_city,
    o.purchase_ts,
    o.delivered_ts,
    o.delivery_days,
    o.days_late,
    o.is_late,
    o.review_score
FROM order_items oi
JOIN master_orders o        ON o.order_id = oi.order_id
LEFT JOIN products pr       ON pr.product_id = oi.product_id
LEFT JOIN category_name ct  ON ct.product_category_name = pr.product_category_name
LEFT JOIN sellers s         ON s.seller_id = oi.seller_id;

ALTER TABLE master_items
    ADD PRIMARY KEY (order_id, order_item_id),
    ADD INDEX idx_mi_seller   (seller_id),
    ADD INDEX idx_mi_product  (product_id),
    ADD INDEX idx_mi_state    (customer_state),
    ADD INDEX idx_mi_category (category),
    ADD INDEX idx_mi_status   (order_status),
    ADD INDEX idx_mi_customer (customer_unique_id);

-- =====================================================================
-- SECTION 3: DO MORE PHOTOS MEAN MORE ORDERS?
-- LEFT JOIN keeps unsold products, otherwise the result is biased.
-- Say "associated with", not "causes".
-- =====================================================================

-- Base table: one row per product, with its sales (delivered orders only)
DROP TABLE IF EXISTS master_product_sales;
CREATE TABLE master_product_sales AS
SELECT
    CAST(p.product_id AS CHAR(32)) AS product_id,
    CAST(COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS CHAR(80)) AS category,
    p.product_photos_qty,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_weight_g,
    p.product_length_cm * p.product_height_cm * p.product_width_cm AS volume_cm3,
    COUNT(o.order_id)                                              AS items_sold,
    COALESCE(SUM(CASE WHEN o.order_id IS NOT NULL THEN oi.price END), 0) AS revenue
FROM products p
LEFT JOIN category_name ct ON ct.product_category_name = p.product_category_name
LEFT JOIN order_items oi   ON oi.product_id = p.product_id
LEFT JOIN master_orders o  ON o.order_id = oi.order_id AND o.order_status = 'delivered'
GROUP BY p.product_id, ct.product_category_name_english, p.product_category_name,
         p.product_photos_qty, p.product_name_lenght, p.product_description_lenght,
         p.product_weight_g, p.product_length_cm, p.product_height_cm, p.product_width_cm;

ALTER TABLE master_product_sales ADD PRIMARY KEY (product_id);


DROP TABLE IF EXISTS geo_buyers;
CREATE TABLE geo_buyers AS
SELECT c.customer_state AS state, c.customer_city AS city,
       ROUND(AVG(g.geolocation_lat), 4) AS lat, ROUND(AVG(g.geolocation_lng), 4) AS lng,
       COUNT(DISTINCT c.customer_unique_id) AS customers,
       COUNT(DISTINCT o.order_id)           AS orders,
       ROUND(SUM(oi.price), 2)              AS revenue
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN geolocation g     ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, c.customer_city;

DROP TABLE IF EXISTS geo_sellers;
CREATE TABLE geo_sellers AS
SELECT s.seller_state AS state, s.seller_city AS city,
       ROUND(AVG(g.geolocation_lat), 4) AS lat, ROUND(AVG(g.geolocation_lng), 4) AS lng,
       COUNT(*) AS sellers,
       ROUND(SUM(r.revenue), 2) AS revenue
FROM (SELECT seller_id, SUM(price) AS revenue
      FROM master_items WHERE order_status = 'delivered'
      GROUP BY seller_id) r
JOIN sellers s ON s.seller_id = r.seller_id
JOIN geolocation g     ON g.geolocation_zip_code_prefix = s.seller_zip_code_prefix
GROUP BY s.seller_state, s.seller_city;

DROP TABLE IF EXISTS tmp_order_rev;
CREATE TABLE tmp_order_rev AS
SELECT order_id, ROUND(SUM(price), 2) AS revenue
FROM master_items WHERE order_status = 'delivered'
GROUP BY order_id;
ALTER TABLE tmp_order_rev ADD PRIMARY KEY (order_id);

DROP TABLE IF EXISTS geo_buyers;
CREATE TABLE geo_buyers AS
SELECT c.customer_state AS state, c.customer_city AS city,
       ROUND(AVG(g.geolocation_lat), 4) AS lat, ROUND(AVG(g.geolocation_lng), 4) AS lng,
       COUNT(DISTINCT c.customer_unique_id) AS customers,
       COUNT(*) AS orders,
       ROUND(SUM(r.revenue), 2) AS revenue
FROM tmp_order_rev r
JOIN orders o    ON o.order_id = r.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN geolocation g   ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
GROUP BY c.customer_state, c.customer_city;

