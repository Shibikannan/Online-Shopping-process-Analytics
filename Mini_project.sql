--   SQL II - Mini Project
-- _________________________________________________________
create database mini_project;
use mini_project;
-- Composite data of a business organisation, confined to ‘sales and delivery’ domain is given for the period of last decade. From the given data retrieve solutions for the given scenario.
show tables;
-- 1.Join all the tables and create a new table called combined_table.
-- (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
with combined_table1 as (
SELECT 
    mf.*
FROM
    mini_project.market_fact mf
         JOIN
    mini_project.cust_dimen cd ON mf.Cust_id = cd.Cust_id
        INNER JOIN
    mini_project.prod_dimen pd ON mf.Prod_id = pd.Prod_id
        INNER JOIN
    mini_project.orders_dimen od ON mf.Ord_id = od.Ord_id
		inner join 
	mini_project.shipping_dimen sd on mf.Ship_id = sd.ship_id) select * from  combined_table1;
    
    drop table combined_table;
    
CREATE TABLE combined_table AS (SELECT mf.*,
    cd.Customer_Name,
    cd.Customer_Segment,
    cd.Province,
    cd.Region,
    pd.Product_Category,
    pd.Product_Sub_Category,
    od.Order_Date,
    od.Order_ID,
    od.Order_Priority,
    sd.Ship_Mode,
    sd.Ship_Date FROM
    mini_project.market_fact mf
        JOIN
    mini_project.cust_dimen cd ON mf.Cust_id = cd.Cust_id
        INNER JOIN
    mini_project.prod_dimen pd ON mf.Prod_id = pd.Prod_id
        INNER JOIN
    mini_project.orders_dimen od ON mf.Ord_id = od.Ord_id
        INNER JOIN
    mini_project.shipping_dimen sd ON mf.Ship_id = sd.ship_id);
select * from shipping_dimen;
-- 3.Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
alter table combined_table add column DaysTakenForDelivery integer;
UPDATE combined_table 
SET 
    DaysTakenForDelivery = DATEDIFF(Ship_Date, Order_Date);

select * from combined_table;
-- 4.Find the customer whose order took the maximum time to get delivered.
SELECT 
    Customer_Name
FROM
    combined_table
WHERE
    DaysTakenForDelivery IN (SELECT 
            MAX(DaysTakenForDelivery)
        FROM
            combined_table);
-- 5.Retrieve total sales made by each product from the data (use Windows function)
select distinct Prod_id,round(sum(sales) over (partition by Prod_id order by Prod_id)) as prod_tot_sales from combined_table;
-- 6.Retrieve total profit made from each product from the data (use windows function)
select distinct Prod_id,round(sum(Profit) over(partition by  Prod_id),2) as tot_profit from combined_table;
-- 7.Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
select count(distinct cust_id) as unique_customers from combined_table where MONTH(Order_Date) = 1 AND YEAR(Order_Date) = 2011;

with every_month as (
SELECT 
    Cust_id, MONTH(order_date) AS month,count(MONTH(Order_Date)) over(partition by Cust_id)  as no_of_months
FROM
    combined_table
WHERE
    cust_id IN (SELECT DISTINCT
            Cust_id
        FROM
            combined_table
        WHERE
            MONTH(Order_Date) = 1
                AND YEAR(Order_Date) = 2011)
        AND YEAR(Order_Date) = 2011
GROUP BY Cust_id , MONTH(order_date)
ORDER BY Cust_id , MONTH(order_date)) select * from every_month where no_of_months =12 order by Cust_id,no_of_months;

-- 8.Retrieve month-by-month customer retention rate since the start of the business.(using views)
-- Tips: 
-- #1: Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple # years since whenever business started operations
-- # 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
-- # 3: Calculate the time gaps between visits
-- # 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
-- # 5: calculate the retention month wise

create or replace view retention as (
SELECT DISTINCT
    c.Cust_id,
    c.Customer_Name,
    YEAR(Order_Date) AS years,
    MONTH(Order_Date) AS mon,
    MONTH(Order_Date)- lag(MONTH(Order_Date)) over(partition by Cust_id,YEAR(Order_Date) order by MONTH(Order_Date),YEAR(Order_Date)) as retention,
 case when   MONTH(Order_Date)- lag(MONTH(Order_Date)) over(partition by Cust_id,YEAR(Order_Date) order by MONTH(Order_Date),YEAR(Order_Date)) =1 then 'Retained'
 when   MONTH(Order_Date)- lag(MONTH(Order_Date)) over(partition by Cust_id,YEAR(Order_Date) order by MONTH(Order_Date),YEAR(Order_Date)) >1 then 'irregular'
 when   MONTH(Order_Date)- lag(MONTH(Order_Date)) over(partition by Cust_id,YEAR(Order_Date) order by MONTH(Order_Date),YEAR(Order_Date)) is NULL then 'churned'
 end
 as retention_category
FROM
    mini_project.combined_table c
GROUP BY c.Cust_id , c.Customer_Name , MONTH(Order_Date) , YEAR(Order_Date) order by c.Cust_id);
select * from mini_project.retention;
