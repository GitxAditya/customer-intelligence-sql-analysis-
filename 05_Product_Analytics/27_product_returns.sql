use customer_intelligence_db;

-- --------------------------------------------------------Ques 27
with product_returns as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        coalesce(sum(oi.quantity),0) as units_sold,
        coalesce(sum(r.quantity),0) as units_returned,
        coalesce(round(sum(oi.quantity * oi.selling_price),2),0) as revenue,
        coalesce(round(sum(r.quantity * oi.selling_price),2),0) as revenue_lost
	from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
		and o.order_status in ('Delivered', 'Shipped')
	left join payments pm on o.order_id = pm.order_id
		and pm.payment_status = 'Success'
	left join returns r on oi.order_id = r.order_id
		and oi.prod_id =r.prod_id
	group by p.prod_id, p.prod_name, p.category, p.brand
)
select
	rank() over(order by return_rate_percent desc) as return_rank,
    prod_id,
    prod_name,
    category,
    brand,
    units_sold,
    units_returned,
    return_rate_percent,
    revenue_lost,
    risk_level
from (
	select *,
		case
			when units_sold = 0 then 0
            else round(100* units_returned / units_sold, 2)
		end as return_rate_percent,
        case
            when units_sold = 0 then 'No Data'
            when (units_returned * 1.0 / units_sold) >= 0.20 then 'High Risk'
            when (units_returned * 1.0 / units_sold) >= 0.10 then 'Medium Risk'
            when (units_returned * 1.0 / units_sold) >= 0.05 then 'Low Risk'
            else 'Very Low'
        END AS risk_level
	from  product_returns
) as return_analysis
where  units_sold > 0
order by return_rank;