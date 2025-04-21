select * from gold.dim_customers
select * from gold.dim_products
select * from gold.fact_sales

select Year(order_date) as Order_Year, Month(order_date) Order_Month,sum(sales_amount) as Total_Sales,
	   count(Distinct customer_key) as Total_customers, Sum(Quantity) as Total_Quantity
from gold.fact_sales
where order_date IS NOT NULL
group by Year(order_date), Month(order_date)
order by Year(order_date), Month(order_date)


select DATETRUNC(year, order_date) as Order_Date,sum(sales_amount) as Total_Sales,
	   count(Distinct customer_key) as Total_customers, Sum(Quantity) as Total_Quantity
from gold.fact_sales
where order_date IS NOT NULL
group by DATETRUNC(year, order_date)
order by DATETRUNC(year, order_date)


select FORMAT(order_date, 'yyyy-MMM') as Order_Date,sum(sales_amount) as Total_Sales,
	   count(Distinct customer_key) as Total_customers, Sum(Quantity) as Total_Quantity
from gold.fact_sales
where order_date IS NOT NULL
group by FORMAT(order_date, 'yyyy-MMM') 
order by FORMAT(order_date, 'yyyy-MMM') 


select year(order_date) order_year, DATENAME(MONTH, order_date) order_month, sum(sales_amount) Total_Sales
from gold.fact_sales
where order_date IS NOT NULL
group by  year(order_date),DATENAME(MONTH, order_date)
order by year(order_date), DATENAME(MONTH, order_date) 

-- Window Function
select order_date, Total_Sales,
		sum(Total_Sales) OVER(order by order_date) as running_total_sales,
		avg_price,
		AVG(avg_price) OVER(order by order_date) as moving_avg_price
from
(
select DATETRUNC(YEAR, order_date) order_date, sum(sales_amount) Total_Sales,
		AVG(Price) avg_price
from gold.fact_sales
where order_date IS NOT NULL
group by DATETRUNC(YEAR, order_date)
) t




with yearly_product_sales as 
(
select YEAR(s.order_date) order_year,p.product_name, sum(s.sales_amount) Current_Sales
from gold.fact_sales s
left join gold.dim_products p on s.product_key = p.product_key
where order_date IS NOT NULL
group by YEAR(order_date),p.product_name
)
select order_year, product_name, Current_Sales , AVG(Current_Sales) over(partition by product_name) avg_sales,
		Current_Sales - AVG(Current_Sales) over(partition by product_name) diff_avg,
		case when Current_Sales - AVG(Current_Sales) over(partition by product_name) > 0 then 'Above AVG'
			 when Current_Sales - AVG(Current_Sales) over(partition by product_name) < 0 then 'below AVG'
			 else 'AVG'
	    END avg_change,
		LAG(Current_Sales) over(partition by product_name order by order_year) py_Sales,
		Current_Sales - LAG(Current_Sales) over(partition by product_name order by order_year) diff_py,
		case when Current_Sales - LAG(Current_Sales) over(partition by product_name order by order_year) > 0 then 'Increase'
			 when Current_Sales - LAG(Current_Sales) over(partition by product_name order by order_year) < 0 then 'Decrease'
			 else 'No Change'
	    END py_change
from yearly_product_sales
order by order_year,product_name



with category_sales as
(
select p.category,sum(s.sales_amount) total_sales
from gold.fact_sales s
left join gold.dim_products p on p.product_key= s.product_key 
group by category
)
select category, total_sales , sum(total_sales) over() as overall_sales,
	concat(round(cast(total_sales as float) / sum(total_sales) over() * 100, 2),'%') as percentage_of_total
from category_sales
order by total_sales Desc


with Product_Segments as (
select product_key, product_name, cost,
		case when cost < 100 then 'Below 100'
			 when cost between 100 and 500 then '100-500'
			 when cost between 500 and 1000 then '500-1000'
			 else 'Above 1000'
		END Cost_Range
from gold.dim_products
)
select Cost_Range, Count(product_key) total_products
from Product_Segments
group by Cost_Range;



with customer_spending AS
(
SELECT c.customer_key , SUM(s.sales_amount) total_spending,
Min(order_date) first_order, MAX(order_date) last_order,	
DATEDiFF(MONTH,Min(order_date), MAX(order_date)) AS LifeSpan,
CASE WHEN DATEDiFF(MONTH,Min(order_date), MAX(order_date)) >= 12 and SUM(s.sales_amount) > 5000 THEN 'VIP'
	 WHEN DATEDiFF(MONTH,Min(order_date), MAX(order_date)) >= 12 and SUM(s.sales_amount) <= 5000 THEN 'REGULAR'
	 ELSE 'NEW'
END customer_segment
from gold.fact_sales s
left join gold.dim_customers c on c.customer_key = s.customer_key
group by c.customer_key
) 
select customer_segment, COUNT(customer_key) total_customers
from customer_spending
group by customer_segment
order by total_customers DESC;


CREATE VIEW gold.report_customers AS
WITH base_query AS 
(
select s.order_number,s.product_key,s.order_date,s.sales_amount, s.quantity ,
	c.customer_key,c.customer_number,c.first_name,c.last_name,
	CONCAT(c.first_name, ' ', c.last_name) Customer_Name, c.birthdate,
	DATEDIFF(YEAR, c.birthdate, GETDATE()) age
from 
gold.fact_sales s
left join gold.dim_customers c on c.customer_key = s.customer_key
where order_date IS NOT NULL
), common_aggregations AS
(
select 
customer_key,customer_number,Customer_Name,age,
count(DISTINCT order_number) total_orders,
sum(sales_amount) total_sales,
sum(quantity) total_quantity,
count(DISTINCT product_key) total_products,
 MAX(order_date) last_order_date,
DATEDiFF(MONTH,Min(order_date), MAX(order_date)) AS LifeSpan
from base_query 
group by customer_key,customer_number,Customer_Name,age
)
select customer_key,customer_number,Customer_Name,age,
total_orders,total_sales,total_quantity,total_products,LifeSpan,last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS receny,
CASE WHEN age < 20  THEN 'Under 20'
	 WHEN age between 20 and 29 THEN '20-29'
	 WHEN age between 30 and 39 THEN '30-39'
	 WHEN age between 40 and 49 THEN '40-49'
	 ELSE '50 and Above'
END age_group,
CASE WHEN LifeSpan >= 12 and total_sales > 5000 THEN 'VIP'
	 WHEN LifeSpan >= 12 and total_sales <= 5000 THEN 'REGULAR'
	 ELSE 'NEW'
END customer_segment,
case when total_orders = 0 then 0
	 ELSE total_sales / total_orders
END avg_order_value,
CASE WHEN LifeSpan = 0 then 0
	 ELSE total_sales/ LifeSpan
END avg_monthly_spend
from common_aggregations


SELECT age_group, customer_segment,count(customer_key) total_customers,
sum(total_sales) total_sales
FROM gold.report_customers
group by age_group,customer_segment;



CREATE VIEW gold.report_Products AS
with base_query as
(
select p.product_key, p.product_name, p.product_number, p.category, p.subcategory,p.cost,s.order_number,s.quantity,s.customer_key,
	s.order_date ,s.sales_amount
from gold.fact_sales s
left join gold.dim_products p on p.product_key = s.product_key
where s.order_date IS NOT NULL
), common_agg as
(
select 
product_key,product_number,product_name,category,subcategory,cost,
count(DISTINCT order_number) total_orders,
sum(sales_amount) total_sales,
sum(quantity) total_quantity,
count(DISTINCT customer_key) total_customer,
MAX(order_date) last_sale_date,
DATEDiFF(MONTH,Min(order_date), MAX(order_date)) AS LifeSpan,
ROUND(
    CAST(SUM(sales_amount) AS FLOAT) / NULLIF(SUM(quantity), 0), 
2) AS avg_selling_price
from base_query 
group by product_key,product_number,product_name,category,subcategory,cost
)
select  product_key,product_name,category,subcategory,total_sales,
DATEDIFF(month,last_sale_date,GETDATE()) receny_in_months,
case when total_sales > 50000 then 'HIGH Performance'
			when total_sales >= 10000 then 'MID Range'
			else 'LOW Perfromer'
end product_segment,
total_orders,
total_customer,
total_quantity,
avg_selling_price,
CASE
    WHEN total_orders = 0 THEN 0
    ELSE total_sales / total_orders
END AS avg_order_revenue,

CASE
    WHEN lifespan = 0 THEN total_sales
    ELSE total_sales / lifespan
END AS avg_monthly_revenue

from common_agg



select product_segment, count(product_key) total_products,
sum(total_sales) total_sales
from gold.report_Products
group by product_segment


