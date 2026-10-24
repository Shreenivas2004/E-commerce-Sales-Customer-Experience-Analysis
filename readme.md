# E-commerce Sales & Customer Experience Analysis

End-to-end analysis of the Olist Brazilian e-commerce dataset: raw CSVs loaded into MySQL with Python, modelled with SQL views and master tables, and presented in a 5-page Power BI dashboard.

**Tools:** Python (pandas, SQLAlchemy), MySQL, Power BI, DAX
--
## Dashboard

| Page | What it answers |
|---|---|
| Overview | Revenue, orders, AOV, repeat rate, review score and late % over time |
| Products and regions | Top categories and states by revenue, freight as % of price by state |
| Delivery and satisfaction | Review score by delivery outcome, late % by state and month |
| Customers and sellers | Where buyers and sellers are concentrated, by state |
| Listing quality | Whether photos and description length relate to sales per product |

![Overview](images/overview.png)
![Products and regions](images/products_regions.png)
![Delivery and satisfaction](images/delivery_satisfaction.png)
![Customers and sellers](images/customers_sellers.png)
![Listing quality](images/listing_quality.png)

## Data

- **Source:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle. About 100,000 orders from 2016 to 2018.
- **Tables loaded (8):** customers, orders, order items, order payments, order reviews, products, sellers, product category name translation, Geolocation.
-  The dataset has no cost or profit data, so the project reports revenue, not profit.

---

## Project structure

```
.
├── import_table_to_sql.py     # loads the CSVs into MySQL
├── sql/
│   ├── Table appropriation.sql   # primary and foreign keys on the raw tables
│   ├── master_table.sql          # master_orders and master_items tables
│   ├── 01.sql                    # views for the analysis plan
│   └── 02.sql                    # views for the 10 business questions
│── Data Files 
│   ├──oilst_customer_dataset.csv
│   ├──oilst_geolocation_dataset.csv
│   ├──oilst_order_items_dataset.csv
│   ├──oilst_order_payments_dataset.csv
│   ├──oilst_order_reviews_dataset.csv
│   ├──oilst_order_dataset.csv
│   ├──oilst_products_dataset.csv
│   ├──oilst_sellers_dataset.csvde
│   └──product_category_name_translation.csv
├── Dashboard.pbix
├── images/                    # dashboard screenshots
└── README.md
```

---

## How to run it

**Requirements:** Python 3, MySQL 8.0 or newer (the views use window functions), and the Olist CSV files.

1. Clone the repository:
   ```
   git clone https://github.com/Shreenivas2004/E-commerce-Sales-Customer-Experience-Analysis
   ```
2. Install the Python packages:
   ```
   pip install pandas sqlalchemy mysql-connector-python
   ```
3. Create the database in MySQL:
   ```sql
   CREATE DATABASE oilst;
   ```
4. run the script. It asks for your MySQL password and prints progress as each table loads:
   ```
   python import_table_to_sql.py
   ```
   Keep the original folder structure intact.
5. Run the SQL files in this order:
   `Table appropriation.sql` → `master_table.sql` → `01.sql` → `02.sql`
6. Check the build:
   ```sql
   SELECT COUNT(*) FROM master_orders;   -- 99,441
   SELECT COUNT(*) FROM master_items;    -- equals the row count of order_items
   ```

If the counts match, the tables and views are ready to query or connect to Power BI.


---

## What each file does

| File | Purpose |
|---|---|
| `import_table_to_sql.py` | Reads the CSVs with pandas and writes them to MySQL. The `oilst` database must already exist |
| `Table appropriation.sql` | Sets primary and foreign keys, because pandas does not create them. Needed for the joins and for an ER diagram |
| `master_table.sql` | Builds `master_orders` (one row per order) and `master_items` (one row per order item), with indexes. Everything downstream reads from these |
| `01.sql` | Views for the analysis plan: best performing products, states, cities, customers, sellers and categories; metrics; and the photos and listing-quality questions (via `master_product_sales`) |
| `02.sql` | Views for 10 business questions: late delivery vs reviews, monthly trend, repeat customers, seller concentration, payments, cancellations, freight, price bands, buying times, same-state vs cross-state delivery |

### Why two master tables

An order can have several items, payments and reviews. Joining everything into one table duplicates rows and double-counts revenue. So there is one table at order level and one at item level, and reviews and payments are aggregated before they are joined.

---

## Definitions

| Term | Definition |
|---|---|
| Revenue | Sum of item `price` on **delivered** orders. Freight is excluded |
| AOV | Revenue divided by distinct orders |
| Freight % | Freight value divided by price |
| Late order | Delivered on a later calendar date than the estimated date |
| Customer | `customer_unique_id` (`customer_id` is created per order) |
| Repeat rate | Customers with more than one delivered order divided by all customers |
| Rankings | Sellers, categories and cities need 30+ orders to be ranked |

---

## Limitations

- **No profit or margin.** The data has no costs, so revenue is the main measure.
- **Association, not causation.** Links between delivery, freight, listing quality and sales cannot be proven causal. The data has no shipping distance.
- **Delivered orders only** for revenue and delivery metrics, over 2016 to 2018. The first and last months of the data are partial.
- **Average sales per product is skewed** by a few bestsellers, so it is read together with the share of products that sold.
