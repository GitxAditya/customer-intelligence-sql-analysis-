use customer_intelligence_db;

-- ------------------------------------------------------------Ques 22
 with product_performance as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        p.price,
        p.stock,
        coalesce(sum(oi.quantity),0) as units_sold,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        max(o.order_date) as last_sale_date,
        datediff(curdate(),min(o.order_date)) as days_since_last_sale
	from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on o.order_id = oi.order_id
    left join payments pm on o.order_id = pm.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand, p.price, p.stock
)
select
	prod_name,
    category,
    brand,
    price,
    stock,
    units_sold,
    revenue,
    last_sale_date,
    days_since_last_sale,
    coalesce(last_sale_date, "Never Sold") as last_sale_date,
	days_since_last_sale,
    case
		when units_sold = 0 or last_sale_date is null then 'Dead Stock'
        when days_since_last_sale >= 180 then 'Slow Selling'
        when days_since_last_sale >= 90 then 'Average'
        else 'Good Selling'
    end as product_status,
    round(100.0 * revenue / NULLIF(SUM(revenue) OVER(), 0), 2) AS revenue_share
from product_performance
where units_sold <= 10 OR days_since_last_sale >= 90 OR units_sold = 0
order by 
case
	when units_sold = 0 then 1
    when days_since_last_sale >= 180 then 2
    when days_since_last_sale >= 90 then 3
    else 4
end,
units_sold asc