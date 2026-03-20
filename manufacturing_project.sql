create database manufacturing_project;
use manufacturing_project;

-- 1. Total Profit by Product(Top 10)
select p.product_name, sum(p.margin * pr.quantity_produced) as total_profit from production pr
left join products p on p.product_id = pr.product_id
group by p.product_name
order by total_profit desc limit 10;

-- 2. Suppliers with Profit Above 30 Million
select s.supplier_name, sum(p.margin * pr.quantity_produced) as total_profit from production pr
left join products p on p.product_id = pr.product_id
inner join suppliers s on s.supplier_id = pr.supplier_id
group by s.supplier_name having total_profit > 30000000
order by total_profit desc;

-- 3. Find products whose average defect rate is greater than overall average defect rate. 
select p.product_name, round(avg(d.defect_quantity / pr.quantity_produced),2) as defect_rate from production pr
left join products p on p.product_id = pr.product_id
inner join defects d on d.production_id = pr.production_id
group by p.product_name
having avg(d.defect_quantity / pr.quantity_produced) >
(select round(avg(d2.defect_quantity / pr2.quantity_produced),2) from production pr2
inner join defects d2 on d2.production_id = pr2.production_id);

-- 4. Rank products by total profit and return top 5.
with product_profit as(
select p.product_name, sum(p.margin * pr.quantity_produced) as total_profit from production pr
left join products p on p.product_id = pr.product_id
group by p.product_name
)
select *,
dense_rank() over(order by total_profit desc) as rnk
from product_profit limit 5;

-- 5. Worst 5 Suppliers by Defect Rate.
with supplier_by_defect_rate as(
select s.supplier_name, round(avg(d.defect_quantity / pr.quantity_produced),2) as defect_rate from production pr
inner join suppliers s on s.supplier_id = pr.supplier_id
inner join defects d on d.production_id = pr.production_id
group by s.supplier_name
)
select *,
row_number() over(order by defect_rate desc) as rnk
from supplier_by_defect_rate limit 5;

-- 6. Show total quantity produced per month. 
select date_format(production_date, '%Y-%m') as month, sum(quantity_produced) as total_quantity
from production
group by date_format(production_date, '%Y-%m')
order by month;

-- 7. Show supplier profit and compare it with overall average profit.
with supplier_profit as (
select s.supplier_name, sum(p.margin * pr.quantity_produced) as total_profit from production pr
left join products p on p.product_id = pr.product_id
inner join suppliers s on s.supplier_id = pr.supplier_id
group by s.supplier_name
)
select supplier_name, total_profit, (select avg(total_profit) from supplier_profit) as overall_avg_profit,
case when total_profit > (select avg(total_profit) from supplier_profit) 
then 'Above Average'
else 'Below Average' end as comparison
from supplier_profit;

-- 8. Calculate running total of quantity produced ordered by production_date.
with daily_production as (
select production_date, sum(quantity_produced) as total_quantity from production group by production_date
)
select *,
sum(total_quantity) over (order by production_date) as running_total
from daily_production;

-- 9. Show each production_date with previous day quantity and calculate difference.
with daily_production as (
select production_date, sum(quantity_produced) as total_quantity from production
group by production_date
)
select production_date, total_quantity,
lag(total_quantity) over (order by production_date) as previous_day_quantity,
total_quantity - lag(total_quantity) over (order by production_date) as difference
from daily_production;

-- 10. Classify products:
-- High Profit (> 50M)
-- Medium Profit (20M–50M)
-- Low Profit (< 20M)
with product_profit as(
select p.product_name, sum(p.margin * pr.quantity_produced) as total_profit from production pr
left join products p on p.product_id = pr.product_id
group by p.product_name
)
select product_name, total_profit,
case when total_profit > 50000000 then 'High Profit'
when total_profit between 20000000 and 50000000 then 'Medium Profit'
else 'Low Profit' end as profit_category
from product_profit order by total_profit desc;





