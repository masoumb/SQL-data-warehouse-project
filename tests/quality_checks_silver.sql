/*
============================================================================================
Quality Checks
============================================================================================
Script Purpose:
  The purpose of his work is to perfomr quality checks for data consistency, accuracy, and 
standardization across the silver schema such as:
  - Null or Duplicates
  - Unwanted spaces in string fields
  - Data Standardization & consistency
  - Invalid data ranges and oders
  - Data consistency between related field
Note:
  Run these checks after loading silver layer to investigate and check data
============================================================================================
*/

--==========================================================================================
--Checking 'silver.crm_cust_info'

/* Data Cleaning*/===========================================================================
-- Quality Check: check for Nulls or duplicates. A primary Key must be unique and not null
-- Expectation: No Result
SELECT 
  cst_id, 
  COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*)>1 OR cst_id IS NULL


-- There should not be any unwanted spaces in string values(cst_firstname & cst_lastname,...)
-- Expectation: No Result
-- TRIM() removes leading and trailing spaces from a string 
-- Check for spaces in firstname
SELECT
cst_firstname
FROM
silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Check for spaces in lastname
SELECT
cst_lastname
FROM
silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Check for spaces in gender
SELECT
cst_gndr
FROM
silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

-- Check for spaces in marital status
SELECT
cst_material_status
FROM
silver.crm_cust_info
WHERE cst_material_status != TRIM(cst_material_status)

/* Data Standardization*/=========================================================================== 
-- Quality Check: Check the consistency of values in low cardinality columns.
-- In our data warehouse, we aim to store clear and meaningful values rather than using abbreviated terms. 
-- There are 3 unique values for cst_gndr: M, F, NULL. We will replace them with M:Male, F:Female, Null: Unknown

SELECT DISTINCT cst_gndr
FROM 
silver.crm_cust_info
--There are 3 unique values for cst_gndr: M, S, NULL. We will replace them with M:Married, S:Single, Null: Unknown
SELECT DISTINCT cst_material_status
FROM 
silver.crm_cust_info

--==========================================================================================
-- Checking 'silver.crm_prd_info'
-- Quality Check: Check for Nulls or Duplicaes in Primary Key
-- Expectation: No Result
SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*)>1 or prd_id IS NULL

-- Quality Check: No unwanted spacs
-- Expectation: No Result
SELECT prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLS or Negative Numbers
-- Expectaions: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost<0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for Invali Date Orders: End date must not be smaller tha n the start date
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt

--==========================================================================================
-- Checking 'silver.crm_sales_details'
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
-- WHERE sls_ord_num != TRIM(sls_ord_num)
-- WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info) --check the data integrity
-- all the prd_key from sales details can be connected to product key from product info
-- WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)
-- all cust_id from sales details exist in cust_id from sliver customer info 

-- Ckeck for Invalid Dates
-- Negative numbers or zeros can't be cast into a date
-- We can make the zero values into NULL using NULLIF
-- NULLIF: Returns NULL if two given values are equal; Otherwise, it returns the first expression.
-- Length of date must be 8
-- Date should not be higher than 20500101 OR 19000101: check for outliers by validating the boundaries of the date range
-- Order date must always be earlier than the shipping date or due date
SELECT 
NULLIF(sls_order_dt, 0) AS sls_order_dt 
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
	OR LEN(sls_order_dt) != 8 
	OR sls_order_dt > 20500101 
	OR sls_order_dt < 19000101
-- Check for Invalid date orders
-- We don't have such mistake in our data
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
	  OR sls_order_dt > sls_due_dt

-- Business Rule: Sales = quantity * price
-- Negative, zeros, nulls are not allowed!
-- We have some negtaive, zero or null values here!
-- Rules: If sales is negative, zero, or null, derive it using quantity & pice.
--        If price is zero or null, calculate it using sales and quantity.
--        If price is negative, convert it to a positive values.		
SELECT 
*
FROM silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity
	  OR sls_sales IS NULL OR sls_price IS NULL OR sls_quantity IS NULL
	  OR sls_sales <= 0 OR sls_price <= 0 OR sls_quantity <= 0
ORDER BY sls_sales, sls_quantity, sls_price

--==========================================================================================
-- Checking 'silver.erp_cust_az12'

-- Identify Out-Of-Range Dates
SELECT DISTINCT
bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR  bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

-- Quality check of our Silver layer:
-- Identify Out-Of-Range Dates
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR  bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT gen
FROM silver.erp_cust_az12

--==========================================================================================
-- Checking 'silver.erp_loc_a101'
-- Data Standardization & Consistency
SELECT DISTINCT 
cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;

SELECT * FROM silver.erp_loc_a101

--==========================================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- Check for unwanted spaces
SELECT  * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Data Standardization & cONSISTENCY
SELECT DISTINCT 
cat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT 
maintenance  
FROM bronze.erp_px_cat_g1v2


