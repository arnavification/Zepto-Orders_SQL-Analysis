-- ========================================================
-- ZEPTO DATA ANALYSIS
-- ========================================================

-- TABLE CREATION
DROP TABLE IF EXISTS zepto CASCADE;

CREATE TABLE zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(140),
    name VARCHAR(150) NOT NULL,
    mrp NUMERIC(8,2) CHECK (mrp >= 0),
    discount_percent NUMERIC(5,2) CHECK (discount_percent >= 0),
    available_quantity INTEGER CHECK (available_quantity >= 0),
    discounted_selling_price NUMERIC(8,2) CHECK (discounted_selling_price >= 0),
    weight_in_gms INTEGER CHECK (weight_in_gms >= 0),
    out_of_stock BOOLEAN DEFAULT FALSE,
    quantity INTEGER CHECK (quantity >= 0)
);

-- ========================================================
-- DATA VERIFICATION
-- ========================================================

-- Row count
SELECT COUNT(*) AS total_rows
FROM zepto;

-- Sample records
SELECT *
FROM zepto
LIMIT 10;

-- Check for nulls
SELECT *
FROM zepto
WHERE name IS NULL
   OR category IS NULL
   OR mrp IS NULL
   OR discount_percent IS NULL
   OR discounted_selling_price IS NULL
   OR weight_in_gms IS NULL
   OR available_quantity IS NULL
   OR out_of_stock IS NULL
   OR quantity IS NULL;

-- Unique categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- Stock availability breakdown
SELECT out_of_stock, COUNT(sku_id) AS total_products
FROM zepto
GROUP BY out_of_stock;

-- Products with duplicate names
SELECT name, COUNT(sku_id) AS sku_count
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) > 1
ORDER BY sku_count DESC
LIMIT 10;

-- ========================================================
-- DATA CLEANING
-- ========================================================

-- Products with zero or invalid prices
DELETE FROM zepto
WHERE mrp = 0
   OR discounted_selling_price = 0;

-- Convert paise → rupees (if required by dataset)
UPDATE zepto
SET mrp = mrp / 100.0,
    discounted_selling_price = discounted_selling_price / 100.0
WHERE mrp > 1000;  -- safeguard: only apply if values look inflated

-- Remove duplicate rows by keeping lowest sku_id
DELETE FROM zepto a
USING zepto b
WHERE a.name = b.name
  AND a.sku_id > b.sku_id;

-- Outlier detection
SELECT *
FROM zepto
WHERE mrp > 10000
   OR mrp < 0
   OR discounted_selling_price < 0;

-- ========================================================
-- DATA ANALYSIS QUERIES
-- ========================================================

-- Q1. Top 10 best-value products by discount %
SELECT name, category, discount_percent
FROM zepto
ORDER BY discount_percent DESC
LIMIT 10;

-- Q2. High-MRP products that are out of stock
SELECT name, mrp
FROM zepto
WHERE out_of_stock = TRUE
  AND mrp > 200
ORDER BY mrp DESC;

-- Q3. Estimated revenue by category
SELECT category,
       SUM(discounted_selling_price * available_quantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue DESC;

-- Q4. Premium products with low discounts
SELECT name, mrp, discount_percent
FROM zepto
WHERE mrp > 500
  AND discount_percent < 10
ORDER BY mrp DESC, discount_percent ASC;

-- Q5. Top 5 categories by avg. discount %
SELECT category,
       ROUND(AVG(discount_percent), 2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Price per gram (for products >100g)
SELECT name, weight_in_gms, discounted_selling_price,
       ROUND(discounted_selling_price::NUMERIC / weight_in_gms, 2) AS price_per_gram
FROM zepto
WHERE weight_in_gms >= 100
ORDER BY price_per_gram ASC;

-- Q7. Categorize products by weight
SELECT name, weight_in_gms,
       CASE 
           WHEN weight_in_gms < 1000 THEN 'Low'
           WHEN weight_in_gms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_category
FROM zepto;

-- Q8. Total inventory weight per category
SELECT category,
       SUM(weight_in_gms * available_quantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight DESC;

-- Q9. Revenue share by category
SELECT category,
       SUM(discounted_selling_price * available_quantity) AS total_revenue,
       ROUND(
           SUM(discounted_selling_price * available_quantity) * 100.0 /
           SUM(SUM(discounted_selling_price * available_quantity)) OVER (), 2
       ) AS revenue_share_percent
FROM zepto
GROUP BY category
ORDER BY revenue_share_percent DESC;

-- Q10. Top 3 discounted products per category
SELECT category, name, discount_percent
FROM (
    SELECT category, name, discount_percent,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY discount_percent DESC) AS rn
    FROM zepto
) ranked
WHERE rn <= 3
ORDER BY category, discount_percent DESC;

-- Q11. Correlation: Discount vs Stock Levels
SELECT 
    CASE 
        WHEN discount_percent >= 30 THEN 'High Discount (>=30%)'
        WHEN discount_percent >= 15 THEN 'Medium Discount (15-30%)'
        ELSE 'Low Discount (<15%)'
    END AS discount_range,
    ROUND(AVG(available_quantity), 2) AS avg_stock
FROM zepto
GROUP BY discount_range
ORDER BY avg_stock DESC;

-- Q12. Revenue lost due to out-of-stock products
SELECT category,
       SUM(discounted_selling_price * quantity) AS revenue_at_risk
FROM zepto
WHERE out_of_stock = TRUE
GROUP BY category
ORDER BY revenue_at_risk DESC;

-- Q13. Price gap analysis (MRP vs discounted price)
SELECT name, mrp, discounted_selling_price,
       ROUND(mrp - discounted_selling_price, 2) AS price_gap
FROM zepto
ORDER BY price_gap DESC
LIMIT 10;

-- Q14. Low stock but high value items
SELECT name, available_quantity, discounted_selling_price,
       ROUND(available_quantity * discounted_selling_price, 2) AS total_value
FROM zepto
WHERE available_quantity < 20
ORDER BY total_value DESC
LIMIT 10;

-- Q15. Weighted avg discount % per category
SELECT category,
       ROUND(
           SUM(discount_percent * discounted_selling_price * available_quantity) / 
           NULLIF(SUM(discounted_selling_price * available_quantity), 0), 
       2) AS weighted_avg_discount
FROM zepto
GROUP BY category
ORDER BY weighted_avg_discount DESC;

-- ========================================================
-- DATA TRANSFORMATION
-- ========================================================

-- Add derived column for discount amount
ALTER TABLE zepto
ADD COLUMN discount_amount NUMERIC(8,2);

UPDATE zepto
SET discount_amount = mrp - discounted_selling_price;

-- Standardize category names
UPDATE zepto
SET category = LOWER(TRIM(category));

-- ========================================================
-- KPI SUMMARY TABLE
-- ========================================================

DROP TABLE IF EXISTS zepto_summary;

CREATE TABLE zepto_summary AS
SELECT category, name,
       SUM(available_quantity * discounted_selling_price) AS stock_value,
       ROUND(
           SUM(available_quantity * discounted_selling_price) * 100.0 /
           SUM(SUM(available_quantity * discounted_selling_price)) OVER (PARTITION BY category), 
       2) AS revenue_share_percent
FROM zepto
GROUP BY category, name
ORDER BY category, revenue_share_percent DESC;
