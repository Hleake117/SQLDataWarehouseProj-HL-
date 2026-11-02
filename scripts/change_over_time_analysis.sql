/*
==================================================================================
Change Over Time Analysis
==================================================================================
Purpose:
	- Track how sales performance and customer counts change across time
	- Identify trends and seasonality
	- Measure growth in new customers year over year

Tables Used:
	- gold.fact_sales
	- gold.dim_customers

SQL Functions Used:
	- Date functions: YEAR(), MONTH()
	- Aggregate functions: SUM(), COUNT()
==================================================================================
*/


-- ================================================================================
-- 1) Monthly sales performance
--    Total sales and distinct customers for each year and month
-- ================================================================================
SELECT
	YEAR(order_date)				AS order_year,
	MONTH(order_date)				AS order_month,
	SUM(sales_amount)				AS total_sales,
	COUNT(DISTINCT customer_key)	AS total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL		-- exclude rows with missing order dates
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);


-- ================================================================================
-- 2) New customers per year
--    Counts customers by the year their record was created in the CRM
-- ================================================================================
SELECT
	YEAR(create_date)				AS create_year,
	COUNT(customer_key)				AS total_new_customers
FROM gold.dim_customers
WHERE create_date IS NOT NULL
GROUP BY YEAR(create_date)
ORDER BY YEAR(create_date);
