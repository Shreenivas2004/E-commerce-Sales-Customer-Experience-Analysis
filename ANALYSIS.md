# Analysis: What drives revenue, delivery performance and retention on Olist

This document summarises the findings from the Power BI dashboard (`dashboard.pbix`) built on the Olist Brazilian e-commerce dataset. All figures are computed from the data inside the dashboard file and match its KPI cards. Amounts are in Brazilian reais (R$), for **delivered orders** unless stated, covering 2016 to August 2018.

## Summary

| Metric | Value |
|---|---|
| Revenue (delivered orders, product price only) | R$ 13.22M |
| Orders / customers / sellers | 96,478 / 93,358 / 2,970 |
| Average order value | R$ 137.04 |
| Freight as % of product price | 16.6% |
| Average review score | 4.16 |
| Orders delivered later than estimated | 6.8% |
| Average delivery time | 12.5 days |
| Customers who ordered more than once | 3.0% |

**Five things stand out:**

1. **Late delivery is the biggest driver of bad reviews.** Review scores fall from 4.29 for early orders to 1.70 for orders 8 or more days late.
2. **Almost nobody reorders.** 97% of customers bought once, so growth depends on winning new customers.
3. **Supply is concentrated in São Paulo, and demand is spread wider.** 60% of sellers are in São Paulo state, but only 42% of customers are. Orders that cross state lines take about twice as long and carry higher freight.
4. **Revenue depends on a small group of sellers.** The top 10% of sellers earn 67% of revenue.
5. **Growth has levelled off.** Monthly revenue climbed through 2017 and has stayed between about R$0.83M and R$0.98M since January 2018.

---

## 1. Revenue trend

![Monthly revenue](images/analysis_monthly_revenue.png)

- Revenue grew from about R$0.11M in January 2017 to R$0.65M in October 2017, then peaked at **R$0.99M in November 2017**. That peak is consistent with Black Friday promotions, but the data cannot confirm the reason.
- From January 2018 the monthly figure is flat, between R$0.83M and R$0.98M. January to August 2018 revenue (R$7.22M) is **141% higher** than the same months of 2017 (R$2.99M), but that comparison starts from a low 2017 base, and month-to-month revenue has not grown since early 2018.
- The earliest months (September to December 2016) hold a handful of orders, so they are left out of the chart and growth rates there are meaningless.

## 2. Delivery and customer satisfaction

![Review score by delivery outcome](images/analysis_review_by_delivery.png)

| Delivery outcome | Orders | Avg review | Share of reviews scoring 1-2 |
|---|---|---|---|
| Early | 88,163 | 4.29 | 9% |
| On the estimated date | 1,280 | 4.04 | 12% |
| 1-3 days late | 1,852 | 3.29 | 32% |
| 4-7 days late | 1,748 | 2.11 | 68% |
| 8+ days late | 2,781 | 1.70 | 79% |

- Only about **4.7% of orders** are 4 or more days late, yet the reviews for those orders are far worse than for any other group. Reviews drop sharply once an order is more than three days late.
- **Estimated delivery dates are generous.** 91.9% of orders arrive before the estimate and only 1.3% on the exact date. A low late rate therefore does not mean delivery is fast. Amazonas has a late rate of only 2.8% but an average delivery time of 26 days, so delivery days is the fairer measure for remote states.
- Late rates vary by state: Alagoas (21%), Maranhão (17%) and Sergipe (15%) are the worst among states with at least 100 orders, against 4.5% in São Paulo. Rio de Janeiro stands out among large states, with 12% late and 15 days average delivery across 12,350 orders.

## 3. Where buyers and sellers are

![Buyers vs sellers by state](images/analysis_buyers_vs_sellers.png)

- **Demand:** São Paulo, Rio de Janeiro and Minas Gerais hold 66.5% of customers and 63.4% of revenue. São Paulo alone is 41.9% of customers and 38.3% of revenue.
- **Supply:** São Paulo state has 59.6% of sellers, ships 71.3% of items sold, and accounts for 64.4% of revenue by seller location.
- **The gap:** Rio de Janeiro has 12.8% of customers but only 5.5% of sellers. Only **7.7%** of items bought in Rio come from Rio sellers, against 76% of items bought in São Paulo that come from São Paulo sellers. Paraná shows the opposite pattern, with 11.3% of sellers and 5.1% of customers.
- This broadly follows where Brazil's population and economy are concentrated, which is context rather than a finding, because the dataset has no population or income data.

### Same-state versus cross-state orders

![Same-state vs cross-state](images/analysis_same_vs_cross_state.png)

| | Same state | Cross state |
|---|---|---|
| Share of items | 36% | **64%** |
| Average delivery time | 7.9 days | 15.0 days |
| Late rate | 4.4% | 7.8% |
| Average review | 4.20 | 4.02 |
| Freight as % of price | 13.0% | 18.3% |

Cross-state orders are the majority, take nearly twice as long, and cost customers more in freight. Because 64% of items cross a state line, the effect on overall delivery performance is large.

## 4. Freight

- Freight is 16.6% of product price overall. It is lowest in São Paulo (13.9%) and highest in the north and north-east: **Maranhão 26.3%, Rondônia 24.7%, Amazonas 24.5%, Sergipe 24.2%, Piauí 24.1%, Tocantins 24.0%** (states with at least 100 orders).
- These are the same states with the longest delivery times. The dataset has no shipping distance or seller shipping cost, so the link between distance, freight and delay is an association, not a measured cause.

## 5. Customers and retention

- 2,801 of 93,358 customers ordered more than once, a **repeat rate of 3.0%**. 97% bought exactly once, and only 181 customers ordered three times.
- Bad delivery and weak retention may be connected, but this dataset does not allow that to be tested directly.

## 6. Sellers

- 2,970 sellers sold at least one delivered item. The **top 10% earn 67.1% of revenue** and the **top 1% earn 25.9%**. The median seller earned R$846 in total.
- Revenue relies heavily on a small group of sellers, mostly in São Paulo.

## 7. Products and categories

- The 74 categories are concentrated too: the top 10 account for **62.4%** of revenue. Health & Beauty (R$1.23M, 9.3%), Watches & Gifts (R$1.17M, 8.8%) and Bed, Bath & Table (R$1.02M, 7.7%) lead.
- **Watches & Gifts** earns the second-highest revenue from far fewer orders (5,495) than Bed, Bath & Table (9,272), because its average item price is higher (R$199 against R$93).
- **Office Furniture** has the lowest average review (3.64) among categories with at least 100 orders. Bulky, slow-to-ship items could explain that, but the data cannot confirm it.
- **Price bands:** items priced R$100 to R$500 bring in 51% of revenue. Items over R$500 are only 2.8% of items sold but 21.7% of revenue. Items under R$50 are 35% of items but 9% of revenue. Review scores are almost the same across bands (4.04 to 4.11).

## 8. Listing quality and sales per product

The dashboard asks whether more photos or longer descriptions go with more sales per product.

- Product sales are very uneven. Across 32,951 products, the **average is 3.3 items but the median is 1**. 53.8% sold exactly once and 2.2% never sold, while the best seller sold 520 items.
- Average sales per product by photo count range only from 3.1 to 3.7 and show no clear pattern. Description length shows the same, except for a higher average (4.07) for descriptions over 2,500 characters, which covers only 863 products and is probably driven by a few bestsellers.
- The share of products that sold at all is about 97-98% in every bucket, and the correlation between sales and either photo count or description length is close to zero.
- Inside the largest categories the pattern is inconsistent. More photos go with higher sales in Bed, Bath & Table, but with lower sales in Auto.
- The one clear signal is for products with **missing listing data** (610 products with no photo or description information): they sell 2.5 items on average against about 3.4 for the rest.

**Conclusion:** on this data, photo count and description length are not reliable predictors of sales per product. The result should not be presented as a lever for sellers.

## 9. Timing and cancellations

- Orders peak on Mondays and Tuesdays (about 16% each) and are lowest on Saturdays (11%). 81.5% of orders are placed between 10:00 and 22:59.
- Cancelled or unavailable orders are 1.2% of all orders (1,234 of 99,441), too small to be a main issue.

---

## Recommendations

1. **Cut severe delays first.** Reviews fall off sharply beyond three days late, and 4+ days late is under 5% of orders. Monitor orders at risk of passing the estimated date, and contact the customer early. Target the highest-delay states and the Rio de Janeiro route first.
2. **Reduce the supply gap outside São Paulo.** Recruit sellers or use regional fulfilment in Rio de Janeiro, Minas Gerais and the north-east, where buyers are served from far away. Track the cross-state share of orders, delivery days and freight % over time.
3. **Review shipping fees in high-freight states.** Freight is 24-26% of price in several northern and north-eastern states against 14% in São Paulo. Test free-shipping thresholds or subsidised shipping there.
4. **Set delivery estimates by route.** 92% of orders arrive before the estimate, so dates could be tightened on short routes, while remote routes need realistic, longer estimates and not an optimistic promise.
5. **Start a retention effort.** With 97% one-time buyers, test post-purchase emails, vouchers for a second order and review-based follow-ups, and track the repeat rate.
6. **Manage concentration risk.** Two-thirds of revenue comes from 10% of sellers. Build account management for top sellers and grow the middle tier.
7. **Fix incomplete listings.** Products with missing photos or descriptions sell less, so prompt sellers to complete them. Do not promise that more photos or longer text will raise sales.

## Limitations

- **No profit or margin.** The data has no cost information, so revenue (product price) is the main measure and freight is reported separately.
- **Association, not causation.** The links between delivery, freight, distance and reviews cannot be proven causal. There is no shipping distance, so state is used as a proxy for geography.
- **Delivered orders only** for revenue and delivery measures. Late means delivered on a later calendar date than the estimate.
- **Period:** September 2016 to August 2018. The first months hold very few orders, and one marketplace snapshot cannot show seasonality across years.
- **Reviews** come only from customers who left one, and an order's score is averaged when it has several. Customers with bad experiences may be more likely to leave a review.
- **Averages are skewed** by a few bestsellers and large sellers, so medians and shares are shown beside them.

## Method

- Data: Olist Brazilian E-Commerce Public Dataset, loaded into MySQL with Python, then modelled into order-level and item-level master tables. Orders with several items, payments or reviews are aggregated before joining, so revenue is not double counted.
- Definitions: revenue is item `price` on delivered orders; AOV is revenue divided by distinct orders; customers are `customer_unique_id`; repeat rate is customers with more than one delivered order divided by all customers; sellers, categories and cities need at least 30 to 100 orders to be ranked.
- The figures above were checked against the dashboard cards: revenue R$13.22M, 96,478 orders, AOV R$137.04, freight 16.63%, late rate 6.77%, early rate 91.89%.
