/*
====================================================================================
Quality Checks: Silver Layer
====================================================================================
Script Purpose:
    Checks the silver tables for data quality problems after loading:
    - NULL or duplicate primary keys
    - Unwanted leading/trailing spaces
    - Unstandardized or inconsistent values
    - Invalid date ranges and date order
    - Sales / quantity / price that don't add up
    - IDs that don't match between related tables

Usage:
    1. Run EXEC silver.load_silver; first.
    2. Run this script (or one section at a time).
    3. Each check says what result to expect. Anything else is worth
       investigating in bronze and fixing in the silver load.
====================================================================================
*/

USE DataWarehouse;
GO


/* ==================================================================
   silver.crm_cust_info
================================================================== */

-- Check for NULLs or duplicates in the primary key
-- Expectation: no rows
-- GROUP BY puts all rows with the same cst_id together;
-- HAVING filters those groups (WHERE can't be used on COUNT).
SELECT
    cst_id,
    COUNT(*) AS row_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: no rows
-- A value that changes when trimmed has leading or trailing spaces.
SELECT cst_key, cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_key       != TRIM(cst_key)
   OR cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname);

-- Data standardization & consistency
-- Expectation: only 'Single', 'Married', 'n/a'
SELECT DISTINCT cst_material_status
FROM silver.crm_cust_info;

-- Expectation: only 'Female', 'Male', 'n/a'
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;


/* ==================================================================
   silver.crm_prd_info
================================================================== */

-- Check for NULLs or duplicates in the primary key
-- Expectation: no rows
SELECT
    prd_id,
    COUNT(*) AS row_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: no rows
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULL or negative costs
-- Expectation: no rows (the load replaces NULL costs with 0)
SELECT prd_id, prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardization & consistency
-- Expectation: only 'Mountain', 'Road', 'Other Sales', 'Touring', 'n/a'
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for invalid date order (a version can't end before it starts)
-- Expectation: no rows
-- NULL end dates are fine: they mark the current version of a product.
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


/* ==================================================================
   silver.crm_sales_details
================================================================== */

-- Check for invalid date order
-- Expectation: no rows
-- An order can't ship or be due before it was placed.
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check for dates outside a sensible range
-- Expectation: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt < '1900-01-01' OR sls_order_dt > GETDATE()
   OR sls_ship_dt  < '1900-01-01'
   OR sls_due_dt   < '1900-01-01';

-- Check business rule: sales = quantity * price
-- Expectation: no rows
-- Values must not be NULL, zero or negative.
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0    OR sls_quantity <= 0    OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


/* ==================================================================
   silver.erp_cust_az12
================================================================== */

-- Identify out-of-range birthdates
-- Expectation: no future dates (the load sets those to NULL).
-- Very old dates (100+ years) aren't fixed by the load; review them if any appear.
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

-- Data standardization & consistency
-- Expectation: only 'Female', 'Male', 'n/a'
SELECT DISTINCT gen
FROM silver.erp_cust_az12;


/* ==================================================================
   silver.erp_loc_a101
================================================================== */

-- Data standardization & consistency
-- Expectation: full country names and 'n/a' only, no codes (DE, US) or blanks
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


/* ==================================================================
   silver.erp_px_cat_g1v2
================================================================== */

-- Check for unwanted spaces
-- Expectation: no rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat          != TRIM(cat)
   OR subcat       != TRIM(subcat)
   OR maintainance != TRIM(maintainance);

-- Data standardization & consistency
-- Expectation: a small set of clean values (e.g. 'Yes', 'No')
SELECT DISTINCT maintainance
FROM silver.erp_px_cat_g1v2;


/* ==================================================================
   Cross-table checks (do the IDs line up for joins in gold?)
   NOT IN returns rows whose value is missing from the other table's list.
================================================================== */

-- ERP customers with no match in CRM customers
-- Expectation: no rows (confirms the 'NAS' prefix removal worked)
SELECT cid
FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- ERP locations with no match in CRM customers
-- Expectation: no rows (confirms the dash removal worked)
SELECT cid
FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Product categories with no match in the category table
-- Expectation: few or no rows (a category may genuinely be missing from ERP)
SELECT DISTINCT cat_id
FROM silver.crm_prd_info
WHERE cat_id NOT IN (SELECT id FROM silver.erp_px_cat_g1v2);

-- Sales with a product key that doesn't exist in products
-- Expectation: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Sales with a customer ID that doesn't exist in customers
-- Expectation: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_crust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);
