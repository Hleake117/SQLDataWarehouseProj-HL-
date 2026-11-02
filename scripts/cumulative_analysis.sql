/*
==================================================================================
Cumulative Analysis
==================================================================================
Purpose:
	- Calculate running totals and moving averages over time
	- Show whether the business is growing or declining cumulatively

Tables Used:
	- gold.fact_sales

SQL Functions Used:
	- Window functions: SUM() OVER(), AVG() OVER()
	- Date functions: DATETRUNC(), YEAR()
	- Requires SQL Server 2022 or later for DATETRUNC()
==================================================================================
*/


-- ================================================================================
-- Monthly sales with a running total (resets each year) and a moving average price
--   - Inner query: aggregates sales and average price to the month level
--   - Outer query: applies window functions over those monthly results
-- ================================================================================
SELECT
	order_date,
	total_sales,
	-- running total of sales, restarting at the beginning of each year
	SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales,
	-- moving average of price across all months to date
	AVG(avg_price)   OVER (ORDER BY order_date)								  AS moving_average_price
FROM (
	SELECT
		DATETRUNC(month, order_date)	AS order_date,
		SUM(sales_amount)				AS total_sales,
		AVG(price)						AS avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
) t;
