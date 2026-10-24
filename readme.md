# E-commerce Sales & Customer Experience Analysis

End-to-end analysis of the Olist Brazilian e-commerce dataset: raw CSVs loaded into MySQL with Python, modelled with SQL views and master tables, and presented in a 5-page Power BI dashboard.

**Tools:** Python (pandas, SQLAlchemy), MySQL, Power BI, DAX

---

## Key findings

> Fill these from your own results before publishing. Use all-time figures, not slicer-filtered ones.

1. **Late delivery hurts reviews.** Orders delivered on time or early average **[X]** stars, falling to **[Y]** when 8+ days late (`vw_late_vs_review`).
2. **Few customers come back.** Only **[X%]** of customers placed more than one order (`vw_repeat_rate`), so retention is a clear opportunity.
3. **Sales are concentrated in the South-East.** São Paulo alone brings in **[X%]** of revenue, and the top three states **[Y%]**.
4. **Remote states pay more for shipping.** Freight is **[X%]** of price in the highest-freight states against **[Y%]** overall, and these states also see **[late % / delivery days]**.
5. **Seller revenue is concentrated.** The top 10% of sellers earn **[X%]** of revenue.

**Recommendations:** **[2-3 actions that follow from the findings, e.g. recruit sellers outside the South-East, review shipping fees for high-freight states, set delivery estimates by state, run a retention offer]**

Findings are associations, not proven causes. See [Limitations](#limitations).

---

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

The Power BI file is in `powerbi/`. It stores its data inside the file, so the visuals work without a database, but refreshing needs the MySQL setup below.

---

## Data

- **Source:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle. About 100,000 orders from 2016 to 2018.
- **Tables loaded (8):** customers, orders, order items, order payments, order reviews, products, sellers, and the product category name translation.
- The geolocation table is not loaded. The dataset has no cost or profit data, so the project reports revenue, not profit.

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
├── powerbi/                   # Power BI file
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
4. Put the CSV files where the script expects them and run it. It asks for your MySQL password and prints progress as each table loads:
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

**Rebuild rule:** the master tables are snapshots. If you reload the raw tables, rerun `master_table.sql` and the views.

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

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Authentication plugin 'caching_sha2_password' is not supported` | `pip install --upgrade mysql-connector-python` |
| Password contains `@` and the connection fails | Build the engine with `sqlalchemy.engine.URL.create(...)` instead of a URL string |
| `Illegal mix of collations` | Run `SET collation_connection = utf8mb4_0900_ai_ci;` in the same session |
| Syntax error near `OVER` | MySQL is older than 8.0. Upgrade it |
| Power BI cannot find the MySQL driver | Install MySQL Connector/NET and restart Power BI Desktop |
