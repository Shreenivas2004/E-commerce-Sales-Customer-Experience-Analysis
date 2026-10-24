use oilst;
ALTER TABLE customers MODIFY customer_id VARCHAR(32), MODIFY customer_unique_id VARCHAR(32);
ALTER TABLE orders MODIFY order_id VARCHAR(32), MODIFY customer_id VARCHAR(32);
ALTER TABLE order_items MODIFY order_id VARCHAR(32), MODIFY product_id VARCHAR(32), MODIFY seller_id VARCHAR(32);
ALTER TABLE products MODIFY product_id VARCHAR(32);
ALTER TABLE sellers MODIFY seller_id VARCHAR(32);

ALTER TABLE customers ADD PRIMARY KEY (customer_id);
ALTER TABLE orders ADD PRIMARY KEY (order_id);
ALTER TABLE products ADD PRIMARY KEY (product_id);
ALTER TABLE sellers ADD PRIMARY KEY (seller_id);
ALTER TABLE order_items ADD PRIMARY KEY (order_id, order_item_id);

ALTER TABLE orders ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE order_items ADD FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE order_items ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE order_items ADD FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);