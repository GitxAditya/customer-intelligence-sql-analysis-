use customer_intelligence_db;

-- ------------------------------------------------------Q17
with basket_analysis as (
	select
		o.order_id,
        o.cust_id,
        o.order_date,
        count(distinct oi.prod_id) as unique_products,
        sum(oi.quantity) as total_units,
        count(distinct oi.item_id) as total_items,
        round(sum(oi.quantity* oi.selling_price),2) as order_value
	from orders o
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
	group by o.order_id, o.cust_id, o.order_date
) 
select
	order_id,
    cust_id,
    order_date,
    unique_products AS distinct_products,
    total_units AS total_units,
    order_value,
    case
        when total_units = 1 then 'Single Item'
        when total_units between 2 and 3 then 'Small Basket'
        when total_units between 4 and 6 then 'Medium Basket'
        else 'Large Basket'
    end as basket_size
from basket_analysis
order by total_units desc;