use customer_intelligence_db;

-- -----------------------------------------------------------Ques 28
with product_inventory as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        p.stock as current_stock,
        coalesce(sum(oi.quantity),0) as units_sold,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue
	from products p
    left join order_items oi on oi.prod_id = p.prod_id
    left join orders o on o.order_id = oi.order_id
		and o.order_status IN ('Delivered', 'Shipped')
    left join payments pm on o.order_id = pm.order_id
		and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand, p.stock
)
select
    prod_id,
    prod_name,
    category,
    brand,
    current_stock,
    units_sold,
    revenue,
    case
		when current_stock = 0 and units_sold >0 then units_sold
		when current_stock = 0 and units_sold = 0 then 0
		else round(units_sold / current_stock,2) 
     end as inventory_turnover_ratio,
     case
		when units_sold =0 then "0 units"
        when current_stock = 0 then '0 stock'
        else ROUND(current_stock / (units_sold / 365), 0)
    end as days_of_inventory,
    case
        when current_stock = 0 and units_sold > 0 then 'Fast Moving (Out of Stock)'
        when units_sold = 0 and current_stock > 0 then 'Dead Stock'
        when ROUND(units_sold / current_stock, 2) >= 5 then 'Fast Moving'
        when ROUND(units_sold / current_stock, 2) >= 2 then 'Normal'
        when ROUND(units_sold / current_stock, 2) > 0 then 'Slow Moving'
        else 'Overstocked'
    end as inventory_category,
    rank() over(order by (units_sold / NULLIF(current_stock, 0)) desc) as  turnover_rank
from product_inventory
where units_sold > 0 or current_stock > 0
order by turnover_rank;