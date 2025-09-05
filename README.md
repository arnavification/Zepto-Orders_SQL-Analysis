# Zepto SQL Data Analysis Project

## Project Overview

This project is a complete end-to-end **SQL analysis** on the **Zepto product dataset**. The aim was to simulate a real-world retail data analyst workflow: from creating a structured schema, verifying and cleaning raw product data, to running exploratory queries and deriving meaningful business insights.

The dataset captures product details such as **categories, pricing, discounts, stock availability, and quantities**, making it a strong use case for SQL-based retail and e-commerce analytics.

Instead of limiting the work to a few random queries, the project has been structured to reflect **how SQL is used in practice** for data quality checks, exploratory analysis, KPI generation, and business insights.

---

## Dataset

**Source:** Zepto product dataset (fields related to price, stock, discount, and category).

* **Full Dataset:** 

  * Contains the complete data used (3000+ rows) for all queries and analysis.

### Fields Included:

* `sku_id` – unique product identifier
* `category` – product category
* `name` – product name
* `mrp` – maximum retail price
* `discount_percent` – discount percentage applied
* `available_quantity` – current stock availability
* `discounted_selling_price` – selling price after discount
* `weight_in_gms` – product weight
* `out_of_stock` – stock availability status (TRUE/FALSE)
* `quantity` – historical purchase quantity
* `discount_amount` (derived) – price gap between MRP and discounted selling price

---

## Steps Followed

### 1. Data Setup

* Created a `zepto` table with proper schema, constraints, and checks (e.g., no negative prices or quantities).
* Imported dataset into PostgreSQL.

### 2. Data Verification

* Row count, sample previews, and distinct category checks.
* Null value detection across key fields.
* Stock availability breakdown (in-stock vs out-of-stock).
* Detection of duplicate product names.

### 3. Data Cleaning

* Removed rows with invalid prices (`mrp = 0` or `discounted_selling_price = 0`).
* Converted **paise → rupees** where values were inflated.
* Deduplicated rows using `sku_id` as reference.
* Standardized category names (lowercase, trimmed).
* Outlier detection for extremely high or negative values.

### 4. Data Analysis & Business Questions

A set of business-oriented queries were designed to simulate real-world analytics:

1. Top 10 best-value products based on discount percentage.
2. High MRP products that are out of stock.
3. Estimated revenue contribution per category.
4. Premium products with low discounts (<10%).
5. Top 5 categories by highest average discount percentage.
6. Price per gram analysis for products above 100g.
7. Grouping products into weight categories (Low, Medium, Bulk).
8. Total inventory weight per category.
9. Revenue share contribution of each category.
10. Top 3 discounted products per category.
11. Correlation between discount range and stock levels.
12. Estimated revenue lost due to out-of-stock items.
13. Price gap analysis between MRP and discounted price.
14. Low stock but high-value products (likely to sell out soon).
15. Weighted average discount per category (stock-adjusted).

### 5. Data Transformation

* Added a new derived column: `discount_amount`.
* Created a **summary table (`zepto_summary`)** with stock value and revenue share per category.

---

## Key Insights

* **Discounts:** Certain categories consistently offer higher discounts, attracting customers through value pricing.
* **Stock Risks:** Several premium, high-MRP products are frequently out of stock, leading to significant revenue at risk.
* **Revenue Concentration:** A few categories contribute the majority of revenue (Pareto distribution).
* **Unit Economics:** Price per gram revealed strong product differentiation between bulk and smaller SKUs.
* **Discount vs Stock:** Products with higher discounts tend to have higher average stock levels, suggesting demand planning around promotions.
* **High-Value Risk Items:** Some low-stock but high-value products are potential sellout risks — critical for inventory teams to monitor.

---

## SQL Functions & Concepts Used

This project demonstrates **moderate SQL concepts**, moving beyond simple queries into applied business analytics:

* **Aggregation Functions**

  * `COUNT()` – product counts, duplicate detection
  * `SUM()` – revenue totals, stock value
  * `AVG()` – average discounts, price insights
  * `ROUND()` – readable output formatting

* **Conditional Expressions**

  * `CASE WHEN` – weight categorization, discount ranges

* **Data Cleaning & Verification**

  * Null handling and invalid value checks
  * Duplicate removal using `DELETE USING`
  * Outlier detection via conditional filters

* **Grouping & Filtering**

  * `GROUP BY` for category and brand-level insights
  * `HAVING` for identifying duplicate product names

* **Sorting & Ranking**

  * `ORDER BY … LIMIT` for top-N queries
  * `ROW_NUMBER() OVER (PARTITION BY …)` for top products per category

* **Window Functions (Intermediate SQL)**

  * `SUM() OVER ()` – revenue share percentages
  * Partitioned aggregation for category-level insights

* **Derived Metrics**

  * `discount_amount`, `price_per_gram`, `weighted_avg_discount`

