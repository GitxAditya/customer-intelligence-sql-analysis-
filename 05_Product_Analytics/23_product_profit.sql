use customer_intelligence_db;

-- --------------------------------------------------Ques 23
with product_profit as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        coalesce(round(sum(oi.quantity*p.cost_price),2),0) as cost,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) - 
        coalesce(round(sum(oi.quantity*p.cost_price),2),0) as gross_profit,
        case
			when coalesce(round(sum(oi.quantity*oi.selling_price),2),0) = 0 then 0
            else
				round(
					100* (sum(oi.quantity*oi.selling_price) - sum(oi.quantity*p.cost_price)) /
                    nullif(sum(oi.quantity*oi.selling_price), 0), 2
                )
		end as profit_margin_percent,
        coalesce(sum(oi.quantity),0) as units_sold
	from products p
    inner join order_items oi on p.prod_id = oi.prod_id
    inner join orders o on o.order_id = oi.order_id
    inner join payments pm on o.order_id = pm.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand
)
select
	rank() over(order by revenue desc) as profit_rank,
    prod_name,
    category,
    brand,
    units_sold,
    revenue,
    cost,
    gross_profit,
	profit_margin_percent,
    case
		when  profit_margin_percent >= 40  then "High Margin"
        when  profit_margin_percent >= 20 then "Good Margin"
        when  profit_margin_percent >= 10 then "Medium Margin"
        when  profit_margin_percent  >= 0 then "Low Margin"
        else "Negative Margin"
	end as margin_category
from product_profit
WHERE revenue > 0
ORDER BY profit_rank;