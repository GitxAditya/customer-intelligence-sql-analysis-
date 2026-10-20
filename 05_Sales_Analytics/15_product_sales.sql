use customer_intelligence_db;

-- ------------------------------------------------Q15
with product_sales as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
		coalesce(sum(oi.quantity),0) as units_sold,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue
	from products p
    inner join order_items oi on p.prod_id = oi.prod_id
    inner join orders o on oi.order_id = o.order_id
    inner join payments pm on o.order_id = pm.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and pm.payment_status = 'Success'
	group by p.prod_id,p.prod_name,p.category, p.brand
)
select
	rank() over(order by revenue desc) as rank_no,
    prod_name,
    category,
    brand,
    units_sold,
    revenue,
	round(100* revenue/ sum(revenue) over(),2) as revenue_share_percent,
    round(100* sum(revenue) over(order by revenue desc)/ sum(revenue) over(), 2) as cumulative_percent
from product_sales
where revenue > 0
order by rank_no;