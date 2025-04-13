/*
=============================================================================================================================
DDL Script: Create Gold Views
=============================================================================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold Layer represents the final dimension and fact tables (Star Schema Method)
    Each view performs transformation and combines data from the silver layer to produce a clean, enriched, and business-ready dataset.

Applications: 
    These views can be queried directly for analytics and reporting.
=============================================================================================================================
*/

--===========================================================================================================================
-- Creates Dimension: gold.dim_customers
--===========================================================================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;

GO

	
CREATE VIEW gold.dim_customer AS (
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_material_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'unknown' THEN ci.cst_gndr -- CRM is a master for gender info
		 ELSE COALESCE(ca.gen,'unknown') 
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM 
	silver.crm_cust_info AS ci
LEFT JOIN 
	silver.erp_cust_az12 ca
ON 
	ca.cid = CI.cst_key
LEFT JOIN 
	silver.erp_loc_a101 la
ON 
	ci.cst_key = la.cid)

--===========================================================================================================================
-- Creates Dimension: gold.dim_product
--===========================================================================================================================

IF OBJECT_ID('gold.dim_product', 'V') IS NOT NULL
	DROP VIEW gold.dim_product;

GO
	
	
CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY pin.prd_start_dt, pin.prd_key) AS product_key,--Surogate key
	pin.prd_id AS product_id,
	pin.prd_key AS product_number,
	pin.prd_nm AS product_name,
	pin.cat_id AS category_id,
	pcg.cat AS category,
	pcg.subcat AS subcategory,
	pcg.maintenance,
	pin.prd_cost AS cost,
	pin.prd_line AS prduct_line,
	pin.prd_start_dt AS product_start_date
FROM silver.crm_prd_info pin
LEFT JOIN silver.erp_px_cat_g1v2 pcg
ON pcg.id = pin.cat_id
WHERE pin.prd_end_dt IS NULL
--===========================================================================================================================
-- Creates Dimension: gold.fact_sales
--===========================================================================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;

GO


CREATE VIEW gold.fact_sales AS 
SELECT 
	sd.sls_ord_num AS order_number,
	-- sd.sls_prd_key,we don't need this column
	-- sd.sls_cust_id, we don't need this column
	gp.product_key,
	gc.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS ship_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products gp
ON sd.sls_prd_key = gp.product_number
LEFT JOIN gold.dim_customer gc
ON sd.sls_cust_id = gc.customer_id
