use customer_intelligence_db;

-- -------------------------------------------------------------Ques 21
with product_sales as (
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity),0) as total_quantity,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue
	from products p
    inner join order_items oi on p.prod_id = oi.prod_id
    inner join orders o on o.order_id = oi.order_id
    inner join payments pm on o.order_id = pm.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand
),
total_revenue as(
	select
		sum(revenue) as total
	from product_sales
)
select
	rank() over(order by revenue desc) as product_rank,
	p.prod_name,
    p.category,
    p.brand,
    p.total_orders,
    p.total_quantity,
    p.revenue,
    round(100* p.revenue/t.total) as revenue_percent,
	round(sum(p.revenue) over(order by p.revenue desc) / t.total, 2) as cumulative_percent
from product_sales p
cross join total_revenue t
where p.revenue >0
order by product_rank