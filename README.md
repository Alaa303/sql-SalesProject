# Sales Data Warehouse & Analytics

This project presents a comprehensive SQL-based analysis on sales, customer behavior, and product performance using a star schema data warehouse. The code is written in T-SQL for platforms like Azure Synapse Analytics, SQL Server, or other platforms supporting T-SQL syntax.

## Schema Overview

The project is built on a **data warehouse** consisting of the following schemas and tables:

### **Schema: `gold`**
- `gold.fact_sales`: Contains transactional sales data.
- `gold.dim_customers`: Customer dimension table.
- `gold.dim_products`: Product dimension table.

---

## Analytical Insights

### 1. **Sales Trends**
- Monthly and yearly breakdowns of total sales, unique customers, and quantities.
- Running totals and moving averages using **window functions**.

### 2. **Customer Analytics**
- Classification of customers into **VIP**, **Regular**, and **New** based on lifespan and spending.
- Age segmentation (`Under 20`, `20–29`, `30–39`, etc.).
- Aggregated insights such as:
  - Average Order Value
  - Average Monthly Spend
  - Recency (months since last order)

> View: `gold.report_customers`  
Enriches customer profiles with KPIs for segmentation and targeting.

### 3. **Product Analytics**
- Product segmentation: `HIGH Performance`, `MID Range`, `LOW Performer`.
- Metrics per product:
  - Avg Selling Price
  - Total Sales
  - Total Orders
  - Total Customers
  - Recency in Months

> View: `gold.report_Products`  
Delivers a robust performance view of all products sold.

### 4. **Product Category Contribution**
- Analyzes each category's contribution to overall sales and their percentage share.

### 5. **Year-over-Year Performance**
- Compares each product’s yearly performance against its average and the previous year.
- Calculates YoY growth and trend (`Increase`, `Decrease`, `No Change`).

---

## SQL Features Used
- Common Table Expressions (CTEs)
- Window Functions: `LAG()`, `AVG() OVER`, `SUM() OVER`, etc.
- Date Functions: `YEAR()`, `MONTH()`, `DATENAME()`, `DATEDIFF()`, `FORMAT()`
- Conditional Logic: `CASE WHEN`
- Views for reporting

---

## Sample KPIs
From the created views and queries, you can extract metrics such as:
- **Customer Lifetime Value (CLV)**
- **Average Order Value (AOV)**
- **Customer Segmentation by Age & Value**
- **Product Recency & Monthly Revenue**

---

## File Structure
- `sales_analysis.sql`: Contains all queries and view definitions for customer and product reports.
- `report_customers` (View): Aggregated customer metrics and segmentation.
- `report_products` (View): Aggregated product metrics and segmentation.

---

## How to Use
1. Load your star schema data warehouse with tables: `fact_sales`, `dim_customers`, `dim_products`.
2. Run the queries or views in your SQL environment (SQL Server, Synapse, Azure Data Studio, etc.).
3. Use BI tools like Power BI or Tableau for visualization, connecting directly to the created views.
