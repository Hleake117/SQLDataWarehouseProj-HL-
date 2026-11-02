/*
==================================================================================
Data Segmentation
==================================================================================
Purpose:
	- Group products and customers into meaningful segments
	- Count how many items fall into each segment

Tables Used:
	- gold.dim_products
	- gold.fact_sales
	- gold.dim_customers

SQL Functions Used:
	- CASE expressions
	- Aggregate functions: SUM(), MIN(), MAX(), COUNT()
	- DATEDIFF()
==================================================================================
*/


-- ================================================================================
-- 1) Product cost segments
--    Segment products into cost ranges and count the products in each range
-- ================================================================================

-- Step 1: assign each product to a cost range
WITH product_segments AS (
	SELECT
		product_key,
		product_name,
		cost,
		CASE
			WHEN cost < 100 THEN 'Below 100'
			WHEN cost BETWEEN 100 AND 500 THEN '100-500'
			WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
			ELSE 'Above 1000'
		END AS cost_range
	FROM gold.dim_products
)

-- Step 2: count products per range
SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;


-- ================================================================================
-- 2) Customer spending segments
--    Group customers into three segments based on spending behavior:
--      - VIP:     at least 12 months of history and spending more than 5,000
--      - Regular: at least 12 months of history and spending 5,000 or less
--      - New:     less than 12 months of history
--    Then count the customers in each segment
-- ================================================================================

-- Step 1: total spending and purchase history length per customer
WITH customer_spending AS (
	SELECT
		c.customer_key,
		SUM(f.sales_amount)								AS total_spending,
		MIN(f.order_date)								AS first_order,
		MAX(f.order_date)								AS last_order,
		DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) AS lifespan	-- months between first and last order
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
		ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)

-- Step 2: assign a segment to each customer, then count customers per segment
SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM (
	SELECT
		customer_key,
		CASE
			WHEN lifespan >= 12 AND total_spending > 5000  THEN 'VIP'
			WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
			ELSE 'New'
		END AS customer_segment
	FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;
