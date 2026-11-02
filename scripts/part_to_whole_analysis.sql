/*
==================================================================================
Part-to-Whole Analysis
==================================================================================
Purpose:
	- Show which categories contribute the most to overall sales
	- Express each category as a percentage of total sales

Tables Used:
	- gold.fact_sales
	- gold.dim_products

SQL Functions Used:
	- Window function: SUM() OVER ()
	- CAST(), ROUND(), CONCAT()
==================================================================================
*/


-- ================================================================================
-- Category contribution to overall sales
-- ================================================================================

-- Step 1: total sales per category
WITH category_sales AS (
	SELECT
		category,
		SUM(sales_amount) AS total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON p.product_key = f.product_key
	GROUP BY category
)

-- Step 2: compare each category to the grand total
SELECT
	category,
	total_sales,
	-- grand total across all categories (empty OVER() = whole result set)
	SUM(total_sales) OVER ()	AS overall_sales,
	-- cast to FLOAT so the division keeps decimals instead of truncating
	CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;
